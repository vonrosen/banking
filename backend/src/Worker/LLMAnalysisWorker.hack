namespace Banking\Worker;

use namespace HH\Lib\Str;
use type Banking\Redis\IRedisClient;
use type Banking\Clients\IGeminiClient;
use type Banking\Logging\LoggerFactory;
use type HackLogging\Logger;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Models\AnalysisStatus;
use type HackLogging\LogLevel;
use type Banking\Services\RedisStreamService;

final class LLMAnalysisWorker extends BaseWorker {

  public function __construct(
    private IRedisClient $redisClient,
    private IGeminiClient $geminiClient,
    private IAnalysisRepository $analysisRepository,
    private AnalysisStatusStateMachine $statusStateMachine,
    private RedisStreamService $redisStreamService,
  ) {
    parent::__construct(
      $redisClient,
      $analysisRepository,
      $statusStateMachine,
      $redisStreamService,
    );
  }

  public function getAnalysisStatus(): AnalysisStatus {
    return AnalysisStatus::ANALYZING_TRANSACTIONS;
  }

  protected async function processMessageAsync(
    string $id,
    dict<string, string> $fields,
  ): Awaitable<void> {
    $analysisId = $fields['analysis_id'];
    $analysis = await $this->analysisRepository->getAnalysis($analysisId) as nonnull;
    $transactionData = $analysis['transaction_data'] as nonnull;
    $prompt = $this->buildPrompt($transactionData);
    $response = await $this->geminiClient->generateContentAsync($prompt);
    
    await $this->logger->writeAsync(
      LogLevel::INFO,
      Str\format('Gemini response for %s: %s', $analysisId, Str\slice($response['text'], 0, 200)),
      dict[],
    );

    await $this->analysisRepository->updateAnalysisLLMResult(
      $analysisId,
      $response['text'],
    );
  }

  private function buildPrompt(mixed $transactionData): string {
    $transactionsJson = $transactionData is string
      ? $transactionData
      : \json_encode($transactionData);

    return <<<PROMPT
Analyze these bank transactions and identify car insurance payments.

For each insurance payment found, identify:
1. The parent insurance company brand (not payment processors or subsidiaries like "United Financial Casualty" - identify the actual brand like "Progressive")
2. Their website URL
3. The monthly payment amount
4. Which transaction IDs are related

Return ONLY valid JSON in this exact format, no other text:
{"insurance_payments": [{"provider": "Provider Name", "website": "https://example.com", "monthly_amount": 123.45, "transaction_ids": ["id1", "id2"]}]}

If no insurance payments are found, return: {"insurance_payments": []}

Transactions:
{$transactionsJson}
PROMPT;
  }
}

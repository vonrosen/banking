namespace Banking\Controllers;

use namespace HH\Lib\Dict;
use type Banking\Attributes\Route;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\Dtos\{AnalysisEvent, CreateAnalysisRequest};
use type Banking\Redis\IRedisClient;
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Services\RedisStreamService;

final class AnalysisController implements IController {

  const string ANALYSIS_CACHE_PREFIX = 'analysis:';
  const int ANALYSIS_CACHE_TTL_SECONDS = 3600;

  public function __construct(
    private IAnalysisRepository $analysisRepository,
    private IRedisClient $redisClient,
    private AnalysisStatusStateMachine $statusStateMachine,
    private RedisStreamService $redisStreamService,
  ) {}

  <<Route('POST', '/v1/analyses')>>
  public async function createAnalysisAsync(): Awaitable<void> {
    $input = \file_get_contents('php://input');
    $data = \json_decode($input, true);

    $request = $data as CreateAnalysisRequest;
    $user_id = $request['user_id'];
    $bank_login_token = $request['bank_login_token'];

    try {
      $analysis = await $this->analysisRepository->createAnalysis(shape(
        'user_id' => $user_id,
        'bank_login_token' => $bank_login_token,
      ));

      $this->redisClient->xadd(
        $this->redisStreamService->getStreamName(
          $this->statusStateMachine
            ->getNextStatus($this->statusStateMachine->getInitialStatus())
            as nonnull,
        ) as nonnull,
        dict[
          'analysis_id' => $analysis['id'],
          'status' => $analysis['status'],
          'user_id' => $user_id,
        ],
      );

      $analysisDto = shape(
        'id' => $analysis['id'],
        'user_id' => $analysis['user_id'],
        'status' => $analysis['status'],
        'llm_analysis_result' => $analysis['llm_analysis_result'],
        'provider_policy_details' => $analysis['provider_policy_details'],
        'error_message' => $analysis['error_message'],
        'error_step' => $analysis['error_step'],
        'retry_count' => $analysis['retry_count'],
        'created_at' => $analysis['created_at'],
        'updated_at' => $analysis['updated_at'],
      );

      $cacheKey = self::ANALYSIS_CACHE_PREFIX.$analysis['id'];
      $this->redisClient->setex(
        $cacheKey,
        self::ANALYSIS_CACHE_TTL_SECONDS,
        \json_encode($analysisDto),
      );

      \http_response_code(201);
      echo \json_encode($analysisDto);
    } catch (\Exception $e) {
      \http_response_code(500);
      echo \json_encode(shape(
        'error' => 'Failed to create analysis: '.$e->getMessage(),
      ));
    }
  }

  <<Route('GET', '/v1/analyses/{id}')>>
  public async function getAnalysisAsync(): Awaitable<void> {
    $pathParams = \HH\global_get('PATH_PARAMS') as dict<_, _>;
    $analysisId = idx($pathParams, 'id') as ?string;

    if ($analysisId === null) {
      \http_response_code(400);
      echo \json_encode(shape('error' => 'Missing analysis ID'));
      return;
    }

    try {
      $cacheKey = self::ANALYSIS_CACHE_PREFIX.$analysisId;
      $cachedAnalysis = $this->redisClient->get($cacheKey);

      if ($cachedAnalysis !== null) {
        \http_response_code(200);
        echo $cachedAnalysis;
        return;
      }

      $analysis = await $this->analysisRepository->getAnalysis($analysisId);

      if ($analysis === null) {
        \http_response_code(404);
        echo \json_encode(shape('error' => 'Analysis not found'));
        return;
      }

      $analysisDto = shape(
        'id' => $analysis['id'],
        'user_id' => $analysis['user_id'],
        'status' => $analysis['status'],
        'llm_analysis_result' => $analysis['llm_analysis_result'],
        'provider_policy_details' => $analysis['provider_policy_details'],
        'error_message' => $analysis['error_message'],
        'error_step' => $analysis['error_step'],
        'retry_count' => $analysis['retry_count'],
        'created_at' => $analysis['created_at'],
        'updated_at' => $analysis['updated_at'],
      );

      $cacheKey = self::ANALYSIS_CACHE_PREFIX.$analysisId;
      $this->redisClient->setex($cacheKey, 3600, \json_encode($analysisDto));
      \http_response_code(200);
      echo \json_encode($analysisDto);
    } catch (\Exception $e) {
      \http_response_code(500);
      echo \json_encode(shape(
        'error' => 'Failed to get analysis: '.$e->getMessage(),
      ));
    }
  }
}
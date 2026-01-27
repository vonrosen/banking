namespace Banking\Controllers;

use type Banking\Attributes\Route;
use type Banking\Repositories\IAnalysisRepository;
use type Banking\Dtos\CreateAnalysisRequest;
use type Banking\Redis\IRedisClient;

final class AnalysisController implements IController {

  public function __construct(
    private IAnalysisRepository $analysisRepository,
    private IRedisClient $redisClient,
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
        'insurance:get_bank_transactions',
        dict[
          'analysis_id' => $analysis['id'],
          'user_id' => $user_id,
          'bank_login_token' => $bank_login_token,
        ],
      );

      \http_response_code(201);
      echo \json_encode($analysis);
    } catch (\Exception $e) {
      \http_response_code(500);
      echo \json_encode(shape(
        'error' => 'Failed to create analysis: '.$e->getMessage(),
      ));
    }
  }
}
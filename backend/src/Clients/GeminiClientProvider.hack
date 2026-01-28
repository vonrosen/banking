namespace Banking\Clients;

use type Nazg\Glue\{Container, ProviderInterface};

final class GeminiClientProvider implements ProviderInterface<IGeminiClient> {

  public function get(Container $container): IGeminiClient {
    $apiKey = \getenv('GEMINI_API_KEY');
    $mockEnabled = \getenv('MOCKED_TRANSACTION_ANALYSIS') === 'true';
    return new GeminiClient(
      $apiKey is string ? $apiKey : '',
      $mockEnabled,
    );
  }
}

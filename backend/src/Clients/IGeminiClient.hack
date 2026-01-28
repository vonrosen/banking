namespace Banking\Clients;

type GeminiResponse = shape(
  'text' => string,
  'model' => string,
);

interface IGeminiClient {
  public function generateContentAsync(string $prompt): Awaitable<GeminiResponse>;
}

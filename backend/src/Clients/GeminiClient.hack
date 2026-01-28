namespace Banking\Clients;

use namespace HH\Lib\Str;
use type Banking\Logging\LoggerFactory;
use type HackLogging\Logger;
use type HackLogging\LogLevel;

final class GeminiClient implements IGeminiClient {
  const string MODEL = 'gemini-3-flash-preview';
  const string BASE_URL = 'generativelanguage.googleapis.com';
  const float TIMEOUT_SECONDS = 30.0;

  private Logger $logger;

  public function __construct(
    private string $apiKey,
    private bool $mockEnabled = false,
  ) {
    $this->logger = LoggerFactory::getLogger(static::class);
  }

  public async function generateContentAsync(string $prompt): Awaitable<GeminiResponse> {
    $this->logger->writeAsync(
      LogLevel::INFO,
      Str\format('mockEnabled is: %s', $this->mockEnabled ? 'true' : 'false'),
      dict[],
    );
    if ($this->mockEnabled) {
      return $this->getMockedResponse();
    }

    return await $this->callGeminiApiAsync($prompt);
  }

  private async function callGeminiApiAsync(string $prompt): Awaitable<GeminiResponse> {
    $url = Str\format(
      'https://%s/v1beta/models/%s:generateContent?key=%s',
      self::BASE_URL,
      self::MODEL,
      $this->apiKey,
    );

    $body = \json_encode(dict[
      'contents' => vec[
        dict[
          'parts' => vec[
            dict['text' => $prompt],
          ],
        ],
      ],
    ]);

    $ch = \curl_init();
    \curl_setopt($ch, \CURLOPT_URL, $url);
    \curl_setopt($ch, \CURLOPT_POST, true);
    \curl_setopt($ch, \CURLOPT_POSTFIELDS, $body);
    \curl_setopt($ch, \CURLOPT_RETURNTRANSFER, true);
    \curl_setopt($ch, \CURLOPT_SSL_VERIFYPEER, true);
    \curl_setopt($ch, \CURLOPT_TIMEOUT, (int)self::TIMEOUT_SECONDS);
    \curl_setopt($ch, \CURLOPT_HTTPHEADER, vec[
      'Content-Type: application/json',
    ]);

    $response = \curl_exec($ch);
    $error = \curl_error($ch);
    $httpCode = \curl_getinfo($ch, \CURLINFO_HTTP_CODE);
    \curl_close($ch);

    if ($response === false) {
      throw new \Exception(Str\format('Failed to connect to Gemini API: %s', $error));
    }

    $json = \json_decode($response as string, true);
    if ($json is null) {
      throw new \Exception(Str\format('Failed to parse Gemini API response: %s', $response as string));
    }

    if (\array_key_exists('error', $json)) {
      $error = $json['error'];
      throw new \Exception(Str\format('Gemini API error: %s', $error['message'] ?? 'Unknown error'));
    }

    $candidates = $json['candidates'] ?? vec[];
    if (\count($candidates) === 0) {
      throw new \Exception('No candidates in Gemini API response');
    }

    $content = $candidates[0]['content'] ?? dict[];
    $parts = $content['parts'] ?? vec[];
    if (\count($parts) === 0) {
      throw new \Exception('No parts in Gemini API response');
    }

    $text = $parts[0]['text'] ?? '';

    return shape(
      'text' => $text,
      'model' => $json['modelVersion'] ?? self::MODEL,
    );
  }

  private function getMockedResponse(): GeminiResponse {
    $mockResponse = dict[
      'insurance_payments' => vec[
        dict[
          'provider' => 'Progressive',
          'website' => 'https://www.progressive.com',
          'monthly_amount' => 127.50,
          'transaction_ids' => vec['txn_001', 'txn_015', 'txn_029'],
          'confidence' => 0.95,
        ],
      ],
    ];

    return shape(
      'text' => \json_encode($mockResponse) as string,
      'model' => 'mocked',
    );
  }
}

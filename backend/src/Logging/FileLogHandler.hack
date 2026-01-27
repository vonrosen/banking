namespace Banking\Logging;

use type HackLogging\Handler\AbstractProcessingHandler;
use type HackLogging\{LogLevel, RecordShape};

class FileLogHandler extends AbstractProcessingHandler {

  public function __construct(
    private string $filePath,
    protected LogLevel $level = LogLevel::DEBUG,
    protected bool $bubble = true,
  )[] {
    parent::__construct($level, $bubble);
  }

  <<__Override>>
  public async function closeAsync(): Awaitable<void> {
    return;
  }

  <<__Override>>
  protected async function writeAsync(
    RecordShape $record,
  ): Awaitable<void> {
    $formatted = Shapes::idx($record, 'formatted', '');
    $handle = \fopen($this->filePath, 'a');
    if ($handle !== false) {
      \fwrite($handle, $formatted);
      \fclose($handle);
    }
  }
}

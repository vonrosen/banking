namespace Banking\Attributes;

use type HH\MethodAttribute;

final class Route implements MethodAttribute {
  public function __construct(
    private string $method,
    private string $path,
  ) {}

  public function getMethod(): string {
    return $this->method;
  }

  public function getPath(): string {
    return $this->path;
  }
}
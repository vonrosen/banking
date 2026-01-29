namespace Banking\Container;

use type Nazg\Glue\{Container, DependencyFactory, Scope};
use type Banking\Repositories\{IUserRepository, IAnalysisRepository, UserRepository, AnalysisRepository};
use type Banking\Database\ConnectionManager;
use type Banking\Database\DatabaseConfig;
use type Banking\Utils\LoggerFactory;
use type Banking\Database\MigrationRunner;
use type Banking\Controllers\UserController;
use type Banking\Controllers\AnalysisController;
use type Banking\Redis\{IRedisClient, RedisClient, RedisConfig};
use type Banking\Worker\{BankTransactionWorker, LLMAnalysisWorker, NotificationWorker};
use type Banking\Clients\{BankingClient, IBankingClient, IGeminiClient, GeminiClientProvider};
use type Banking\StateMachine\AnalysisStatusStateMachine;
use type Banking\Services\RedisStreamService;

final class AppContainer {
  private static ?Container $container = null;

  public static async function getAsync(): Awaitable<Container> {
    if (self::$container === null) {
      $container = new Container(new DependencyFactory());

      $container->bind(IUserRepository::class)
        ->to(UserRepository::class)
        ->in(Scope::SINGLETON);

      $container->bind(IAnalysisRepository::class)
        ->to(AnalysisRepository::class)
        ->in(Scope::SINGLETON);

      $container->bind(ConnectionManager::class)
        ->to(ConnectionManager::class)
        ->in(Scope::SINGLETON);

      $container->bind(DatabaseConfig::class)
        ->to(DatabaseConfig::class)
        ->in(Scope::SINGLETON);

      $container->bind(MigrationRunner::class)
        ->to(MigrationRunner::class)
        ->in(Scope::SINGLETON);

      $container->bind(UserController::class)
        ->to(UserController::class)
        ->in(Scope::SINGLETON);

      $container->bind(AnalysisController::class)
        ->to(AnalysisController::class)
        ->in(Scope::SINGLETON);

      $container->bind(RedisConfig::class)
        ->to(RedisConfig::class)
        ->in(Scope::SINGLETON);

      $container->bind(IRedisClient::class)
        ->to(RedisClient::class)
        ->in(Scope::SINGLETON);

      $container->bind(BankTransactionWorker::class)
        ->to(BankTransactionWorker::class)
        ->in(Scope::SINGLETON);

      $container->bind(IBankingClient::class)
        ->to(BankingClient::class)
        ->in(Scope::SINGLETON);

      $container->bind(AnalysisStatusStateMachine::class)
        ->to(AnalysisStatusStateMachine::class)
        ->in(Scope::SINGLETON);

      $container->bind(RedisStreamService::class)
        ->to(RedisStreamService::class)
        ->in(Scope::SINGLETON);

      $container->bind(IGeminiClient::class)
        ->provider(new GeminiClientProvider())
        ->in(Scope::SINGLETON);

      $container->bind(LLMAnalysisWorker::class)
        ->to(LLMAnalysisWorker::class)
        ->in(Scope::SINGLETON);

      $container->bind(NotificationWorker::class)
        ->to(NotificationWorker::class)
        ->in(Scope::SINGLETON);

      await $container->lockAsync();

      self::$container = $container;
    }
    return self::$container;
  }
}

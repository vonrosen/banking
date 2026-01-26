namespace Banking\Container;

use type Nazg\Glue\{Container, DependencyFactory, Scope};
use type Banking\Repositories\{IUserRepository, UserRepository};
use type Banking\Database\ConnectionManager;
use type Banking\Database\DatabaseConfig;
use type Banking\Utils\LoggerFactory;
use type Banking\Database\MigrationRunner;
use type Banking\Controllers\UserController;

final class AppContainer {
  private static ?Container $container = null;

  public static async function getAsync(): Awaitable<Container> {
    if (self::$container === null) {
      $container = new Container(new DependencyFactory());

      $container->bind(IUserRepository::class)
        ->to(UserRepository::class)
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

      await $container->lockAsync();

      self::$container = $container;
    }
    return self::$container;
  }
}

namespace Banking\Repositories;

use type Banking\Models\{User, CreateUser};

/**
 * Interface for user data access operations.
 */
interface IUserRepository {
  public function createUser(CreateUser $user): Awaitable<User>;
  public function findByPhoneNumber(string $phoneNumber): Awaitable<?User>;
  public function findById(string $id): Awaitable<?User>;
}

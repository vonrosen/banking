namespace Banking\Repositories;

use type Banking\Models\{User, CreateUser};

/**
 * Interface for user data access operations.
 */
interface IUserRepository {
  public function createUser(CreateUser $user): User;
  public function findByPhoneNumber(string $phoneNumber): ?User;
  public function findById(string $id): ?User;
}

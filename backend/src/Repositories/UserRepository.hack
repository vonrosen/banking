namespace Banking\Repositories;

use namespace HH\Lib\C;
use type Banking\Database\ConnectionManager;
use type Banking\Models\{CreateUser, User};

final class UserRepository implements IUserRepository {

  public function __construct(
    private ConnectionManager $connectionManager
  ) {}

  public async function createUser(CreateUser $user): Awaitable<User> {
    $hashedPassword = \password_hash($user['password'], \PASSWORD_BCRYPT);

    $sql = <<<SQL
INSERT INTO "user" (phone_number, password)
VALUES (\$1, \$2)
RETURNING id, phone_number, password, created_at
SQL;

    $rows = await $this->connectionManager->queryAsync($sql, vec[
      $user['phone_number'],
      $hashedPassword,
    ]);

    if (C\is_empty($rows)) {
      throw new \Exception('Failed to create user');
    }

    $row = $rows[0];
    return shape(
      'id' => (string)$row['id'],
      'phone_number' => (string)$row['phone_number'],
      'password' => (string)$row['password'],
      'created_at' => (string)$row['created_at'],
    );
  }

  public async function findByPhoneNumber(string $phoneNumber): Awaitable<?User> {
    $sql = 'SELECT id, phone_number, password, created_at FROM "user" WHERE phone_number = $1';
    $rows = await $this->connectionManager->queryAsync($sql, vec[$phoneNumber]);

    if (C\is_empty($rows)) {
      return null;
    }

    $row = $rows[0];
    return shape(
      'id' => (string)$row['id'],
      'phone_number' => (string)$row['phone_number'],
      'password' => (string)$row['password'],
      'created_at' => (string)$row['created_at'],
    );
  }

  public async function findById(string $id): Awaitable<?User> {
    $sql = 'SELECT id, phone_number, password, created_at FROM "user" WHERE id = $1';
    $rows = await $this->connectionManager->queryAsync($sql, vec[$id]);

    if (C\is_empty($rows)) {
      return null;
    }

    $row = $rows[0];
    return shape(
      'id' => (string)$row['id'],
      'phone_number' => (string)$row['phone_number'],
      'password' => (string)$row['password'],
      'created_at' => (string)$row['created_at'],
    );
  }
}

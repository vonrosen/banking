namespace Banking\Repositories;

use namespace HH\Lib\C;
use type Banking\Database\ConnectionManager;
use type Banking\Models\{User, CreateUser};

final class UserRepository implements IUserRepository {

  public function createUser(CreateUser $user): User {
    $hashedPassword = \password_hash($user['password'], \PASSWORD_BCRYPT);

    $sql = <<<SQL
INSERT INTO users (phone_number, password)
VALUES (\$1, \$2)
RETURNING id, phone_number, password, created_at
SQL;

    $row = ConnectionManager::query($sql, vec[
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

  public function findByPhoneNumber(string $phoneNumber): ?User {
    $sql = 'SELECT id, phone_number, password, created_at FROM users WHERE phone_number = $1';
    $rows = ConnectionManager::query($sql, vec[$phoneNumber]);

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

  public function findById(string $id): ?User {
    $sql = 'SELECT id, phone_number, password, created_at FROM users WHERE id = $1';
    $rows = ConnectionManager::query($sql, vec[$id]);

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

namespace Banking\Controllers;

use type Banking\Dtos\CreateUserRequest;
use type Banking\Models\User;
use type Banking\Attributes\Route;
use type Banking\Repositories\{IUserRepository, UserRepository};

final class UserController implements IController {

  private IUserRepository $userRepository;

  public function __construct() {
    $this->userRepository = new UserRepository();
  }

  <<Route('POST', '/v1/users')>>
  public async function createUserAsync(): Awaitable<void> {
    $input = \file_get_contents('php://input');
    $data = \json_decode($input, true);

    $request = $data as CreateUserRequest;
    $phone_number = $request['phone_number'];
    $password = $request['password'];

    $existingUser = await $this->userRepository->findByPhoneNumber($phone_number);
    if ($existingUser !== null) {
      \http_response_code(409);
      echo \json_encode(shape(
        'error' => 'User with this phone number already exists',
      ));
      return;
    }

    try {
      $user = await $this->userRepository->createUser(shape(
        'phone_number' => $phone_number,
        'password' => $password,
      ));

      \http_response_code(201);
      echo \json_encode($user);
    } catch (\Exception $e) {
      \error_log('Failed to create user: '.$e->getMessage());
      \http_response_code(500);
      echo \json_encode(shape(
        'error' => 'Failed to create user',
      ));
    }
  }
}

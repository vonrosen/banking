namespace Banking\Controllers;

use type Banking\Dtos\{CreateUserRequest, LoginRequest};
use type Banking\Models\User;
use type Banking\Attributes\Route;
use type Banking\Repositories\{IUserRepository, UserRepository};
use type Banking\Logging\LoggerFactory;
use type HackLogging\LogLevel;
use type HackLogging\Logger;

final class UserController implements IController {

  private Logger $logger;

  public function __construct(private IUserRepository $userRepository) {
    $this->logger = LoggerFactory::getLogger('UserController');
  }

  <<Route('POST', '/v1/users/login')>>
  public async function loginUserAsync(): Awaitable<void> {
    $input = \file_get_contents('php://input');
    $data = \json_decode($input, true);

    $request = $data as LoginRequest;
    $phone_number = $request['phone_number'];
    $password = $request['password'];

    $existingUser = await $this->userRepository
      ->findByPhoneNumberAndPassword($phone_number, $password);
    if ($existingUser === null) {
      \http_response_code(404);
      echo \json_encode(shape(
        'error' => 'Cannot find user',
      ));
      return;
    }

    \http_response_code(200);
    echo \json_encode($existingUser);
  }

  <<Route('POST', '/v1/users')>>
  public async function createUserAsync(): Awaitable<void> {
    $input = \file_get_contents('php://input');
    $data = \json_decode($input, true);

    $request = $data as CreateUserRequest;
    $phone_number = $request['phone_number'];
    $password = $request['password'];

    $existingUser = await $this->userRepository
      ->findByPhoneNumber($phone_number);
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
      await $this->logger->writeAsync(
        LogLevel::ERROR,
        'Failed to create user: '.$e->getMessage(),
        dict[],
      );
      \http_response_code(500);
      echo \json_encode(shape(
        'error' => 'Failed to create user',
      ));
    }
  }
}

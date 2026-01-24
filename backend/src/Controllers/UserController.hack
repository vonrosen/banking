namespace Banking\Controllers;

use Dtos\CreateUserRequest;
use namespace HH\Lib\{IO, Vec, Str};

final class UserController {
  public async function createAsync(): Awaitable<void> {
    $input = \file_get_contents('php://input');
    $data = \json_decode($input, true);

    $request = $data as CreateUserRequest;
    $phone_number = $request['phone_number'];
    $password = $request['password'];

    \error_log("Received user creation request:");
    \error_log("  Phone Number: ".$phone_number);
    \error_log("  Password: ".$password);

    \http_response_code(201);
    echo \json_encode(shape(
      'status' => 'created',
    ));
  }
}

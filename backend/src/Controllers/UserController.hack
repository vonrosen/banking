namespace Banking\Controllers;

use type Banking\Dtos\CreateUserRequest;
use type Banking\Attributes\Route;
use type Banking\Interfaces\IController;

final class UserController implements IController {
  
  <<Route('POST', '/v1/users')>>
  public async function createUserAsync(): Awaitable<void> {
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

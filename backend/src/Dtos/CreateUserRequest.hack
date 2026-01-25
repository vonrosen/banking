namespace Banking\Dtos;

type CreateUserRequest = shape(
  'phone_number' => string,
  'password' => string,
);
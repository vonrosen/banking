namespace Banking\Dtos;

type LoginRequest = shape(
  'phone_number' => string,
  'password' => string,
);
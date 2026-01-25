namespace Banking\Models;

type User = shape(
  'id' => string,
  'phone_number' => string,
  'password' => string,
  'created_at' => string,
);

type CreateUser = shape(
  'phone_number' => string,
  'password' => string,
);

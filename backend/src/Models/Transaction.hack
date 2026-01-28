namespace Banking\Models;

type Transaction = shape(
  'id' => string,
  'description' => string,
  'amount' => float,
  'created_at' => int,
);

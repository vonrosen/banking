namespace Banking\Dtos;

type CreateAnalysisRequest = shape(
  'bank_login_token' => string,
  'user_id' => string,
);
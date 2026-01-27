namespace Banking\Models;

type Analysis = shape(
  'id' => string,
  'user_id' => string,
  'status' => string,
  'bank_login_token' => string,
  'transaction_data' => mixed,
  'llm_analysis_result' => mixed,
  'provider_policy_details' => mixed,
  'quotes' => mixed,
  'error_message' => ?string,
  'error_step' => ?string,
  'retry_count' => int,
  'created_at' => string,
  'updated_at' => string,
);

type CreateAnalysis = shape(
  'user_id' => string,
  'bank_login_token' => string,
);
export type Analysis = {
    id: string;
    user_id: string;
    status: string;
    bank_login_token: string;
    transaction_data: any;
    llm_analysis_result: any;
    provider_policy_details: any;
    quotes: any;
    error_message: string | null;
    error_step: string | null;
    retry_count: number;
    created_at: Date;
    updated_at: Date;
};

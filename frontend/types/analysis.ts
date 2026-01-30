import { AnalysisStatus } from './analysisStatus';

export type Analysis = {
    id: string;
    user_id: string;
    status: AnalysisStatus;
    provider_policy_details: any;
    error_message: string | null;
    error_step: string | null;
    retry_count: number;
    created_at: string;
    updated_at: string;
};

import { Analysis } from '@/types/analysis';
import { CreateAnalysisRequest } from '@/types/createAnalysisRequest';
import { get, post } from './api';

export class AnalysisService {
    async createAnalysis(request: CreateAnalysisRequest): Promise<Analysis> {
        return post<Analysis>('/v1/analyses', request);
    }

    async getAnalysis(analysisId: string): Promise<Analysis> {
        return get<Analysis>(`/v1/analyses/${analysisId}`);
    }
}
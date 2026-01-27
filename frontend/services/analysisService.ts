import { Analysis } from '@/types/analysis';
import { CreateAnalysisRequest } from '@/types/createAnalysisRequest';
import { post } from './api';

export class AnalysisService {
    async createAnalysis(request: CreateAnalysisRequest): Promise<Analysis> {
        return post<Analysis>('/v1/analyses', request);
    }
}
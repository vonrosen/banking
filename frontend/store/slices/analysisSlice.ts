import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Analysis } from '@/types/analysis';

type AnalysisState = {
  currentAnalysis: Analysis | null;
  error: string | null;
};

const initialState: AnalysisState = {
  currentAnalysis: null,
  error: null,
};

const analysisSlice = createSlice({
  name: 'analysis',
  initialState,
  reducers: {
    setAnalysis: (state, action: PayloadAction<Analysis>) => {
      state.currentAnalysis = action.payload;
      state.error = null;
    },
    updateAnalysis: (state, action: PayloadAction<Analysis>) => {
      state.currentAnalysis = action.payload;
    },
    setError: (state, action: PayloadAction<string>) => {
      state.error = action.payload;
    },
    clearAnalysis: (state) => {
      state.currentAnalysis = null;
      state.error = null;
    },
  },
});

export const { setAnalysis, updateAnalysis, setError, clearAnalysis } = analysisSlice.actions;
export default analysisSlice.reducer;

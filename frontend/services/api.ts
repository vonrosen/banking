import axios from 'axios';

const API_BASE_URL = process.env.EXPO_PUBLIC_API_BASE_URL;

export async function get<T>(url: string): Promise<T> {
  const response = await axios.get<T>(`${API_BASE_URL}${url}`);
  return response.data;
}

export async function post<T>(url: string, data?: unknown): Promise<T> {
  const response = await axios.post<T>(`${API_BASE_URL}${url}`, data);
  return response.data;
}

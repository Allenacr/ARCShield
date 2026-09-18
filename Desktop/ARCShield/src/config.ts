const configuredApiUrl = import.meta.env.VITE_API_URL?.trim();

export const API_BASE_URL = configuredApiUrl || '/api';

export function apiUrl(path: string): string {
  return `${API_BASE_URL.replace(/\/$/, '')}/${path.replace(/^\//, '')}`;
}
import {apiClient} from './apiClient';

/**
 * User API service
 * Handles authentication and user profile operations
 */

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
}

export interface UserProfile {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
  is_verified?: boolean;
  profile?: {
    phone_number?: string;
    address?: string;
  };
}

export interface TokenResponse {
  access: string;
  refresh: string;
}

export const userApi = {
  // Login
  async login(credentials: LoginCredentials): Promise<TokenResponse> {
    return apiClient.post('/users/login/', credentials);
  },

  // Register
  async register(data: RegisterData): Promise<TokenResponse> {
    return apiClient.post('/users/register/', data);
  },

  // Get current user
  async getMe(): Promise<UserProfile> {
    return apiClient.get('/users/me/');
  },

  // Get user profile
  async getProfile(): Promise<any> {
    return apiClient.get('/users/profile/');
  },

  // Update profile
  async updateProfile(data: any): Promise<any> {
    return apiClient.patch('/users/profile/', data);
  },

  // Refresh token
  async refreshToken(refreshToken: string): Promise<TokenResponse> {
    return apiClient.post('/users/token/refresh/', {refresh: refreshToken});
  },

  // Logout (if backend has endpoint)
  async logout(): Promise<void> {
    // Clear tokens locally
    // If backend has logout endpoint, call it here
  },
};

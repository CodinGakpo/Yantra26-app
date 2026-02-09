import {apiClient} from './apiClient';

/**
 * Report API service
 * Handles issue reporting and tracking
 */

export interface ReportData {
  issue_title: string;
  location: string;
  issue_description: string;
  image_url?: string;
}

export interface IssueReport {
  id: number;
  issue_title: string;
  location: string;
  issue_description: string;
  image_url?: string;
  tracking_id?: string;
  status?: string;
  created_at?: string;
  updated_at?: string;
}

export const reportApi = {
  // Create a new report
  async createReport(data: ReportData): Promise<IssueReport> {
    return apiClient.post('/report/', data);
  },

  // Get report by tracking ID
  async getReportByTrackingId(trackingId: string): Promise<IssueReport> {
    return apiClient.get(`/report/track/${trackingId}/`);
  },

  // Get all reports (for community view)
  async getAllReports(): Promise<IssueReport[]> {
    return apiClient.get('/report/');
  },

  // Get user's reports
  async getUserReports(): Promise<IssueReport[]> {
    return apiClient.get('/report/history/');
  },

  // Upload image
  async uploadImage(formData: FormData): Promise<{url: string}> {
    return apiClient.post('/report/upload/', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
};

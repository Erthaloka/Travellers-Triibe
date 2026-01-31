/**
 * PAN Verification Service
 * Integrates with PlanAPI for PAN verification
 * File: src/services/pan-verification.service.ts
 */
import axios, { AxiosInstance } from 'axios';
import { env } from '../config/env.js';

// Response interfaces
interface PANDetails {
  pan: string;
  name: string;
  category: string; // Individual, Company, Firm, etc.
  status: string; // Valid, Invalid, Deactivated
  lastUpdated?: string;
  aadhaarSeeded?: boolean;
}

interface PANVerificationResult {
  success: boolean;
  verified: boolean;
  data?: PANDetails;
  error?: string;
  errorCode?: string;
}

export class PANVerificationService {
  private apiClient: AxiosInstance;
  private baseURL: string;
  private apiKey: string;

  constructor() {
    this.baseURL = env.PLANAPI_BASE_URL;
    this.apiKey = env.PLANAPI_API_KEY;

    this.apiClient = axios.create({
      baseURL: this.baseURL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
      },
    });
  }

  /**
   * Verify PAN using PlanAPI
   * @param pan - 10 character PAN
   * @returns Verification result with holder details
   */
  async verifyPAN(pan: string): Promise<PANVerificationResult> {
    try {
      // Validate PAN format
      if (!this.isValidPANFormat(pan)) {
        return {
          success: false,
          verified: false,
          error: 'Invalid PAN format',
          errorCode: 'INVALID_FORMAT',
        };
      }

      const normalizedPAN = pan.toUpperCase().trim();

      // Call PlanAPI PAN Verification API
      const response = await this.apiClient.post('/v1/pan/verify', {
        pan: normalizedPAN,
      });

      // Check if API call was successful
      if (response.data && response.data.status === 'success') {
        const panData = response.data.data;

        // Check if PAN is valid
        const isValid = panData.status?.toLowerCase() === 'valid' || 
                        panData.panStatus?.toLowerCase() === 'valid' ||
                        panData.valid === true;

        if (!isValid) {
          return {
            success: true,
            verified: false,
            error: 'PAN is not valid or is deactivated',
            errorCode: 'INVALID_PAN',
          };
        }

        return {
          success: true,
          verified: true,
          data: {
            pan: normalizedPAN,
            name: panData.name || panData.fullName || panData.holderName,
            category: panData.category || panData.panType || this.getPANCategory(normalizedPAN),
            status: panData.status || panData.panStatus || 'Valid',
            lastUpdated: panData.lastUpdated || panData.updatedAt,
            aadhaarSeeded: panData.aadhaarSeeded || panData.isAadhaarLinked || false,
          },
        };
      } else {
        return {
          success: false,
          verified: false,
          error: response.data?.message || 'PAN verification failed',
          errorCode: 'VERIFICATION_FAILED',
        };
      }
    } catch (error: any) {
      console.error('PAN Verification Error:', error);

      // Handle specific error cases
      if (error.response) {
        const status = error.response.status;
        const errorData = error.response.data;

        if (status === 404) {
          return {
            success: false,
            verified: false,
            error: 'PAN not found in income tax records',
            errorCode: 'PAN_NOT_FOUND',
          };
        } else if (status === 401 || status === 403) {
          return {
            success: false,
            verified: false,
            error: 'API authentication failed. Please contact support.',
            errorCode: 'API_AUTH_ERROR',
          };
        } else if (status === 429) {
          return {
            success: false,
            verified: false,
            error: 'Too many requests. Please try again later.',
            errorCode: 'RATE_LIMIT_EXCEEDED',
          };
        } else {
          return {
            success: false,
            verified: false,
            error: errorData?.message || 'PAN verification service error',
            errorCode: 'API_ERROR',
          };
        }
      } else if (error.code === 'ECONNABORTED') {
        return {
          success: false,
          verified: false,
          error: 'Verification request timed out. Please try again.',
          errorCode: 'TIMEOUT',
        };
      } else {
        return {
          success: false,
          verified: false,
          error: 'Network error. Please check your connection.',
          errorCode: 'NETWORK_ERROR',
        };
      }
    }
  }

  /**
   * Validate PAN format
   * Format: AAAAA9999A
   * 5 letters + 4 digits + 1 letter
   * @param pan - PAN to validate
   * @returns boolean
   */
  isValidPANFormat(pan: string): boolean {
    const panRegex = /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/;
    return panRegex.test(pan.toUpperCase());
  }

  /**
   * Get PAN category from 4th character
   * @param pan - PAN
   * @returns Category
   */
  getPANCategory(pan: string): string {
    if (!this.isValidPANFormat(pan)) {
      return 'Unknown';
    }

    const fourthChar = pan.charAt(3).toUpperCase();
    const categoryMapping: { [key: string]: string } = {
      'P': 'Individual',
      'C': 'Company',
      'H': 'Hindu Undivided Family (HUF)',
      'F': 'Firm',
      'A': 'Association of Persons (AOP)',
      'T': 'Trust',
      'B': 'Body of Individuals (BOI)',
      'L': 'Local Authority',
      'J': 'Artificial Juridical Person',
      'G': 'Government',
    };

    return categoryMapping[fourthChar] || 'Unknown';
  }

  /**
   * Check if PAN belongs to a company/firm
   * @param pan - PAN
   * @returns boolean
   */
  isBusinessPAN(pan: string): boolean {
    const fourthChar = pan.charAt(3).toUpperCase();
    return ['C', 'F', 'A', 'T', 'B', 'L', 'J'].includes(fourthChar);
  }

  /**
   * Check if PAN belongs to an individual
   * @param pan - PAN
   * @returns boolean
   */
  isIndividualPAN(pan: string): boolean {
    const fourthChar = pan.charAt(3).toUpperCase();
    return fourthChar === 'P';
  }

  /**
   * Mask PAN for display (show only first 2 and last 2 characters)
   * @param pan - PAN
   * @returns Masked PAN
   */
  maskPAN(pan: string): string {
    if (pan.length !== 10) {
      return pan;
    }
    return `${pan.substring(0, 2)}XXXXXX${pan.substring(8)}`;
  }
}

export default new PANVerificationService();
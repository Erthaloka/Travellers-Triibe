/**
 * GST Verification Service
 * Integrates with APIClub for GSTIN verification
 * File: src/services/gst-verification.service.ts
 */
import axios, { AxiosInstance } from 'axios';
import { env } from '../config/env.js';

// Response interfaces
interface GSTINDetails {
  gstin: string;
  legalName: string;
  tradeName: string;
  registrationDate: string;
  constitutionOfBusiness: string;
  taxpayerType: string;
  gstinStatus: string;
  lastUpdatedDate: string;
  stateJurisdiction: string;
  centerJurisdiction: string;
  principalPlaceOfBusiness: {
    address: string;
    state: string;
    pincode: string;
  };
}

interface GSTVerificationResult {
  success: boolean;
  verified: boolean;
  data?: GSTINDetails;
  error?: string;
  errorCode?: string;
}

export class GSTVerificationService {
  private apiClient: AxiosInstance;
  private baseURL: string;
  private apiKey: string;

  constructor() {
    this.baseURL = env.APICLUB_BASE_URL;
    this.apiKey = env.APICLUB_API_KEY;

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
   * Verify GSTIN using APIClub
   * @param gstin - 15 character GSTIN
   * @returns Verification result with business details
   */
  async verifyGSTIN(gstin: string): Promise<GSTVerificationResult> {
    try {
      // Validate GSTIN format
      if (!this.isValidGSTINFormat(gstin)) {
        return {
          success: false,
          verified: false,
          error: 'Invalid GSTIN format',
          errorCode: 'INVALID_FORMAT',
        };
      }

      const normalizedGSTIN = gstin.toUpperCase().trim();

      // Call APIClub GST Verification API
      const response = await this.apiClient.post('/v1/gst/verify', {
        gstin: normalizedGSTIN,
      });

      // Check if API call was successful
      if (response.data && response.data.status === 'success') {
        const gstData = response.data.data;

        // Check if GST is active
        const isActive = gstData.gstinStatus?.toLowerCase() === 'active';

        if (!isActive) {
          return {
            success: true,
            verified: false,
            error: 'GSTIN is not active',
            errorCode: 'INACTIVE_GSTIN',
          };
        }

        return {
          success: true,
          verified: true,
          data: {
            gstin: normalizedGSTIN,
            legalName: gstData.legalName || gstData.legalBusinessName,
            tradeName: gstData.tradeName || gstData.tradeNameOfBusiness,
            registrationDate: gstData.registrationDate || gstData.dateOfRegistration,
            constitutionOfBusiness: gstData.constitutionOfBusiness,
            taxpayerType: gstData.taxpayerType,
            gstinStatus: gstData.gstinStatus,
            lastUpdatedDate: gstData.lastUpdatedDate,
            stateJurisdiction: gstData.stateJurisdiction,
            centerJurisdiction: gstData.centerJurisdiction,
            principalPlaceOfBusiness: {
              address: gstData.pradr?.addr?.bno 
                ? `${gstData.pradr.addr.bno}, ${gstData.pradr.addr.st}, ${gstData.pradr.addr.loc}`
                : gstData.principalPlaceOfBusinessAddress || '',
              state: gstData.pradr?.addr?.stcd || gstData.state || '',
              pincode: gstData.pradr?.addr?.pncd || gstData.pincode || '',
            },
          },
        };
      } else {
        return {
          success: false,
          verified: false,
          error: response.data?.message || 'GST verification failed',
          errorCode: 'VERIFICATION_FAILED',
        };
      }
    } catch (error: any) {
      console.error('GST Verification Error:', error);

      // Handle specific error cases
      if (error.response) {
        const status = error.response.status;
        const errorData = error.response.data;

        if (status === 404) {
          return {
            success: false,
            verified: false,
            error: 'GSTIN not found in government records',
            errorCode: 'GSTIN_NOT_FOUND',
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
            error: errorData?.message || 'GST verification service error',
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
   * Extract PAN from GSTIN
   * PAN is characters 3-12 of GSTIN (10 characters)
   * @param gstin - 15 character GSTIN
   * @returns PAN (10 characters)
   */
  extractPANFromGSTIN(gstin: string): string {
    if (gstin.length !== 15) {
      throw new Error('Invalid GSTIN length');
    }
    return gstin.substring(2, 12).toUpperCase();
  }

  /**
   * Validate GSTIN format
   * Format: 22AAAAA0000A1Z5
   * 2 digits (state code) + 10 chars (PAN) + 1 char (entity number) + 1 char (Z) + 1 check digit
   * @param gstin - GSTIN to validate
   * @returns boolean
   */
  isValidGSTINFormat(gstin: string): boolean {
    const gstinRegex = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
    return gstinRegex.test(gstin.toUpperCase());
  }

  /**
   * Validate state code in GSTIN
   * @param gstin - GSTIN
   * @returns boolean
   */
  isValidStateCode(gstin: string): boolean {
    const stateCode = parseInt(gstin.substring(0, 2));
    return stateCode >= 1 && stateCode <= 37;
  }

  /**
   * Get state name from GSTIN state code
   * @param gstin - GSTIN
   * @returns State name
   */
  getStateFromGSTIN(gstin: string): string {
    const stateCode = gstin.substring(0, 2);
    const stateMapping: { [key: string]: string } = {
      '01': 'Jammu and Kashmir',
      '02': 'Himachal Pradesh',
      '03': 'Punjab',
      '04': 'Chandigarh',
      '05': 'Uttarakhand',
      '06': 'Haryana',
      '07': 'Delhi',
      '08': 'Rajasthan',
      '09': 'Uttar Pradesh',
      '10': 'Bihar',
      '11': 'Sikkim',
      '12': 'Arunachal Pradesh',
      '13': 'Nagaland',
      '14': 'Manipur',
      '15': 'Mizoram',
      '16': 'Tripura',
      '17': 'Meghalaya',
      '18': 'Assam',
      '19': 'West Bengal',
      '20': 'Jharkhand',
      '21': 'Odisha',
      '22': 'Chhattisgarh',
      '23': 'Madhya Pradesh',
      '24': 'Gujarat',
      '26': 'Dadra and Nagar Haveli and Daman and Diu',
      '27': 'Maharashtra',
      '29': 'Karnataka',
      '30': 'Goa',
      '31': 'Lakshadweep',
      '32': 'Kerala',
      '33': 'Tamil Nadu',
      '34': 'Puducherry',
      '35': 'Andaman and Nicobar Islands',
      '36': 'Telangana',
      '37': 'Andhra Pradesh',
    };
    return stateMapping[stateCode] || 'Unknown State';
  }
}

export default new GSTVerificationService();
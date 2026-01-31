/**
 * Cross Verification Service
 * Verifies that PAN embedded in GSTIN matches the provided PAN
 * Optional: Uses IDCentral for advanced GST-PAN cross-verification
 * File: src/services/cross-verification.service.ts
 */
import axios, { AxiosInstance } from 'axios';
import { env } from '../config/env.js';
import gstVerificationService from './gst-verification.service.js';
import panVerificationService from './pan-verification.service.js';

interface CrossVerificationResult {
  success: boolean;
  matched: boolean;
  data?: {
    gstin: string;
    pan: string;
    legalName: string;
    panName: string;
    matchConfidence: number; // 0-100
    details: {
      panFromGSTIN: string;
      providedPAN: string;
      exactMatch: boolean;
      nameMatch?: boolean;
      nameMatchScore?: number;
    };
  };
  error?: string;
  errorCode?: string;
}

export class CrossVerificationService {
  private apiClient: AxiosInstance | null = null;
  private baseURL: string;
  private apiKey: string;
  private useAdvancedVerification: boolean;

  constructor() {
    this.baseURL = env.IDCENTRAL_BASE_URL;
    this.apiKey = env.IDCENTRAL_API_KEY;

    // Only initialize API client if credentials are provided
    this.useAdvancedVerification = !!(this.baseURL && this.apiKey);

    if (this.useAdvancedVerification) {
      this.apiClient = axios.create({
        baseURL: this.baseURL,
        timeout: 30000,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`,
        },
      });
    }
  }

  /**
   * Cross-verify GST and PAN
   * First performs basic verification (PAN extraction from GSTIN)
   * Then optionally performs advanced verification via IDCentral
   * @param gstin - 15 character GSTIN
   * @param pan - 10 character PAN
   * @returns Cross-verification result
   */
  async crossVerifyGSTAndPAN(
    gstin: string,
    pan: string
  ): Promise<CrossVerificationResult> {
    try {
      // Step 1: Basic validation
      if (!gstVerificationService.isValidGSTINFormat(gstin)) {
        return {
          success: false,
          matched: false,
          error: 'Invalid GSTIN format',
          errorCode: 'INVALID_GSTIN_FORMAT',
        };
      }

      if (!panVerificationService.isValidPANFormat(pan)) {
        return {
          success: false,
          matched: false,
          error: 'Invalid PAN format',
          errorCode: 'INVALID_PAN_FORMAT',
        };
      }

      // Step 2: Extract PAN from GSTIN (characters 3-12)
      const extractedPAN = gstVerificationService.extractPANFromGSTIN(gstin);
      const normalizedPAN = pan.toUpperCase().trim();
      const normalizedGSTIN = gstin.toUpperCase().trim();

      // Step 3: Check if PANs match
      if (extractedPAN !== normalizedPAN) {
        return {
          success: true,
          matched: false,
          error: 'PAN in GSTIN does not match provided PAN',
          errorCode: 'PAN_MISMATCH',
          data: {
            gstin: normalizedGSTIN,
            pan: normalizedPAN,
            legalName: '',
            panName: '',
            matchConfidence: 0,
            details: {
              panFromGSTIN: extractedPAN,
              providedPAN: normalizedPAN,
              exactMatch: false,
            },
          },
        };
      }

      // Step 4: Verify both GST and PAN individually
      const [gstResult, panResult] = await Promise.all([
        gstVerificationService.verifyGSTIN(normalizedGSTIN),
        panVerificationService.verifyPAN(normalizedPAN),
      ]);

      // Check if individual verifications failed
      if (!gstResult.success || !gstResult.verified) {
        return {
          success: false,
          matched: false,
          error: gstResult.error || 'GSTIN verification failed',
          errorCode: gstResult.errorCode || 'GSTIN_VERIFICATION_FAILED',
        };
      }

      if (!panResult.success || !panResult.verified) {
        return {
          success: false,
          matched: false,
          error: panResult.error || 'PAN verification failed',
          errorCode: panResult.errorCode || 'PAN_VERIFICATION_FAILED',
        };
      }

      // Step 5: Perform name matching
      const nameMatchResult = this.matchNames(
        gstResult.data!.legalName,
        panResult.data!.name
      );

      // Step 6: If advanced verification is available, use it
      let advancedVerificationData = null;
      if (this.useAdvancedVerification && this.apiClient) {
        try {
          advancedVerificationData = await this.performAdvancedVerification(
            normalizedGSTIN,
            normalizedPAN
          );
        } catch (error) {
          console.warn('Advanced verification failed, using basic verification:', error);
          // Continue with basic verification if advanced fails
        }
      }

      // Step 7: Calculate match confidence
      let matchConfidence = 100;
      if (!nameMatchResult.exactMatch) {
        matchConfidence = nameMatchResult.similarity;
      }

      // If advanced verification provided additional confidence, factor it in
      if (advancedVerificationData?.confidence) {
        matchConfidence = Math.min(matchConfidence, advancedVerificationData.confidence);
      }

      return {
        success: true,
        matched: true,
        data: {
          gstin: normalizedGSTIN,
          pan: normalizedPAN,
          legalName: gstResult.data!.legalName,
          panName: panResult.data!.name,
          matchConfidence,
          details: {
            panFromGSTIN: extractedPAN,
            providedPAN: normalizedPAN,
            exactMatch: true,
            nameMatch: nameMatchResult.match,
            nameMatchScore: nameMatchResult.similarity,
          },
        },
      };
    } catch (error: any) {
      console.error('Cross Verification Error:', error);
      return {
        success: false,
        matched: false,
        error: error.message || 'Cross-verification failed',
        errorCode: 'CROSS_VERIFICATION_ERROR',
      };
    }
  }

  /**
   * Perform advanced verification using IDCentral API
   * @param gstin - GSTIN
   * @param pan - PAN
   * @returns Advanced verification data
   */
  private async performAdvancedVerification(
    gstin: string,
    pan: string
  ): Promise<{ confidence: number; additionalData?: any } | null> {
    if (!this.apiClient) {
      return null;
    }

    try {
      const response = await this.apiClient.post('/v1/verification/gst-pan', {
        gstin,
        pan,
      });

      if (response.data && response.data.status === 'success') {
        return {
          confidence: response.data.data.matchScore || 100,
          additionalData: response.data.data,
        };
      }

      return null;
    } catch (error) {
      console.error('IDCentral verification error:', error);
      return null;
    }
  }

  /**
   * Match two names and calculate similarity
   * @param name1 - First name
   * @param name2 - Second name
   * @returns Match result
   */
  private matchNames(name1: string, name2: string): {
    match: boolean;
    exactMatch: boolean;
    similarity: number;
  } {
    if (!name1 || !name2) {
      return { match: false, exactMatch: false, similarity: 0 };
    }

    // Normalize names
    const normalized1 = this.normalizeName(name1);
    const normalized2 = this.normalizeName(name2);

    // Check exact match
    if (normalized1 === normalized2) {
      return { match: true, exactMatch: true, similarity: 100 };
    }

    // Calculate similarity using Levenshtein distance
    const similarity = this.calculateSimilarity(normalized1, normalized2);

    // Consider it a match if similarity is above 70%
    const match = similarity >= 70;

    return { match, exactMatch: false, similarity };
  }

  /**
   * Normalize name for comparison
   * @param name - Name to normalize
   * @returns Normalized name
   */
  private normalizeName(name: string): string {
    return name
      .toUpperCase()
      .trim()
      .replace(/[^A-Z0-9\s]/g, '') // Remove special characters
      .replace(/\s+/g, ' ') // Normalize whitespace
      .replace(/\b(PVT|LTD|LIMITED|PRIVATE|LLP|COMPANY|CO|CORPORATION|CORP|INC)\b/g, '') // Remove common business suffixes
      .trim();
  }

  /**
   * Calculate similarity between two strings using Levenshtein distance
   * @param str1 - First string
   * @param str2 - Second string
   * @returns Similarity percentage (0-100)
   */
  private calculateSimilarity(str1: string, str2: string): number {
    const distance = this.levenshteinDistance(str1, str2);
    const maxLength = Math.max(str1.length, str2.length);
    
    if (maxLength === 0) {
      return 100;
    }

    const similarity = ((maxLength - distance) / maxLength) * 100;
    return Math.round(similarity);
  }

  /**
   * Calculate Levenshtein distance between two strings
   * @param str1 - First string
   * @param str2 - Second string
   * @returns Levenshtein distance
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;
    const matrix: number[][] = [];

    // Initialize matrix
    for (let i = 0; i <= len1; i++) {
      matrix[i] = [i];
    }
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Fill matrix
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1, // Deletion
          matrix[i][j - 1] + 1, // Insertion
          matrix[i - 1][j - 1] + cost // Substitution
        );
      }
    }

    return matrix[len1][len2];
  }

  /**
   * Validate that GSTIN and PAN are from the same entity type
   * @param gstin - GSTIN
   * @param pan - PAN
   * @returns Validation result
   */
  validateEntityTypeMatch(gstin: string, pan: string): {
    valid: boolean;
    message?: string;
  } {
    const panCategory = panVerificationService.getPANCategory(pan);
    const gstinPAN = gstVerificationService.extractPANFromGSTIN(gstin);

    // Extract entity type from GSTIN (13th character)
    const entityNumber = gstin.charAt(12).toUpperCase();

    // For companies, PAN should be 'C' category
    if (panCategory === 'Company' && !['1', '2', '3', '4', '5'].includes(entityNumber)) {
      return {
        valid: false,
        message: 'Entity type mismatch: PAN indicates company but GSTIN suggests otherwise',
      };
    }

    return { valid: true };
  }
}

export default new CrossVerificationService();
/**
 * Verification routes - GST and PAN verification endpoints
 * File: src/routes/verification.routes.ts
 * UPDATED: Complete implementation with actual API services
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody } from '../middleware/validate.js';
import { authenticate, requirePartner } from '../middleware/auth.js';
import { Partner, VerificationStatus } from '../models/Partner.js';
import gstVerificationService from '../services/gst-verification.service.js';
import panVerificationService from '../services/pan-verification.service.js';
import crossVerificationService from '../services/cross-verification.service.js';

const router = Router();

// ============== Validation Schemas ==============

const gstVerificationSchema = z.object({
  gstin: z
    .string()
    .regex(
      /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/,
      'Invalid GSTIN format. Format: 22AAAAA0000A1Z5'
    ),
  pan: z
    .string()
    .regex(
      /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/,
      'Invalid PAN format. Format: AAAAA9999A'
    ),
});

const panVerificationSchema = z.object({
  pan: z
    .string()
    .regex(
      /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/,
      'Invalid PAN format. Format: AAAAA9999A'
    ),
});

// ============== Routes ==============

/**
 * POST /api/verification/verify-gst
 * Verify GST and PAN together with cross-verification
 */
router.post(
  '/verify-gst',
  authenticate,
  requirePartner,
  validateBody(gstVerificationSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;
    const { gstin, pan } = req.body;

    // Find partner profile
    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found. Please complete onboarding first.');
    }

    // Normalize inputs
    const normalizedGSTIN = gstin.toUpperCase().trim();
    const normalizedPAN = pan.toUpperCase().trim();

    try {
      // Step 1: Perform cross-verification
      console.log('Starting GST-PAN cross-verification...');
      const crossResult = await crossVerificationService.crossVerifyGSTAndPAN(
        normalizedGSTIN,
        normalizedPAN
      );

      if (!crossResult.success || !crossResult.matched) {
        throw new ApiError(
          400,
          crossResult.error || 'GST and PAN verification failed',
          crossResult.errorCode
        );
      }

      // Step 2: Additional entity type validation
      const entityValidation = crossVerificationService.validateEntityTypeMatch(
        normalizedGSTIN,
        normalizedPAN
      );

      if (!entityValidation.valid) {
        throw new ApiError(400, entityValidation.message || 'Entity type mismatch');
      }

      // Step 3: Update partner with verified details
      partner.isGstRegistered = true;

      // Update GSTIN details
      partner.verificationDetails.gstin = {
        number: normalizedGSTIN,
        status: VerificationStatus.VERIFIED,
        verifiedAt: new Date(),
        legalName: crossResult.data!.legalName,
        tradeName: crossResult.data!.legalName, // Can be updated with actual trade name if available
        lastUpdated: new Date(),
      };

      // Update PAN details
      partner.verificationDetails.pan = {
        number: normalizedPAN,
        status: VerificationStatus.VERIFIED,
        verifiedAt: new Date(),
        name: crossResult.data!.panName,
      };

      // Mark as cross-verified
      partner.verificationDetails.crossVerified = {
        status: true,
        verifiedAt: new Date(),
      };

      // Update legal business name if not set or if GST name is more authoritative
      if (!partner.legalBusinessName || partner.legalBusinessName.length < 3) {
        partner.legalBusinessName = crossResult.data!.legalName;
      }

      // Unblock payouts if blocked due to GST requirement
      if (partner.payoutControl.requiresGstForUnblock) {
        partner.payoutControl.enabled = true;
        partner.payoutControl.blockedAt = undefined;
        partner.payoutControl.blockReason = undefined;
        partner.payoutControl.requiresGstForUnblock = false;
      }

      // Update revenue tracking to mark GST as applicable
      const currentFY = partner.getCurrentFinancialYear();
      const currentTracking = partner.revenueTracking.find(
        (r) => r.financialYear === currentFY
      );
      if (currentTracking) {
        currentTracking.gstApplicable = true;
      }

      // Save partner
      await partner.save();

      res.json({
        success: true,
        message: 'GST and PAN verified successfully',
        data: {
          gstin: normalizedGSTIN,
          pan: normalizedPAN,
          verified: true,
          legalName: crossResult.data!.legalName,
          panName: crossResult.data!.panName,
          matchConfidence: crossResult.data!.matchConfidence,
          payoutUnblocked: partner.payoutControl.enabled,
          verifiedAt: new Date(),
        },
      });
    } catch (error: any) {
      // If verification failed, mark as failed in partner profile
      if (partner.verificationDetails.gstin) {
        partner.verificationDetails.gstin.status = VerificationStatus.FAILED;
      }
      if (partner.verificationDetails.pan) {
        partner.verificationDetails.pan.status = VerificationStatus.FAILED;
      }
      await partner.save();

      throw error;
    }
  })
);

/**
 * POST /api/verification/verify-pan
 * Verify PAN only (for non-GST businesses)
 */
router.post(
  '/verify-pan',
  authenticate,
  requirePartner,
  validateBody(panVerificationSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;
    const { pan } = req.body;

    // Find partner profile
    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found. Please complete onboarding first.');
    }

    const normalizedPAN = pan.toUpperCase().trim();

    try {
      // Verify PAN
      console.log('Starting PAN verification...');
      const panResult = await panVerificationService.verifyPAN(normalizedPAN);

      if (!panResult.success || !panResult.verified) {
        throw new ApiError(
          400,
          panResult.error || 'PAN verification failed',
          panResult.errorCode
        );
      }

      // Update partner with verified PAN
      partner.verificationDetails.pan = {
        number: normalizedPAN,
        status: VerificationStatus.VERIFIED,
        verifiedAt: new Date(),
        name: panResult.data!.name,
      };

      // If this is a non-GST business, ensure GST is not marked as registered
      if (!partner.isGstRegistered) {
        partner.verificationDetails.gstin = undefined;
        partner.verificationDetails.crossVerified = undefined;
      }

      await partner.save();

      res.json({
        success: true,
        message: 'PAN verified successfully',
        data: {
          pan: normalizedPAN,
          verified: true,
          name: panResult.data!.name,
          category: panResult.data!.category,
          status: panResult.data!.status,
          verifiedAt: new Date(),
        },
      });
    } catch (error: any) {
      // Mark PAN verification as failed
      if (partner.verificationDetails.pan) {
        partner.verificationDetails.pan.status = VerificationStatus.FAILED;
      }
      await partner.save();

      throw error;
    }
  })
);

/**
 * POST /api/verification/re-verify-gst
 * Re-verify existing GST registration (for annual compliance)
 */
router.post(
  '/re-verify-gst',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    if (!partner.isGstRegistered || !partner.verificationDetails.gstin) {
      throw new ApiError(400, 'No GST registration found for this partner');
    }

    const gstin = partner.verificationDetails.gstin.number;
    const pan = partner.verificationDetails.pan.number;

    try {
      // Re-verify GST
      const crossResult = await crossVerificationService.crossVerifyGSTAndPAN(gstin, pan);

      if (!crossResult.success || !crossResult.matched) {
        // Mark as failed
        partner.verificationDetails.gstin.status = VerificationStatus.FAILED;
        await partner.save();

        throw new ApiError(
          400,
          crossResult.error || 'GST re-verification failed',
          crossResult.errorCode
        );
      }

      // Update verification timestamp
      partner.verificationDetails.gstin.verifiedAt = new Date();
      partner.verificationDetails.gstin.lastUpdated = new Date();
      partner.verificationDetails.gstin.status = VerificationStatus.VERIFIED;
      partner.verificationDetails.crossVerified = {
        status: true,
        verifiedAt: new Date(),
      };

      await partner.save();

      res.json({
        success: true,
        message: 'GST re-verified successfully',
        data: {
          gstin,
          verified: true,
          legalName: crossResult.data!.legalName,
          verifiedAt: new Date(),
        },
      });
    } catch (error) {
      throw error;
    }
  })
);

/**
 * GET /api/verification/status
 * Get verification status for current partner
 */
router.get(
  '/status',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    res.json({
      success: true,
      data: {
        isGstRegistered: partner.isGstRegistered,
        gstin: partner.verificationDetails.gstin
          ? {
              number: partner.verificationDetails.gstin.number,
              status: partner.verificationDetails.gstin.status,
              verifiedAt: partner.verificationDetails.gstin.verifiedAt,
              legalName: partner.verificationDetails.gstin.legalName,
            }
          : null,
        pan: {
          number: panVerificationService.maskPAN(partner.verificationDetails.pan.number),
          status: partner.verificationDetails.pan.status,
          verifiedAt: partner.verificationDetails.pan.verifiedAt,
          name: partner.verificationDetails.pan.name,
        },
        crossVerified: partner.verificationDetails.crossVerified,
        payoutEnabled: partner.payoutControl.enabled,
        payoutBlockedDueToGst: partner.payoutControl.requiresGstForUnblock,
      },
    });
  })
);

/**
 * POST /api/verification/check-gstin
 * Check GSTIN validity without saving (for real-time validation)
 */
router.post(
  '/check-gstin',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { gstin } = req.body;

    if (!gstin || typeof gstin !== 'string') {
      throw new ApiError(400, 'GSTIN is required');
    }

    const normalizedGSTIN = gstin.toUpperCase().trim();

    // Validate format
    if (!gstVerificationService.isValidGSTINFormat(normalizedGSTIN)) {
      return res.json({
        success: false,
        valid: false,
        error: 'Invalid GSTIN format',
      });
    }

    try {
      // Quick verification
      const result = await gstVerificationService.verifyGSTIN(normalizedGSTIN);

      res.json({
        success: result.success,
        valid: result.verified,
        data: result.verified
          ? {
              gstin: normalizedGSTIN,
              legalName: result.data?.legalName,
              state: gstVerificationService.getStateFromGSTIN(normalizedGSTIN),
              extractedPAN: gstVerificationService.extractPANFromGSTIN(normalizedGSTIN),
            }
          : null,
        error: result.error,
      });
    } catch (error: any) {
      res.json({
        success: false,
        valid: false,
        error: 'Verification service temporarily unavailable',
      });
    }
  })
);

/**
 * POST /api/verification/check-pan
 * Check PAN validity without saving (for real-time validation)
 */
router.post(
  '/check-pan',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { pan } = req.body;

    if (!pan || typeof pan !== 'string') {
      throw new ApiError(400, 'PAN is required');
    }

    const normalizedPAN = pan.toUpperCase().trim();

    // Validate format
    if (!panVerificationService.isValidPANFormat(normalizedPAN)) {
      return res.json({
        success: false,
        valid: false,
        error: 'Invalid PAN format',
      });
    }

    try {
      // Quick verification
      const result = await panVerificationService.verifyPAN(normalizedPAN);

      res.json({
        success: result.success,
        valid: result.verified,
        data: result.verified
          ? {
              pan: normalizedPAN,
              category: panVerificationService.getPANCategory(normalizedPAN),
              isBusinessPAN: panVerificationService.isBusinessPAN(normalizedPAN),
            }
          : null,
        error: result.error,
      });
    } catch (error: any) {
      res.json({
        success: false,
        valid: false,
        error: 'Verification service temporarily unavailable',
      });
    }
  })
);

export default router;
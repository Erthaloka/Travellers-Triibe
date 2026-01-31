/**
 * Partner routes - Business onboarding and management with GST/Non-GST support - partners.ts
 * UPDATED: Added GST verification, revenue tracking, and compliance endpoints
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import QRCode from 'qrcode';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody, validateParams } from '../middleware/validate.js';
import { authenticate, requirePartner, requireAdmin } from '../middleware/auth.js';
import { Partner, PartnerStatus, BusinessCategory, User, UserRole, VerificationStatus } from '../models/index.js';
import { env } from '../config/env.js';

const router = Router();

// ============== Validation Schemas ==============

const onboardingSchema = z.object({
  businessName: z.string().min(2, 'Business name is required'),
  legalBusinessName: z.string().min(2, 'Legal business name is required'),
  category: z.nativeEnum(BusinessCategory),
  description: z.string().optional(),
  isGstRegistered: z.boolean(),
  gstNumber: z
    .string()
    .regex(/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, 'Invalid GSTIN format')
    .optional(),
  panNumber: z
    .string()
    .regex(/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/, 'Invalid PAN format'),
  businessPhone: z.string().regex(/^\+91[6-9]\d{9}$/, 'Invalid phone number'),
  businessEmail: z.string().email('Invalid email'),
  address: z.object({
    line1: z.string().min(1, 'Address line 1 is required'),
    line2: z.string().optional(),
    city: z.string().min(1, 'City is required'),
    state: z.string().min(1, 'State is required'),
    pincode: z.string().regex(/^\d{6}$/, 'Invalid pincode'),
  }),
  discountRate: z.number().min(1).max(20).default(env.DISCOUNT_RATE_DEFAULT),
  settlementMode: z.enum(['PLATFORM', 'DIRECT']).optional(),
  upiId: z.string().optional(),
  bankDetails: z
    .object({
      accountNumber: z.string(),
      ifscCode: z.string(),
      accountHolderName: z.string(),
      bankName: z.string(),
    })
    .optional(),
});

const updateProfileSchema = onboardingSchema.partial();

const partnerIdSchema = z.object({
  id: z.string().regex(/^[a-fA-F0-9]{24}$/, 'Invalid partner ID'),
});

// ============== Routes ==============

/**
 * POST /api/partners/onboard
 * Complete partner onboarding with GST/Non-GST support
 */
router.post(
  '/onboard',
  authenticate,
  validateBody(onboardingSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    // Check if partner profile already exists
    let partner = await Partner.findOne({ userId });

    const autoApprove = process.env.AUTO_APPROVE_PARTNERS === 'true';
    const initialStatus = autoApprove ? PartnerStatus.ACTIVE : PartnerStatus.PENDING;

    const {
      businessName,
      legalBusinessName,
      category,
      description,
      isGstRegistered,
      gstNumber,
      panNumber,
      businessPhone,
      businessEmail,
      address,
      discountRate,
      settlementMode,
      upiId,
      bankDetails,
    } = req.body;

    if (partner) {
      // Update existing profile
      Object.assign(partner, {
        businessName,
        legalBusinessName,
        category,
        description,
        isGstRegistered,
        businessPhone,
        businessEmail,
        address,
        discountRate: discountRate || partner.discountRate,
        settlementMode: settlementMode || partner.settlementMode,
        upiId,
        bankDetails,
      });

      // Update verification details
      if (isGstRegistered && gstNumber) {
        partner.verificationDetails.gstin = {
          number: gstNumber.toUpperCase(),
          status: VerificationStatus.PENDING,
        };
      }
      partner.verificationDetails.pan = {
        number: panNumber.toUpperCase(),
        status: VerificationStatus.PENDING,
      };

      partner.status = initialStatus;
      
      if (autoApprove) {
        partner.isVerified = true;
        partner.verifiedAt = new Date();
        partner.activatedAt = new Date();
      }
      
      await partner.save();
    } else {
      // Create new partner profile
      const currentFY = getCurrentFinancialYear();
      
      partner = await Partner.create({
        userId,
        businessName,
        legalBusinessName,
        category,
        description,
        isGstRegistered,
        businessPhone,
        businessEmail,
        address: {
          ...address,
          country: 'India',
        },
        verificationDetails: {
          ...(isGstRegistered && gstNumber && {
            gstin: {
              number: gstNumber.toUpperCase(),
              status: VerificationStatus.PENDING,
            },
          }),
          pan: {
            number: panNumber.toUpperCase(),
            status: VerificationStatus.PENDING,
          },
        },
        discountRate: discountRate || env.DISCOUNT_RATE_DEFAULT,
        settlementMode: settlementMode || 'PLATFORM',
        upiId,
        bankDetails,
        status: initialStatus,
        isVerified: autoApprove,
        verifiedAt: autoApprove ? new Date() : undefined,
        activatedAt: autoApprove ? new Date() : undefined,
        onboardedAt: new Date(),
        revenueTracking: [
          {
            financialYear: currentFY,
            totalRevenue: 0,
            gstApplicable: isGstRegistered,
            thresholdWarnings: {
              warning16L: false,
              warning19L: false,
              threshold20L: false,
            },
            lastCalculatedAt: new Date(),
          },
        ],
        payoutControl: {
          enabled: true,
          requiresGstForUnblock: false,
        },
      });
    }

    // Add PARTNER role to user if not already present
    if (!req.user!.roles.includes(UserRole.PARTNER)) {
      await User.findByIdAndUpdate(
        userId,
        { $addToSet: { roles: UserRole.PARTNER } },
        { new: true }
      );
    }

    // Generate QR code data
    const qrData = JSON.stringify({
      partnerId: partner._id,
      businessName: partner.businessName,
      discountRate: partner.discountRate,
    });

    partner.qrCodeData = qrData;
    await partner.save();

    res.status(201).json({
      success: true,
      data: partner,
      message: autoApprove 
        ? 'Partner registration approved! You can now start accepting payments.'
        : 'Partner onboarding submitted. Awaiting verification.',
    });
  })
);

/**
 * GET /api/partners/profile
 * Get current partner's profile
 */
router.get(
  '/profile',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId }).populate(
      'userId',
      'name email phone'
    );

    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    res.json({
      success: true,
      data: partner,
    });
  })
);

/**
 * GET /api/partners/revenue-summary
 * Get partner's revenue summary for current financial year
 */
router.get(
  '/revenue-summary',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    const currentFY = partner.getCurrentFinancialYear();
    const currentRevenue = partner.getCurrentYearRevenue();
    const gstThreshold = parseInt(process.env.GST_THRESHOLD || '2000000000');
    const remainingBeforeGST = Math.max(0, gstThreshold - currentRevenue);
    const percentageUsed = (currentRevenue / gstThreshold) * 100;

    const tracking = partner.revenueTracking.find(
      (r) => r.financialYear === currentFY
    );

    res.json({
      success: true,
      data: {
        financialYear: currentFY,
        currentRevenue,
        gstThreshold,
        remainingBeforeGST,
        percentageUsed: Math.min(100, percentageUsed),
        isGstRequired: currentRevenue >= gstThreshold,
        isGstRegistered: partner.isGstRegistered,
        payoutBlocked: !partner.payoutControl.enabled,
        warnings: tracking?.thresholdWarnings || {
          warning16L: false,
          warning19L: false,
          threshold20L: false,
        },
      },
    });
  })
);

/**
 * GET /api/partners/compliance-status
 * Get partner's compliance status
 */
router.get(
  '/compliance-status',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    const currentRevenue = partner.getCurrentYearRevenue();
    const gstThreshold = parseInt(process.env.GST_THRESHOLD || '2000000000');

    res.json({
      success: true,
      data: {
        isGstRegistered: partner.isGstRegistered,
        gstDetails: partner.verificationDetails.gstin,
        panDetails: partner.verificationDetails.pan,
        revenue: {
          current: currentRevenue,
          threshold: gstThreshold,
          isGstRequired: currentRevenue >= gstThreshold,
        },
        payoutStatus: {
          enabled: partner.payoutControl.enabled,
          blockedAt: partner.payoutControl.blockedAt,
          blockReason: partner.payoutControl.blockReason,
          requiresGst: partner.payoutControl.requiresGstForUnblock,
        },
        compliance: {
          isCompliant: partner.isGstRegistered || currentRevenue < gstThreshold,
          requiresAction: !partner.isGstRegistered && currentRevenue >= gstThreshold,
        },
      },
    });
  })
);

/**
 * PUT /api/partners/profile
 * Update partner profile
 */
router.put(
  '/profile',
  authenticate,
  requirePartner,
  validateBody(updateProfileSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOneAndUpdate(
      { userId },
      { $set: req.body },
      { new: true, runValidators: true }
    );

    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    res.json({
      success: true,
      data: partner,
    });
  })
);

/**
 * GET /api/partners/qr-code
 * Generate QR code for partner
 */
router.get(
  '/qr-code',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    if (!partner.isActive()) {
      throw new ApiError(403, 'Partner account is not active');
    }

    if (!partner.canAcceptOrders()) {
      throw new ApiError(403, 'Partner cannot accept orders at this time');
    }

    const qrData = {
      type: 'TT_PAYMENT',
      partnerId: partner._id,
      businessName: partner.businessName,
      discountRate: partner.discountRate,
      timestamp: Date.now(),
    };

    const qrCodeDataUrl = await QRCode.toDataURL(JSON.stringify(qrData), {
      errorCorrectionLevel: 'M',
      width: 300,
      margin: 2,
    });

    res.json({
      success: true,
      data: {
        qrCode: qrCodeDataUrl,
        qrData,
      },
    });
  })
);

/**
 * GET /api/partners/analytics
 * Get partner analytics
 */
router.get(
  '/analytics',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const { Order, OrderStatus } = await import('../models/index.js');

    const [dailyStats, weeklyTrend] = await Promise.all([
      Order.aggregate([
        {
          $match: {
            partnerId: partner._id,
            status: OrderStatus.COMPLETED,
            createdAt: { $gte: thisWeek },
          },
        },
        {
          $group: {
            _id: {
              $dateToString: { format: '%Y-%m-%d', date: '$createdAt' },
            },
            orders: { $sum: 1 },
            revenue: { $sum: '$finalAmount' },
            discount: { $sum: '$discountAmount' },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      Order.aggregate([
        {
          $match: {
            partnerId: partner._id,
            status: OrderStatus.COMPLETED,
            createdAt: { $gte: thisMonth },
          },
        },
        {
          $group: {
            _id: { $hour: '$createdAt' },
            count: { $sum: 1 },
          },
        },
        { $sort: { _id: 1 } },
      ]),
    ]);

    res.json({
      success: true,
      data: {
        summary: partner.analytics,
        dailyStats,
        peakHours: weeklyTrend,
        discountRate: partner.discountRate,
        revenueTracking: partner.revenueTracking,
      },
    });
  })
);

// ============== Public Routes ==============

/**
 * GET /api/partners/:id/public
 * Get public partner info (for QR scan)
 */
router.get(
  '/:id/public',
  validateParams(partnerIdSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;

    const partner = await Partner.findById(id).select(
      'businessName category discountRate address.city status payoutControl.enabled'
    );

    if (!partner) {
      throw new ApiError(404, 'Partner not found');
    }

    if (!partner.isActive()) {
      throw new ApiError(403, 'Partner is not accepting payments');
    }

    if (!partner.canAcceptOrders()) {
      throw new ApiError(403, 'Partner cannot accept orders at this time');
    }

    res.json({
      success: true,
      data: partner,
    });
  })
);

// ============== Admin Routes ==============

/**
 * GET /api/partners/admin/pending
 * Get pending partner applications (Admin only)
 */
router.get(
  '/admin/pending',
  authenticate,
  requireAdmin,
  asyncHandler(async (_req: Request, res: Response) => {
    const partners = await Partner.find({ status: PartnerStatus.PENDING })
      .populate('userId', 'name email phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: partners,
    });
  })
);

/**
 * PUT /api/partners/admin/:id/verify
 * Verify or reject partner application (Admin only)
 */
router.put(
  '/admin/:id/verify',
  authenticate,
  requireAdmin,
  validateParams(partnerIdSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const { approved, reason } = req.body;

    const partner = await Partner.findById(id);
    if (!partner) {
      throw new ApiError(404, 'Partner not found');
    }

    if (approved) {
      partner.status = PartnerStatus.ACTIVE;
      partner.isVerified = true;
      partner.verifiedAt = new Date();
      partner.activatedAt = new Date();
    } else {
      partner.status = PartnerStatus.REJECTED;
      // Could store rejection reason
    }

    await partner.save();

    res.json({
      success: true,
      data: partner,
      message: approved ? 'Partner verified' : 'Partner rejected',
    });
  })
);

// ============== Helper Functions ==============

function getCurrentFinancialYear(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  
  if (month >= 4) {
    return `FY${year}-${(year + 1).toString().slice(2)}`;
  } else {
    return `FY${year - 1}-${year.toString().slice(2)}`;
  }
}

export default router;
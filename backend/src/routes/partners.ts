/**
 * Partner routes - Business onboarding and management
 * UPDATED: Added auto-approve option for development
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import QRCode from 'qrcode';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody, validateParams } from '../middleware/validate.js';
import { authenticate, requirePartner, requireAdmin } from '../middleware/auth.js';
import { Partner, PartnerStatus, BusinessCategory, User, UserRole } from '../models/index.js';
import { env } from '../config/env.js';

const router = Router();

// ============== Validation Schemas ==============

const onboardingSchema = z.object({
  businessName: z.string().min(2, 'Business name is required'),
  category: z.nativeEnum(BusinessCategory),
  description: z.string().optional(),
  gstNumber: z.string().optional(),
  panNumber: z.string().optional(),
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
 * Complete partner onboarding (creates partner profile and adds role)
 * 
 * ✅ UPDATED: Auto-approve for development (set AUTO_APPROVE_PARTNERS=true in env)
 */
router.post(
  '/onboard',
  authenticate,
  validateBody(onboardingSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    // Check if partner profile already exists
    let partner = await Partner.findOne({ userId });

    // ✅ UPDATED: Auto-approve based on environment variable
    const autoApprove = process.env.AUTO_APPROVE_PARTNERS === 'true';
    const initialStatus = autoApprove ? PartnerStatus.ACTIVE : PartnerStatus.PENDING;

    if (partner) {
      // Update existing profile
      Object.assign(partner, req.body);
      partner.status = initialStatus;
      
      // If auto-approving, mark as verified
      if (autoApprove) {
        partner.isVerified = true;
        partner.verifiedAt = new Date();
      }
      
      await partner.save();
    } else {
      // Create new partner profile
      partner = await Partner.create({
        userId,
        ...req.body,
        status: initialStatus,
        isVerified: autoApprove,
        verifiedAt: autoApprove ? new Date() : undefined,
      });
    }

    // Add PARTNER role to user if not already present
    if (!req.user!.roles.includes(UserRole.PARTNER)) {
      await User.findByIdAndUpdate(
        userId,
        { $addToSet: { roles: UserRole.PARTNER } },
        { new: true }
      );
      
      // Update the user object in request for consistency
      req.user!.roles.push(UserRole.PARTNER);
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

    // Generate QR code with partner payment data
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

    // Get date ranges
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const thisWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Aggregate order data
    const { Order, OrderStatus } = await import('../models/index.js');

    const [dailyStats, weeklyTrend] = await Promise.all([
      // Daily stats for the last 7 days
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
      // Category breakdown (if applicable)
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
      'businessName category discountRate address.city status'
    );

    if (!partner) {
      throw new ApiError(404, 'Partner not found');
    }

    if (!partner.isActive()) {
      throw new ApiError(403, 'Partner is not accepting payments');
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
    const { approved, reason: _reason } = req.body;

    const partner = await Partner.findById(id);
    if (!partner) {
      throw new ApiError(404, 'Partner not found');
    }

    if (approved) {
      partner.status = PartnerStatus.ACTIVE;
      partner.isVerified = true;
      partner.verifiedAt = new Date();
    } else {
      partner.status = PartnerStatus.REJECTED;
      // Could store rejection reason (_reason) in metadata
    }

    await partner.save();

    res.json({
      success: true,
      data: partner,
      message: approved ? 'Partner verified' : 'Partner rejected',
    });
  })
);

export default router;
/**
 * Partner routes - Business onboarding and management
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

/* ================= Validation Schemas ================= */

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

/* ================= Routes ================= */

/**
 * GET /api/partners/onboarding-status
 * Check if user needs to complete onboarding
 * Returns: { needsOnboarding: boolean, hasPartnerRole: boolean, profile: Partner | null }
 */
router.get(
  '/onboarding-status',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const hasPartnerRole = req.user!.roles.includes(UserRole.PARTNER);
    
    if (!hasPartnerRole) {
      return res.json({
        success: true,
        data: {
          needsOnboarding: false,
          hasPartnerRole: false,
          profile: null,
        },
      });
    }

    const partner = await Partner.findOne({ userId: req.user!._id });

    res.json({
      success: true,
      data: {
        needsOnboarding: !partner,
        hasPartnerRole: true,
        profile: partner,
      },
    });
  })
);

/**
 * POST /api/partners/onboard
 * Create partner business profile
 */
router.post(
  '/onboard',
  authenticate,
  validateBody(onboardingSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    // Check if already onboarded
    const existing = await Partner.findOne({ userId });
    if (existing) {
      throw new ApiError(409, 'Partner profile already exists');
    }

    // Create partner profile (DEV MODE - auto-approve)
    const partner = await Partner.create({
      userId,
      ...req.body,
      status: PartnerStatus.ACTIVE, // 🔥 DEV: Auto-approve
      isVerified: true,
      verifiedAt: new Date(),
    });

    // Add PARTNER role if not present
    if (!req.user!.roles.includes(UserRole.PARTNER)) {
      await User.findByIdAndUpdate(userId, {
        $addToSet: { roles: UserRole.PARTNER },
      });
    }

    // Generate QR code data
    partner.qrCodeData = JSON.stringify({
      partnerId: partner._id,
      businessName: partner.businessName,
      discountRate: partner.discountRate,
    });

    await partner.save();

    res.status(201).json({
      success: true,
      data: partner,
      message: 'Partner onboarded successfully',
    });
  })
);

/**
 * GET /api/partners/profile
 * Get current partner profile
 * ⚠️ Only authenticate - don't require partner profile to exist yet
 */
router.get(
  '/profile',
  authenticate, //  Only check if user is logged in
  asyncHandler(async (req: Request, res: Response) => {
    const partner = await Partner.findOne({ userId: req.user!._id }).populate(
      'userId',
      'name email phone'
    );

    // Return null if no profile exists (user hasn't onboarded yet)
    if (!partner) {
      return res.json({
        success: true,
        data: null,
        message: 'Partner profile not found. Please complete onboarding.',
      });
    }

    res.json({ success: true, data: partner });
  })
);

/**
 * PUT /api/partners/profile
 * Update partner profile
 */
router.put(
  '/profile',
  authenticate,
  requirePartner, // ✅ Now require partner profile to exist
  validateBody(updateProfileSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const partner = await Partner.findOneAndUpdate(
      { userId: req.user!._id },
      { $set: req.body },
      { new: true, runValidators: true }
    );

    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    res.json({ success: true, data: partner });
  })
);

/**
 * GET /api/partners/qr-code
 * Generate QR code for partner payments
 */
router.get(
  '/qr-code',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const partner = await Partner.findOne({ userId: req.user!._id });
    
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    if (!partner.isActive()) {
      throw new ApiError(403, 'Partner account is not active');
    }

    // Generate QR code data
    const qrData = {
      type: 'TT_PAYMENT',
      partnerId: partner._id,
      businessName: partner.businessName,
      discountRate: partner.discountRate,
      timestamp: Date.now(),
    };

    const qrCode = await QRCode.toDataURL(JSON.stringify(qrData), {
      errorCorrectionLevel: 'M',
      width: 300,
      margin: 2,
    });

    res.json({
      success: true,
      data: { qrCode, qrData },
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
    const partner = await Partner.findOne({ userId: req.user!._id });
    
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    res.json({
      success: true,
      data: partner.analytics,
    });
  })
);

/* ================= Public Routes ================= */

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

/* ================= Admin Routes ================= */

/**
 * GET /api/partners/admin/pending
 * Get pending partner applications
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
 * Verify or reject partner application
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
    } else {
      partner.status = PartnerStatus.REJECTED;
      // Store rejection reason in description or metadata
      if (reason) {
        partner.description = `Rejected: ${reason}`;
      }
    }

    await partner.save();

    res.json({
      success: true,
      data: partner,
      message: approved ? 'Partner verified successfully' : 'Partner rejected',
    });
  })
);

export default router;
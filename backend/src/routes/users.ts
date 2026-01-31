/**
 * User routes - users.ts
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import { User, Order, OrderStatus } from '../models/index.js';

const router = Router();

// ============== Validation Schemas ==============

const updateProfileSchema = z.object({
  name: z.string().min(2).optional(),
  phone: z
    .string()
    .regex(/^\+91[6-9]\d{9}$/, 'Invalid phone number')
    .optional(),
  avatar: z.string().url().optional(),
});

// ============== Routes ==============

/**
 * GET /api/users/profile
 * Get current user's profile
 */
router.get(
  '/profile',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    res.json({
      success: true,
      data: req.user,
    });
  })
);

/**
 * PUT /api/users/profile
 * Update user profile
 */
router.put(
  '/profile',
  authenticate,
  validateBody(updateProfileSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;
    const updates = req.body;

    // Check if phone is being changed and is unique
    if (updates.phone) {
      const existingUser = await User.findOne({
        phone: updates.phone,
        _id: { $ne: userId },
      });
      if (existingUser) {
        throw new ApiError(409, 'Phone number already in use');
      }
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    res.json({
      success: true,
      data: user,
    });
  })
);



/**
 * GET /api/users/savings
 * Get user's savings statistics
 */
router.get(
  '/savings',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    // Get date ranges
    const now = new Date();
    const thisMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const lastMonthEnd = new Date(now.getFullYear(), now.getMonth(), 0);

    // Aggregate savings data
    const [monthlySavings, categorySavings, recentSavings] = await Promise.all([
      // Monthly savings trend
      Order.aggregate([
        {
          $match: {
            userId,
            status: OrderStatus.COMPLETED,
            createdAt: { $gte: new Date(now.getFullYear(), 0, 1) }, // This year
          },
        },
        {
          $group: {
            _id: { $month: '$createdAt' },
            savings: { $sum: '$discountAmount' },
            orders: { $sum: 1 },
            spent: { $sum: '$finalAmount' },
          },
        },
        { $sort: { _id: 1 } },
      ]),
      // Savings by category
      Order.aggregate([
        {
          $match: {
            userId,
            status: OrderStatus.COMPLETED,
          },
        },
        {
          $lookup: {
            from: 'partners',
            localField: 'partnerId',
            foreignField: '_id',
            as: 'partner',
          },
        },
        { $unwind: '$partner' },
        {
          $group: {
            _id: '$partner.category',
            savings: { $sum: '$discountAmount' },
            orders: { $sum: 1 },
          },
        },
        { $sort: { savings: -1 } },
      ]),
      // Recent savings
      Order.find({
        userId,
        status: OrderStatus.COMPLETED,
      })
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('partnerId', 'businessName category'),
    ]);

    // Calculate this month vs last month
    const thisMonthData = await Order.aggregate([
      {
        $match: {
          userId,
          status: OrderStatus.COMPLETED,
          createdAt: { $gte: thisMonth },
        },
      },
      {
        $group: {
          _id: null,
          savings: { $sum: '$discountAmount' },
          orders: { $sum: 1 },
        },
      },
    ]);

    const lastMonthData = await Order.aggregate([
      {
        $match: {
          userId,
          status: OrderStatus.COMPLETED,
          createdAt: { $gte: lastMonth, $lte: lastMonthEnd },
        },
      },
      {
        $group: {
          _id: null,
          savings: { $sum: '$discountAmount' },
          orders: { $sum: 1 },
        },
      },
    ]);

    const thisMonthSavings = thisMonthData[0]?.savings || 0;
    const lastMonthSavingsVal = lastMonthData[0]?.savings || 0;

    // Calculate growth percentage
    const growth =
      lastMonthSavingsVal > 0
        ? ((thisMonthSavings - lastMonthSavingsVal) / lastMonthSavingsVal) * 100
        : 0;

    res.json({
      success: true,
      data: {
        totalSavings: req.user!.totalSavings,
        totalOrders: req.user!.totalOrders,
        thisMonth: {
          savings: thisMonthSavings,
          orders: thisMonthData[0]?.orders || 0,
        },
        lastMonth: {
          savings: lastMonthSavingsVal,
          orders: lastMonthData[0]?.orders || 0,
        },
        growthPercentage: Math.round(growth * 100) / 100,
        monthlySavings,
        categorySavings,
        recentSavings,
      },
    });
  })
);

/**
 * DELETE /api/users/account
 * Deactivate user account
 */
router.delete(
  '/account',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    // Soft delete - just mark as inactive
    await User.findByIdAndUpdate(userId, {
      status: 'INACTIVE',
    });

    res.json({
      success: true,
      message: 'Account deactivated successfully',
    });
  })
);

export default router;

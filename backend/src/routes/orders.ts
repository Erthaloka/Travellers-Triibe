/**
 * Order routes
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateParams, validateQuery } from '../middleware/validate.js';
import { authenticate, requirePartner } from '../middleware/auth.js';
import { Order, OrderStatus, Partner, UserRole } from '../models/index.js';

const router = Router();

// ============== Validation Schemas ==============

const orderIdSchema = z.object({
  id: z.string().regex(/^[a-fA-F0-9]{24}$/, 'Invalid order ID'),
});

const listOrdersSchema = z.object({
  page: z.string().optional().default('1').transform(Number),
  limit: z.string().optional().default('10').transform(Number),
  status: z.nativeEnum(OrderStatus).optional(),
});

// ============== User Routes ==============

/**
 * GET /api/orders
 * Get user's orders
 */
router.get(
  '/',
  authenticate,
  validateQuery(listOrdersSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 10;
    const status = req.query.status as OrderStatus | undefined;
    const userId = req.user!._id;

    const query: Record<string, unknown> = { userId };
    if (status) {
      query.status = status;
    }

    const skip = (page - 1) * limit;

    const [orders, total] = await Promise.all([
      Order.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('partnerId', 'businessName category address'),
      Order.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      },
    });
  })
);

/**
 * GET /api/orders/:id
 * Get order details
 */
router.get(
  '/:id',
  authenticate,
  validateParams(orderIdSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const userId = req.user!._id;

    const order = await Order.findById(id)
      .populate('partnerId', 'businessName category address businessPhone')
      .populate('userId', 'name email phone');

    if (!order) {
      throw new ApiError(404, 'Order not found');
    }

    // Check authorization
    const isOwner = order.userId._id.toString() === userId.toString();
    const isPartner = req.user!.roles.includes(UserRole.PARTNER);
    const isAdmin = req.user!.roles.includes(UserRole.ADMIN);

    if (!isOwner && !isPartner && !isAdmin) {
      throw new ApiError(403, 'Not authorized to view this order');
    }

    res.json({
      success: true,
      data: order,
    });
  })
);

// ============== Partner Routes ==============

/**
 * GET /api/orders/partner/list
 * Get partner's orders
 */
router.get(
  '/partner/list',
  authenticate,
  requirePartner,
  validateQuery(listOrdersSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 10;
    const status = req.query.status as OrderStatus | undefined;
    const userId = req.user!._id;

    // Find partner for this user
    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    const query: Record<string, unknown> = { partnerId: partner._id };
    if (status) {
      query.status = status;
    }

    const skip = (page - 1) * limit;

    const [orders, total] = await Promise.all([
      Order.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('userId', 'name email phone'),
      Order.countDocuments(query),
    ]);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit),
        },
      },
    });
  })
);

/**
 * GET /api/orders/partner/stats
 * Get partner order statistics
 */
router.get(
  '/partner/stats',
  authenticate,
  requirePartner,
  asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user!._id;

    const partner = await Partner.findOne({ userId });
    if (!partner) {
      throw new ApiError(404, 'Partner profile not found');
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const thisMonth = new Date(today.getFullYear(), today.getMonth(), 1);

    const [todayStats, monthStats, recentOrders] = await Promise.all([
      // Today's stats
      Order.aggregate([
        {
          $match: {
            partnerId: partner._id,
            status: OrderStatus.COMPLETED,
            createdAt: { $gte: today },
          },
        },
        {
          $group: {
            _id: null,
            count: { $sum: 1 },
            revenue: { $sum: '$finalAmount' },
            discount: { $sum: '$discountAmount' },
          },
        },
      ]),
      // This month's stats
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
            _id: null,
            count: { $sum: 1 },
            revenue: { $sum: '$finalAmount' },
            discount: { $sum: '$discountAmount' },
          },
        },
      ]),
      // Recent orders
      Order.find({ partnerId: partner._id })
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('userId', 'name'),
    ]);

    res.json({
      success: true,
      data: {
        today: todayStats[0] || { count: 0, revenue: 0, discount: 0 },
        thisMonth: monthStats[0] || { count: 0, revenue: 0, discount: 0 },
        allTime: partner.analytics,
        recentOrders,
      },
    });
  })
);

export default router;

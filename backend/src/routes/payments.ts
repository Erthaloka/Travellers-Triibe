/**
 * Payment routes - Razorpay integration
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
import mongoose from 'mongoose';
import { Order, OrderStatus, Partner, User } from '../models/index.js';
import {
  createRazorpayOrder,
  verifyPaymentSignature,
  verifyWebhookSignature,
  fetchPayment,
} from '../services/razorpay.js';

const router = Router();

// ============== Validation Schemas ==============

const createPaymentSchema = z.object({
  partnerId: z.string().regex(/^[a-fA-F0-9]{24}$/, 'Invalid partner ID'),
  amount: z.number().min(100, 'Minimum amount is ₹1 (100 paise)'),
  notes: z.string().optional(),
});

const verifyPaymentSchema = z.object({
  orderId: z.string(),
  razorpayOrderId: z.string(),
  razorpayPaymentId: z.string(),
  razorpaySignature: z.string(),
});

const preparePaymentSchema = z.object({
  merchant_id: z.string(), // Can be MongoDB ObjectId or custom merchant ID
  bill_amount: z.number().min(0.01, 'Bill amount must be at least ₹0.01'),
});

// ============== Routes ==============

/**
 * POST /api/payments/prepare
 * POST /api/v1/payment/prepare (alternative path)
 * Prepare payment - creates order and Razorpay order without payment
 */
router.post(
  '/prepare',
  validateBody(preparePaymentSchema),
  asyncHandler(async (req: Request, res: Response) => {
    console.log('preparePayment route hit');
    const { merchant_id, bill_amount } = req.body;
    const userId = null;

    // Convert bill_amount from rupees to paise
    const billAmountInPaise = Math.round(bill_amount * 100);

    // Find partner by ID (merchant_id can be MongoDB ObjectId)
    let partner;
    if (mongoose.Types.ObjectId.isValid(merchant_id)) {
      partner = await Partner.findById(merchant_id);
    } else {
      // If not a valid ObjectId, try to find by custom merchant ID if it exists
      throw new ApiError(400, 'Invalid merchant ID format');
    }

    if (!partner || !partner.isActive()) {
      throw new ApiError(404, 'Merchant not found or not active');
    }

    // Calculate discount
    const discountRate = partner.discountRate;
    const discountAmount = Math.round((billAmountInPaise * discountRate) / 100);
    const finalAmount = billAmountInPaise - discountAmount;

    // Platform fee (example: 2% of final amount)
    const platformFee = Math.round((finalAmount * 2) / 100);
    const partnerPayout = finalAmount - platformFee;

    // Create Razorpay order
    const razorpayOrder = await createRazorpayOrder({
      amount: finalAmount, // Amount in paise
      currency: 'INR',
      receipt: `prep_${Date.now()}`,
      notes: {
        userId: "DEV_USER",
        partnerId: partner._id.toString(),
        originalAmount: billAmountInPaise.toString(),
        discountRate: discountRate.toString(),
      },
    });

    // Create order in database (but don't mark as paid yet)
    const order = await Order.create({
      userId: partner._id, // TEMP: use merchant as user for dev-only testing
      partnerId: partner._id,
      originalAmount: billAmountInPaise,
      discountRate,
      discountAmount,
      finalAmount,
      partnerPayout,
      platformFee,
      razorpayOrderId: razorpayOrder.id,
      status: OrderStatus.PENDING,
    });

    // Return response matching API documentation format
    res.status(201).json({
      order_id: order.orderId,
      merchant: {
        name: partner.businessName,
        category: partner.category,
      },
      amounts: {
        gross: bill_amount, // in rupees
        discount_percent: discountRate,
        discount: discountAmount / 100, // in rupees
        net_payable: finalAmount / 100, // in rupees
      },
      razorpay: {
        order_id: razorpayOrder.id,
        amount: finalAmount, // in paise
        currency: 'INR',
      },
    });
  })
);

/**
 * POST /api/payments/create
 * Create a new payment order
 */
router.post(
  '/create',
  authenticate,
  validateBody(createPaymentSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { partnerId, amount, notes } = req.body;
    const userId = req.user!._id;

    // Find partner
    const partner = await Partner.findById(partnerId);
    if (!partner || !partner.isActive()) {
      throw new ApiError(404, 'Partner not found or not active');
    }

    // Calculate discount
    const discountRate = partner.discountRate;
    const discountAmount = Math.floor((amount * discountRate) / 100);
    const finalAmount = amount - discountAmount;

    // Platform fee (example: 2% of final amount)
    const platformFee = Math.floor((finalAmount * 2) / 100);
    const partnerPayout = finalAmount - platformFee;

    // Create Razorpay order
    const razorpayOrder = await createRazorpayOrder({
      amount: finalAmount, // Amount in paise
      receipt: `rcpt_${Date.now()}`,
      notes: {
        userId: userId.toString(),
        partnerId: partnerId,
        originalAmount: amount.toString(),
        discountRate: discountRate.toString(),
      },
    });

    // Create order in database
    const order = await Order.create({
      userId,
      partnerId,
      originalAmount: amount,
      discountRate,
      discountAmount,
      finalAmount,
      partnerPayout,
      razorpayOrderId: razorpayOrder.id,
      status: OrderStatus.PENDING,
      notes,
    });

    res.status(201).json({
      success: true,
      data: {
        order: {
          id: order._id,
          orderId: order.orderId,
          originalAmount: order.originalAmount,
          discountRate: order.discountRate,
          discountAmount: order.discountAmount,
          finalAmount: order.finalAmount,
        },
        razorpay: {
          orderId: razorpayOrder.id,
          amount: razorpayOrder.amount,
          currency: razorpayOrder.currency,
        },
        partner: {
          id: partner._id,
          businessName: partner.businessName,
        },
      },
    });
  })
);

/**
 * POST /api/payments/verify
 * Verify payment after Razorpay checkout
 */
router.post(
  '/verify',
  authenticate,
  validateBody(verifyPaymentSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } =
      req.body;

    // Find order
    const order = await Order.findById(orderId);
    if (!order) {
      throw new ApiError(404, 'Order not found');
    }

    if (order.userId.toString() !== req.user!._id.toString()) {
      throw new ApiError(403, 'Not authorized');
    }

    if (order.status !== OrderStatus.PENDING) {
      throw new ApiError(400, 'Order is not pending');
    }

    if (order.razorpayOrderId !== razorpayOrderId) {
      throw new ApiError(400, 'Order ID mismatch');
    }

    // Verify signature
    const isValid = verifyPaymentSignature(
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature
    );

    if (!isValid) {
      order.status = OrderStatus.FAILED;
      order.notes = 'Payment signature verification failed';
      await order.save();
      throw new ApiError(400, 'Payment verification failed');
    }

    // Verify payment with Razorpay
    const payment = await fetchPayment(razorpayPaymentId);
    if (payment.status !== 'captured') {
      throw new ApiError(400, 'Payment not captured');
    }

    // Mark order as completed
    await order.markCompleted(razorpayPaymentId, razorpaySignature);

    // Update user stats
    await User.findByIdAndUpdate(order.userId, {
      $inc: {
        totalSavings: order.discountAmount,
        totalOrders: 1,
      },
    });

    // Update partner analytics
    const partner = await Partner.findById(order.partnerId);
    if (partner) {
      await partner.updateAnalytics(order.finalAmount, order.discountAmount);
    }

    res.json({
      success: true,
      data: {
        order,
        message: 'Payment verified successfully',
      },
    });
  })
);

/**
 * POST /api/payments/webhook
 * Handle Razorpay webhooks
 */
router.post(
  '/webhook',
  asyncHandler(async (req: Request, res: Response) => {
    const signature = req.headers['x-razorpay-signature'] as string;

    if (!signature) {
      throw new ApiError(400, 'Missing signature');
    }

    // Verify webhook signature
    const isValid = verifyWebhookSignature(
      JSON.stringify(req.body),
      signature
    );

    if (!isValid) {
      throw new ApiError(400, 'Invalid webhook signature');
    }

    const { event, payload } = req.body;

    switch (event) {
      case 'payment.captured': {
        const { payment } = payload;
        const razorpayOrderId = payment.entity.order_id;

        // Find and update order
        const order = await Order.findOne({ razorpayOrderId });
        if (order && order.status === OrderStatus.PENDING) {
          await order.markCompleted(
            payment.entity.id,
            '' // Webhook doesn't provide signature
          );
        }
        break;
      }

      case 'payment.failed': {
        const { payment } = payload;
        const razorpayOrderId = payment.entity.order_id;

        const order = await Order.findOne({ razorpayOrderId });
        if (order && order.status === OrderStatus.PENDING) {
          await order.markFailed(payment.entity.error_description);
        }
        break;
      }

      case 'refund.created': {
        const { refund } = payload;
        const paymentId = refund.entity.payment_id;

        const order = await Order.findOne({ razorpayPaymentId: paymentId });
        if (order) {
          order.status = OrderStatus.REFUNDED;
          await order.save();
        }
        break;
      }

      default:
        console.log(`Unhandled webhook event: ${event}`);
    }

    // Always respond 200 to acknowledge receipt
    res.json({ received: true });
  })
);

/**
 * GET /api/payments/history
 * Get payment history for current user
 */
router.get(
  '/history',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { page = 1, limit = 10 } = req.query;
    const userId = req.user!._id;

    const skip = (Number(page) - 1) * Number(limit);

    const [orders, total] = await Promise.all([
      Order.find({ userId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit))
        .populate('partnerId', 'businessName category'),
      Order.countDocuments({ userId }),
    ]);

    res.json({
      success: true,
      data: {
        orders,
        pagination: {
          page: Number(page),
          limit: Number(limit),
          total,
          pages: Math.ceil(total / Number(limit)),
        },
      },
    });
  })
);

export default router;

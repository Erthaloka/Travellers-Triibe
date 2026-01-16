/**
 * Payment routes - Razorpay integration
 */
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody } from '../middleware/validate.js';
import { authenticate } from '../middleware/auth.js';
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

// ============== Routes ==============

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

    // Platform fee (1% of original amount)
    const platformFee = Math.floor((amount * 1) / 100);
    const partnerPayout = amount - platformFee;

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
      platformFee,
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

    console.log('🔍 Payment verification request:', {
      orderId,
      razorpayOrderId,
      razorpayPaymentId,
    });

    // Find order by MongoDB _id
    const order = await Order.findById(orderId);
    if (!order) {
      console.log('❌ Order not found:', orderId);
      throw new ApiError(404, 'Order not found');
    }

    if (order.userId.toString() !== req.user!._id.toString()) {
      throw new ApiError(403, 'Not authorized');
    }

    if (order.status !== OrderStatus.PENDING) {
      console.log('❌ Order status not pending:', order.status);
      throw new ApiError(400, 'Order is not pending');
    }

    if (order.razorpayOrderId !== razorpayOrderId) {
      console.log('❌ Order ID mismatch:', {
        expected: order.razorpayOrderId,
        received: razorpayOrderId,
      });
      throw new ApiError(400, 'Order ID mismatch');
    }

    // Verify signature
    const isValid = verifyPaymentSignature(
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature
    );

    if (!isValid) {
      console.log('❌ Invalid signature');
      order.status = OrderStatus.FAILED;
      order.notes = 'Payment signature verification failed';
      await order.save();
      throw new ApiError(400, 'Payment verification failed');
    }

    console.log('✅ Signature verified');

    // Verify payment with Razorpay
    try {
      const payment = await fetchPayment(razorpayPaymentId);
      console.log('💳 Razorpay payment status:', payment.status);

      if (payment.status !== 'captured' && payment.status !== 'authorized') {
        throw new ApiError(400, 'Payment not captured');
      }
    } catch (error) {
      console.log('⚠️ Could not fetch payment from Razorpay:', error);
      // Continue anyway if signature is valid
    }

    // Mark order as completed
    await order.markCompleted(razorpayPaymentId, razorpaySignature);
    console.log('✅ Order marked as completed');

    // Update user stats
    await User.findByIdAndUpdate(order.userId, {
      $inc: {
        totalSavings: order.discountAmount,
        totalOrders: 1,
      },
    });
    console.log('✅ User stats updated');

    // Update partner analytics
    const partner = await Partner.findById(order.partnerId);
    if (partner) {
      await partner.updateAnalytics(order.originalAmount, order.discountAmount);
      console.log('✅ Partner analytics updated');
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
      console.log('❌ Webhook: Missing signature');
      throw new ApiError(400, 'Missing signature');
    }

    // Get raw body (should be Buffer from express.raw())
    let rawBody: string;
    if (Buffer.isBuffer(req.body)) {
      rawBody = req.body.toString('utf8');
    } else if (typeof req.body === 'string') {
      rawBody = req.body;
    } else {
      rawBody = JSON.stringify(req.body);
    }

    console.log('📥 Webhook received, verifying signature...');

    // Verify signature
    const isValid = verifyWebhookSignature(rawBody, signature);
    if (!isValid) {
      console.log('❌ Webhook: Invalid signature');
      throw new ApiError(400, 'Invalid webhook signature');
    }

    console.log('✅ Webhook signature verified');

    // Parse payload
    const payload = JSON.parse(rawBody);
    const { event, payload: eventPayload } = payload;

    console.log('📨 Webhook event:', event);

    switch (event) {
      case 'payment.captured': {
        const payment = eventPayload.payment.entity;
        const razorpayOrderId = payment.order_id;
        const paymentId = payment.id;

        console.log('💳 Payment captured:', { razorpayOrderId, paymentId });

        // Find and update order
        const order = await Order.findOne({ razorpayOrderId });
        if (order && order.status === OrderStatus.PENDING) {
          await order.markCompleted(paymentId, '');
          console.log('✅ Order marked as completed via webhook');

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
            await partner.updateAnalytics(order.originalAmount, order.discountAmount);
          }
        }
        break;
      }

      case 'payment.failed': {
        const payment = eventPayload.payment.entity;
        const razorpayOrderId = payment.order_id;
        const errorDescription = payment.error_description;

        console.log('❌ Payment failed:', { razorpayOrderId, errorDescription });

        const order = await Order.findOne({ razorpayOrderId });
        if (order && order.status === OrderStatus.PENDING) {
          await order.markFailed(errorDescription);
          console.log('✅ Order marked as failed via webhook');
        }
        break;
      }

      case 'refund.created': {
        const refund = eventPayload.refund.entity;
        const paymentId = refund.payment_id;

        console.log('💸 Refund created for payment:', paymentId);

        const order = await Order.findOne({ razorpayPaymentId: paymentId });
        if (order) {
          order.status = OrderStatus.REFUNDED;
          await order.save();
          console.log('✅ Order marked as refunded');
        }
        break;
      }

      default:
        console.log(`ℹ️ Unhandled webhook event: ${event}`);
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
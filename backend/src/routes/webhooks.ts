/**
 * Webhook routes
 * Handles external webhook callbacks (Razorpay, etc.)
 */
import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { asyncHandler } from '../middleware/errorHandler.js';
import { Order, OrderStatus } from '../models/Order.js';
import { env } from '../config/env.js';

const router = Router();

/**
 * Verify Razorpay webhook signature
 * @param body - Request body object
 * @param signature - Signature from x-razorpay-signature header
 * @returns true if signature is valid
 */
function verifySignature(body: unknown, signature: string): boolean {
  if (!env.RAZORPAY_WEBHOOK_SECRET) {
    console.warn('⚠️ RAZORPAY_WEBHOOK_SECRET not configured');
    return false;
  }

  const expected = crypto
    .createHmac('sha256', env.RAZORPAY_WEBHOOK_SECRET)
    .update(JSON.stringify(body))
    .digest('hex');

  return expected === signature;
}

/**
 * POST /webhooks/razorpay
 * Handle Razorpay webhook events
 * Webhook decides final payment status - UI success callback is NOT trusted
 */
router.post(
  '/razorpay',
  asyncHandler(async (req: Request, res: Response) => {
    const signature = req.headers['x-razorpay-signature'] as string;

    if (!signature) {
      return res.status(400).send('Missing signature');
    }

    // Verify webhook signature
    if (!verifySignature(req.body, signature)) {
      return res.status(400).send('Invalid signature');
    }

    const event = req.body.event;
    const payment = req.body.payload.payment.entity;

    // Find order by Razorpay order ID
    const order = await Order.findOne({
      razorpayOrderId: payment.order_id,
    });

    if (!order) {
      // Order not found - still return 200 to acknowledge receipt
      return res.sendStatus(200);
    }

    // Handle payment events
    if (event === 'payment.captured') {
      // Payment successful - use markCompleted method
      await order.markCompleted(payment.id, ''); // Webhook doesn't provide signature
    }

    if (event === 'payment.failed') {
      // Payment failed - use markFailed method
      await order.markFailed(payment.error_description || 'Payment failed');
    }

    // Always return 200 to acknowledge receipt
    res.sendStatus(200);
  })
);

export default router;


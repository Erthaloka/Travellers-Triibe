/**
 * Razorpay payment service
 */
import Razorpay from 'razorpay';
import crypto from 'crypto';
import { env } from '../config/env.js';

// Initialize Razorpay instance
export const razorpay = new Razorpay({
  key_id: env.RAZORPAY_KEY_ID,
  key_secret: env.RAZORPAY_KEY_SECRET,
});

export interface CreateOrderParams {
  amount: number; // Amount in paise (100 = ₹1)
  currency?: string;
  receipt?: string;
  notes?: Record<string, string>;
}

export interface RazorpayOrder {
  id: string;
  entity: string;
  amount: number;
  amount_paid: number;
  amount_due: number;
  currency: string;
  receipt: string;
  status: string;
  created_at: number;
}

/**
 * Create a Razorpay order
 */
export const createRazorpayOrder = async (
  params: CreateOrderParams
): Promise<RazorpayOrder> => {
  const order = await razorpay.orders.create({
    amount: params.amount,
    currency: params.currency || 'INR',
    receipt: params.receipt || `rcpt_${Date.now()}`,
    notes: params.notes || {},
  });

  return order as RazorpayOrder;
};

/**
 * Verify Razorpay payment signature
 */
export const verifyPaymentSignature = (
  orderId: string,
  paymentId: string,
  signature: string
): boolean => {
  const body = `${orderId}|${paymentId}`;
  const expectedSignature = crypto
    .createHmac('sha256', env.RAZORPAY_KEY_SECRET)
    .update(body)
    .digest('hex');

  return expectedSignature === signature;
};

/**
 * Verify webhook signature
 */
export const verifyWebhookSignature = (
  body: string,
  signature: string
): boolean => {
  if (!env.RAZORPAY_WEBHOOK_SECRET) {
    console.warn('⚠️ Webhook secret not configured');
    return false;
  }

  const expectedSignature = crypto
    .createHmac('sha256', env.RAZORPAY_WEBHOOK_SECRET)
    .update(body)
    .digest('hex');

  return expectedSignature === signature;
};

/**
 * Fetch payment details
 */
export const fetchPayment = async (paymentId: string) => {
  return razorpay.payments.fetch(paymentId);
};

/**
 * Capture payment (for manual capture)
 */
export const capturePayment = async (paymentId: string, amount: number) => {
  return razorpay.payments.capture(paymentId, amount, 'INR');
};

/**
 * Refund payment
 */
export const refundPayment = async (
  paymentId: string,
  amount?: number,
  notes?: Record<string, string>
) => {
  return razorpay.payments.refund(paymentId, {
    amount,
    notes,
  });
};

/**
 * Create a Virtual Account (for UPI)
 */
export const createVirtualAccount = async (
  customerId: string,
  orderId: string
) => {
  // Razorpay virtual accounts for UPI payments
  // This is a simplified version - actual implementation may vary
  return {
    id: `va_${Date.now()}`,
    customer_id: customerId,
    order_id: orderId,
  };
};

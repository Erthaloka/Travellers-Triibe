/**
 * Razorpay payment service
 */
import Razorpay from 'razorpay';
import crypto from 'crypto';
import mongoose from 'mongoose';
import { env } from '../config/env.js';
import { Order, IOrder } from '../models/Order.js';
import { ApiError } from '../middleware/errorHandler.js';

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

/**
 * Create Razorpay order and update MongoDB order record
 * @param orderId - MongoDB order document ID or order document
 * @param netPayableAmount - Net payable amount in paise
 * @param options - Optional parameters for Razorpay order
 * @returns Updated order details with Razorpay order information
 */
export const createRazorpayOrderAndUpdate = async (
  orderId: string | mongoose.Types.ObjectId | IOrder,
  netPayableAmount: number,
  options?: {
    currency?: string;
    receipt?: string;
    notes?: Record<string, string>;
  }
): Promise<IOrder> => {
  // Find order if orderId is provided as string or ObjectId
  let order: IOrder | null;
  
  if (typeof orderId === 'string' || orderId instanceof mongoose.Types.ObjectId) {
    order = await Order.findById(orderId);
    if (!order) {
      throw new ApiError(404, `Order not found with ID: ${orderId}`);
    }
  } else {
    order = orderId;
  }

  // Validate net payable amount
  if (netPayableAmount <= 0) {
    throw new ApiError(400, 'Net payable amount must be greater than 0');
  }

  // Create receipt if not provided
  const receipt = options?.receipt || `order_${order.orderId}_${Date.now()}`;

  // Create Razorpay order
  const razorpayOrder = await createRazorpayOrder({
    amount: netPayableAmount,
    currency: options?.currency || 'INR',
    receipt,
    notes: {
      orderId: order.orderId,
      userId: order.userId.toString(),
      partnerId: order.partnerId.toString(),
      ...options?.notes,
    },
  });

  // Update MongoDB order with Razorpay order ID
  order.razorpayOrderId = razorpayOrder.id;
  await order.save();

  return order;
};

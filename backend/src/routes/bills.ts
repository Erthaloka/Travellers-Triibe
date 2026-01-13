/**
 * File: bills.ts
 * Purpose: Bill creation and QR management routes
 * Context: Partner creates bills, User validates QR codes
 */

import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { BillRequest } from '../models/BillRequest.js';
import { Partner } from '../models/Partner.js';
import { Order } from '../models/Order.js';
import { User } from '../models/User.js';
import { authenticate } from '../middleware/auth.js';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { generateQRToken, validateQRToken, getQRExpiry, getQRExpiryTimestamp } from '../utils/qr.js';
import { createRazorpayOrder } from '../services/razorpay.js';
import { env } from '../config/env.js';

const router = Router();

// =====================================================
// PARTNER ROUTES - Create bills and generate QR
// =====================================================

// Validation schema for bill creation
const createBillSchema = z.object({
  amount: z.number().min(1, 'Amount must be at least ₹1').max(100000, 'Amount cannot exceed ₹1,00,000'),
  discountRate: z.number().min(0, 'Discount cannot be negative').max(50, 'Discount cannot exceed 50%'),
  description: z.string().max(200).optional(),
  expiryMinutes: z.number().min(1).max(30).default(5),
});

/**
 * POST /api/bills/create
 * Partner creates a new bill and gets QR code token
 */
router.post('/create', authenticate, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.userId!;

  // Find partner profile
  const partner = await Partner.findOne({ userId });
  if (!partner) {
    throw new ApiError(403, 'You are not registered as a partner');
  }

  // Check if partner is active
  if (!partner.isActive()) {
    throw new ApiError(403, 'Your partner account is not active');
  }

  // Validate input
  const validation = createBillSchema.safeParse(req.body);
  if (!validation.success) {
    throw new ApiError(400, validation.error.errors[0].message);
  }

  const { amount, discountRate, description, expiryMinutes } = validation.data;
  const amountInPaise = Math.round(amount * 100);
  const expiresAt = getQRExpiry(expiryMinutes);
  const expTimestamp = getQRExpiryTimestamp(expiryMinutes);

  // Calculate discount amounts for response
  const discountAmount = Math.round(amountInPaise * discountRate / 100);
  const finalAmount = amountInPaise - discountAmount;

  // Generate QR token
  const qrPayload = {
    billId: '', // Will be set after save
    partnerId: partner._id.toString(),
    amount: amountInPaise,
    exp: expTimestamp,
  };

  // Create bill request (without qrToken first to get billId)
  // Store discount rate so it's locked at creation time
  const billRequest = new BillRequest({
    partnerId: partner._id,
    amount: amountInPaise,
    discountRate, // Lock discount rate at bill creation
    description,
    qrToken: 'temp', // Temporary, will update
    expiresAt,
  });

  await billRequest.save();

  // Now generate QR token with actual billId
  qrPayload.billId = billRequest.billId;
  const qrToken = generateQRToken(qrPayload);

  // Update bill request with actual QR token
  billRequest.qrToken = qrToken;
  await billRequest.save();

  res.status(201).json({
    success: true,
    data: {
      billId: billRequest.billId,
      qrToken,
      amounts: {
        original: amount,
        originalInPaise: amountInPaise,
        discountRate,
        discountAmount: discountAmount / 100,
        discountAmountInPaise: discountAmount,
        final: finalAmount / 100,
        finalInPaise: finalAmount,
      },
      expiresAt: expiresAt.toISOString(),
      expiryMinutes,
      partner: {
        businessName: partner.businessName,
        category: partner.category,
      },
    },
  });
}));

/**
 * GET /api/bills/active
 * Get partner's active bills
 */
router.get('/active', authenticate, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.userId!;

  const partner = await Partner.findOne({ userId });
  if (!partner) {
    throw new ApiError(403, 'You are not registered as a partner');
  }

  const activeBills = await BillRequest.find({
    partnerId: partner._id,
    status: 'ACTIVE',
    expiresAt: { $gt: new Date() },
  }).sort({ createdAt: -1 });

  res.json({
    success: true,
    data: {
      bills: activeBills.map((bill) => ({
        billId: bill.billId,
        amount: bill.amount / 100,
        amountInPaise: bill.amount,
        status: bill.status,
        expiresAt: bill.expiresAt,
        createdAt: bill.createdAt,
      })),
    },
  });
}));

/**
 * DELETE /api/bills/:billId
 * Cancel an active bill
 */
router.delete('/:billId', authenticate, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.userId!;
  const { billId } = req.params;

  const partner = await Partner.findOne({ userId });
  if (!partner) {
    throw new ApiError(403, 'You are not registered as a partner');
  }

  const bill = await BillRequest.findOne({ billId, partnerId: partner._id });
  if (!bill) {
    throw new ApiError(404, 'Bill not found');
  }

  if (bill.status !== 'ACTIVE') {
    throw new ApiError(400, 'Bill is not active');
  }

  bill.status = 'CANCELLED';
  await bill.save();

  res.json({
    success: true,
    data: { message: 'Bill cancelled successfully' },
  });
}));

// =====================================================
// USER ROUTES - Validate QR and initiate payment
// =====================================================

/**
 * POST /api/bills/validate
 * User validates a scanned QR code
 */
router.post('/validate', authenticate, asyncHandler(async (req: Request, res: Response) => {
  const { qrToken } = req.body;

  if (!qrToken) {
    throw new ApiError(400, 'QR token is required');
  }

  // Validate QR token signature and expiry
  const payload = validateQRToken(qrToken);
  if (!payload) {
    throw new ApiError(400, 'QR code is invalid or expired');
  }

  // Find bill request
  const billRequest = await BillRequest.findOne({ billId: payload.billId });
  if (!billRequest) {
    throw new ApiError(404, 'Bill not found');
  }

  // Check bill status
  if (billRequest.status === 'USED') {
    throw new ApiError(400, 'This bill has already been paid');
  }

  if (billRequest.status === 'CANCELLED') {
    throw new ApiError(400, 'This bill has been cancelled');
  }

  if (billRequest.status === 'EXPIRED' || new Date() > billRequest.expiresAt) {
    billRequest.status = 'EXPIRED';
    await billRequest.save();
    throw new ApiError(400, 'This bill has expired. Ask merchant to generate a new one.');
  }

  // Get partner details
  const partner = await Partner.findById(billRequest.partnerId);
  if (!partner || !partner.isActive()) {
    throw new ApiError(400, 'This merchant is not active');
  }

  // Calculate discount using STORED rate from bill creation time
  const originalAmount = billRequest.amount; // in paise
  const discountPercent = billRequest.discountRate; // Use stored rate, not partner's current rate
  const discountAmount = Math.round(originalAmount * discountPercent / 100);
  const finalAmount = originalAmount - discountAmount;

  res.json({
    success: true,
    data: {
      billId: billRequest.billId,
      merchant: {
        id: partner._id,
        businessName: partner.businessName,
        category: partner.category,
        isVerified: partner.isVerified,
      },
      amounts: {
        original: originalAmount / 100,
        originalInPaise: originalAmount,
        discountPercent,
        discountAmount: discountAmount / 100,
        discountAmountInPaise: discountAmount,
        final: finalAmount / 100,
        finalInPaise: finalAmount,
      },
      description: billRequest.description,
      expiresAt: billRequest.expiresAt,
    },
  });
}));

/**
 * POST /api/bills/pay
 * User initiates payment for a validated bill
 */
router.post('/pay', authenticate, asyncHandler(async (req: Request, res: Response) => {
  const userId = req.userId!;
  const { billId } = req.body;

  if (!billId) {
    throw new ApiError(400, 'Bill ID is required');
  }

  // Find bill request
  const billRequest = await BillRequest.findOne({ billId });
  if (!billRequest) {
    throw new ApiError(404, 'Bill not found');
  }

  // Validate bill is still active
  if (!billRequest.isValid()) {
    throw new ApiError(400, 'This bill is no longer valid');
  }

  // Get partner
  const partner = await Partner.findById(billRequest.partnerId);
  if (!partner || !partner.isActive()) {
    throw new ApiError(400, 'This merchant is not active');
  }

  // Calculate amounts using STORED discount rate from bill creation time
  const originalAmount = billRequest.amount;
  const discountRate = billRequest.discountRate; // Use stored rate, not partner's current rate
  const discountAmount = Math.round(originalAmount * discountRate / 100);
  const finalAmount = originalAmount - discountAmount;
  const platformFee = Math.round(originalAmount * (env.DISCOUNT_RATE_DEFAULT / 100)); // Platform fee from original amount
  const partnerPayout = originalAmount - platformFee; // Partner gets original minus platform fee

  // Get or create user record
  const user = await User.findById(userId);
  if (!user) {
    throw new ApiError(404, 'User not found');
  }

  // Create Razorpay order for final amount
  const razorpayOrder = await createRazorpayOrder({
    amount: finalAmount,
    currency: 'INR',
    receipt: `bill_${billRequest.billId}`,
    notes: {
      billId: billRequest.billId,
      partnerId: partner._id.toString(),
      userId: user._id.toString(),
      originalAmount: originalAmount.toString(),
      discountAmount: discountAmount.toString(),
    },
  });

  // Create order record
  const order = await Order.create({
    userId: user._id,
    partnerId: partner._id,
    billRequestId: billRequest._id,
    originalAmount,
    discountRate,
    discountAmount,
    platformFee,
    finalAmount,
    partnerPayout,
    razorpayOrderId: razorpayOrder.id,
    status: 'PENDING',
    description: billRequest.description,
  });

  // Update bill request
  billRequest.usedBy = user._id;
  billRequest.orderId = order._id;
  await billRequest.save();

  res.json({
    success: true,
    data: {
      orderId: order.orderId,
      order: {
        id: order._id,
        originalAmount: originalAmount / 100,
        discountRate,
        discountAmount: discountAmount / 100,
        finalAmount: finalAmount / 100,
      },
      razorpay: {
        orderId: razorpayOrder.id,
        amount: finalAmount,
        currency: 'INR',
        key: env.RAZORPAY_KEY_ID,
      },
      merchant: {
        businessName: partner.businessName,
        category: partner.category,
      },
    },
  });
}));

export default router;

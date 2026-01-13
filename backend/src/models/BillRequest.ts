/**
 * File: BillRequest.ts
 * Purpose: Bill/QR request model for payment initiation
 * Context: Created by partner, scanned by user to initiate payment
 */

import mongoose, { Schema, Document } from 'mongoose';

export interface IBillRequest extends Document {
  billId: string;
  partnerId: mongoose.Types.ObjectId;
  amount: number; // in paise
  discountRate: number; // Discount % locked at bill creation time
  description?: string;
  qrToken: string;
  status: 'ACTIVE' | 'EXPIRED' | 'USED' | 'CANCELLED';
  expiresAt: Date;
  usedBy?: mongoose.Types.ObjectId;
  usedAt?: Date;
  orderId?: mongoose.Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
  isValid(): boolean;
}

const billRequestSchema = new Schema<IBillRequest>(
  {
    billId: {
      type: String,
      unique: true,
      index: true,
    },
    partnerId: {
      type: Schema.Types.ObjectId,
      ref: 'Partner',
      required: true,
      index: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 100, // Minimum 1 rupee (100 paise)
    },
    discountRate: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },
    description: {
      type: String,
      maxlength: 200,
    },
    qrToken: {
      type: String,
      required: true,
      unique: true,
    },
    status: {
      type: String,
      enum: ['ACTIVE', 'EXPIRED', 'USED', 'CANCELLED'],
      default: 'ACTIVE',
    },
    expiresAt: {
      type: Date,
      required: true,
      index: true,
    },
    usedBy: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    usedAt: {
      type: Date,
    },
    orderId: {
      type: Schema.Types.ObjectId,
      ref: 'Order',
    },
  },
  {
    timestamps: true,
  }
);

// Generate billId before saving
billRequestSchema.pre('save', async function (next) {
  if (!this.billId) {
    const count = await mongoose.model('BillRequest').countDocuments();
    this.billId = `BR-${String(count + 1).padStart(6, '0')}`;
  }
  next();
});

// Check if bill request is valid
billRequestSchema.methods.isValid = function (): boolean {
  return this.status === 'ACTIVE' && new Date() < this.expiresAt;
};

// TTL index to auto-delete expired bills after 24 hours
billRequestSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 86400 });

// Compound index for partner queries
billRequestSchema.index({ partnerId: 1, createdAt: -1 });

export const BillRequest = mongoose.model<IBillRequest>('BillRequest', billRequestSchema);

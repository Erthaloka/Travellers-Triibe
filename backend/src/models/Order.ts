
/**
 * Order model - represents payment transactions
 */
import mongoose, { Document, Schema } from 'mongoose';

// Order status enum
export enum OrderStatus {
  PENDING = 'PENDING',
  PROCESSING = 'PROCESSING',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
  REFUNDED = 'REFUNDED',
  CANCELLED = 'CANCELLED',
}

// Payment method enum
export enum PaymentMethod {
  UPI = 'UPI',
  CARD = 'CARD',
  NETBANKING = 'NETBANKING',
  WALLET = 'WALLET',
}

// Order interface
export interface IOrder extends Document {
  _id: mongoose.Types.ObjectId;
  orderId: string; // Human-readable order ID (TT-xxxxx)

  // References
  userId: mongoose.Types.ObjectId;
  partnerId: mongoose.Types.ObjectId;
  billRequestId?: mongoose.Types.ObjectId;

  // Amounts (in paise for precision)
  originalAmount: number; // Original bill amount
  discountRate: number; // Discount percentage applied
  discountAmount: number; // Discount amount
  platformFee: number; // Platform fee in paise
  finalAmount: number; // Amount paid by user
  partnerPayout: number; // Amount to be paid to partner
  description?: string; // Bill description

  // Payment details
  paymentMethod?: PaymentMethod;
  razorpayOrderId?: string;
  razorpayPaymentId?: string;
  razorpaySignature?: string;

  // Status
  status: OrderStatus;

  // Metadata
  notes?: string;
  metadata?: Record<string, unknown>;

  // Settlement
  isSettled: boolean;
  settledAt?: Date;
  settlementId?: string;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  completedAt?: Date;

  // Methods
  markCompleted(paymentId: string, signature: string): Promise<void>;
  markFailed(reason?: string): Promise<void>;
}

// Order schema
const orderSchema = new Schema<IOrder>(
  {
    orderId: {
      type: String,
      unique: true,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    partnerId: {
      type: Schema.Types.ObjectId,
      ref: 'Partner',
      required: true,
      index: true,
    },
    billRequestId: {
      type: Schema.Types.ObjectId,
      ref: 'BillRequest',
      index: true,
    },
    originalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    discountRate: {
      type: Number,
      required: true,
      min: 0,
      max: 100,
    },
    discountAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    platformFee: {
      type: Number,
      default: 0,
      min: 0,
    },
    finalAmount: {
      type: Number,
      required: true,
      min: 0,
    },
    partnerPayout: {
      type: Number,
      required: true,
      min: 0,
    },
    description: {
      type: String,
      maxlength: 200,
    },
    paymentMethod: {
      type: String,
      enum: Object.values(PaymentMethod),
    },
    razorpayOrderId: {
      type: String,
      sparse: true,
      index: true,
    },
    razorpayPaymentId: {
      type: String,
      sparse: true,
      index: true,
    },
    razorpaySignature: String,
    status: {
      type: String,
      enum: Object.values(OrderStatus),
      default: OrderStatus.PENDING,
      index: true,
    },
    notes: String,
    metadata: Schema.Types.Mixed,
    isSettled: {
      type: Boolean,
      default: false,
    },
    settledAt: Date,
    settlementId: String,
    completedAt: Date,
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_, ret: Record<string, unknown>) => {
        ret.id = ret._id;
        ret._id = undefined;
        ret.__v = undefined;
        return ret;
      },
    },
  }
);

// Indexes
orderSchema.index({ userId: 1, status: 1, createdAt: -1 });
orderSchema.index({ partnerId: 1, status: 1, createdAt: -1 });
orderSchema.index({ status: 1, isSettled: 1 });
orderSchema.index({ createdAt: -1 });

// Pre-save middleware to generate orderId
orderSchema.pre('save', async function (next) {
  if (this.isNew && !this.orderId) {
    const count = await mongoose.model('Order').countDocuments();
    this.orderId = `TT-${String(count + 1).padStart(6, '0')}`;
  }
  next();
});

// Methods
orderSchema.methods.markCompleted = async function (
  paymentId: string,
  signature: string
): Promise<void> {
  this.razorpayPaymentId = paymentId;
  this.razorpaySignature = signature;
  this.status = OrderStatus.COMPLETED;
  this.completedAt = new Date();
  await this.save();
};

orderSchema.methods.markFailed = async function (reason?: string): Promise<void> {
  this.status = OrderStatus.FAILED;
  if (reason) {
    this.notes = reason;
  }
  await this.save();
};

// Statics
orderSchema.statics.findByOrderId = function (orderId: string) {
  return this.findOne({ orderId });
};

orderSchema.statics.findByRazorpayOrderId = function (razorpayOrderId: string) {
  return this.findOne({ razorpayOrderId });
};

orderSchema.statics.getUserOrders = function (
  userId: mongoose.Types.ObjectId,
  status?: OrderStatus
) {
  const query: Record<string, unknown> = { userId };
  if (status) {
    query.status = status;
  }
  return this.find(query).sort({ createdAt: -1 }).populate('partnerId');
};

orderSchema.statics.getPartnerOrders = function (
  partnerId: mongoose.Types.ObjectId,
  status?: OrderStatus
) {
  const query: Record<string, unknown> = { partnerId };
  if (status) {
    query.status = status;
  }
  return this.find(query).sort({ createdAt: -1 }).populate('userId');
};

export const Order = mongoose.model<IOrder>('Order', orderSchema);
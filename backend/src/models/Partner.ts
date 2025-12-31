/**
 * Partner model - represents business/merchant partners
 */
import mongoose, { Document, Schema } from 'mongoose';

// Partner status enum
export enum PartnerStatus {
  PENDING = 'PENDING',
  ACTIVE = 'ACTIVE',
  SUSPENDED = 'SUSPENDED',
  REJECTED = 'REJECTED',
}

// Business category enum
export enum BusinessCategory {
  RESTAURANT = 'RESTAURANT',
  CAFE = 'CAFE',
  RETAIL = 'RETAIL',
  GROCERY = 'GROCERY',
  SALON = 'SALON',
  GYM = 'GYM',
  HOTEL = 'HOTEL',
  TRAVEL = 'TRAVEL',
  ENTERTAINMENT = 'ENTERTAINMENT',
  OTHER = 'OTHER',
}

// Bank details interface
interface IBankDetails {
  accountNumber: string;
  ifscCode: string;
  accountHolderName: string;
  bankName: string;
}

// Partner interface
export interface IPartner extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId; // Reference to User

  // Business details
  businessName: string;
  category: BusinessCategory;
  description?: string;
  gstNumber?: string;
  panNumber?: string;

  // Contact
  businessPhone: string;
  businessEmail: string;

  // Address
  address: {
    line1: string;
    line2?: string;
    city: string;
    state: string;
    pincode: string;
    coordinates?: {
      lat: number;
      lng: number;
    };
  };

  // Payment settings
  discountRate: number; // Percentage discount offered
  bankDetails?: IBankDetails;
  upiId?: string;
  razorpayAccountId?: string;

  // Status
  status: PartnerStatus;

  // Analytics
  analytics: {
    totalOrders: number;
    totalRevenue: number;
    totalDiscountGiven: number;
    averageOrderValue: number;
  };

  // QR Code
  qrCodeData?: string;

  // Verification
  isVerified: boolean;
  verifiedAt?: Date;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;

  // Methods
  isActive(): boolean;
  updateAnalytics(orderAmount: number, discountAmount: number): Promise<void>;
}

// Partner schema
const partnerSchema = new Schema<IPartner>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true,
    },
    businessName: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    category: {
      type: String,
      enum: Object.values(BusinessCategory),
      required: true,
    },
    description: String,
    gstNumber: {
      type: String,
      uppercase: true,
      sparse: true,
    },
    panNumber: {
      type: String,
      uppercase: true,
      sparse: true,
    },
    businessPhone: {
      type: String,
      required: true,
    },
    businessEmail: {
      type: String,
      required: true,
      lowercase: true,
    },
    address: {
      line1: { type: String, required: true },
      line2: String,
      city: { type: String, required: true },
      state: { type: String, required: true },
      pincode: { type: String, required: true },
      coordinates: {
        lat: Number,
        lng: Number,
      },
    },
    discountRate: {
      type: Number,
      required: true,
      min: 1,
      max: 20,
      default: 5,
    },
    bankDetails: {
      accountNumber: String,
      ifscCode: String,
      accountHolderName: String,
      bankName: String,
    },
    upiId: String,
    razorpayAccountId: String,
    status: {
      type: String,
      enum: Object.values(PartnerStatus),
      default: PartnerStatus.PENDING,
    },
    analytics: {
      totalOrders: { type: Number, default: 0 },
      totalRevenue: { type: Number, default: 0 },
      totalDiscountGiven: { type: Number, default: 0 },
      averageOrderValue: { type: Number, default: 0 },
    },
    qrCodeData: String,
    isVerified: {
      type: Boolean,
      default: false,
    },
    verifiedAt: Date,
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
partnerSchema.index({ status: 1 });
partnerSchema.index({ category: 1, status: 1 });
partnerSchema.index({ 'address.city': 1, status: 1 });

// Methods
partnerSchema.methods.isActive = function (): boolean {
  return this.status === PartnerStatus.ACTIVE;
};

partnerSchema.methods.updateAnalytics = async function (
  orderAmount: number,
  discountAmount: number
): Promise<void> {
  this.analytics.totalOrders += 1;
  this.analytics.totalRevenue += orderAmount;
  this.analytics.totalDiscountGiven += discountAmount;
  this.analytics.averageOrderValue =
    this.analytics.totalRevenue / this.analytics.totalOrders;
  await this.save();
};

export const Partner = mongoose.model<IPartner>('Partner', partnerSchema);

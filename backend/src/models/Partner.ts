/**
 * Partner model - represents business/merchant partners with GST/Non-GST support
 * UPDATED: Added GST verification, revenue tracking, and compliance features
 */
import mongoose, { Document, Schema } from 'mongoose';

// Partner status enum
export enum PartnerStatus {
  PENDING = 'PENDING',
  UNDER_REVIEW = 'UNDER_REVIEW',
  VERIFIED = 'VERIFIED',
  ACTIVE = 'ACTIVE',
  SUSPENDED = 'SUSPENDED',
  REJECTED = 'REJECTED',
  BLOCKED = 'BLOCKED',
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

// Verification Status Enum
export enum VerificationStatus {
  PENDING = 'PENDING',
  VERIFIED = 'VERIFIED',
  FAILED = 'FAILED',
  EXPIRED = 'EXPIRED',
}

// Settlement Mode Enum
export enum SettlementMode {
  PLATFORM = 'PLATFORM',
  DIRECT = 'DIRECT',
}

// Document Type Enum
export enum DocumentType {
  GST_CERTIFICATE = 'GST_CERTIFICATE',
  PAN_CARD = 'PAN_CARD',
  FSSAI_LICENSE = 'FSSAI_LICENSE',
  TRADE_LICENSE = 'TRADE_LICENSE',
  UDYAM_CERTIFICATE = 'UDYAM_CERTIFICATE',
  CIN_CERTIFICATE = 'CIN_CERTIFICATE',
  LLPIN_CERTIFICATE = 'LLPIN_CERTIFICATE',
}

// Bank details interface
interface IBankDetails {
  accountNumber: string;
  ifscCode: string;
  accountHolderName: string;
  bankName: string;
}

// Document Interface
interface IDocument {
  type: DocumentType;
  url: string;
  uploadedAt: Date;
  verifiedAt?: Date;
  status: VerificationStatus;
  rejectionReason?: string;
}

// Verification Details Interface
interface IVerificationDetails {
  gstin?: {
    number: string;
    status: VerificationStatus;
    verifiedAt?: Date;
    legalName?: string;
    tradeName?: string;
    registrationDate?: Date;
    lastUpdated?: Date;
  };
  pan: {
    number: string;
    status: VerificationStatus;
    verifiedAt?: Date;
    name?: string;
  };
  crossVerified?: {
    status: boolean;
    verifiedAt?: Date;
  };
}

// Revenue Tracking Interface
interface IRevenueTracking {
  financialYear: string;
  totalRevenue: number;
  gstApplicable: boolean;
  thresholdWarnings: {
    warning16L: boolean;
    warning19L: boolean;
    threshold20L: boolean;
  };
  lastCalculatedAt: Date;
}

// Payout Control Interface
interface IPayoutControl {
  enabled: boolean;
  blockedAt?: Date;
  blockReason?: string;
  requiresGstForUnblock: boolean;
}

// Partner interface
export interface IPartner extends Document {
  _id: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;

  // Business details
  businessName: string;
  legalBusinessName: string;
  category: BusinessCategory;
  description?: string;
  
  // GST Registration
  isGstRegistered: boolean;
  gstNumber?: string; // Deprecated - use verificationDetails.gstin.number
  panNumber?: string; // Deprecated - use verificationDetails.pan.number
  
  // Verification
  verificationDetails: IVerificationDetails;

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

  // Documents
  documents: IDocument[];

  // Payment settings
  discountRate: number;
  settlementMode: SettlementMode;
  bankDetails?: IBankDetails;
  upiId?: string;
  razorpayAccountId?: string;

  // Revenue Tracking
  revenueTracking: IRevenueTracking[];

  // Payout Control
  payoutControl: IPayoutControl;

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

  // Metadata
  onboardedAt: Date;
  activatedAt?: Date;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;

  // Methods
  isActive(): boolean;
  updateAnalytics(orderAmount: number, discountAmount: number): Promise<void>;
  getCurrentFinancialYear(): string;
  getCurrentYearRevenue(): number;
  shouldBlockPayout(): boolean;
  canAcceptOrders(): boolean;
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
    legalBusinessName: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
      type: String,
      enum: Object.values(BusinessCategory),
      required: true,
    },
    description: String,
    isGstRegistered: {
      type: Boolean,
      required: true,
      default: false,
    },
    // Deprecated fields (kept for backward compatibility)
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
    verificationDetails: {
      gstin: {
        number: {
          type: String,
          uppercase: true,
          trim: true,
          sparse: true,
        },
        status: {
          type: String,
          enum: Object.values(VerificationStatus),
          default: VerificationStatus.PENDING,
        },
        verifiedAt: Date,
        legalName: String,
        tradeName: String,
        registrationDate: Date,
        lastUpdated: Date,
      },
      pan: {
        number: {
          type: String,
          required: true,
          uppercase: true,
          trim: true,
          index: true,
        },
        status: {
          type: String,
          enum: Object.values(VerificationStatus),
          default: VerificationStatus.PENDING,
        },
        verifiedAt: Date,
        name: String,
      },
      crossVerified: {
        status: {
          type: Boolean,
          default: false,
        },
        verifiedAt: Date,
      },
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
    documents: [
      {
        type: {
          type: String,
          enum: Object.values(DocumentType),
          required: true,
        },
        url: { type: String, required: true },
        uploadedAt: { type: Date, default: Date.now },
        verifiedAt: Date,
        status: {
          type: String,
          enum: Object.values(VerificationStatus),
          default: VerificationStatus.PENDING,
        },
        rejectionReason: String,
      },
    ],
    discountRate: {
      type: Number,
      required: true,
      min: 1,
      max: 20,
      default: 5,
    },
    settlementMode: {
      type: String,
      enum: Object.values(SettlementMode),
      default: SettlementMode.PLATFORM,
    },
    bankDetails: {
      accountNumber: String,
      ifscCode: String,
      accountHolderName: String,
      bankName: String,
    },
    upiId: String,
    razorpayAccountId: String,
    revenueTracking: [
      {
        financialYear: { type: String, required: true },
        totalRevenue: { type: Number, default: 0 },
        gstApplicable: { type: Boolean, default: false },
        thresholdWarnings: {
          warning16L: { type: Boolean, default: false },
          warning19L: { type: Boolean, default: false },
          threshold20L: { type: Boolean, default: false },
        },
        lastCalculatedAt: { type: Date, default: Date.now },
      },
    ],
    payoutControl: {
      enabled: { type: Boolean, default: true },
      blockedAt: Date,
      blockReason: String,
      requiresGstForUnblock: { type: Boolean, default: false },
    },
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
    onboardedAt: {
      type: Date,
      default: Date.now,
    },
    activatedAt: Date,
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_, ret: Record<string, unknown>) => {
        ret.id = ret._id;
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

// Indexes
partnerSchema.index({ status: 1 });
partnerSchema.index({ category: 1, status: 1 });
partnerSchema.index({ 'address.city': 1, status: 1 });
partnerSchema.index({ 'verificationDetails.gstin.number': 1 }, { sparse: true });
partnerSchema.index({ 'verificationDetails.pan.number': 1 });
partnerSchema.index({ status: 1, isGstRegistered: 1 });

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

partnerSchema.methods.getCurrentFinancialYear = function (): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;
  
  if (month >= 4) {
    return `FY${year}-${(year + 1).toString().slice(2)}`;
  } else {
    return `FY${year - 1}-${year.toString().slice(2)}`;
  }
};

partnerSchema.methods.getCurrentYearRevenue = function (): number {
  const currentFY = this.getCurrentFinancialYear();
  const tracking = this.revenueTracking.find(
    (r: IRevenueTracking) => r.financialYear === currentFY
  );
  return tracking?.totalRevenue || 0;
};

partnerSchema.methods.shouldBlockPayout = function (): boolean {
  const revenue = this.getCurrentYearRevenue();
  const threshold = parseInt(process.env.GST_THRESHOLD || '2000000000');
  
  return !this.isGstRegistered && revenue >= threshold;
};

partnerSchema.methods.canAcceptOrders = function (): boolean {
  return (
    this.status === PartnerStatus.ACTIVE &&
    this.payoutControl.enabled
  );
};

export const Partner = mongoose.model<IPartner>('Partner', partnerSchema);
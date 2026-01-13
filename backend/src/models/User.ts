/**
 * User model - represents app users (customers)
 */
import mongoose, { Document, Schema } from 'mongoose';

// User roles enum
export enum UserRole {
  USER = 'USER',
  PARTNER = 'PARTNER',
  ADMIN = 'ADMIN',
}

// Account status enum
export enum AccountStatus {
  ACTIVE = 'ACTIVE',
  INACTIVE = 'INACTIVE',
  SUSPENDED = 'SUSPENDED',
  PENDING_VERIFICATION = 'PENDING_VERIFICATION',
}

// User interface
export interface IUser extends Document {
  _id: mongoose.Types.ObjectId;
  email: string;
  phone: string;
  name: string;
  passwordHash?: string;
  roles: UserRole[];
  status: AccountStatus;

  // Profile
  avatar?: string;

  // Stats
  totalSavings: number;
  totalOrders: number;

  // Supabase integration
  supabaseId?: string;
  googleId?: string;

  // Timestamps
  createdAt: Date;
  updatedAt: Date;
  lastLoginAt?: Date;

  // Methods
  hasRole(role: UserRole): boolean;
  isActive(): boolean;
}

// User schema
const userSchema = new Schema<IUser>(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    passwordHash: {
      type: String,
      select: false, // Don't return password by default
    },
    roles: {
      type: [String],
      enum: Object.values(UserRole),
      default: [UserRole.USER],
    },
    status: {
      type: String,
      enum: Object.values(AccountStatus),
      default: AccountStatus.ACTIVE,
    },
    avatar: String,
    totalSavings: {
      type: Number,
      default: 0,
    },
    totalOrders: {
      type: Number,
      default: 0,
    },
    supabaseId: {
      type: String,
      sparse: true,
      index: true,
    },
    googleId: {
      type: String,
      sparse: true,
    },
    lastLoginAt: Date,
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_, ret: Record<string, unknown>) => {
        ret.id = ret._id;
        ret._id = undefined;
        ret.__v = undefined;
        ret.passwordHash = undefined;
        return ret;
      },
    },
  }
);

// Indexes
userSchema.index({ email: 1, status: 1 });
userSchema.index({ phone: 1, status: 1 });

// Methods
userSchema.methods.hasRole = function (role: UserRole): boolean {
  return this.roles.includes(role);
};

userSchema.methods.isActive = function (): boolean {
  return this.status === AccountStatus.ACTIVE;
};

// Statics
userSchema.statics.findByEmail = function (email: string) {
  return this.findOne({ email: email.toLowerCase() });
};

userSchema.statics.findByPhone = function (phone: string) {
  return this.findOne({ phone });
};

export const User = mongoose.model<IUser>('User', userSchema);

/**
 * Authentication middleware
 */
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { User, IUser, UserRole, Partner } from '../models/index.js';
import { ApiError } from './errorHandler.js';

// Extend Express Request type
declare global {
  namespace Express {
    interface Request {
      user?: IUser;
      userId?: string;
    }
  }
}

// JWT payload interface
interface JwtPayload {
  userId: string;
  email: string;
  roles: UserRole[];
  iat: number;
  exp: number;
}

/**
 * Generate JWT token
 */
export const generateToken = (user: IUser): string => {
  const payload: Omit<JwtPayload, 'iat' | 'exp'> = {
    userId: user._id.toString(),
    email: user.email,
    roles: user.roles,
  };

  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRES_IN as string,
  } as jwt.SignOptions);
};

/**
 * Verify JWT token
 */
export const verifyToken = (token: string): JwtPayload => {
  return jwt.verify(token, env.JWT_SECRET) as JwtPayload;
};

/**
 * Authentication middleware - requires valid JWT
 */
export const authenticate = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new ApiError(401, 'No token provided');
    }

    const token = authHeader.split(' ')[1];

    // Verify token
    const decoded = verifyToken(token);

    // Get user from database
    const user = await User.findById(decoded.userId);

    if (!user) {
      throw new ApiError(401, 'User not found');
    }

    if (!user.isActive()) {
      throw new ApiError(403, 'Account is not active');
    }

    // Attach user to request
    req.user = user;
    req.userId = user._id.toString();

    next();
  } catch (error) {
    if (error instanceof jwt.JsonWebTokenError) {
      next(new ApiError(401, 'Invalid token'));
    } else if (error instanceof jwt.TokenExpiredError) {
      next(new ApiError(401, 'Token expired'));
    } else {
      next(error);
    }
  }
};

/**
 * Optional authentication - attaches user if token exists but doesn't require it
 */
export const optionalAuth = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const decoded = verifyToken(token);
      const user = await User.findById(decoded.userId);

      if (user?.isActive()) {
        req.user = user;
        req.userId = user._id.toString();
      }
    }

    next();
  } catch {
    // Ignore errors for optional auth
    next();
  }
};

/**
 * Role-based authorization middleware
 */
export const authorize = (...allowedRoles: UserRole[]) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(new ApiError(401, 'Authentication required'));
    }

    const hasRole = allowedRoles.some((role) => req.user!.roles.includes(role));

    if (!hasRole) {
      return next(new ApiError(403, 'Insufficient permissions'));
    }

    next();
  };
};

/**
 * Require specific role
 */
export const requireRole = (role: UserRole) => authorize(role);

/**
 * Require admin role
 */
export const requireAdmin = authorize(UserRole.ADMIN);

/**
 * Require partner role AND partner profile to exist
 * ⚠️ This checks BOTH:
 * 1. User has PARTNER role
 * 2. Partner profile document exists in database
 */
export const requirePartner = async (
  req: Request,
  _res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    if (!req.user) {
      return next(new ApiError(401, 'Authentication required'));
    }

    // Check if user has PARTNER or ADMIN role
    const hasPartnerRole = req.user.roles.includes(UserRole.PARTNER) || 
                          req.user.roles.includes(UserRole.ADMIN);

    if (!hasPartnerRole) {
      return next(new ApiError(403, 'Partner role required'));
    }

    // ✅ CRITICAL: Check if partner profile exists
    const partnerProfile = await Partner.findOne({ userId: req.user._id });

    if (!partnerProfile) {
      return next(
        new ApiError(
          403, 
          'Partner profile not found. Please complete onboarding first.'
        )
      );
    }

    // Check if partner is active
    if (!partnerProfile.isActive()) {
      return next(
        new ApiError(
          403, 
          'Partner account is not active. Please contact support.'
        )
      );
    }

    next();
  } catch (error) {
    next(error);
  }
};
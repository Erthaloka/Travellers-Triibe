/**
 * Authentication routes - Firebase Auth integration
 */
import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { z } from 'zod';
import { asyncHandler, ApiError } from '../middleware/errorHandler.js';
import { validateBody } from '../middleware/validate.js';
import { authenticate, generateToken } from '../middleware/auth.js';
import { User, UserRole, AccountStatus } from '../models/index.js';
import { verifyFirebaseToken } from '../config/firebase.js';

const router = Router();

// ============== Validation Schemas ==============

const signupSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  phone: z.string().regex(/^\+91[6-9]\d{9}$/, 'Invalid Indian phone number'),
  role: z.string().transform(val => val.toLowerCase()).pipe(z.enum(['user', 'partner'])).default('user'),
});

const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(1, 'Password is required'),
});

const firebaseAuthSchema = z.object({
  idToken: z.string().min(1, 'Firebase ID token is required'),
  email: z.string().email().optional(), // For Google access token fallback
  name: z.string().optional(), // For Google access token fallback
  role: z.string().transform(val => val.toLowerCase()).pipe(z.enum(['user', 'partner'])).optional(),
});

// ============== Routes ==============

/**
 * POST /api/auth/signup
 * Create new account with email/password
 */
router.post(
  '/signup',
  validateBody(signupSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { name, email, password, phone, role } = req.body;

    // Check if email or phone already exists
    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { phone }],
    });

    if (existingUser) {
      if (existingUser.email === email.toLowerCase()) {
        throw new ApiError(409, 'Email already registered');
      }
      throw new ApiError(409, 'Phone number already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);

    // Determine roles
    const roles = role === 'partner'
      ? [UserRole.PARTNER, UserRole.USER]
      : [UserRole.USER];

    // Create user
    const user = await User.create({
      name,
      email: email.toLowerCase(),
      phone,
      passwordHash,
      roles,
      status: AccountStatus.ACTIVE,
    });

    // Generate token
    const token = generateToken(user);

    res.status(201).json({
      success: true,
      data: {
        token,
        account: user,
      },
    });
  })
);

/**
 * POST /api/auth/login
 * Login with email and password
 */
router.post(
  '/login',
  validateBody(loginSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { email, password } = req.body;

    // Find user with password
    const user = await User.findOne({ email: email.toLowerCase() }).select(
      '+passwordHash'
    );

    if (!user) {
      throw new ApiError(401, 'Invalid email or password');
    }

    if (!user.passwordHash) {
      throw new ApiError(401, 'Please login with Google');
    }

    // Verify password
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      throw new ApiError(401, 'Invalid email or password');
    }

    if (!user.isActive()) {
      throw new ApiError(403, 'Account is not active');
    }

    // Update last login
    user.lastLoginAt = new Date();
    await user.save();

    // Generate token
    const token = generateToken(user);

    res.json({
      success: true,
      data: {
        token,
        account: user,
      },
    });
  })
);

/**
 * Verify Google access token using Google's tokeninfo endpoint
 */
async function verifyGoogleAccessToken(accessToken: string): Promise<{ email: string; name?: string; picture?: string } | null> {
  try {
    const response = await fetch(`https://www.googleapis.com/oauth2/v3/userinfo`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) return null;
    const data = await response.json();
    return {
      email: data.email,
      name: data.name,
      picture: data.picture,
    };
  } catch {
    return null;
  }
}

/**
 * POST /api/auth/firebase
 * Login/Signup with Firebase (Google, Apple, etc.) or Google access token
 */
router.post(
  '/firebase',
  validateBody(firebaseAuthSchema),
  asyncHandler(async (req: Request, res: Response) => {
    const { idToken, email: providedEmail, name: providedName, role } = req.body;

    let email: string | undefined;
    let name: string | undefined;
    let picture: string | undefined;
    let uid: string | undefined;

    // Try Firebase ID token first
    try {
      const decodedToken = await verifyFirebaseToken(idToken);
      uid = decodedToken.uid;
      email = decodedToken.email;
      name = decodedToken.name;
      picture = decodedToken.picture;
    } catch {
      // Firebase verification failed, try as Google access token
      const googleUser = await verifyGoogleAccessToken(idToken);
      if (googleUser) {
        email = googleUser.email;
        name = googleUser.name;
        picture = googleUser.picture;
        uid = `google_${email}`; // Generate a pseudo-UID for Google-only auth
      } else if (providedEmail) {
        // Fallback to provided email/name (for web where we can't verify)
        email = providedEmail;
        name = providedName;
        uid = `web_${email}`;
      } else {
        throw new ApiError(401, 'Invalid authentication token');
      }
    }

    if (!email) {
      throw new ApiError(400, 'Email is required from authentication');
    }

    // Check if user exists
    let user = await User.findOne({ email: email.toLowerCase() });
    let isNewUser = false;

    if (!user) {
      // Create new user
      isNewUser = true;
      const roles = role === 'partner'
        ? [UserRole.PARTNER, UserRole.USER]
        : [UserRole.USER];

      user = await User.create({
        email: email.toLowerCase(),
        phone: `+91${Math.floor(9000000000 + Math.random() * 999999999)}`, // Temp phone
        name: name || email.split('@')[0],
        supabaseId: uid,
        roles,
        status: AccountStatus.ACTIVE,
        avatar: picture,
      });
    }

    // Update last login
    user.lastLoginAt = new Date();
    await user.save();

    // Generate our JWT token
    const token = generateToken(user);

    res.json({
      success: true,
      data: {
        token,
        account: user,
        isNewUser,
      },
    });
  })
);

/**
 * POST /api/auth/google
 * Alias for Firebase auth (backwards compatibility)
 */
router.post(
  '/google',
  validateBody(firebaseAuthSchema),
  asyncHandler(async (req: Request, res: Response) => {
    // Forward to Firebase auth handler
    const { idToken, role } = req.body;

    const decodedToken = await verifyFirebaseToken(idToken);
    const { uid, email, name, picture } = decodedToken;

    if (!email) {
      throw new ApiError(400, 'Email is required');
    }

    let user = await User.findOne({ email: email.toLowerCase() });
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      const roles = role === 'partner'
        ? [UserRole.PARTNER, UserRole.USER]
        : [UserRole.USER];

      user = await User.create({
        email: email.toLowerCase(),
        phone: `+91${Math.floor(9000000000 + Math.random() * 999999999)}`,
        name: name || 'User',
        googleId: uid,
        roles,
        status: AccountStatus.ACTIVE,
        avatar: picture,
      });
    }

    user.lastLoginAt = new Date();
    await user.save();

    const token = generateToken(user);

    res.json({
      success: true,
      data: {
        token,
        account: user,
        isNewUser,
      },
    });
  })
);

/**
 * GET /api/auth/me
 * Get current authenticated user
 */
router.get(
  '/me',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    res.json({
      success: true,
      data: req.user,
    });
  })
);

/**
 * PUT /api/auth/update-phone
 * Update phone number (required after social login)
 */
router.put(
  '/update-phone',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { phone } = req.body;

    if (!phone || !/^\+91[6-9]\d{9}$/.test(phone)) {
      throw new ApiError(400, 'Valid Indian phone number required');
    }

    // Check if phone is already in use
    const existing = await User.findOne({
      phone,
      _id: { $ne: req.user!._id },
    });

    if (existing) {
      throw new ApiError(409, 'Phone number already in use');
    }

    req.user!.phone = phone;
    await req.user!.save();

    res.json({
      success: true,
      data: req.user,
    });
  })
);

/**
 * POST /api/auth/logout
 * Logout (client-side token removal)
 */
router.post(
  '/logout',
  authenticate,
  asyncHandler(async (_req: Request, res: Response) => {
    res.json({
      success: true,
      message: 'Logged out successfully',
    });
  })
);

export default router;

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
    console.log('Verifying as Google Access Token...');
    const response = await fetch(`https://www.googleapis.com/oauth2/v3/userinfo`, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
    if (!response.ok) {
      console.log('Google Access Token verification failed:', response.status, await response.text());
      return null;
    }
    const data = await response.json() as any;
    return {
      email: data.email,
      name: data.name,
      picture: data.picture,
    };
  } catch (error) {
    console.log('Google Access Token flow error:', error);
    return null;
  }
}

/**
 * Verify Google ID Token using tokeninfo endpoint
 */
async function verifyGoogleIdToken(idToken: string): Promise<{ email: string; name?: string; picture?: string; sub: string } | null> {
  try {
    console.log('Verifying as Google ID Token...');
    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    if (!response.ok) {
      console.log('Google ID Token verification failed:', response.status, await response.text());
      return null;
    }
    const data = await response.json() as any;
    return {
      email: data.email,
      name: data.name,
      picture: data.picture,
      sub: data.sub
    };
  } catch (error) {
    console.log('Google ID Token flow error:', error);
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

    console.log('Received auth request. Token length:', idToken?.length);
    console.log('Provided email/name:', providedEmail, providedName);

    let email: string | undefined;
    let name: string | undefined;
    let picture: string | undefined;
    let uid: string | undefined;

    // Try Firebase ID token first
    try {
      const decodedToken = await verifyFirebaseToken(idToken);
      console.log('Firebase verification successful');
      uid = decodedToken.uid;
      email = decodedToken.email;
      name = decodedToken.name;
      picture = decodedToken.picture;
    } catch (firebaseError) {
      console.log('Firebase v/erification failed:', firebaseError);

      // Try as Google ID Token (standard Google Sign In)
      const googleIdUser = await verifyGoogleIdToken(idToken);
      if (googleIdUser) {
        console.log('Google ID Token verification successful');
        email = googleIdUser.email;
        name = googleIdUser.name;
        picture = googleIdUser.picture;
        uid = `google_${googleIdUser.sub}`;
      } else {
        // Fallback: Try as Google Access Token
        const googleUser = await verifyGoogleAccessToken(idToken);
        if (googleUser) {
          console.log('Google Access Token verification successful');
          email = googleUser.email;
          name = googleUser.name;
          picture = googleUser.picture;
          uid = `google_${email}`; // Generate a pseudo-UID for Google-only auth
        } else {
          console.log('All verification methods failed');
          throw new ApiError(401, 'Invalid authentication token');
        }
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
        name: name || email.split('@')[0],
        supabaseId: uid,
        roles,
        status: AccountStatus.ACTIVE,
        avatar: picture,
      });
    }

    // If user exists, try to update avatar from Google if missing
    if (!isNewUser && picture && !user.avatar) {
      user.avatar = picture;
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
 * PUT /api/auth/update-profile
 * Update profile details (Name & Phone) - User completes profile
 */
router.put(
  '/update-profile',
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const { name, phone, avatar } = req.body;

    // Validate inputs
    if (!name || name.trim().length < 2) {
      throw new ApiError(400, 'Name must be at least 2 characters');
    }

    if (!phone || !/^\+91[6-9]\d{9}$/.test(phone)) {
      throw new ApiError(400, 'Valid Indian phone number required');
    }

    // Check if phone is already in use by ANOTHER user
    const existing = await User.findOne({
      phone,
      _id: { $ne: req.user!._id },
    });

    if (existing) {
      throw new ApiError(409, 'Phone number already in use');
    }

    // Update user
    req.user!.name = name.trim();
    req.user!.phone = phone;
    if (avatar) req.user!.avatar = avatar; // Update avatar if provided
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

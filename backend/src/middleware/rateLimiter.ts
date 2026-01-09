/**
 * Rate Limiter Middleware
 */
import rateLimit from 'express-rate-limit';
import { env } from '../config/env.js';

// Global API limiter
// 100 requests per 15 minutes
export const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 100,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: {
        success: false,
        error: {
            code: 429,
            message: 'Too many requests, please try again later.',
        },
    },
    skip: () => env.NODE_ENV === 'test' || env.NODE_ENV === 'development',
});

// Stricter limiter for Auth routes (Login/Signup)
// 10 requests per 15 minutes to prevent brute force
export const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 10,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    message: {
        success: false,
        error: {
            code: 429,
            message: 'Too many login attempts, please try again in 15 minutes.',
        },
    },
    skip: () => env.NODE_ENV === 'test' || env.NODE_ENV === 'development',
});

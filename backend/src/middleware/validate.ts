/**
 * Validation middleware using Zod-validate.ts
 */
import { Request, Response, NextFunction } from 'express';
import { z, ZodSchema } from 'zod';

/**
 * Validate request body against a Zod schema
 */
export const validateBody = <T extends ZodSchema>(schema: T) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      next(result.error);
      return;
    }

    req.body = result.data;
    next();
  };
};

/**
 * Validate request query against a Zod schema
 */
export const validateQuery = <T extends ZodSchema>(schema: T) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.query);

    if (!result.success) {
      next(result.error);
      return;
    }

    req.query = result.data;
    next();
  };
};

/**
 * Validate request params against a Zod schema
 */
export const validateParams = <T extends ZodSchema>(schema: T) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.params);

    if (!result.success) {
      next(result.error);
      return;
    }

    req.params = result.data;
    next();
  };
};

// ============== Common Validation Schemas ==============

/**
 * Email validation
 */
export const emailSchema = z.string().email('Invalid email address');

/**
 * Phone validation (Indian)
 */
export const phoneSchema = z
  .string()
  .regex(/^\+91[6-9]\d{9}$/, 'Invalid Indian phone number');

/**
 * Password validation
 */
export const passwordSchema = z
  .string()
  .min(6, 'Password must be at least 6 characters');

/**
 * OTP validation
 */
export const otpSchema = z
  .string()
  .length(6, 'OTP must be 6 digits')
  .regex(/^\d+$/, 'OTP must contain only digits');

/**
 * MongoDB ObjectId validation
 */
export const objectIdSchema = z
  .string()
  .regex(/^[a-fA-F0-9]{24}$/, 'Invalid ID format');

/**
 * Pagination schema
 */
export const paginationSchema = z.object({
  page: z
    .string()
    .optional()
    .default('1')
    .transform(Number)
    .pipe(z.number().min(1)),
  limit: z
    .string()
    .optional()
    .default('10')
    .transform(Number)
    .pipe(z.number().min(1).max(100)),
});

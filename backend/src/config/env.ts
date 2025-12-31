/**
 * Environment configuration with validation
 */
import dotenv from 'dotenv';
import { z } from 'zod';

// Load .env file
dotenv.config();

// Environment schema
const envSchema = z.object({
  // Server
  PORT: z.string().default('3000').transform(Number),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // MongoDB Atlas
  MONGODB_URI: z.string().min(1, 'MongoDB URI is required'),

  // Firebase Auth
  FIREBASE_SERVICE_ACCOUNT_PATH: z.string().default('./travellers-triibe-firebase-adminsdk-fbsvc-c5f6474fd0.json'),

  // Supabase (for storage/realtime) - truly optional
  SUPABASE_URL: z.string().url().optional().or(z.literal('')),
  SUPABASE_ANON_KEY: z.string().optional().or(z.literal('')),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional().or(z.literal('')),

  // JWT (for our own tokens, in addition to Firebase)
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('7d'),

  // Razorpay
  RAZORPAY_KEY_ID: z.string().min(1, 'Razorpay Key ID is required'),
  RAZORPAY_KEY_SECRET: z.string().min(1, 'Razorpay Secret is required'),
  RAZORPAY_WEBHOOK_SECRET: z.string().optional(),

  // App Settings
  DISCOUNT_RATE_DEFAULT: z.string().default('5').transform(Number),
  MAX_DISCOUNT_RATE: z.string().default('15').transform(Number),
});

// Parse and validate environment
const parseEnv = () => {
  const parsed = envSchema.safeParse(process.env);

  if (!parsed.success) {
    console.error('❌ Invalid environment variables:');
    console.error(parsed.error.flatten().fieldErrors);
    process.exit(1);
  }

  return parsed.data;
};

export const env = parseEnv();

export type Env = z.infer<typeof envSchema>;

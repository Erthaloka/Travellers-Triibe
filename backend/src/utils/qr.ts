
/**
 * File: qr.ts
 * Purpose: QR code token generation and validation utilities
 * Context: Creates secure, expiring QR tokens for bill payments
 */

import crypto from 'crypto';
import { env } from '../config/env';

interface QRPayload {
  billId: string;
  partnerId: string;
  amount: number;
  exp: number; // Unix timestamp
}

/**
 * Generate a secure QR token from bill data
 * Format: Base64 encoded JSON with signature
 */
export function generateQRToken(payload: QRPayload): string {
  const data = JSON.stringify(payload);

  // Create signature for integrity
  const signature = crypto
    .createHmac('sha256', env.JWT_SECRET)
    .update(data)
    .digest('hex')
    .substring(0, 16);

  // Combine data and signature
  const tokenData = {
    ...payload,
    sig: signature,
  };

  // Base64 encode for QR safety (ASCII only)
  return Buffer.from(JSON.stringify(tokenData)).toString('base64');
}

/**
 * Validate and decode a QR token
 * Returns payload if valid, null if invalid/expired
 */
export function validateQRToken(token: string): QRPayload | null {
  try {
    // Decode from Base64
    const decoded = Buffer.from(token, 'base64').toString('utf-8');
    const tokenData = JSON.parse(decoded);

    const { sig, ...payload } = tokenData;

    // Verify signature
    const expectedSig = crypto
      .createHmac('sha256', env.JWT_SECRET)
      .update(JSON.stringify(payload))
      .digest('hex')
      .substring(0, 16);

    if (sig !== expectedSig) {
      return null;
    }

    // Check expiry
    if (payload.exp < Math.floor(Date.now() / 1000)) {
      return null;
    }

    return payload as QRPayload;
  } catch {
    return null;
  }
}

/**
 * Generate QR expiry timestamp (default 5 minutes)
 */
export function getQRExpiry(minutes: number = 5): Date {
  return new Date(Date.now() + minutes * 60 * 1000);
}

/**
 * Get Unix timestamp for expiry
 */
export function getQRExpiryTimestamp(minutes: number = 5): number {
  return Math.floor(Date.now() / 1000) + minutes * 60;
}
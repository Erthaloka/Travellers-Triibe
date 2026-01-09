/**
 * Firebase Admin SDK configuration
 */
import admin from 'firebase-admin';
import { env } from './env.js';
import path from 'path';
import fs from 'fs';

// Initialize Firebase Admin
const initializeFirebase = (): admin.app.App => {
  if (admin.apps.length > 0) {
    return admin.apps[0]!;
  }

  // Use service account JSON file - resolve from project root
  const serviceAccountPath = path.resolve(
    process.cwd(),
    env.FIREBASE_SERVICE_ACCOUNT_PATH
  );

  // Ensure file exists and provide a clear error if not
  if (!fs.existsSync(serviceAccountPath)) {
    console.error(`Firebase service account file not found at: ${serviceAccountPath}`);
    console.error('Download a service account JSON from Firebase Console and set FIREBASE_SERVICE_ACCOUNT_PATH in your .env');
    process.exit(1);
  }

  return admin.initializeApp({
    credential: admin.credential.cert(serviceAccountPath),
  });
};

// Initialize on import
const firebaseApp = initializeFirebase();

// Export Firebase Auth
export const firebaseAuth: admin.auth.Auth = admin.auth();

/**
 * Verify Firebase ID token
 */
export const verifyFirebaseToken = async (
  idToken: string
): Promise<admin.auth.DecodedIdToken> => {
  try {
    const decodedToken = await firebaseAuth.verifyIdToken(idToken);
    return decodedToken;
  } catch (error) {
    throw new Error(`Firebase token verification failed: ${error}`);
  }
};

/**
 * Get Firebase user by UID
 */
export const getFirebaseUser = async (
  uid: string
): Promise<admin.auth.UserRecord> => {
  return firebaseAuth.getUser(uid);
};

/**
 * Get Firebase user by email
 */
export const getFirebaseUserByEmail = async (
  email: string
): Promise<admin.auth.UserRecord | null> => {
  try {
    return await firebaseAuth.getUserByEmail(email);
  } catch {
    return null;
  }
};

/**
 * Create custom token for user
 */
export const createCustomToken = async (
  uid: string,
  claims?: Record<string, unknown>
): Promise<string> => {
  return firebaseAuth.createCustomToken(uid, claims);
};

export default firebaseApp;

/**
 * Firebase Admin SDK configuration-firebase.ts
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

  try {
    // Option 1: PRODUCTION - Use JSON from environment variable
    if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
      console.log('🔥 Firebase: Initializing from environment variable');
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
      return admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
      });
    }

    // Option 2: DEVELOPMENT - Use file path (your current method)
    if (env.FIREBASE_SERVICE_ACCOUNT_PATH) {
      const serviceAccountPath = path.resolve(
        process.cwd(),
        env.FIREBASE_SERVICE_ACCOUNT_PATH
      );

      if (!fs.existsSync(serviceAccountPath)) {
        console.error(`Firebase service account file not found at: ${serviceAccountPath}`);
        console.error('Download a service account JSON from Firebase Console and set FIREBASE_SERVICE_ACCOUNT_PATH in your .env');
        process.exit(1);
      }

      console.log('🔥 Firebase: Initializing from file path');
      return admin.initializeApp({
        credential: admin.credential.cert(serviceAccountPath),
      });
    }

    throw new Error('No Firebase configuration found. Set either FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_PATH');

  } catch (error) {
    console.error('❌ Firebase initialization failed:', error);
    process.exit(1);
  }
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
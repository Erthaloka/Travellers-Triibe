/**
 * Firebase Admin SDK configuration
 * Backend ONLY (Node / Express)
 */

import admin from "firebase-admin";
import path from "path";
import fs from "fs";

// Initialize Firebase Admin only once
const initializeFirebase = (): admin.app.App => {
  // Prevent re-initialization in watch mode
  if (admin.apps.length > 0) {
    return admin.apps[0];
  }

  // Resolve service account path relative to backend root
  const serviceAccountPath = path.resolve(
    process.cwd(),
    "travellers-triibe-firebase-adminsdk.json"
  );

  // Ensure file exists
  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(
      `Firebase service account not found at: ${serviceAccountPath}`
    );
  }

  // Load service account
  const serviceAccount = JSON.parse(
    fs.readFileSync(serviceAccountPath, "utf-8")
  );

  return admin.initializeApp({
    credential: admin.credential.cert(
      serviceAccount as admin.ServiceAccount
    ),
  });
};

// Initialize immediately on import
const firebaseApp = initializeFirebase();

// Export Firebase Auth instance
export const firebaseAuth = admin.auth();

/**
 * Verify Firebase ID token
 */
export const verifyFirebaseToken = async (
  idToken: string
): Promise<admin.auth.DecodedIdToken> => {
  return firebaseAuth.verifyIdToken(idToken);
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
 * Create custom token (optional)
 */
export const createCustomToken = async (
  uid: string,
  claims?: Record<string, unknown>
): Promise<string> => {
  return firebaseAuth.createCustomToken(uid, claims);
};

export default firebaseApp;

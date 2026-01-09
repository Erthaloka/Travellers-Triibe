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
    return admin.apps[0] as admin.app.App;
  }

  // Resolve service account path relative to backend root
  // Look for any file matching the pattern pattern
  const rootDir = process.cwd();
  const files = fs.readdirSync(rootDir);
  const serviceAccountFile = files.find(file =>
    file.startsWith('travellers-triibe-firebase-adminsdk-') &&
    file.endsWith('.json')
  );

  if (!serviceAccountFile) {
    throw new Error(
      `Firebase service account not found in ${rootDir}. Expected file starting with 'travellers-triibe-firebase-adminsdk-'`
    );
  }

  const serviceAccountPath = path.resolve(rootDir, serviceAccountFile);

  console.log(`✅ Loaded Firebase Service Account: ${serviceAccountFile}`);

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
export const firebaseAuth: admin.auth.Auth = admin.auth();

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

// 🔴 Firebase DISABLED for local development
// This prevents server crash when service account file is missing

const admin = null as any;

export default admin;

// Dummy exports (if used elsewhere)
export const firebaseAuth = null as any;

export const verifyFirebaseToken = async () => {
  throw new Error("Firebase disabled in local development");
};

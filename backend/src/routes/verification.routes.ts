import { Router } from "express";
import {
  verifyGSTIN,
  verifyPAN,
  getVerificationStatus
} from "../controllers/verification.controller";

const router = Router();

router.post("/verify/gstin", verifyGSTIN);
router.post("/verify/pan", verifyPAN);
router.get("/business/verification-status", getVerificationStatus);

export default router;


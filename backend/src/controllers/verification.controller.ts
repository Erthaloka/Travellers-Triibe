import { Request, Response } from "express";

// Mock GSTIN verification
export const verifyGSTIN = async (req: Request, res: Response) => {
  const { businessId, gstin } = req.body;

  if (!gstin) {
    return res.status(400).json({ message: "GSTIN is required" });
  }

  const isValid = gstin.endsWith("Z5"); // mock rule

  return res.json({
    businessId,
    gstin,
    status: isValid ? "verified" : "failed"
  });
};

// Mock PAN verification
export const verifyPAN = async (req: Request, res: Response) => {
  const { businessId, pan } = req.body;

  if (!pan) {
    return res.status(400).json({ message: "PAN is required" });
  }

  const isValid = pan.length === 10; // mock rule

  return res.json({
    businessId,
    pan,
    status: isValid ? "verified" : "failed"
  });
};

// Fetch verification status (mock)
export const getVerificationStatus = async (_req: Request, res: Response) => {
  return res.json({
    gstin: { status: "verified" },
    pan: { status: "pending" },
    overall_status: "pending"
  });
};


import { Router } from "express";
import { createOrder } from "../controllers/payment.controller";

const router = Router();

router.post("/create-order", createOrder);

export default router;



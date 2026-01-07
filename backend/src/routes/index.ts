/**
 * API Routes index
 */
import { Router } from 'express';
import authRoutes from './auth.js';
import userRoutes from './users.js';
import partnerRoutes from './partners.js';
import orderRoutes from './orders.js';
import paymentRoutes from './payments.js';
import billRoutes from './bills.js';

const router = Router();

// Health check
router.get('/health', (_, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Mount routes
router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/partners', partnerRoutes);
router.use('/orders', orderRoutes);
router.use('/payments', paymentRoutes);
router.use('/bills', billRoutes);

// Support /v1 prefix and singular /payment path for backward compatibility
const v1Router = Router();
v1Router.use('/payment', paymentRoutes); // /api/v1/payment/* routes
router.use('/v1', v1Router);

export default router;

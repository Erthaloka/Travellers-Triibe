/**
 * Travellers Triibe Backend
 * Express + TypeScript API Server
 */
import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';

import { env } from './config/env.js';
import { connectDatabase, disconnectDatabase } from './config/database.js';
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js';
import routes from './routes/index.js';

// Initialize Express app
const app: Express = express();

// ============== Middleware ==============

// Security headers
app.use(helmet());

// CORS
app.use(
  cors({
    origin: env.NODE_ENV === 'production'
      ? ['https://travellers-triibe.com']
      : '*',
    credentials: true,
  })
);

// Request logging
if (env.NODE_ENV !== 'test') {
  app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Trust proxy (for rate limiting behind reverse proxy)
app.set('trust proxy', 1);

// ============== Routes ==============

// API routes
app.use('/api', routes);

// Root endpoint
app.get('/', (_, res) => {
  res.json({
    name: 'Travellers Triibe API',
    version: '1.0.0',
    status: 'running',
    docs: '/api/health',
  });
});

// ============== Error Handling ==============

// 404 handler
app.use(notFoundHandler);

// Global error handler
app.use(errorHandler);

// ============== Server Startup ==============

const startServer = async (): Promise<void> => {
  try {
    // Connect to MongoDB
    await connectDatabase();

    // Start server
    app.listen(env.PORT, () => {
      console.log(`
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║   🚀 Travellers Triibe API Server                     ║
║                                                       ║
║   Environment: ${env.NODE_ENV.padEnd(38)}             ║
║   Port: ${String(env.PORT).padEnd(46)}                ║
║   URL: http://localhost:${String(env.PORT).padEnd(30)}║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};
// ============== Graceful Shutdown ==============
const gracefulShutdown = async (signal: string): Promise<void> => {
  console.log(`\n📡 Received ${signal}. Shutting down gracefully...`);

  try {
    await disconnectDatabase();
    console.log('✅ Cleanup completed. Goodbye!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during shutdown:', error);
    process.exit(1);
  }
};
// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
});

// Start the server
startServer();
export default app;
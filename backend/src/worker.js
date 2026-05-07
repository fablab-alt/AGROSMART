const prisma = require('./config/prisma');
const logger = require('./utils/logger');

const shutdown = async (signal) => {
  logger.info(`Worker shutdown signal received: ${signal}`);

  await prisma.$disconnect();
  logger.info('Prisma disconnected for worker');
  process.exit(0);
};

const startWorker = async () => {
  try {
    await prisma.$connect();
    logger.info('Prisma connected for worker');

    logger.info('Worker dédié désactivé: le traitement se fait directement dans le backend.');
    process.exit(0);
  } catch (error) {
    logger.error('Worker startup failed', { error: error.message });
    process.exit(1);
  }
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception in worker', { error: error.message, stack: error.stack });
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled rejection in worker', { reason });
});

startWorker();

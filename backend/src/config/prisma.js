require('./loadEnv');

const { PrismaClient } = require('@prisma/client');

// Singleton instance - Prisma 5.x with native mysql2 driver
let prisma;

if (process.env.NODE_ENV === 'production') {
    prisma = new PrismaClient({
        datasourceUrl: process.env.DATABASE_URL,
        log: ['error', 'warn'],
    });
} else {
    // In development, use a global variable to preserve the instance across hot-reloads
    if (!global.prisma) {
        global.prisma = new PrismaClient({
            datasourceUrl: process.env.DATABASE_URL,
            log: ['query', 'error', 'warn'],
        });
    }
    prisma = global.prisma;
}

// Graceful shutdown helpers
const cleanup = async () => {
    if (prisma) await prisma.$disconnect();
};

process.on('SIGINT', cleanup);
process.on('SIGTERM', cleanup);

module.exports = prisma;

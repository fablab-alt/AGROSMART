/**
 * Scripts de maintenance de la base de données
 * AgriSmart CI - Backend
 * 
 * Ce script gère:
 * - Purge des OTP codes expirés
 * - Purge des refresh tokens révoqués/expirés
 * - Archivage des mesures anciennes
 * 
 * Usage: node scripts/db-maintenance.js [action]
 * Actions: purge-otp, purge-tokens, archive-mesures, all
 */

const prisma = require('../src/config/prisma');
const logger = require('../src/utils/logger');

// Configuration
const CONFIG = {
    OTP_EXPIRY_HOURS: 24,
    TOKEN_EXPIRY_DAYS: 30,
    MESURES_ARCHIVE_MONTHS: 6,
    BATCH_SIZE: 1000,
};

/**
 * Purge les OTP codes expirés
 */
async function purgeExpiredOtpCodes() {
    const expiryDate = new Date();
    expiryDate.setHours(expiryDate.getHours() - CONFIG.OTP_EXPIRY_HOURS);

    try {
        const result = await prisma.otpCode.deleteMany({
            where: {
                OR: [
                    { used: true },
                    { expiresAt: { lt: new Date() } },
                    { createdAt: { lt: expiryDate } }
                ]
            }
        });

        logger.info(`[MAINTENANCE] Purge OTP: ${result.count} codes supprimés`);
        return result.count;
    } catch (error) {
        logger.error('[MAINTENANCE] Erreur purge OTP', { error: error.message });
        throw error;
    }
}

/**
 * Purge les refresh tokens expirés ou révoqués
 */
async function purgeExpiredRefreshTokens() {
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() - CONFIG.TOKEN_EXPIRY_DAYS);

    try {
        const result = await prisma.refreshToken.deleteMany({
            where: {
                OR: [
                    { revoked: true },
                    { expiresAt: { lt: new Date() } },
                    { createdAt: { lt: expiryDate } }
                ]
            }
        });

        logger.info(`[MAINTENANCE] Purge Tokens: ${result.count} tokens supprimés`);
        return result.count;
    } catch (error) {
        logger.error('[MAINTENANCE] Erreur purge tokens', { error: error.message });
        throw error;
    }
}

/**
 * Archive les mesures anciennes
 * (Pour le moment, on les supprime. En production, il faudrait les déplacer vers une table d'archive)
 */
async function archiveOldMesures() {
    const archiveDate = new Date();
    archiveDate.setMonth(archiveDate.getMonth() - CONFIG.MESURES_ARCHIVE_MONTHS);

    try {
        // Compter d'abord
        const count = await prisma.mesure.count({
            where: {
                timestamp: { lt: archiveDate }
            }
        });

        logger.info(`[MAINTENANCE] ${count} mesures à archiver (> ${CONFIG.MESURES_ARCHIVE_MONTHS} mois)`);

        if (count === 0) {
            return 0;
        }

        // Supprimer par lots pour éviter les timeouts
        let totalDeleted = 0;
        while (totalDeleted < count) {
            const deleted = await prisma.mesure.deleteMany({
                where: {
                    timestamp: { lt: archiveDate }
                },
                // Note: Prisma ne supporte pas LIMIT dans deleteMany
                // On fait plusieurs passes
            });

            totalDeleted += deleted.count;
            logger.info(`[MAINTENANCE] Archivage mesures: ${totalDeleted}/${count}`);

            if (deleted.count === 0) break;
        }

        logger.info(`[MAINTENANCE] Archivage mesures terminé: ${totalDeleted} supprimées`);
        return totalDeleted;
    } catch (error) {
        logger.error('[MAINTENANCE] Erreur archivage mesures', { error: error.message });
        throw error;
    }
}

/**
 * Nettoie les notifications lues depuis plus de 30 jours
 */
async function purgeOldNotifications() {
    const expiryDate = new Date();
    expiryDate.setDate(expiryDate.getDate() - 30);

    try {
        const result = await prisma.notification.deleteMany({
            where: {
                AND: [
                    { lue: true },
                    { createdAt: { lt: expiryDate } }
                ]
            }
        });

        logger.info(`[MAINTENANCE] Purge Notifications: ${result.count} notifications supprimées`);
        return result.count;
    } catch (error) {
        logger.error('[MAINTENANCE] Erreur purge notifications', { error: error.message });
        throw error;
    }
}

/**
 * Exécute toutes les tâches de maintenance
 */
async function runAllMaintenance() {
    logger.info('[MAINTENANCE] Début de la maintenance complète');

    const results = {
        otpPurged: 0,
        tokensPurged: 0,
        mesuresArchived: 0,
        notificationsPurged: 0,
    };

    try {
        results.otpPurged = await purgeExpiredOtpCodes();
        results.tokensPurged = await purgeExpiredRefreshTokens();
        results.mesuresArchived = await archiveOldMesures();
        results.notificationsPurged = await purgeOldNotifications();

        logger.info('[MAINTENANCE] Maintenance complète terminée', results);
        return results;
    } catch (error) {
        logger.error('[MAINTENANCE] Erreur pendant la maintenance', { error: error.message });
        throw error;
    }
}

// CLI Interface
async function main() {
    const action = process.argv[2] || 'all';

    try {
        switch (action) {
            case 'purge-otp':
                await purgeExpiredOtpCodes();
                break;
            case 'purge-tokens':
                await purgeExpiredRefreshTokens();
                break;
            case 'archive-mesures':
                await archiveOldMesures();
                break;
            case 'purge-notifications':
                await purgeOldNotifications();
                break;
            case 'all':
                await runAllMaintenance();
                break;
            default:
                console.log('Actions disponibles: purge-otp, purge-tokens, archive-mesures, purge-notifications, all');
        }
    } catch (error) {
        console.error('Erreur:', error.message);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

// Exporter pour utilisation en tant que module
module.exports = {
    purgeExpiredOtpCodes,
    purgeExpiredRefreshTokens,
    archiveOldMesures,
    purgeOldNotifications,
    runAllMaintenance,
    CONFIG
};

// Exécuter si appelé directement
if (require.main === module) {
    main();
}

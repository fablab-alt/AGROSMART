/**
 * Gamification Controller
 * AgroSmart - Points, Badges, Leaderboard
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Get user points and level
 * GET /api/gamification/points
 */
/**
 * Get user points and level
 * GET /api/gamification/points
 */
exports.getUserPoints = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // Find or create user points
        let userPoints = await prisma.userPoint.findUnique({
            where: { userId }
        });

        if (!userPoints) {
            userPoints = await prisma.userPoint.create({
                data: {
                    userId,
                    pointsTotal: 0,
                    niveau: 1
                }
            });
        }

        res.json({
            success: true,
            data: userPoints
        });
    } catch (error) {
        logger.error('Error fetching user points:', error);
        next(error);
    }
};

/**
 * Award points to user
 * POST /api/gamification/points/award
 */
exports.awardPoints = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { points, action } = req.body;

        // Transaction to ensure atomic update
        const result = await prisma.$transaction(async (prisma) => {
            const currentPoints = await prisma.userPoint.findUnique({
                where: { userId }
            });

            const currentTotal = currentPoints ? currentPoints.pointsTotal : 0;
            const currentActions = currentPoints ? currentPoints.actionsCompletees : 0;
            const newTotal = currentTotal + points;
            const newLevel = Math.max(1, Math.floor(newTotal / 100)); // Logic from legacy SQL

            return await prisma.userPoint.upsert({
                where: { userId },
                update: {
                    pointsTotal: newTotal,
                    niveau: newLevel,
                    actionsCompletees: currentActions + 1,
                    derniereActivite: new Date()
                },
                create: {
                    userId,
                    pointsTotal: points,
                    niveau: Math.max(1, Math.floor(points / 100)),
                    actionsCompletees: 1,
                    derniereActivite: new Date()
                }
            });
        });

        res.json({
            success: true,
            message: `${points} points gagnés!`,
            data: result
        });
    } catch (error) {
        logger.error('Error awarding points:', error);
        next(error);
    }
};

/**
 * Get leaderboard
 * GET /api/gamification/leaderboard
 */
exports.getLeaderboard = async (req, res, next) => {
    try {
        const { limit = 100 } = req.query;

        const leaderboard = await prisma.userPoint.findMany({
            take: parseInt(limit),
            orderBy: {
                pointsTotal: 'desc'
            },
            include: {
                user: {
                    select: {
                        nom: true,
                        prenoms: true
                    }
                }
            }
        });

        res.json({
            success: true,
            data: leaderboard
        });
    } catch (error) {
        logger.error('Error fetching leaderboard:', error);
        next(error);
    }
};

/**
 * Get user's badges
 * GET /api/gamification/badges
 */
exports.getUserBadges = async (req, res, next) => {
    try {
        const userId = req.user.id;

        const userBadges = await prisma.userBadge.findMany({
            where: { userId },
            include: {
                badge: true
            },
            orderBy: {
                obtenuLe: 'desc'
            }
        });

        // Flatten result to match legacy format if needed, or send as structured
        const formatted = userBadges.map(ub => ({
            ...ub.badge,
            date_obtention: ub.obtenuLe
        }));

        res.json({
            success: true,
            data: formatted
        });
    } catch (error) {
        logger.error('Error fetching badges:', error);
        next(error);
    }
};

module.exports = exports;

/**
 * Contrôleur du Dashboard
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');

exports.getStats = async (req, res, next) => {
    try {
        const userId = req.user.id;

        const [parcellesAgg, capteursCount, alertesCount] = await Promise.all([
            // Parcelles Stats
            prisma.parcelle.aggregate({
                _count: { id: true },
                _sum: { superficie: true },
                where: { userId }
            }),
            // Capteurs Stats (via Stations -> Parcelles)
            prisma.capteur.count({
                where: {
                    station: {
                        parcelle: { userId }
                    }
                }
            }),
            // Alertes Stats (via Parcelles owner, filtered by status 'nouvelle')
            prisma.alerte.count({
                where: {
                    userId,
                    statut: 'NOUVELLE'
                }
            })
        ]);

        // Placeholder pour ROI/Production - à connecter avec futures tables ventes/récoltes
        const production = {
            volume_tonnes: 12.5,
            revenu_estime: 4500000
        };

        res.json({
            success: true,
            data: {
                parcelles: {
                    count: parcellesAgg._count.id,
                    superficie: parseFloat(parcellesAgg._sum.superficie || 0).toFixed(1)
                },
                capteurs: capteursCount,
                alertes: alertesCount,
                production
            }
        });

    } catch (error) {
        next(error);
    }
};

exports.getCultureDistribution = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // Agréger la superficie par culture
        // Use raw query for complex join + aggregation (MySQL compatible)
        const dataRaw = await prisma.$queryRaw`
            SELECT c.nom, SUM(p.superficie) as value
            FROM parcelles p
            JOIN plantations pl ON p.id = pl.parcelle_id
            JOIN cultures c ON pl.culture_id = c.id
            WHERE p.user_id = ${userId} AND pl.statut = 'active'
            GROUP BY c.nom
        `;

        // Formatter pour le frontend rechart
        const colors = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884d8'];

        const data = dataRaw.map((row, index) => ({
            name: row.nom,
            value: Number(row.value || 0), // Handle Decimal/BigInt
            color: colors[index % colors.length]
        }));

        res.json({
            success: true,
            data: data
        });

    } catch (error) {
        next(error);
    }
};

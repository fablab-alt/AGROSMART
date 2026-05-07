const prisma = require('../config/prisma');

exports.getAllRegions = async (req, res, next) => {
    try {
        const regions = await prisma.region.findMany({
            select: {
                id: true,
                nom: true,
                code: true,
                createdAt: true,
                updatedAt: true
            },
            orderBy: {
                nom: 'asc'
            }
        });

        res.json({
            success: true,
            count: regions.length,
            data: regions
        });
    } catch (error) {
        next(error);
    }
};

const prisma = require('../config/prisma');
const logger = require('../utils/logger');
const { errors } = require('../middlewares/errorHandler');

/**
 * Récupérer tous les paramètres système
 */
exports.getSettings = async (req, res, next) => {
    try {
        const result = await prisma.configuration.findMany();

        // Transformer en objet clé-valeur avec le bon type
        const settings = {};
        result.forEach(row => {
            let value = row.valeur;

            // Conversion de type
            if (row.type === 'boolean') {
                value = value === 'true';
            } else if (row.type === 'number') {
                value = Number(value);
            } else if (row.type === 'json') {
                try {
                    value = JSON.parse(value);
                } catch (e) {
                    logger.warn(`Erreur parsing JSON pour setting ${row.cle}`, e);
                }
            }

            settings[row.cle] = value;
        });

        res.json({
            success: true,
            data: settings
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Mettre à jour les paramètres système
 */
/**
 * Mettre à jour les paramètres système
 */
exports.updateSettings = async (req, res, next) => {
    try {
        const settings = req.body;
        const updates = Object.entries(settings);

        const operations = updates.map(([key, value]) => {
            let type = 'string';
            let stringValue = String(value);

            if (typeof value === 'boolean') {
                type = 'boolean';
                stringValue = String(value);
            } else if (typeof value === 'number') {
                type = 'number';
                stringValue = String(value);
            } else if (typeof value === 'object') {
                type = 'json';
                stringValue = JSON.stringify(value);
            }

            return prisma.configuration.upsert({
                where: { cle: key },
                update: {
                    valeur: stringValue,
                    type,
                    updatedAt: new Date()
                },
                create: {
                    cle: key,
                    valeur: stringValue,
                    type
                }
            });
        });

        await prisma.$transaction(operations, {
            maxWait: 10000,
            timeout: 20000
        });

        res.json({
            success: true,
            message: 'Paramètres mis à jour avec succès',
            count: updates.length
        });

    } catch (error) {
        next(error);
    }
};

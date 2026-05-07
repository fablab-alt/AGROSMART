/**
 * Group Purchases Controller
 * AgroSmart - Achats Groupés
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

exports.getGroupPurchases = async (req, res, next) => {
    try {
        const { statut, categorie } = req.query;

        const where = {};
        if (statut) where.statut = statut;
        if (categorie) where.categorie = categorie;

        const purchases = await prisma.achatGroupe.findMany({
            where,
            orderBy: { dateLimite: 'asc' }
        });

        res.json({
            success: true,
            data: purchases
        });
    } catch (error) {
        logger.error('Error fetching group purchases:', error);
        next(error);
    }
};

exports.joinGroupPurchase = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const { quantite } = req.body;

        await prisma.$transaction(async (tx) => {
            const gp = await tx.achatGroupe.findUnique({
                where: { id }
            });

            if (!gp) {
                throw { status: 404, message: 'Achat groupé non trouvé' };
            }

            const montant = quantite * parseFloat(gp.prixGroupe);

            const participation = await tx.participationAchatGroupe.create({
                data: {
                    achatGroupeId: id,
                    participantId: userId,
                    quantite,
                    montant
                }
            });

            // Update quantities using increment directly? Need to check threshold for status update.
            // Easier to update explicitly.
            const newQuantite = gp.quantiteActuelle + quantite;
            const newStatut = newQuantite >= gp.quantiteObjectif ? 'objectif_atteint' : gp.statut;

            await tx.achatGroupe.update({
                where: { id },
                data: {
                    quantiteActuelle: newQuantite,
                    statut: newStatut
                }
            });

            res.status(201).json({
                success: true,
                message: 'Participation enregistrée',
                data: participation
            });
        });

    } catch (error) {
        if (error.status === 404) return res.status(404).json({ success: false, message: error.message });
        logger.error('Error joining group purchase:', error);
        next(error);
    }
};

module.exports = exports;

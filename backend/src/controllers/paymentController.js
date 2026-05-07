/**
 * Payment Controller
 * Mobile Money Integration (Orange Money, MTN Money, Moov Money)
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');
const crypto = require('crypto');

exports.initiatePayment = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { montant, fournisseur, numero_telephone, commande_id, location_id, achat_groupe_id } = req.body;

        // Generate unique reference
        const reference = `PAY_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;

        // Create transaction record
        const transaction = await prisma.transactionPaiement.create({
            data: {
                userId,
                commandeId: commande_id,
                locationId: location_id,
                achatGroupeId: achat_groupe_id,
                montant,
                fournisseur,
                numeroTelephone: numero_telephone,
                referencePaiement: reference,
                statut: 'en_attente'
            }
        });

        res.status(201).json({
            success: true,
            message: 'Paiement initié',
            data: {
                ...transaction,
                payment_url: null,
                provider_status: 'pending_provider_confirmation'
            }
        });
    } catch (error) {
        logger.error('Error initiating payment:', error);
        next(error);
    }
};

exports.getTransactions = async (req, res, next) => {
    try {
        const userId = req.user.id;

        const transactions = await prisma.transactionPaiement.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' }
        });

        res.json({
            success: true,
            data: transactions
        });
    } catch (error) {
        logger.error('Error fetching transactions:', error);
        next(error);
    }
};

module.exports = exports;

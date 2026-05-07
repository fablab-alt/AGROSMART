/**
 * Routes SMS Gateway
 * AgroSmart - Backend API
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth');
const { adminMiddleware } = require('../middlewares/admin');
const { smsGateway, SMS_PRIORITY } = require('../services/smsGatewayService');
const logger = require('../config/logger');
const prisma = require('../config/prisma');
const { body, validationResult } = require('express-validator');

/**
 * @swagger
 * tags:
 *   name: SMS
 *   description: Service SMS pour alertes et notifications
 */

/**
 * @swagger
 * /api/sms/send:
 *   post:
 *     summary: Envoie un SMS (admin uniquement)
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - phoneNumber
 *               - message
 *             properties:
 *               phoneNumber:
 *                 type: string
 *                 example: "+2250701234567"
 *               message:
 *                 type: string
 *                 example: "Votre alerte AgroSmart"
 */
router.post('/send',
  authenticate,
  adminMiddleware,
  [
    body('phoneNumber').notEmpty().withMessage('Numéro de téléphone requis'),
    body('message').notEmpty().withMessage('Message requis'),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { phoneNumber, message } = req.body;
      const result = await smsGateway.sendSms(phoneNumber, message);

      // Logger l'envoi
      logger.info(`[SMS] Admin ${req.user.id} sent SMS to ${phoneNumber.slice(-4)}`);

      res.json({
        success: result.success,
        messageId: result.messageId,
        provider: result.provider,
      });
    } catch (error) {
      logger.error('[SMS] Send error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi du SMS' });
    }
  }
);

/**
 * @swagger
 * /api/sms/send-template:
 *   post:
 *     summary: Envoie un SMS à partir d'un template
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.post('/send-template',
  authenticate,
  adminMiddleware,
  [
    body('phoneNumber').notEmpty(),
    body('templateKey').notEmpty(),
    body('language').optional().isIn(['fr', 'bci', 'dyu']),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { phoneNumber, templateKey, variables, language } = req.body;
      const result = await smsGateway.sendFromTemplate(
        phoneNumber,
        templateKey,
        variables || {},
        language || 'fr'
      );

      res.json({
        success: result.success,
        messageId: result.messageId,
      });
    } catch (error) {
      logger.error('[SMS] Template send error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi du SMS' });
    }
  }
);

/**
 * @swagger
 * /api/sms/bulk:
 *   post:
 *     summary: Envoie des SMS en masse (admin uniquement)
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.post('/bulk',
  authenticate,
  adminMiddleware,
  [
    body('recipients').isArray().withMessage('Liste de destinataires requise'),
    body('recipients.*.phoneNumber').notEmpty(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { recipients, options } = req.body;
      const result = await smsGateway.sendBulk(recipients, options || {});

      logger.info(`[SMS] Bulk send by admin ${req.user.id}: ${result.success}/${result.total}`);

      res.json(result);
    } catch (error) {
      logger.error('[SMS] Bulk send error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi en masse' });
    }
  }
);

/**
 * @swagger
 * /api/sms/alert/weather:
 *   post:
 *     summary: Envoie une alerte météo aux agriculteurs d'une région
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.post('/alert/weather',
  authenticate,
  adminMiddleware,
  [
    body('regionId').optional().isInt(),
    body('message').notEmpty(),
    body('severity').optional().isIn(['low', 'medium', 'high', 'critical']),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { regionId, message, severity } = req.body;

      // Récupérer les agriculteurs de la région avec SMS activés
      const whereClause = {
        smsAlertsEnabled: true,
        telephone: { not: null },
      };

      if (regionId) {
        whereClause.parcelles = {
          some: { regionId: parseInt(regionId) }
        };
      }

      const farmers = await prisma.utilisateur.findMany({
        where: whereClause,
        select: {
          id: true,
          telephone: true,
          preferredLanguage: true,
          parcelles: {
            select: { nom: true },
            take: 1,
          },
        },
      });

      if (farmers.length === 0) {
        return res.json({ success: true, sent: 0, message: 'Aucun agriculteur à notifier' });
      }

      const result = await smsGateway.sendWeatherAlert(farmers, {
        message,
        parcelleName: null, // Sera remplacé par "votre parcelle"
      });

      // Créer une entrée de notification
      await prisma.notification.createMany({
        data: farmers.map(f => ({
          utilisateurId: f.id,
          type: 'WEATHER_ALERT',
          titre: 'Alerte Météo',
          message,
          priorite: severity === 'critical' ? 'URGENT' : 'HAUTE',
          canal: 'SMS',
        })),
      });

      logger.info(`[SMS] Weather alert sent to ${result.success} farmers`);

      res.json({
        success: true,
        total: result.total,
        sent: result.success,
        failed: result.failed,
      });
    } catch (error) {
      logger.error('[SMS] Weather alert error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi des alertes météo' });
    }
  }
);

/**
 * @swagger
 * /api/sms/alert/disease:
 *   post:
 *     summary: Envoie une alerte maladie
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.post('/alert/disease',
  authenticate,
  [
    body('parcelleId').isInt(),
    body('diseaseName').notEmpty(),
    body('treatment').optional(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { parcelleId, diseaseName, treatment } = req.body;

      // Récupérer la parcelle et son propriétaire
      const parcelle = await prisma.parcelle.findUnique({
        where: { id: parseInt(parcelleId) },
        include: {
          utilisateur: {
            select: {
              id: true,
              telephone: true,
              preferredLanguage: true,
              smsAlertsEnabled: true,
            },
          },
        },
      });

      if (!parcelle) {
        return res.status(404).json({ error: 'Parcelle non trouvée' });
      }

      if (!parcelle.utilisateur.smsAlertsEnabled || !parcelle.utilisateur.telephone) {
        return res.json({ success: true, sent: false, reason: 'SMS alerts disabled' });
      }

      const result = await smsGateway.sendDiseaseAlert(parcelle.utilisateur, {
        name: diseaseName,
        parcelleName: parcelle.nom,
        treatment: treatment || 'Consultez un agronome',
      });

      res.json({
        success: result.success,
        messageId: result.messageId,
      });
    } catch (error) {
      logger.error('[SMS] Disease alert error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi de l\'alerte' });
    }
  }
);

/**
 * @swagger
 * /api/sms/alert/sensor:
 *   post:
 *     summary: Envoie une alerte capteur
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.post('/alert/sensor',
  authenticate,
  [
    body('capteurId').isInt(),
    body('parameter').notEmpty(),
    body('value').notEmpty(),
    body('threshold').optional(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { capteurId, parameter, value, unit, threshold } = req.body;

      // Récupérer le capteur et le propriétaire de la parcelle
      const capteur = await prisma.capteur.findUnique({
        where: { id: parseInt(capteurId) },
        include: {
          parcelle: {
            include: {
              utilisateur: {
                select: {
                  id: true,
                  telephone: true,
                  preferredLanguage: true,
                  smsAlertsEnabled: true,
                },
              },
            },
          },
        },
      });

      if (!capteur || !capteur.parcelle) {
        return res.status(404).json({ error: 'Capteur non trouvé' });
      }

      const farmer = capteur.parcelle.utilisateur;
      if (!farmer.smsAlertsEnabled || !farmer.telephone) {
        return res.json({ success: true, sent: false, reason: 'SMS alerts disabled' });
      }

      const result = await smsGateway.sendSensorAlert(farmer, {
        sensorName: capteur.nom || capteur.type,
        parcelleName: capteur.parcelle.nom,
        parameter,
        value,
        unit: unit || '',
        threshold: threshold || 'N/A',
      });

      res.json({
        success: result.success,
        messageId: result.messageId,
      });
    } catch (error) {
      logger.error('[SMS] Sensor alert error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi de l\'alerte' });
    }
  }
);

/**
 * @swagger
 * /api/sms/otp:
 *   post:
 *     summary: Envoie un code OTP
 *     tags: [SMS]
 */
router.post('/otp',
  [
    body('phoneNumber').notEmpty(),
    body('code').notEmpty().isLength({ min: 4, max: 6 }),
    body('language').optional().isIn(['fr', 'bci', 'dyu']),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { phoneNumber, code, language } = req.body;
      const result = await smsGateway.sendOtp(phoneNumber, code, language || 'fr');

      res.json({
        success: result.success,
        messageId: result.messageId,
      });
    } catch (error) {
      logger.error('[SMS] OTP send error:', error);
      res.status(500).json({ error: 'Erreur lors de l\'envoi du code' });
    }
  }
);

/**
 * @swagger
 * /api/sms/balance:
 *   get:
 *     summary: Récupère le solde SMS (admin uniquement)
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.get('/balance', authenticate, adminMiddleware, async (req, res) => {
  try {
    const balance = await smsGateway.getBalance();
    res.json(balance);
  } catch (error) {
    logger.error('[SMS] Balance error:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération du solde' });
  }
});

/**
 * @swagger
 * /api/sms/templates:
 *   get:
 *     summary: Liste les templates SMS disponibles
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.get('/templates', authenticate, async (req, res) => {
  res.json({
    templates: smsGateway.getTemplates(),
    languages: smsGateway.getSupportedLanguages(),
  });
});

/**
 * @swagger
 * /api/sms/preferences:
 *   put:
 *     summary: Met à jour les préférences SMS de l'utilisateur
 *     tags: [SMS]
 *     security:
 *       - bearerAuth: []
 */
router.put('/preferences',
  authenticate,
  [
    body('smsAlertsEnabled').optional().isBoolean(),
    body('preferredLanguage').optional().isIn(['fr', 'bci', 'dyu']),
    body('alertTypes').optional().isArray(),
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { smsAlertsEnabled, preferredLanguage, alertTypes } = req.body;
      
      const updateData = {};
      if (smsAlertsEnabled !== undefined) updateData.smsAlertsEnabled = smsAlertsEnabled;
      if (preferredLanguage) updateData.preferredLanguage = preferredLanguage;
      if (alertTypes) updateData.smsAlertTypes = alertTypes;

      const user = await prisma.utilisateur.update({
        where: { id: req.user.id },
        data: updateData,
        select: {
          smsAlertsEnabled: true,
          preferredLanguage: true,
          smsAlertTypes: true,
        },
      });

      res.json({
        success: true,
        preferences: user,
      });
    } catch (error) {
      logger.error('[SMS] Preferences update error:', error);
      res.status(500).json({ error: 'Erreur lors de la mise à jour des préférences' });
    }
  }
);

module.exports = router;

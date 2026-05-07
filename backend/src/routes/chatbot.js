/**
 * Routes Chatbot IA Assistant Vocal
 * AgroSmart - Backend
 * 
 * Endpoints pour l'assistant vocal multilingue:
 * - POST /chatbot/message - Envoyer un message et recevoir une réponse IA
 * - POST /chatbot/voice - Traiter une commande vocale
 * - GET /chatbot/actions - Liste des actions disponibles
 * - POST /chatbot/execute - Exécuter une action dans l'app
 * - GET /chatbot/languages - Langues supportées
 */

const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middlewares/auth');
const { apiLimiter } = require('../middlewares/rateLimiter');
const chatbotController = require('../controllers/chatbotController');

// Rate limiting spécifique pour le chatbot (plus permissif)
const chatbotLimiter = apiLimiter; // 100 req/min

/**
 * @swagger
 * /chatbot/message:
 *   post:
 *     summary: Envoyer un message au chatbot
 *     tags: [Chatbot]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - message
 *             properties:
 *               message:
 *                 type: string
 *                 description: Message de l'utilisateur
 *               langue:
 *                 type: string
 *                 enum: [fr, bci, dyu, sev, bev, goa, ati]
 *                 default: fr
 *               contexte:
 *                 type: string
 *                 description: Contexte de la conversation
 *               historique:
 *                 type: array
 *                 description: Historique de la conversation
 *     responses:
 *       200:
 *         description: Réponse du chatbot
 */
router.post('/message', authenticate, chatbotLimiter, chatbotController.processMessage);

/**
 * @swagger
 * /chatbot/voice:
 *   post:
 *     summary: Traiter une commande vocale
 *     tags: [Chatbot]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - transcription
 *             properties:
 *               transcription:
 *                 type: string
 *                 description: Texte transcrit de la voix
 *               langue:
 *                 type: string
 *                 default: fr
 *     responses:
 *       200:
 *         description: Action à exécuter
 */
router.post('/voice', authenticate, chatbotLimiter, chatbotController.processVoiceCommand);

/**
 * @swagger
 * /chatbot/execute:
 *   post:
 *     summary: Exécuter une action dans l'application
 *     tags: [Chatbot]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - action
 *             properties:
 *               action:
 *                 type: string
 *                 enum: [navigate, create_parcelle, check_weather, diagnose, marketplace_search, send_message, get_alerts, get_sensors, irrigation_control]
 *               params:
 *                 type: object
 *                 description: Paramètres de l'action
 *     responses:
 *       200:
 *         description: Résultat de l'action
 */
router.post('/execute', authenticate, chatbotController.executeAction);

/**
 * @swagger
 * /chatbot/actions:
 *   get:
 *     summary: Liste des actions disponibles pour l'assistant
 *     tags: [Chatbot]
 *     responses:
 *       200:
 *         description: Liste des actions
 */
router.get('/actions', chatbotController.getAvailableActions);

/**
 * @swagger
 * /chatbot/languages:
 *   get:
 *     summary: Langues supportées par l'assistant
 *     tags: [Chatbot]
 *     responses:
 *       200:
 *         description: Liste des langues
 */
router.get('/languages', chatbotController.getSupportedLanguages);

/**
 * @swagger
 * /chatbot/context:
 *   get:
 *     summary: Obtenir le contexte utilisateur pour l'assistant
 *     tags: [Chatbot]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Contexte utilisateur (parcelles, alertes, etc.)
 */
router.get('/context', authenticate, chatbotController.getUserContext);

module.exports = router;

/**
 * Routes du système d'amitié (réseau social)
 * AgroSmart - Système Agricole Intelligent
 *
 * Toutes les routes nécessitent une authentification.
 */
const express = require('express');
const router = express.Router();
const friendshipsController = require('../controllers/friendshipsController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

// Liste des amis confirmés
router.get('/', friendshipsController.getFriends);

// Suggestions d'amis (utilisateurs à proximité, par région)
router.get('/suggestions', friendshipsController.getSuggestions);

// Statut d'amitié avec un autre user (pour afficher le bouton "Ajouter / Accepter / Retirer")
router.get('/status/:userId', friendshipsController.getFriendshipStatus);

// Demandes reçues / envoyées
router.get('/requests/received', friendshipsController.getReceivedRequests);
router.get('/requests/sent', friendshipsController.getSentRequests);

// Envoyer une demande
router.post('/', friendshipsController.sendRequest);

// Accepter / Refuser une demande
router.patch('/:id/accept', friendshipsController.acceptRequest);
router.patch('/:id/reject', friendshipsController.rejectRequest);

// Supprimer une amitié
router.delete('/:id', friendshipsController.removeFriend);

module.exports = router;

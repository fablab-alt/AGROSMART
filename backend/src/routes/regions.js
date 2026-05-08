const express = require('express');
const router = express.Router();
const regionsController = require('../controllers/regionsController');

// La liste des régions est PUBLIQUE (utilisée par le formulaire d'inscription).
// Pas de middleware auth requis — c'est de la donnée de référence.
router.get('/', regionsController.getAllRegions);

module.exports = router;

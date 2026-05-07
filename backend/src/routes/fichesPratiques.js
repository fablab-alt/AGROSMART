/**
 * Routes Fiches Pratiques - Bibliothèque Agricole
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const fichesPratiquesController = require('../controllers/fichesPratiquesController');
const { authenticate } = require('../middlewares/auth');
const { requireRole } = require('../middlewares/rbac');

// Routes publiques (lecture)
router.get('/', authenticate, fichesPratiquesController.getAll);
router.get('/search', authenticate, fichesPratiquesController.search);
router.get('/categories', authenticate, fichesPratiquesController.getCategories);
router.get('/:id', authenticate, fichesPratiquesController.getById);

// Routes admin (écriture)
router.post('/', authenticate, requireRole('ADMIN', 'CONSEILLER', 'AGRONOME'), fichesPratiquesController.create);
router.put('/:id', authenticate, requireRole('ADMIN', 'CONSEILLER', 'AGRONOME'), fichesPratiquesController.update);
router.delete('/:id', authenticate, requireRole('ADMIN'), fichesPratiquesController.remove);

module.exports = router;

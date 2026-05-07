/**
 * Equipment Rental Routes
 * AgroSmart - Marketplace Location d'Équipements
 */

const express = require('express');
const router = express.Router();
const equipmentController = require('../controllers/equipmentController');
const { authenticate } = require('../middlewares/auth');

// All routes require authentication
router.use(authenticate);

// Equipment routes
router.get('/', equipmentController.getEquipments);
router.get('/:id', equipmentController.getEquipmentById);
router.post('/', equipmentController.createEquipment);

// Rental routes
router.post('/:id/rent', equipmentController.createRentalRequest);
router.get('/rentals/my-rentals', equipmentController.getMyRentals);
router.get('/rentals/requests', equipmentController.getRentalRequests);
router.put('/rentals/:id/status', equipmentController.updateRentalStatus);
router.delete('/rentals/:id', equipmentController.cancelRental);

module.exports = router;

const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

router.get('/stats', dashboardController.getStats);
router.get('/cultures', dashboardController.getCultureDistribution);

module.exports = router;

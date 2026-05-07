const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/paymentController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

router.post('/initiate', paymentController.initiatePayment);
router.get('/transactions', paymentController.getTransactions);

module.exports = router;

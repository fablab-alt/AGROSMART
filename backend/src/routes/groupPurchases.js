const express = require('express');
const router = express.Router();
const groupPurchasesController = require('../controllers/groupPurchasesController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

router.get('/', groupPurchasesController.getGroupPurchases);
router.post('/:id/join', groupPurchasesController.joinGroupPurchase);

module.exports = router;

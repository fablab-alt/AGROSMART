const express = require('express');
const router = express.Router();
const regionsController = require('../controllers/regionsController');
const { authenticate: protect } = require('../middlewares/auth');

router.get('/', protect, regionsController.getAllRegions);

module.exports = router;

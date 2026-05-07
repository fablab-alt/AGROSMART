const express = require('express');
const router = express.Router();
const gamificationController = require('../controllers/gamificationController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

router.get('/points', gamificationController.getUserPoints);
router.post('/points/award', gamificationController.awardPoints);
router.get('/leaderboard', gamificationController.getLeaderboard);
router.get('/badges', gamificationController.getUserBadges);

module.exports = router;

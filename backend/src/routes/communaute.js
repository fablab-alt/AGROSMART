const express = require('express');
const router = express.Router();
const communauteController = require('../controllers/communauteController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

// Posts
router.get('/posts', communauteController.getPosts);
router.post('/posts', communauteController.createPost);
router.get('/posts/:id', communauteController.getPostById);

// Réponses
router.post('/posts/:id/reponses', communauteController.createReponse);
router.put('/posts/:postId/reponses/:reponseId/solution', communauteController.markSolution);

// Stats & Leaderboard
router.get('/stats', communauteController.getStats);
router.get('/leaderboard', communauteController.getLeaderboard);

module.exports = router;

const express = require('express');
const router = express.Router();
const communauteController = require('../controllers/communauteController');
const { authenticate } = require('../middlewares/auth');

router.use(authenticate);

// Catégories (liste statique + comptage par catégorie)
router.get('/categories', communauteController.getCategories);

// Stats & Leaderboard (avant les routes :id pour éviter conflit)
router.get('/stats', communauteController.getStats);
router.get('/leaderboard', communauteController.getLeaderboard);

// Posts CRUD
router.get('/posts', communauteController.getPosts);
router.post('/posts', communauteController.createPost);
router.get('/posts/:id', communauteController.getPostById);
router.put('/posts/:id', communauteController.updatePost);
router.delete('/posts/:id', communauteController.deletePost);

// Like / Unlike post (toggle)
router.post('/posts/:id/like', communauteController.toggleLikePost);

// Réponses CRUD
router.post('/posts/:id/reponses', communauteController.createReponse);
router.put('/posts/:postId/reponses/:reponseId', communauteController.updateReponse);
router.delete('/posts/:postId/reponses/:reponseId', communauteController.deleteReponse);
router.put('/posts/:postId/reponses/:reponseId/solution', communauteController.markSolution);

// Upvote / Downvote réponse (toggle)
router.post('/posts/:postId/reponses/:reponseId/upvote', communauteController.toggleUpvoteReponse);

module.exports = router;

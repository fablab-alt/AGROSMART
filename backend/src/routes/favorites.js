const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth');
const {
  getFavorites,
  addToFavorites,
  removeFromFavorites,
  checkFavorite,
  toggleFavorite,
  getFavoritesCount
} = require('../controllers/favoritesController');

// All routes are protected
router.use(authenticate);

router.route('/')
  .get(getFavorites)
  .post(addToFavorites);

router.get('/count', getFavoritesCount);
router.post('/toggle', toggleFavorite);
router.get('/check/:produitId', checkFavorite);
router.delete('/:produitId', removeFromFavorites);

module.exports = router;

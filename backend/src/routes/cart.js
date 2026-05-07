const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth');
const {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  getCartCount
} = require('../controllers/cartController');

// All routes are protected
router.use(authenticate);

router.route('/')
  .get(getCart)
  .delete(clearCart);

router.get('/count', getCartCount);

router.route('/items')
  .post(addToCart);

router.route('/items/:itemId')
  .put(updateCartItem)
  .delete(removeFromCart);

module.exports = router;

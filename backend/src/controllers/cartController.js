const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * @desc    Get user's cart with items
 * @route   GET /api/v1/cart
 * @access  Private
 */
const getCart = async (req, res) => {
  try {
    const userId = req.user.id;

    let cart = await prisma.cart.findUnique({
      where: { userId },
      include: {
        items: {
          include: {
            produit: {
              select: {
                id: true,
                nom: true,
                description: true,
                prix: true,
                unite: true,
                stock: true,
                images: true,
                categorie: true,
                vendeur: {
                  select: {
                    id: true,
                    nom: true,
                    prenoms: true,
                  }
                }
              }
            }
          },
          orderBy: { createdAt: 'desc' }
        }
      }
    });

    // Create cart if doesn't exist
    if (!cart) {
      cart = await prisma.cart.create({
        data: { userId },
        include: { items: [] }
      });
    }

    // Calculate totals
    const totalItems = cart.items.reduce((sum, item) => sum + item.quantite, 0);
    const totalPrice = cart.items.reduce((sum, item) => {
      return sum + (parseFloat(item.produit.prix) * item.quantite);
    }, 0);

    res.status(200).json({
      success: true,
      data: {
        ...cart,
        totalItems,
        totalPrice: totalPrice.toFixed(2)
      }
    });
  } catch (error) {
    logger.error('Error getting cart:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du panier'
    });
  }
};

/**
 * @desc    Add item to cart
 * @route   POST /api/v1/cart/items
 * @access  Private
 */
const addToCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { produitId, quantite = 1 } = req.body;

    if (!produitId) {
      return res.status(400).json({
        success: false,
        error: 'produitId est requis'
      });
    }

    // Check if product exists and has stock
    const produit = await prisma.marketplaceProduit.findUnique({
      where: { id: produitId }
    });

    if (!produit) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    if (produit.stock < quantite) {
      return res.status(400).json({
        success: false,
        error: 'Stock insuffisant'
      });
    }

    // Get or create cart
    let cart = await prisma.cart.findUnique({
      where: { userId }
    });

    if (!cart) {
      cart = await prisma.cart.create({
        data: { userId }
      });
    }

    // Check if item already in cart
    const existingItem = await prisma.cartItem.findUnique({
      where: {
        cartId_produitId: {
          cartId: cart.id,
          produitId
        }
      }
    });

    let cartItem;
    if (existingItem) {
      // Update quantity
      const newQuantite = existingItem.quantite + quantite;
      if (produit.stock < newQuantite) {
        return res.status(400).json({
          success: false,
          error: 'Stock insuffisant pour cette quantité'
        });
      }

      cartItem = await prisma.cartItem.update({
        where: { id: existingItem.id },
        data: { quantite: newQuantite },
        include: { produit: true }
      });
    } else {
      // Create new item
      cartItem = await prisma.cartItem.create({
        data: {
          cartId: cart.id,
          produitId,
          quantite
        },
        include: { produit: true }
      });
    }

    res.status(201).json({
      success: true,
      message: 'Produit ajouté au panier',
      data: cartItem
    });
  } catch (error) {
    logger.error('Error adding to cart:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'ajout au panier'
    });
  }
};

/**
 * @desc    Update cart item quantity
 * @route   PUT /api/v1/cart/items/:itemId
 * @access  Private
 */
const updateCartItem = async (req, res) => {
  try {
    const userId = req.user.id;
    const { itemId } = req.params;
    const { quantite } = req.body;

    if (quantite < 1) {
      return res.status(400).json({
        success: false,
        error: 'La quantité doit être au moins 1'
      });
    }

    // Verify item belongs to user's cart
    const item = await prisma.cartItem.findFirst({
      where: {
        id: itemId,
        cart: { userId }
      },
      include: { produit: true }
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        error: 'Article non trouvé dans votre panier'
      });
    }

    // Check stock
    if (item.produit.stock < quantite) {
      return res.status(400).json({
        success: false,
        error: 'Stock insuffisant'
      });
    }

    const updatedItem = await prisma.cartItem.update({
      where: { id: itemId },
      data: { quantite },
      include: { produit: true }
    });

    res.status(200).json({
      success: true,
      message: 'Quantité mise à jour',
      data: updatedItem
    });
  } catch (error) {
    logger.error('Error updating cart item:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour'
    });
  }
};

/**
 * @desc    Remove item from cart
 * @route   DELETE /api/v1/cart/items/:itemId
 * @access  Private
 */
const removeFromCart = async (req, res) => {
  try {
    const userId = req.user.id;
    const { itemId } = req.params;

    // Verify item belongs to user's cart
    const item = await prisma.cartItem.findFirst({
      where: {
        id: itemId,
        cart: { userId }
      }
    });

    if (!item) {
      return res.status(404).json({
        success: false,
        error: 'Article non trouvé dans votre panier'
      });
    }

    await prisma.cartItem.delete({
      where: { id: itemId }
    });

    res.status(200).json({
      success: true,
      message: 'Article retiré du panier'
    });
  } catch (error) {
    logger.error('Error removing from cart:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression'
    });
  }
};

/**
 * @desc    Clear entire cart
 * @route   DELETE /api/v1/cart
 * @access  Private
 */
const clearCart = async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await prisma.cart.findUnique({
      where: { userId }
    });

    if (cart) {
      await prisma.cartItem.deleteMany({
        where: { cartId: cart.id }
      });
    }

    res.status(200).json({
      success: true,
      message: 'Panier vidé'
    });
  } catch (error) {
    logger.error('Error clearing cart:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors du vidage du panier'
    });
  }
};

/**
 * @desc    Get cart count (for badge)
 * @route   GET /api/v1/cart/count
 * @access  Private
 */
const getCartCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const cart = await prisma.cart.findUnique({
      where: { userId },
      include: {
        items: {
          select: { quantite: true }
        }
      }
    });

    const count = cart?.items.reduce((sum, item) => sum + item.quantite, 0) || 0;

    res.status(200).json({
      success: true,
      data: { count }
    });
  } catch (error) {
    logger.error('Error getting cart count:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur'
    });
  }
};

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
  getCartCount
};

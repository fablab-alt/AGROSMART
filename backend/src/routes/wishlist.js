/**
 * Routes pour la wishlist (liste de souhaits)
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth');
const prisma = require('../config/prisma');
const logger = require('../utils/logger');

// Toutes les routes nécessitent l'authentification
router.use(authenticate);

/**
 * @route   GET /api/v1/wishlist
 * @desc    Récupérer la wishlist de l'utilisateur
 * @access  Private
 */
router.get('/', async (req, res) => {
  try {
    const userId = req.user.id;

    const wishlist = await prisma.wishlist.findUnique({
      where: { userId },
      include: {
        items: {
          include: {
            produit: {
              select: {
                id: true,
                nom: true,
                prix: true,
                images: true,
                stock: true,
              },
            },
          },
          orderBy: { addedAt: 'desc' },
        },
      },
    });

    if (!wishlist) {
      const newWishlist = await prisma.wishlist.create({
        data: { userId },
      });

      return res.json({
        success: true,
        data: {
          id: newWishlist.id,
          items: [],
          createdAt: newWishlist.createdAt,
        },
      });
    }

    const formattedItems = wishlist.items.map(item => ({
      id: item.id,
      produitId: item.produitId,
      nom: item.produit.nom,
      prix: item.produit.prix,
      images: item.produit.images,
      disponible: item.produit.stock > 0,
      addedAt: item.addedAt,
    }));

    res.json({
      success: true,
      data: {
        id: wishlist.id,
        items: formattedItems,
        createdAt: wishlist.createdAt,
        updatedAt: wishlist.updatedAt,
      },
    });
  } catch (error) {
    logger.error('Erreur récupération wishlist:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération de la wishlist' });
  }
});

/**
 * @route   POST /api/v1/wishlist
 * @desc    Ajouter un produit à la wishlist
 * @access  Private
 */
router.post('/', async (req, res) => {
  try {
    const { produitId } = req.body;
    const userId = req.user.id;

    if (!produitId) {
      return res.status(400).json({ success: false, message: 'produitId est requis' });
    }

    // Vérifier que le produit existe
    const product = await prisma.marketplaceProduit.findUnique({
      where: { id: produitId },
    });

    if (!product) {
      return res.status(404).json({ success: false, message: 'Produit non trouvé' });
    }

    // Récupérer ou créer la wishlist
    let wishlist = await prisma.wishlist.findUnique({
      where: { userId },
    });

    if (!wishlist) {
      wishlist = await prisma.wishlist.create({
        data: { userId },
      });
    }

    // Vérifier si le produit est déjà dans la wishlist
    const existingItem = await prisma.wishlistItem.findUnique({
      where: {
        wishlistId_produitId: { wishlistId: wishlist.id, produitId },
      },
    });

    if (existingItem) {
      return res.status(409).json({
        success: false,
        message: 'Ce produit est déjà dans vos favoris'
      });
    }

    const item = await prisma.wishlistItem.create({
      data: {
        wishlistId: wishlist.id,
        produitId,
      },
    });

    res.status(201).json({
      success: true,
      data: {
        id: item.id,
        produitId: item.produitId,
        nom: product.nom,
        prix: product.prix,
        images: product.images,
        disponible: product.stock > 0,
        addedAt: item.addedAt,
      },
    });
  } catch (error) {
    logger.error('Erreur ajout wishlist:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de l\'ajout à la wishlist' });
  }
});

/**
 * @route   GET /api/v1/wishlist/check/:produitId
 * @desc    Vérifier si un produit est dans la wishlist
 * @access  Private
 */
router.get('/check/:produitId', async (req, res) => {
  try {
    const { produitId } = req.params;
    const userId = req.user.id;

    const wishlist = await prisma.wishlist.findUnique({
      where: { userId },
    });

    if (!wishlist) {
      return res.json({ success: true, inWishlist: false });
    }

    const item = await prisma.wishlistItem.findUnique({
      where: {
        wishlistId_produitId: { wishlistId: wishlist.id, produitId },
      },
    });

    res.json({ success: true, inWishlist: !!item });
  } catch (error) {
    logger.error('Erreur vérification wishlist:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la vérification' });
  }
});

/**
 * @route   DELETE /api/v1/wishlist/:produitId
 * @desc    Retirer un produit de la wishlist
 * @access  Private
 */
router.delete('/:produitId', async (req, res) => {
  try {
    const { produitId } = req.params;
    const userId = req.user.id;

    const wishlist = await prisma.wishlist.findUnique({
      where: { userId },
    });

    if (!wishlist) {
      return res.status(404).json({ success: false, message: 'Wishlist non trouvée' });
    }

    const item = await prisma.wishlistItem.findUnique({
      where: {
        wishlistId_produitId: { wishlistId: wishlist.id, produitId },
      },
    });

    if (!item) {
      return res.status(404).json({ success: false, message: 'Produit non trouvé dans la wishlist' });
    }

    await prisma.wishlistItem.delete({ where: { id: item.id } });
    res.status(204).send();
  } catch (error) {
    logger.error('Erreur suppression wishlist:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression' });
  }
});

/**
 * @route   DELETE /api/v1/wishlist
 * @desc    Vider la wishlist
 * @access  Private
 */
router.delete('/', async (req, res) => {
  try {
    const userId = req.user.id;

    const wishlist = await prisma.wishlist.findUnique({
      where: { userId },
    });

    if (!wishlist) {
      return res.status(404).json({ success: false, message: 'Wishlist non trouvée' });
    }

    await prisma.wishlistItem.deleteMany({
      where: { wishlistId: wishlist.id },
    });

    res.status(204).send();
  } catch (error) {
    logger.error('Erreur vidage wishlist:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors du vidage de la wishlist' });
  }
});

module.exports = router;

const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');

const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

/**
 * @desc    Get user's favorites
 * @route   GET /api/v1/favorites
 * @access  Private
 */
const getFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    const [favorites, total] = await Promise.all([
      prisma.favorite.findMany({
        where: { userId },
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
              actif: true,
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
        orderBy: { createdAt: 'desc' },
        skip: parseInt(skip),
        take: parseInt(limit)
      }),
      prisma.favorite.count({ where: { userId } })
    ]);

    res.status(200).json({
      success: true,
      data: favorites,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    logger.error('Error getting favorites:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des favoris'
    });
  }
};

/**
 * @desc    Add product to favorites
 * @route   POST /api/v1/favorites
 * @access  Private
 */
const addToFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { produitId } = req.body;

    if (!produitId) {
      return res.status(400).json({
        success: false,
        error: 'produitId est requis'
      });
    }

    // Check if product exists
    const produit = await prisma.marketplaceProduit.findUnique({
      where: { id: produitId }
    });

    if (!produit) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    // Check if already in favorites
    const existing = await prisma.favorite.findUnique({
      where: {
        userId_produitId: {
          userId,
          produitId
        }
      }
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        error: 'Ce produit est déjà dans vos favoris'
      });
    }

    const favorite = await prisma.favorite.create({
      data: {
        userId,
        produitId
      },
      include: {
        produit: {
          select: {
            id: true,
            nom: true,
            prix: true,
            images: true
          }
        }
      }
    });

    res.status(201).json({
      success: true,
      message: 'Produit ajouté aux favoris',
      data: favorite
    });
  } catch (error) {
    logger.error('Error adding to favorites:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'ajout aux favoris'
    });
  }
};

/**
 * @desc    Remove product from favorites
 * @route   DELETE /api/v1/favorites/:produitId
 * @access  Private
 */
const removeFromFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { produitId } = req.params;

    const favorite = await prisma.favorite.findUnique({
      where: {
        userId_produitId: {
          userId,
          produitId
        }
      }
    });

    if (!favorite) {
      return res.status(404).json({
        success: false,
        error: 'Ce produit n\'est pas dans vos favoris'
      });
    }

    await prisma.favorite.delete({
      where: { id: favorite.id }
    });

    res.status(200).json({
      success: true,
      message: 'Produit retiré des favoris'
    });
  } catch (error) {
    logger.error('Error removing from favorites:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression'
    });
  }
};

/**
 * @desc    Check if product is in favorites
 * @route   GET /api/v1/favorites/check/:produitId
 * @access  Private
 */
const checkFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { produitId } = req.params;

    const favorite = await prisma.favorite.findUnique({
      where: {
        userId_produitId: {
          userId,
          produitId
        }
      }
    });

    res.status(200).json({
      success: true,
      data: { isFavorite: !!favorite }
    });
  } catch (error) {
    logger.error('Error checking favorite:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur'
    });
  }
};

/**
 * @desc    Toggle favorite (add if not exists, remove if exists)
 * @route   POST /api/v1/favorites/toggle
 * @access  Private
 */
const toggleFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { produitId } = req.body;

    if (!produitId) {
      return res.status(400).json({
        success: false,
        error: 'produitId est requis'
      });
    }

    const existing = await prisma.favorite.findUnique({
      where: {
        userId_produitId: {
          userId,
          produitId
        }
      }
    });

    if (existing) {
      // Remove from favorites
      await prisma.favorite.delete({
        where: { id: existing.id }
      });

      return res.status(200).json({
        success: true,
        message: 'Retiré des favoris',
        data: { isFavorite: false }
      });
    } else {
      // Check if product exists
      const produit = await prisma.marketplaceProduit.findUnique({
        where: { id: produitId }
      });

      if (!produit) {
        return res.status(404).json({
          success: false,
          error: 'Produit non trouvé'
        });
      }

      // Add to favorites
      await prisma.favorite.create({
        data: {
          userId,
          produitId
        }
      });

      return res.status(201).json({
        success: true,
        message: 'Ajouté aux favoris',
        data: { isFavorite: true }
      });
    }
  } catch (error) {
    logger.error('Error toggling favorite:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur'
    });
  }
};

/**
 * @desc    Get favorites count
 * @route   GET /api/v1/favorites/count
 * @access  Private
 */
const getFavoritesCount = async (req, res) => {
  try {
    const userId = req.user.id;

    const count = await prisma.favorite.count({
      where: { userId }
    });

    res.status(200).json({
      success: true,
      data: { count }
    });
  } catch (error) {
    logger.error('Error getting favorites count:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur'
    });
  }
};

module.exports = {
  getFavorites,
  addToFavorites,
  removeFromFavorites,
  checkFavorite,
  toggleFavorite,
  getFavoritesCount
};

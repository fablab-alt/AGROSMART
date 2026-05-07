/**
 * Contrôleur pour la gestion des stocks agricoles
 * AgroSmart - Système Agricole Intelligent
 */

const { PrismaClient } = require('@prisma/client');
const logger = require('../utils/logger');
const { ApiError } = require('../middlewares/errorHandler');

const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });

/**
 * @swagger
 * tags:
 *   name: Stocks
 *   description: Gestion des stocks agricoles (semences, engrais, récoltes, etc.)
 */

/**
 * @swagger
 * /api/stocks:
 *   get:
 *     summary: Récupère la liste des stocks de l'utilisateur
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: categorie
 *         schema:
 *           type: string
 *           enum: [SEMENCES, ENGRAIS, PESTICIDES, HERBICIDES, OUTILS, RECOLTES, AUTRES]
 *       - in: query
 *         name: parcelleId
 *         schema:
 *           type: string
 *       - in: query
 *         name: estActif
 *         schema:
 *           type: boolean
 *     responses:
 *       200:
 *         description: Liste des stocks récupérée avec succès
 */
const getStocks = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { categorie, parcelleId, estActif } = req.query;

    const where = {
      userId,
      ...(categorie && { categorie }),
      ...(parcelleId && { parcelleId }),
      ...(estActif !== undefined && { estActif: estActif === 'true' }),
    };

    const stocks = await prisma.stock.findMany({
      where,
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true,
          },
        },
        _count: {
          select: {
            mouvements: true,
            alertesStock: { where: { estLue: false } },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Vérifier les stocks bas et générer des alertes si nécessaire
    for (const stock of stocks) {
      if (stock.quantite <= stock.seuilAlerte && stock.estActif) {
        // Vérifier si une alerte existe déjà
        const alerteExistante = await prisma.alerteStock.findFirst({
          where: {
            stockId: stock.id,
            typeAlerte: stock.quantite === 0 ? 'STOCK_EPUISE' : 'STOCK_BAS',
            estLue: false,
          },
        });

        if (!alerteExistante) {
          await prisma.alerteStock.create({
            data: {
              stockId: stock.id,
              typeAlerte: stock.quantite === 0 ? 'STOCK_EPUISE' : 'STOCK_BAS',
              message:
                stock.quantite === 0
                  ? `Le stock "${stock.nom}" est épuisé.`
                  : `Le stock "${stock.nom}" est en dessous du seuil d'alerte (${stock.quantite} ${stock.unite}).`,
            },
          });
        }
      }
    }

    logger.info('[Stocks] Liste récupérée', { userId, count: stocks.length });
    res.json({
      success: true,
      data: stocks,
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la récupération:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/{id}:
 *   get:
 *     summary: Récupère un stock par son ID
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Stock récupéré avec succès
 */
const getStockById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const stock = await prisma.stock.findFirst({
      where: { id, userId },
      include: {
        parcelle: true,
        mouvements: {
          orderBy: { createdAt: 'desc' },
          take: 20,
        },
        alertesStock: {
          where: { estLue: false },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!stock) {
      throw new ApiError(404, 'Stock non trouvé');
    }

    logger.info('[Stocks] Stock récupéré', { stockId: id, userId });
    res.json({
      success: true,
      data: stock,
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la récupération du stock:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks:
 *   post:
 *     summary: Crée un nouveau stock
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - nom
 *               - categorie
 *               - type
 *               - quantite
 *               - unite
 *               - seuilAlerte
 *             properties:
 *               nom:
 *                 type: string
 *               categorie:
 *                 type: string
 *                 enum: [SEMENCES, ENGRAIS, PESTICIDES, HERBICIDES, OUTILS, RECOLTES, AUTRES]
 *               type:
 *                 type: string
 *               quantite:
 *                 type: number
 *               unite:
 *                 type: string
 *               seuilAlerte:
 *                 type: number
 *               parcelleId:
 *                 type: string
 *               prixUnitaire:
 *                 type: number
 *               dateAchat:
 *                 type: string
 *                 format: date
 *               dateExpiration:
 *                 type: string
 *                 format: date
 *               fournisseur:
 *                 type: string
 *               localisation:
 *                 type: string
 *               notes:
 *                 type: string
 *     responses:
 *       201:
 *         description: Stock créé avec succès
 */
const createStock = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      nom,
      categorie,
      type,
      quantite,
      unite,
      seuilAlerte,
      parcelleId,
      prixUnitaire,
      dateAchat,
      dateExpiration,
      fournisseur,
      localisation,
      notes,
    } = req.body;

    // Vérifier que la parcelle appartient à l'utilisateur si spécifiée
    if (parcelleId) {
      const parcelle = await prisma.parcelle.findFirst({
        where: { id: parcelleId, userId },
      });
      if (!parcelle) {
        throw new ApiError(404, 'Parcelle non trouvée');
      }
    }

    const stock = await prisma.stock.create({
      data: {
        userId,
        nom,
        categorie,
        type,
        quantite,
        unite,
        seuilAlerte,
        parcelleId,
        prixUnitaire,
        dateAchat: dateAchat ? new Date(dateAchat) : null,
        dateExpiration: dateExpiration ? new Date(dateExpiration) : null,
        fournisseur,
        localisation,
        notes,
      },
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    // Créer un mouvement d'entrée initial
    await prisma.mouvementStock.create({
      data: {
        stockId: stock.id,
        typeMouvement: 'ENTREE',
        quantite,
        quantiteAvant: 0,
        quantiteApres: quantite,
        motif: 'Création du stock',
      },
    });

    logger.info('[Stocks] Stock créé', { stockId: stock.id, userId });
    res.status(201).json({
      success: true,
      data: stock,
      message: 'Stock créé avec succès',
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la création:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/{id}:
 *   put:
 *     summary: Met à jour un stock
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *     responses:
 *       200:
 *         description: Stock mis à jour avec succès
 */
const updateStock = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const updateData = req.body;

    // Vérifier que le stock appartient à l'utilisateur
    const stockExistant = await prisma.stock.findFirst({
      where: { id, userId },
    });

    if (!stockExistant) {
      throw new ApiError(404, 'Stock non trouvé');
    }

    // Vérifier la parcelle si elle est mise à jour
    if (updateData.parcelleId) {
      const parcelle = await prisma.parcelle.findFirst({
        where: { id: updateData.parcelleId, userId },
      });
      if (!parcelle) {
        throw new ApiError(404, 'Parcelle non trouvée');
      }
    }

    // Convertir les dates si nécessaire
    if (updateData.dateAchat) {
      updateData.dateAchat = new Date(updateData.dateAchat);
    }
    if (updateData.dateExpiration) {
      updateData.dateExpiration = new Date(updateData.dateExpiration);
    }

    const stock = await prisma.stock.update({
      where: { id },
      data: updateData,
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true,
          },
        },
      },
    });

    logger.info('[Stocks] Stock mis à jour', { stockId: id, userId });
    res.json({
      success: true,
      data: stock,
      message: 'Stock mis à jour avec succès',
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la mise à jour:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/{id}/mouvement:
 *   post:
 *     summary: Enregistre un mouvement de stock (entrée/sortie)
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - typeMouvement
 *               - quantite
 *             properties:
 *               typeMouvement:
 *                 type: string
 *                 enum: [ENTREE, SORTIE, AJUSTEMENT, PERTE]
 *               quantite:
 *                 type: number
 *               motif:
 *                 type: string
 *               reference:
 *                 type: string
 *     responses:
 *       200:
 *         description: Mouvement enregistré avec succès
 */
const addMouvement = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const { typeMouvement, quantite, motif, reference } = req.body;

    // Vérifier que le stock appartient à l'utilisateur
    const stock = await prisma.stock.findFirst({
      where: { id, userId },
    });

    if (!stock) {
      throw new ApiError(404, 'Stock non trouvé');
    }

    // Calculer la nouvelle quantité
    let nouvelleQuantite = parseFloat(stock.quantite);
    const quantiteMouvement = parseFloat(quantite);

    switch (typeMouvement) {
      case 'ENTREE':
        nouvelleQuantite += quantiteMouvement;
        break;
      case 'SORTIE':
      case 'PERTE':
        nouvelleQuantite -= quantiteMouvement;
        if (nouvelleQuantite < 0) {
          throw new ApiError(400, 'Quantité insuffisante en stock');
        }
        break;
      case 'AJUSTEMENT':
        nouvelleQuantite = quantiteMouvement;
        break;
    }

    // Créer le mouvement et mettre à jour le stock dans une transaction
    const [mouvement, stockMisAJour] = await prisma.$transaction([
      prisma.mouvementStock.create({
        data: {
          stockId: id,
          typeMouvement,
          quantite: quantiteMouvement,
          quantiteAvant: stock.quantite,
          quantiteApres: nouvelleQuantite,
          motif,
          reference,
        },
      }),
      prisma.stock.update({
        where: { id },
        data: { quantite: nouvelleQuantite },
        include: {
          parcelle: {
            select: {
              id: true,
              nom: true,
            },
          },
        },
      }),
    ]);

    // Vérifier si on doit créer une alerte
    if (nouvelleQuantite <= stock.seuilAlerte) {
      const alerteExistante = await prisma.alerteStock.findFirst({
        where: {
          stockId: id,
          typeAlerte: nouvelleQuantite === 0 ? 'STOCK_EPUISE' : 'STOCK_BAS',
          estLue: false,
        },
      });

      if (!alerteExistante) {
        await prisma.alerteStock.create({
          data: {
            stockId: id,
            typeAlerte: nouvelleQuantite === 0 ? 'STOCK_EPUISE' : 'STOCK_BAS',
            message:
              nouvelleQuantite === 0
                ? `Le stock "${stock.nom}" est épuisé.`
                : `Le stock "${stock.nom}" est en dessous du seuil d'alerte (${nouvelleQuantite} ${stock.unite}).`,
          },
        });
      }
    }

    logger.info('[Stocks] Mouvement enregistré', {
      stockId: id,
      typeMouvement,
      quantite: quantiteMouvement,
    });

    res.json({
      success: true,
      data: {
        mouvement,
        stock: stockMisAJour,
      },
      message: 'Mouvement enregistré avec succès',
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de l\'enregistrement du mouvement:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/{id}/alertes:
 *   get:
 *     summary: Récupère les alertes d'un stock
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Alertes récupérées avec succès
 */
const getAlertes = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que le stock appartient à l'utilisateur
    const stock = await prisma.stock.findFirst({
      where: { id, userId },
    });

    if (!stock) {
      throw new ApiError(404, 'Stock non trouvé');
    }

    const alertes = await prisma.alerteStock.findMany({
      where: { stockId: id },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      data: alertes,
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la récupération des alertes:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/{id}/alertes/{alerteId}/marquer-lue:
 *   patch:
 *     summary: Marque une alerte comme lue
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: alerteId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Alerte marquée comme lue
 */
const marquerAlerteLue = async (req, res, next) => {
  try {
    const { id, alerteId } = req.params;
    const userId = req.user.id;

    // Vérifier que le stock appartient à l'utilisateur
    const stock = await prisma.stock.findFirst({
      where: { id, userId },
    });

    if (!stock) {
      throw new ApiError(404, 'Stock non trouvé');
    }

    const alerte = await prisma.alerteStock.update({
      where: { id: alerteId },
      data: { estLue: true },
    });

    logger.info('[Stocks] Alerte marquée comme lue', { alerteId, userId });
    res.json({
      success: true,
      data: alerte,
      message: 'Alerte marquée comme lue',
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors du marquage de l\'alerte:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/{id}:
 *   delete:
 *     summary: Désactive un stock (soft delete)
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Stock désactivé avec succès
 */
const deleteStock = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Vérifier que le stock appartient à l'utilisateur
    const stock = await prisma.stock.findFirst({
      where: { id, userId },
    });

    if (!stock) {
      throw new ApiError(404, 'Stock non trouvé');
    }

    await prisma.stock.update({
      where: { id },
      data: { estActif: false },
    });

    logger.info('[Stocks] Stock désactivé', { stockId: id, userId });
    res.json({
      success: true,
      message: 'Stock désactivé avec succès',
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la suppression:', error);
    next(error);
  }
};

/**
 * @swagger
 * /api/stocks/statistiques:
 *   get:
 *     summary: Récupère les statistiques des stocks de l'utilisateur
 *     tags: [Stocks]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques récupérées avec succès
 */
const getStatistiques = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const stats = await prisma.stock.groupBy({
      by: ['categorie'],
      where: {
        userId,
        estActif: true,
      },
      _count: true,
      _sum: {
        quantite: true,
      },
    });

    const stocksBas = await prisma.stock.count({
      where: {
        userId,
        estActif: true,
        quantite: {
          lte: prisma.stock.fields.seuilAlerte,
        },
      },
    });

    const alertesNonLues = await prisma.alerteStock.count({
      where: {
        stock: {
          userId,
        },
        estLue: false,
      },
    });

    const valeurTotale = await prisma.stock.aggregate({
      where: {
        userId,
        estActif: true,
        prixUnitaire: {
          not: null,
        },
      },
      _sum: {
        quantite: true,
      },
    });

    res.json({
      success: true,
      data: {
        parCategorie: stats,
        stocksBas,
        alertesNonLues,
        valeurTotale: valeurTotale._sum.quantite || 0,
      },
    });
  } catch (error) {
    logger.error('[Stocks] Erreur lors de la récupération des statistiques:', error);
    next(error);
  }
};

module.exports = {
  getStocks,
  getStockById,
  createStock,
  updateStock,
  addMouvement,
  getAlertes,
  marquerAlerteLue,
  deleteStock,
  getStatistiques,
};

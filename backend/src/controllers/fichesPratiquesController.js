/**
 * Contrôleur Fiches Pratiques - Bibliothèque Agricole
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Récupérer toutes les fiches pratiques avec pagination et filtres
 */
exports.getAll = async (req, res) => {
  try {
    const { page = 1, limit = 20, categorie, culture } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const where = {};
    if (categorie) where.categorie = categorie;
    if (culture) where.contenu = { contains: culture };

    const [fiches, total] = await Promise.all([
      prisma.fichePratique.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { createdAt: 'desc' }
      }),
      prisma.fichePratique.count({ where })
    ]);

    res.json({
      success: true,
      data: fiches,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    logger.error('Erreur récupération fiches pratiques:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/**
 * Rechercher dans les fiches pratiques
 */
exports.search = async (req, res) => {
  try {
    const { q, categorie } = req.query;
    if (!q) {
      return res.status(400).json({ success: false, message: 'Paramètre de recherche requis' });
    }

    const where = {
      OR: [
        { titre: { contains: q } },
        { contenu: { contains: q } },
        { categorie: { contains: q } }
      ]
    };
    if (categorie) where.categorie = categorie;

    const fiches = await prisma.fichePratique.findMany({
      where,
      take: 50,
      orderBy: { createdAt: 'desc' }
    });

    res.json({ success: true, data: fiches });
  } catch (error) {
    logger.error('Erreur recherche fiches:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/**
 * Récupérer les catégories distinctes
 */
exports.getCategories = async (req, res) => {
  try {
    const fiches = await prisma.fichePratique.findMany({
      select: { categorie: true },
      distinct: ['categorie']
    });

    const categories = fiches.map(f => f.categorie).filter(Boolean);
    res.json({ success: true, data: categories });
  } catch (error) {
    logger.error('Erreur catégories fiches:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/**
 * Récupérer une fiche par ID
 */
exports.getById = async (req, res) => {
  try {
    const fiche = await prisma.fichePratique.findUnique({
      where: { id: req.params.id }
    });

    if (!fiche) {
      return res.status(404).json({ success: false, message: 'Fiche non trouvée' });
    }

    res.json({ success: true, data: fiche });
  } catch (error) {
    logger.error('Erreur récupération fiche:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/**
 * Créer une fiche pratique
 */
exports.create = async (req, res) => {
  try {
    const { titre, categorie, contenu, fichierUrl } = req.body;

    if (!titre || !contenu) {
      return res.status(400).json({ success: false, message: 'Titre et contenu requis' });
    }

    const fiche = await prisma.fichePratique.create({
      data: { titre, categorie, contenu, fichierUrl }
    });

    res.status(201).json({ success: true, data: fiche });
  } catch (error) {
    logger.error('Erreur création fiche:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/**
 * Mettre à jour une fiche pratique
 */
exports.update = async (req, res) => {
  try {
    const { titre, categorie, contenu, fichierUrl } = req.body;

    const fiche = await prisma.fichePratique.update({
      where: { id: req.params.id },
      data: { titre, categorie, contenu, fichierUrl }
    });

    res.json({ success: true, data: fiche });
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Fiche non trouvée' });
    }
    logger.error('Erreur mise à jour fiche:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

/**
 * Supprimer une fiche pratique
 */
exports.remove = async (req, res) => {
  try {
    await prisma.fichePratique.delete({
      where: { id: req.params.id }
    });

    res.json({ success: true, message: 'Fiche supprimée' });
  } catch (error) {
    if (error.code === 'P2025') {
      return res.status(404).json({ success: false, message: 'Fiche non trouvée' });
    }
    logger.error('Erreur suppression fiche:', error);
    res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};

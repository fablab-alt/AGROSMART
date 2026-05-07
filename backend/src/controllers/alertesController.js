/**
 * Contrôleur des alertes
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');
const notificationService = require('../services/notificationService');

/**
 * Obtenir toutes les alertes
 */
exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const { categorie, niveau, statut } = req.query;

    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    if (categorie) where.type = categorie; // Schema uses 'type', not 'categorie'
    if (niveau) where.niveau = niveau;
    if (statut) where.statut = statut;

    const [alertes, total] = await Promise.all([
      prisma.alerte.findMany({
        where,
        // Removed include parcelle as it doesn't exist in schema
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset
      }),
      prisma.alerte.count({ where })
    ]);

    // Map 'type' to 'categorie' and 'statut' to 'status' for frontend compatibility
    const mappedAlertes = alertes.map(alerte => ({
      ...alerte,
      categorie: alerte.type,
      status: alerte.statut,
      lu_at: alerte.statut === 'LUE' || alerte.statut === 'TRAITEE' ? alerte.createdAt : null,
      created_at: alerte.createdAt
    }));

    res.json({
      success: true,
      data: mappedAlertes,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les alertes non lues
 */
exports.getUnread = async (req, res, next) => {
  try {
    const where = {
      statut: 'NOUVELLE'
    };

    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    const alertes = await prisma.alerte.findMany({
      where,
      orderBy: [
        { niveau: 'desc' },
        { createdAt: 'desc' }
      ]
    });

    // Map 'type' to 'categorie' and 'statut' to 'status' for frontend compatibility
    const mappedAlertes = alertes.map(alerte => ({
      ...alerte,
      categorie: alerte.type,
      status: alerte.statut,
      lu_at: null,
      created_at: alerte.createdAt
    }));

    res.json({
      success: true,
      data: mappedAlertes,
      count: mappedAlertes.length
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Statistiques des alertes
 */
exports.getStats = async (req, res, next) => {
  try {
    const now = new Date();
    const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);

    const [total, nonLues, statutStats, niveauStats, last24h, typeStats] = await Promise.all([
      prisma.alerte.count(),
      prisma.alerte.count({ where: { statut: 'NOUVELLE' } }),
      prisma.alerte.groupBy({ by: ['statut'], _count: true }),
      prisma.alerte.groupBy({ by: ['niveau'], _count: true }),
      prisma.alerte.count({ where: { createdAt: { gt: oneDayAgo } } }),
      prisma.alerte.groupBy({
        by: ['type'], // Schema uses 'type'
        where: { createdAt: { gt: sevenDaysAgo } },
        _count: true
      })
    ]);

    const nouvelles = statutStats.find(s => s.statut === 'NOUVELLE')?._count || 0;
    const critiques = niveauStats.find(n => n.niveau === 'CRITIQUE')?._count || 0;
    const warning = niveauStats.find(n => n.niveau === 'IMPORTANT')?._count || 0; // Schema uses IMPORTANT, not AVERTISSEMENT
    const info = niveauStats.find(n => n.niveau === 'INFO')?._count || 0; // Schema uses INFO, not INFORMATION

    res.json({
      success: true,
      data: {
        total,
        non_lues: nonLues,
        nouvelles,
        critiques,
        warning,
        info,
        dernieres_24h: last24h,
        par_categorie: typeStats.map(t => ({
          categorie: t.type,
          count: t._count
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Créer une alerte manuellement
 */
exports.create = async (req, res, next) => {
  try {
    const { categorie, niveau, titre, message, parcelle_id, destinataires } = req.body;

    // Si des destinataires spécifiques sont fournis
    if (destinataires && Array.isArray(destinataires)) {
      const alertes = [];
      for (const userId of destinataires) {
        const alerte = await prisma.alerte.create({
          data: {
            userId,
            // parcelleId: parcelle_id, // Removed as per schema
            type: categorie || 'SYSTEME', // Schema uses 'type'
            niveau: niveau || 'INFO',
            titre,
            message
          }
        });
        alertes.push(alerte);

        // Envoyer notification
        await notificationService.sendAlert(userId, alerte);
      }

      return res.status(201).json({
        success: true,
        message: `${alertes.length} alertes créées`,
        data: alertes
      });
    }

    // Sinon, créer pour le propriétaire de la parcelle
    let userId = req.user.id;
    if (parcelle_id) {
      const parcelle = await prisma.parcelle.findUnique({
        where: { id: parcelle_id },
        select: { userId: true }
      });
      if (parcelle) {
        userId = parcelle.userId;
      }
    }

    const alerte = await prisma.alerte.create({
      data: {
        userId,
        // parcelleId: parcelle_id, // Removed
        type: categorie || 'SYSTEME', // Schema uses 'type'
        niveau: niveau || 'INFO',
        titre,
        message
      }
    });

    // Envoyer notification
    await notificationService.sendAlert(userId, alerte);

    // Émettre via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.to(`user_${userId}`).emit('nouvelle_alerte', alerte);
    }

    logger.audit('Création alerte manuelle', { createdBy: req.user.id, alerteId: alerte.id });

    res.status(201).json({
      success: true,
      message: 'Alerte créée',
      data: alerte
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir une alerte par son ID
 */
exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const alerte = await prisma.alerte.findUnique({
      where: { id },
      // include: { parcelle: ... } // Removed
    });

    if (!alerte) {
      throw errors.notFound('Alerte non trouvée');
    }

    res.json({
      success: true,
      data: alerte
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Marquer une alerte comme lue
 */
exports.markAsRead = async (req, res, next) => {
  try {
    const { id } = req.params;

    const alerte = await prisma.alerte.update({
      where: { id },
      data: { statut: 'LUE' } // Changed from luAt: new Date()
    });

    if (!alerte) {
      throw errors.notFound('Alerte non trouvée');
    }

    res.json({
      success: true,
      message: 'Alerte marquée comme lue',
      data: alerte
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Résoudre une alerte
 */
exports.resolve = async (req, res, next) => {
  try {
    const { id } = req.params;
    // const { notes } = req.body; // Unused in schema

    const alerte = await prisma.alerte.update({
      where: { id },
      data: {
        statut: 'TRAITEE'
        // traiteAt, traitePar, commentaireTraitement removed
      }
    });

    if (!alerte) {
      throw errors.notFound('Alerte non trouvée');
    }

    logger.audit('Résolution alerte', { userId: req.user.id, alerteId: id });

    res.json({
      success: true,
      message: 'Alerte résolue',
      data: alerte
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Marquer toutes les alertes comme lues
 */
exports.markAllAsRead = async (req, res, next) => {
  try {
    const where = { statut: 'NOUVELLE' };

    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    const { count } = await prisma.alerte.updateMany({
      where,
      data: { statut: 'LUE' }
    });

    res.json({
      success: true,
      message: `${count} alertes marquées comme lues`
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Supprimer une alerte
 */
exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;

    const deleted = await prisma.alerte.delete({
      where: { id }
    });

    if (!deleted) {
      throw errors.notFound('Alerte non trouvée');
    }

    logger.audit('Suppression alerte', { userId: req.user.id, alerteId: id });

    res.json({
      success: true,
      message: 'Alerte supprimée'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Envoyer une alerte de test
 */
exports.sendTest = async (req, res, next) => {
  try {
    const { categorie = 'SYSTEME', niveau = 'INFO', destinataire_id } = req.body;
    const userId = destinataire_id || req.user.id;

    const alerte = await prisma.alerte.create({
      data: {
        userId,
        type: categorie, // Uses 'type'
        niveau: niveau.toUpperCase(),
        titre: 'Alerte de test',
        message: 'Ceci est une alerte de test du système AgroSmart'
      }
    });

    // Envoyer les notifications
    await notificationService.sendAlert(userId, alerte);

    // Émettre via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.to(`user_${userId}`).emit('nouvelle_alerte', alerte);
    }

    res.json({
      success: true,
      message: 'Alerte de test envoyée',
      data: alerte
    });
  } catch (error) {
    next(error);
  }
};

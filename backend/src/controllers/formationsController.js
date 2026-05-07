/**
 * Contrôleur des Formations
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');

/* ========== FORMATIONS ========== */

exports.getAllFormations = async (req, res, next) => {
  try {
    const { type, categorie, langue } = req.query;
    const userId = req.user.id;

    const where = {
      active: true
    };
    if (type) where.type = type;
    if (categorie) where.categorie = categorie;
    if (langue) where.langue = langue;

    const formations = await prisma.formation.findMany({
      where,
      include: {
        _count: {
          select: { progressions: true } // Relation name in Formation model
        },
        progressions: { // Relation name in Formation model
          where: { userId },
          select: {
            progression: true,
            complete: true
          },
          take: 1
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const data = formations.map(f => ({
      ...f,
      nb_inscrits: f._count.progressions,
      progression: f.progressions.length > 0 ? f.progressions[0].progression : null,
      complete: f.progressions.length > 0 ? f.progressions[0].complete : null,
      progressions: undefined, // Cleanup
      _count: undefined // Cleanup
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.getFormationById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const formation = await prisma.formation.findUnique({
      where: { id }
    });

    if (!formation) {
      throw errors.notFound('Formation non trouvée');
    }

    let progression = null;
    if (req.user) {
      const userFormation = await prisma.progressionFormation.findFirst({
        where: { userId: req.user.id, formationId: id }
      });
      progression = userFormation || null;
    }

    // Increment views (Maintenant supporté !)
    await prisma.formation.update({
      where: { id },
      data: { vues: { increment: 1 } }
    });

    res.json({
      success: true,
      data: {
        ...formation,
        progression
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.createFormation = async (req, res, next) => {
  try {
    const { titre, description, type, categorie, url, duree_minutes, langue, cultures_id } = req.body;

    const formation = await prisma.formation.create({
      data: {
        titre,
        description,
        type,
        categorie,
        url,
        dureeMinutes: duree_minutes,
        langue,
        culturesId: cultures_id // Assuming simple field match, check schema if relation needed
      }
    });

    logger.audit('Création formation', { userId: req.user.id, formationId: formation.id });

    res.status(201).json({
      success: true,
      message: 'Formation créée',
      data: formation
    });
  } catch (error) {
    next(error);
  }
};

exports.updateFormation = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { titre, description, type, categorie, url, duree_minutes, langue, est_actif } = req.body;

    // Check existence
    const exists = await prisma.formation.findUnique({ where: { id } });
    if (!exists) {
      throw errors.notFound('Formation non trouvée');
    }

    const updated = await prisma.formation.update({
      where: { id },
      data: {
        titre,
        description,
        type,
        categorie,
        url,
        dureeMinutes: duree_minutes,
        langue,
        active: est_actif
      }
    });

    res.json({
      success: true,
      message: 'Formation mise à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteFormation = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if exists first to match old logic roughly or relies on Prisma error
    // Prisma delete throws if record not found
    try {
      await prisma.formation.delete({ where: { id } });
    } catch (e) {
      if (e.code === 'P2025') throw errors.notFound('Formation non trouvée');
      throw e;
    }

    res.json({
      success: true,
      message: 'Formation supprimée'
    });
  } catch (error) {
    next(error);
  }
};

/* ========== INSCRIPTIONS ========== */

exports.inscrireFormation = async (req, res, next) => {
  try {
    const { id } = req.params;

    const formation = await prisma.formation.findFirst({
      where: { id, active: true }
    });

    if (!formation) {
      throw errors.notFound('Formation non trouvée ou inactive');
    }

    const existing = await prisma.progressionFormation.findFirst({
      where: { userId: req.user.id, formationId: id }
    });

    if (existing) {
      throw errors.conflict('Vous êtes déjà inscrit à cette formation');
    }

    const inscription = await prisma.progressionFormation.create({
      data: {
        userId: req.user.id,
        formationId: id,
        progression: 0,
        complete: false
      }
    });

    res.status(201).json({
      success: true,
      message: 'Inscription réussie',
      data: inscription
    });
  } catch (error) {
    next(error);
  }
};

exports.getMesFormations = async (req, res, next) => {
  try {
    const inscriptions = await prisma.progressionFormation.findMany({
      where: { userId: req.user.id },
      include: { formation: true },
      orderBy: { createdAt: 'desc' }
    });

    const data = inscriptions.map(uf => ({
      ...uf.formation,
      progression: uf.progression,
      complete: uf.complete,
      date_inscription: uf.createdAt
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.getMyProgressions = async (req, res, next) => {
  try {
    const inscriptions = await prisma.progressionFormation.findMany({
      where: { userId: req.user.id },
      include: {
        formation: {
          select: {
            titre: true,
            type: true,
            dureeMinutes: true
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const data = inscriptions.map(uf => ({
      ...uf,
      titre: uf.formation.titre,
      type: uf.formation.type,
      duree_minutes: uf.formation.dureeMinutes
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.updateProgression = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { progression, complete } = req.body;

    // Use updateMany for safety if no composite unique id ID available in schema, 
    // but typically unique constraints exist.
    // Assuming user_formations table has logic to support this update.
    const result = await prisma.progressionFormation.updateMany({
      where: {
        userId: req.user.id,
        formationId: id
      },
      data: {
        progression: progression !== undefined ? progression : undefined,
        complete: complete !== undefined ? complete : undefined
      }
    });

    if (result.count === 0) {
      throw errors.notFound('Inscription non trouvée');
    }

    // Since updateMany doesn't return data, fetch it if needed or just return status.
    // Original returned row. Let's fetch.
    const updated = await prisma.progressionFormation.findFirst({
      where: { userId: req.user.id, formationId: id }
    });

    res.json({
      success: true,
      message: 'Progression mise à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

/* ========== STATISTIQUES ========== */

exports.getStats = async (req, res, next) => {
  try {
    const [formationsActives, totalInscriptions, formationsTerminees, progressionAgg, apprenantsActifs] = await Promise.all([
      prisma.formation.count({ where: { active: true } }),
      prisma.progressionFormation.count(),
      prisma.progressionFormation.count({ where: { complete: true } }),
      prisma.progressionFormation.aggregate({ _avg: { progression: true } }),
      prisma.progressionFormation.groupBy({
        by: ['userId'],
      }) // count length of this result for distinct users
    ]);

    res.json({
      success: true,
      data: {
        formations_actives: formationsActives,
        total_inscriptions: totalInscriptions,
        formations_terminees: formationsTerminees,
        progression_moyenne: progressionAgg._avg.progression,
        apprenants_actifs: apprenantsActifs.length
      }
    });
  } catch (error) {
    next(error);
  }
};

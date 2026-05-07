/**
 * Contrôleur des capteurs et stations
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');

/* ========== STATIONS ========== */

/**
 * Obtenir toutes les stations
 */
exports.getAllStations = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.parcelle = { userId: req.user.id };
    }

    const stations = await prisma.station.findMany({
      where,
      include: {
        parcelle: {
          select: { nom: true, userId: true }
        },
        _count: {
          select: { capteurs: true }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset
    });

    const data = stations.map(s => ({
      ...s,
      parcelle_nom: s.parcelle?.nom,
      user_id: s.parcelle?.userId,
      nb_capteurs: s._count.capteurs
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Créer une station
 */
exports.createStation = async (req, res, next) => {
  try {
    const { nom, parcelle_id, latitude, longitude } = req.body;

    // Check permissions
    if (req.user.role === ROLES.PRODUCTEUR) {
      const parcelle = await prisma.parcelle.findFirst({
        where: { id: parcelle_id, userId: req.user.id }
      });
      if (!parcelle) {
        throw errors.forbidden('Vous n\'avez pas accès à cette parcelle');
      }
    }

    const numeroSerie = `STA-${Date.now().toString(36).toUpperCase()}`;

    const station = await prisma.station.create({
      data: {
        numeroSerie, // Schema uses numero_serie map
        nom,
        parcelleId: parcelle_id,
        latitude,
        longitude,
        statut: 'ACTIVE' // Schema uses 'statut' ENUM('ACTIVE', etc)
      }
    });

    logger.audit('Création station', { userId: req.user.id, stationId: station.id });

    res.status(201).json({
      success: true,
      message: 'Station créée avec succès',
      data: station
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir une station par son ID
 */
exports.getStationById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const station = await prisma.station.findUnique({
      where: { id },
      include: {
        parcelle: {
          select: { nom: true, userId: true }
        },
        capteurs: {
          select: {
            id: true,
            type: true,
            // modele: true, // Removed as not in schema
            statut: true // 'statut'
          }
        }
      }
    });

    if (!station) {
      throw errors.notFound('Station non trouvée');
    }

    const data = {
      ...station,
      parcelle_nom: station.parcelle?.nom,
      user_id: station.parcelle?.userId
    };

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Mettre à jour une station
 */
exports.updateStation = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nom, latitude, longitude, status } = req.body;

    const updated = await prisma.station.update({
      where: { id },
      data: {
        ...(nom && { nom }),
        ...(latitude && { latitude }),
        ...(longitude && { longitude }),
        ...(status && { statut: status.toUpperCase() }), // 'statut'
        updatedAt: new Date()
      }
    });

    if (!updated) {
      throw errors.notFound('Station non trouvée');
    }

    res.json({
      success: true,
      message: 'Station mise à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Supprimer une station
 */
exports.deleteStation = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Hard delete or Soft delete? Schema Enum: ACTIVE, MAINTENANCE, HORS_SERVICE. No INACTIF.
    // Use HORS_SERVICE or delete.
    // Let's use delete()
    await prisma.station.delete({ where: { id } });

    logger.audit('Suppression station', { userId: req.user.id, stationId: id });

    res.json({
      success: true,
      message: 'Station supprimée'
    });
  } catch (error) {
    next(error);
  }
};

/* ========== CAPTEURS ========== */

/**
 * Obtenir tous les capteurs
 */
exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const { type, status, parcelle_id } = req.query;

    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.station = { parcelle: { userId: req.user.id } };
    }

    if (type) where.type = type;
    if (status) where.statut = status.toUpperCase(); // 'statut'
    if (parcelle_id) {
      // Merge parcelle_id filter with existing station filter to preserve userId check
      if (where.station) {
        where.station = { ...where.station, parcelleId: parcelle_id };
      } else {
        where.station = { parcelleId: parcelle_id };
      }
    }

    const capteurs = await prisma.capteur.findMany({
      where,
      include: {
        station: {
          include: {
            parcelle: { select: { nom: true, userId: true } }
          }
        },
        parcelle: { select: { nom: true, userId: true } },
        mesures: {
          orderBy: { timestamp: 'desc' },
          take: 1,
          select: { valeur: true, unite: true, timestamp: true }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset
    });

    const data = capteurs.map(c => {
      const result = {
        ...c,
        station_nom: c.station?.nom,
        parcelle_nom: c.parcelle?.nom || c.station?.parcelle?.nom,
        parcelle_id: c.parcelleId, // Already exists in capteur directly
        user_id: c.station?.parcelle?.userId,
        derniere_valeur: c.mesures[0]?.valeur,
        derniereMesure: c.mesures[0] ? {
          valeur: c.mesures[0].valeur,
          unite: c.mesures[0].unite || c.unite,
          date: c.mesures[0].timestamp
        } : null,
        // Add explicit field mapping for mobile compatibility
        code: c.id, // If mobile expects 'code' field
        statut: c.statut  // Ensure status field is present
      };

      // Pour les capteurs NPK, extraire les valeurs N, P, K de la dernière mesure
      if (c.type === 'NPK' && c.mesures[0]?.valeur) {
        try {
          const parsed = JSON.parse(c.mesures[0].valeur);
          if (typeof parsed === 'object') {
            result.nitrogen = parsed.N ?? parsed.nitrogen ?? parsed.azote ?? 0;
            result.phosphorus = parsed.P ?? parsed.phosphorus ?? parsed.phosphore ?? 0;
            result.potassium = parsed.K ?? parsed.potassium ?? 0;
          }
        } catch {
          // Valeur simple, pas de JSON
          result.nitrogen = 0;
          result.phosphorus = 0;
          result.potassium = 0;
        }
      }

      return result;
    });

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Statistiques des capteurs
 */
exports.getStats = async (req, res, next) => {
  try {
    // Enum Statut: ACTIF, INACTIF, MAINTENANCE, DEFAILLANT
    const [total, statusStats, typeStats] = await Promise.all([
      prisma.capteur.count(),
      prisma.capteur.groupBy({
        by: ['statut'], // 'statut'
        _count: true
      }),
      prisma.capteur.groupBy({
        by: ['type'],
        _count: true
      })
    ]);

    const actifs = statusStats.find(s => s.statut === 'ACTIF')?._count || 0;
    const inactifs = statusStats.find(s => s.statut === 'INACTIF')?._count || 0;
    const maintenance = statusStats.find(s => s.statut === 'MAINTENANCE')?._count || 0;

    res.json({
      success: true,
      data: {
        total,
        actifs,
        inactifs,
        en_maintenance: maintenance,
        par_type: typeStats.map(t => ({
          type: t.type,
          count: t._count
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Créer un capteur
 */
exports.create = async (req, res, next) => {
  try {
    let { station_id } = req.body;
    const { parcelle_id, nom, type, unite_mesure, seuil_min, seuil_max } = req.body;

    if (!station_id && !parcelle_id) {
      throw errors.badRequest('Station ID ou Parcelle ID requis');
    }

    // Si on a parcelle_id mais pas station_id, on cherche ou crée une station par défaut
    if (parcelle_id && !station_id) {
      // Vérifier accès parcelle
      if (req.user.role === ROLES.PRODUCTEUR) {
        const parcelle = await prisma.parcelle.findFirst({
          where: { id: parcelle_id, userId: req.user.id }
        });
        if (!parcelle) throw errors.forbidden('Accès refusé à cette parcelle');
      }

      // Chercher une station existante
      let station = await prisma.station.findFirst({
        where: { parcelleId: parcelle_id }
      });

      // Sinon créer une station par défaut
      if (!station) {
        const numeroSerie = `STA-${Date.now().toString(36).toUpperCase()}`;
        station = await prisma.station.create({
          data: {
            nom: 'Station Principale',
            parcelleId: parcelle_id,
            statut: 'ACTIVE',
            numeroSerie
          }
        });
      }
      station_id = station.id;
    }
    // Si on a station_id direct (cas legacy)
    else if (station_id) {
      if (req.user.role === ROLES.PRODUCTEUR) {
        const station = await prisma.station.findFirst({
          where: {
            id: station_id,
            parcelle: { userId: req.user.id }
          }
        });
        if (!station) {
          throw errors.forbidden('Vous n\'avez pas accès à cette station');
        }
      }
    }

    // code removed as not in schema. id is generated by uuid.

    const capteur = await prisma.capteur.create({
      data: {
        nom,
        stationId: station_id,
        type, // Enum or string? Schema has ENUM in SQL but maybe string in Prisma if not mapped typed? SQL said ENUM.
        // uniteMesure maps to 'unite'? SQL has 'unite'. Prisma has 'unite' if mapped.
        unite: unite_mesure || 'N/A',
        seuilMin: parseFloat(seuil_min || 0),
        seuilMax: parseFloat(seuil_max || 100),
        statut: 'ACTIF'
      }
    });

    logger.audit('Création capteur', { userId: req.user.id, capteurId: capteur.id });

    res.status(201).json({
      success: true,
      message: 'Capteur créé avec succès',
      data: capteur
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir un capteur par son ID
 */
exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const capteur = await prisma.capteur.findUnique({
      where: { id },
      include: {
        station: {
          include: {
            parcelle: { select: { nom: true } }
          }
        },
        parcelle: { select: { nom: true } },
        mesures: {
          orderBy: { timestamp: 'desc' },
          take: 1,
          select: { valeur: true, unite: true, timestamp: true }
        }
      }
    });

    if (!capteur) {
      throw errors.notFound('Capteur non trouvé');
    }

    const data = {
      ...capteur,
      station_nom: capteur.station?.nom,
      parcelle_id: capteur.station?.parcelleId || capteur.parcelleId,
      parcelle_nom: capteur.parcelle?.nom || capteur.station?.parcelle?.nom,
      derniere_valeur: capteur.mesures[0]?.valeur,
      derniereMesure: capteur.mesures[0] ? {
        valeur: capteur.mesures[0].valeur,
        unite: capteur.mesures[0].unite || capteur.unite,
        date: capteur.mesures[0].timestamp
      } : null,
    };

    // Pour les capteurs NPK, extraire les valeurs N, P, K
    if (capteur.type === 'NPK' && capteur.mesures[0]?.valeur) {
      try {
        const parsed = JSON.parse(capteur.mesures[0].valeur);
        if (typeof parsed === 'object') {
          data.nitrogen = parsed.N ?? parsed.nitrogen ?? parsed.azote ?? 0;
          data.phosphorus = parsed.P ?? parsed.phosphorus ?? parsed.phosphore ?? 0;
          data.potassium = parsed.K ?? parsed.potassium ?? 0;
        }
      } catch {
        data.nitrogen = 0;
        data.phosphorus = 0;
        data.potassium = 0;
      }
    }

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Mettre à jour un capteur
 */
exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nom, status, unite_mesure, seuil_min, seuil_max } = req.body;

    const updated = await prisma.capteur.update({
      where: { id },
      data: {
        ...(nom && { nom }),
        ...(status && { statut: status.toUpperCase() }), // 'statut'
        ...(unite_mesure && { unite: unite_mesure }),
        ...(seuil_min !== undefined && { seuilMin: parseFloat(seuil_min) }),
        ...(seuil_max !== undefined && { seuilMax: parseFloat(seuil_max) }),
        updatedAt: new Date()
      }
    });

    if (!updated) {
      throw errors.notFound('Capteur non trouvé');
    }

    res.json({
      success: true,
      message: 'Capteur mis à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Supprimer un capteur
 */
exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Hard delete
    await prisma.capteur.delete({ where: { id } });

    logger.audit('Suppression capteur', { userId: req.user.id, capteurId: id });

    res.json({
      success: true,
      message: 'Capteur supprimé'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Calibrer un capteur
 */
exports.calibrate = async (req, res, next) => {
  // Schema check: facteurCorrection?
  // Migration SQL doesn't show `facteur_correction` or `derniere_calibration` in `capteurs` table!
  // It only shows `statut`, `signal`, `batterie`.
  // So this function uses non-existent fields!
  // I will comment it out or stub it.

  try {
    const { id } = req.params;
    // const { facteur_correction } = req.body;

    // Not supported in DB yet
    // const updated = await prisma.capteur.update({...});

    throw errors.badRequest('La calibration n\'est pas supportée par la base de données actuelle');

    /* 
    res.json({
      success: true,
      message: 'Capteur calibré',
      data: updated
    });
    */
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les mesures d'un capteur
 */
exports.getMesures = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { debut, fin, limit: queryLimit } = req.query;
    const limit = Math.min(parseInt(queryLimit) || 100, 1000);

    const where = {
      capteurId: id
    };

    if (debut) where.timestamp = { gte: new Date(debut) };
    if (fin) where.timestamp = { ...where.timestamp, lte: new Date(fin) };

    const mesures = await prisma.mesure.findMany({
      where,
      orderBy: { timestamp: 'desc' },
      take: limit
    });

    res.json({
      success: true,
      data: mesures
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir le statut d'un capteur
 */
exports.getStatus = async (req, res, next) => {
  try {
    const { id } = req.params;

    const capteur = await prisma.capteur.findUnique({
      where: { id },
      include: {
        mesures: {
          orderBy: { timestamp: 'desc' },
          take: 1,
          select: {
            valeur: true,
            timestamp: true
          }
        }
      }
    });

    if (!capteur) {
      throw errors.notFound('Capteur non trouvé');
    }

    const lastMeasure = capteur.mesures[0]?.timestamp;
    const isOnline = lastMeasure && (new Date() - new Date(lastMeasure)) < 30 * 60 * 1000; // 30 min

    res.json({
      success: true,
      data: {
        id: capteur.id,
        type: capteur.type,
        status: capteur.statut, // 'statut'
        en_ligne: isOnline,
        derniere_valeur: capteur.mesures[0]?.valeur || null,
        derniere_mesure: lastMeasure || null,
        niveau_batterie: capteur.batterie // Schema has 'batterie'
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Activer ou désactiver un capteur
 */
exports.toggleStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    logger.info('Toggle status request', { id, status, body: req.body });

    // Vérifier que le status est présent
    if (!status) {
      throw errors.badRequest('Le champ status est requis');
    }

    // Validate status match Enum values in SQL: ACTIF, INACTIF
    const validStatuses = ['ACTIF', 'INACTIF', 'MAINTENANCE'];
    const newStatus = status.toUpperCase();

    logger.info('Status validation', { newStatus, validStatuses });

    if (!validStatuses.includes(newStatus)) {
      throw errors.badRequest('Le statut doit être "actif" ou "inactif"');
    }

    const updated = await prisma.capteur.update({
      where: { id },
      data: {
        statut: newStatus,
        updatedAt: new Date()
      }
    });

    if (!updated) {
      throw errors.notFound('Capteur non trouvé');
    }

    logger.info(`Capteur ${id} ${status} par utilisateur ${req.user.id}`);

    // Recalculer la santé de la parcelle associée
    try {
      const parcelleHealthService = require('../services/parcelleHealthService');
      await parcelleHealthService.recalculateFromCapteur(id);
    } catch (healthErr) {
      logger.warn('Erreur recalcul santé après toggle', { error: healthErr.message });
    }

    res.json({
      success: true,
      message: `Capteur ${status === 'actif' ? 'activé' : 'désactivé'} avec succès`,
      data: updated
    });
  } catch (error) {
    next(error);
  }
};


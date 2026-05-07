/**
 * Contrôleur des mesures IoT
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const config = require('../config');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');
const alertesService = require('../services/alertesService');
const queueService = require('../services/queueService');

/**
 * Créer une nouvelle mesure
 */
exports.create = async (req, res, next) => {
  try {
    const { capteur_id, valeur, unite } = req.body;
    const mesureTime = new Date();

    // Ajout à la file d'attente pour traitement asynchrone
    await queueService.addJob({
      capteur_id,
      valeur,
      unite,
      mesure_at: mesureTime,
      batch: false
    });

    // Réponse immédiate 202 Accepted
    res.status(202).json({
      success: true,
      message: 'Mesure reçue et mise en file de traitement',
      data: {
        status: 'pending',
        timestamp: mesureTime
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Créer plusieurs mesures en lot
 */
exports.createBatch = async (req, res, next) => {
  try {
    const { mesures } = req.body;

    const promises = mesures.map(mesure => {
      return queueService.addJob({
        capteur_id: mesure.capteur_id,
        valeur: mesure.valeur,
        unite: mesure.unite,
        mesure_at: new Date(),
        batch: true
      });
    });

    await Promise.all(promises);

    logger.info('Batch mesures mis en file', { total: mesures.length });

    res.status(202).json({
      success: true,
      message: `${mesures.length} mesures mises en file de traitement`,
      data: {
        processed: false,
        queued: true
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les mesures avec filtres
 */
exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 50, 500);
    const offset = (page - 1) * limit;
    const { capteur_id, parcelle_id, type, debut, fin } = req.query;

    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.capteur = {
        station: { parcelle: { userId: req.user.id } }
      };
    }

    if (capteur_id) where.capteurId = capteur_id;
    if (parcelle_id) {
      // Merge parcelleId into existing station filter (preserves ownership check for producteurs)
      where.capteur = {
        ...where.capteur,
        station: {
          ...(where.capteur?.station || {}),
          parcelleId: parcelle_id
        }
      };
    }
    if (type) where.capteur = { ...where.capteur, type };

    if (debut || fin) {
      where.timestamp = {};
      if (debut) where.timestamp.gte = new Date(debut);
      if (fin) where.timestamp.lte = new Date(fin);
    }

    const [mesures, total] = await Promise.all([
      prisma.mesure.findMany({
        where,
        include: {
          capteur: {
            include: {
              station: {
                include: {
                  parcelle: { select: { nom: true } }
                }
              }
            }
          }
        },
        orderBy: { timestamp: 'desc' },
        take: limit,
        skip: offset
      }),
      prisma.mesure.count({ where })
    ]);

    const data = mesures.map(m => ({
      ...m,
      capteur_type: m.capteur?.type,
      station_nom: m.capteur?.station?.nom,
      parcelle_nom: m.capteur?.station?.parcelle?.nom
    }));

    res.json({
      success: true,
      data,
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
 * Obtenir les dernières mesures par capteur
 */
exports.getLatest = async (req, res, next) => {
  try {
    const { parcelle_id } = req.query;

    const where = {
      statut: 'ACTIF'
    };

    if (req.user.role === ROLES.PRODUCTEUR) {
      where.station = { parcelle: { userId: req.user.id } };
    }

    if (parcelle_id) {
      where.station = {
        ...where.station,
        parcelleId: parcelle_id
      };
    }

    // Get active sensors with their latest measurement
    const capteurs = await prisma.capteur.findMany({
      where,
      include: {
        station: {
          include: {
            parcelle: { select: { id: true, nom: true, userId: true } }
          }
        },
        mesures: {
          orderBy: { timestamp: 'desc' },
          take: 1
        }
      }
    });

    const data = capteurs.map(c => ({
      capteur_id: c.id,
      capteur_type: c.type,
      station_nom: c.station?.nom,
      parcelle_id: c.station?.parcelleId,
      parcelle_nom: c.station?.parcelle?.nom,
      valeur: c.mesures[0]?.valeur,
      unite: c.mesures[0]?.unite,
      mesure_at: c.mesures[0]?.timestamp
    })).filter(item => item.valeur !== undefined); // Optional: filter out sensors with no measurements if desired, though Query didn't strictly imply inner join on measures (it was LEFT JOIN)

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Statistiques des mesures
 */
exports.getStats = async (req, res, next) => {
  try {
    const now = new Date();
    const oneDayAgo = new Date(now - 24 * 60 * 60 * 1000);
    const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(now - 30 * 24 * 60 * 60 * 1000);

    const [total, last24h, last7d, activeSensors] = await Promise.all([
      prisma.mesure.count({ where: { timestamp: { gt: thirtyDaysAgo } } }),
      prisma.mesure.count({ where: { timestamp: { gt: oneDayAgo } } }),
      prisma.mesure.count({ where: { timestamp: { gt: sevenDaysAgo } } }),
      prisma.capteur.count({ where: { statut: 'ACTIF' } })
    ]);

    const typeStatsRaw = await prisma.$queryRaw`
      SELECT c.type, 
             COUNT(m.id) as nb_mesures,
             AVG(m.valeur) as moyenne,
             MIN(m.valeur) as min,
             MAX(m.valeur) as max
      FROM mesures m
      JOIN capteurs c ON m.capteur_id = c.id
      WHERE m.timestamp > ${oneDayAgo}
      GROUP BY c.type
    `;

    const processedTypeStats = typeStatsRaw.map(t => ({
      type: t.type,
      nb_mesures: Number(t.nb_mesures),
      moyenne: t.moyenne,
      min: t.min,
      max: t.max
    }));

    res.json({
      success: true,
      data: {
        total_mesures: total,
        mesures_24h: last24h,
        mesures_7j: last7d,
        capteurs_actifs: activeSensors,
        par_type: processedTypeStats
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Données agrégées (moyennes horaires/journalières)
 */
exports.getAggregated = async (req, res, next) => {
  try {
    const { parcelle_id, capteur_id, type, periode = 'jour', debut, fin } = req.query;

    const dateFormat = periode === 'heure' ? '%Y-%m-%d %H:00:00' : '%Y-%m-%d';

    const paramsUnsafe = [debut ? new Date(debut) : new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), fin ? new Date(fin) : new Date()];

    let sql = `
      SELECT 
        DATE_FORMAT(m.timestamp, '${dateFormat}') as periode,
        c.type as capteur_type,
        AVG(m.valeur) as moyenne,
        MIN(m.valeur) as min,
        MAX(m.valeur) as max,
        COUNT(*) as nb_mesures
      FROM mesures m
      JOIN capteurs c ON m.capteur_id = c.id
      JOIN stations s ON c.station_id = s.id
      JOIN parcelles p ON s.parcelle_id = p.id
      WHERE m.timestamp >= ? AND m.timestamp <= ?
    `;

    if (req.user.role === ROLES.PRODUCTEUR) {
      sql += ` AND p.user_id = ?`;
      paramsUnsafe.push(req.user.id);
    }

    if (parcelle_id) {
      sql += ` AND p.id = ?`;
      paramsUnsafe.push(parcelle_id);
    }

    if (capteur_id) {
      sql += ` AND c.id = ?`;
      paramsUnsafe.push(capteur_id);
    }

    if (type) {
      sql += ` AND c.type = ?`;
      paramsUnsafe.push(type);
    }

    sql += ` GROUP BY periode, c.type ORDER BY periode DESC`;

    const result = await prisma.$queryRawUnsafe(sql, ...paramsUnsafe);

    // Map BigInts
    const data = result.map(row => ({
      periode: row.periode,
      capteur_type: row.capteur_type,
      moyenne: row.moyenne,
      min: row.min,
      max: row.max,
      nb_mesures: Number(row.nb_mesures)
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
 * Exporter les mesures en CSV
 */
exports.exportCsv = async (req, res, next) => {
  try {
    const { parcelle_id, capteur_id, debut, fin } = req.query;

    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.capteur = {
        station: { parcelle: { userId: req.user.id } }
      };
    }

    if (parcelle_id) {
      where.capteur = { ...where.capteur, station: { parcelleId: parcelle_id } };
    }

    if (capteur_id) {
      where.capteurId = capteur_id;
    }

    if (debut || fin) {
      where.timestamp = {};
      if (debut) where.timestamp.gte = new Date(debut); // or COALESCE logic
      else where.timestamp.gte = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000); // Default 30 days

      if (fin) where.timestamp.lte = new Date(fin);
      else where.timestamp.lte = new Date();
    } else {
      // Default 30 days if neither provided
      where.timestamp = {
        gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        lte: new Date()
      };
    }

    const mesures = await prisma.mesure.findMany({
      where,
      include: {
        capteur: {
          include: {
            station: {
              include: {
                parcelle: { select: { nom: true } }
              }
            }
          }
        }
      },
      orderBy: { timestamp: 'desc' },
      take: 10000
    });

    // Générer le CSV
    const headers = ['date_mesure', 'type_capteur', 'valeur', 'unite', 'station', 'parcelle'];
    const csv = [
      headers.join(','),
      ...mesures.map(m =>
        [
          m.timestamp.toISOString(),
          m.capteur?.type,
          m.valeur,
          m.unite,
          m.capteur?.station?.nom,
          m.capteur?.station?.parcelle?.nom
        ].join(',')
      )
    ].join('\n');

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=mesures.csv');
    res.send(csv);
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir une mesure par son ID
 */
exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const mesure = await prisma.mesure.findUnique({
      where: { id },
      include: {
        capteur: {
          include: {
            station: { select: { nom: true } }
          }
        }
      }
    });

    if (!mesure) {
      throw errors.notFound('Mesure non trouvée');
    }

    const data = {
      ...mesure,
      capteur_type: mesure.capteur?.type,
      station_nom: mesure.capteur?.station?.nom
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
 * Supprimer une mesure
 */
exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;

    const deleted = await prisma.mesure.delete({
      where: { id }
    });

    if (!deleted) {
      throw errors.notFound('Mesure non trouvée');
    }

    logger.info('Suppression mesure', { userId: req.user.id, mesureId: id });

    res.json({
      success: true,
      message: 'Mesure supprimée'
    });
  } catch (error) {
    next(error);
  }
};

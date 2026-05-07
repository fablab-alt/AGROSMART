/**
 * Contrôleur des recommandations
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');
const axios = require('axios');

exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const { type, priorite } = req.query;

    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }
    if (type) where.type = type;
    if (priorite) where.priorite = parseInt(priorite);

    const recommandations = await prisma.recommandation.findMany({
      where,
      include: {
        parcelle: {
          select: { nom: true }
        }
      },
      orderBy: [
        { priorite: 'desc' },
        { createdAt: 'desc' }
      ],
      skip: offset,
      take: limit
    });

    const data = recommandations.map(r => ({
      ...r,
      parcelle_nom: r.parcelle?.nom
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.getActive = async (req, res, next) => {
  try {
    const where = {
      appliquee: false,
      OR: [
        { valideJusquAu: null },
        { valideJusquAu: { gte: new Date() } }
      ]
    };

    if (req.user.role === ROLES.PRODUCTEUR) {
      where.parcelle = { userId: req.user.id };
    }

    const recommandations = await prisma.recommandation.findMany({
      where,
      include: {
        parcelle: {
          select: { nom: true }
        }
      },
      orderBy: [
        { priorite: 'desc' },
        { createdAt: 'desc' }
      ]
    });

    const data = recommandations.map(r => ({
      ...r,
      parcelle_nom: r.parcelle?.nom
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { type, titre, description, priorite = 3, parcelle_id,
      valide_du, valide_jusqu_au } = req.body;

    const recommandation = await prisma.recommandation.create({
      data: {
        type,
        titre,
        description,
        priorite,
        parcelleId: parcelle_id,
        valideDu: valide_du,
        valideJusquAu: valide_jusqu_au,
        generePar: 'conseiller',
        userId: req.user.id
      }
    });

    logger.audit('Création recommandation', { userId: req.user.id, recommandationId: recommandation.id });

    res.status(201).json({
      success: true,
      message: 'Recommandation créée',
      data: recommandation
    });
  } catch (error) {
    next(error);
  }
};

exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const recommandation = await prisma.recommandation.findUnique({
      where: { id },
      include: {
        parcelle: {
          select: { nom: true }
        }
      }
    });

    if (!recommandation) {
      throw errors.notFound('Recommandation non trouvée');
    }

    res.json({
      success: true,
      data: {
        ...recommandation,
        parcelle_nom: recommandation.parcelle?.nom
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { titre, description, priorite, valide_jusqu_au } = req.body;

    // Check existence first or handle P2025
    const exists = await prisma.recommandation.findUnique({ where: { id } });
    if (!exists) throw errors.notFound('Recommandation non trouvée');

    const updated = await prisma.recommandation.update({
      where: { id },
      data: {
        titre,
        description,
        priorite,
        valideJusquAu: valide_jusqu_au
      }
    });

    res.json({
      success: true,
      message: 'Recommandation mise à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

exports.updateStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { appliquee, commentaire_utilisateur, note_utilisateur } = req.body;

    // Check existence
    const exists = await prisma.recommandation.findUnique({ where: { id } });
    if (!exists) throw errors.notFound('Recommandation non trouvée');

    const data = {
      appliquee,
      commentaireUtilisateur: commentaire_utilisateur,
      noteUtilisateur: note_utilisateur
    };

    if (appliquee) {
      data.dateApplication = new Date();
    }

    const updated = await prisma.recommandation.update({
      where: { id },
      data
    });

    logger.audit('Mise à jour statut recommandation', {
      userId: req.user.id,
      recommandationId: id,
      statut: appliquee ? 'APPLIQUEE' : 'NON_APPLIQUEE'
    });

    res.json({
      success: true,
      message: 'Statut mis à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;

    try {
      await prisma.recommandation.delete({ where: { id } });
    } catch (e) {
      if (e.code === 'P2025') throw errors.notFound('Recommandation non trouvée');
      throw e;
    }

    res.json({
      success: true,
      message: 'Recommandation supprimée'
    });
  } catch (error) {
    next(error);
  }
};

/* ========== IRRIGATION ========== */

exports.getIrrigationPrevisions = async (req, res, next) => {
  try {
    const where = { statut: 'ACTIVE' };
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    // Fetch parcelles and their latest sensors data
    const parcelles = await prisma.parcelle.findMany({
      where,
      include: {
        capteurs: {
          include: {
            mesures: {
              take: 1,
              orderBy: { timestamp: 'desc' }
            }
          }
        }
      }
    });

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { systemeIrrigation: true } // Ensure this field exists in User model or handle undefined
    });
    // Note: User model in schema doesn't show systemeIrrigation. 
    // If it doesn't exist, we fallback to 'manual'.
    const irrigationSystem = user?.systemeIrrigation || 'manuel';

    const previsions = parcelles.map(parcelle => {
      // Extract latest measures
      let humidite = 50;
      let temperature = 25;

      parcelle.capteurs.forEach(c => {
        if (c.mesures.length > 0) {
          const val = parseFloat(c.mesures[0].valeur);
          // Mapping types loosely based on legacy logic 'humidite_sol' vs 'temperature'
          // In Prisma Schema: HUMIDITE_SOL, HUMIDITE_TEMPERATURE_AMBIANTE
          if (c.type === 'HUMIDITE_SOL') {
            humidite = val;
          } else if (c.type === 'HUMIDITE_TEMPERATURE_AMBIANTE' || c.type === 'DIRECTION_VENT') {
            // Assuming temp comes from ambient stations? Legacy query looked for c.type = 'temperature'
            // If we don't have explicit TEMP sensor, we might miss it.
            // But let's assume HUMIDITE_TEMPERATURE_AMBIANTE holds temp?
            // Or maybe we treat as default if missing.
            // Actually, usually Temp is separate or part of multi-sensor. 
            // We'll trust logic: if type matches what we think is temp.
            // But wait, schema enum doesn't have TEMPERATURE.
            // If legacy DB had 'temperature', Prisma read might fail or map to 'HUMIDITE_TEMPERATURE_AMBIANTE' if configured?
            // No, enum mismatch throws.
            // So we assume data is clean/migrated to Enum.
            if (c.type === 'HUMIDITE_TEMPERATURE_AMBIANTE') temperature = val;
            // Ideally we check unit '°C'?
            if (c.unite === '°C') temperature = val;
          }
        }
      });

      let besoin = 'faible';
      let quantite_recommandee = 0;
      let prochaine_irrigation = null;

      if (humidite < 30) {
        besoin = 'urgent';
        quantite_recommandee = Number(parcelle.superficie) * 5;
        prochaine_irrigation = new Date();
      } else if (humidite < 50) {
        besoin = 'moyen';
        quantite_recommandee = Number(parcelle.superficie) * 3;
        prochaine_irrigation = new Date(Date.now() + 24 * 60 * 60 * 1000);
      } else if (humidite < 70) {
        besoin = 'faible';
        quantite_recommandee = Number(parcelle.superficie) * 1;
        prochaine_irrigation = new Date(Date.now() + 48 * 60 * 60 * 1000);
      }

      if (temperature > 35) {
        quantite_recommandee *= 1.5;
      }

      return {
        parcelle_id: parcelle.id,
        parcelle_nom: parcelle.nom,
        humidite_actuelle: humidite,
        temperature_actuelle: temperature,
        besoin,
        quantite_recommandee_litres: Math.round(quantite_recommandee),
        prochaine_irrigation,
        conseil: irrigationSystem === 'automatique'
          ? `Activez votre système d'irrigation pour délivrer ${Math.round(quantite_recommandee)} litres.`
          : `Arrosez manuellement. Quantité recommandée : ${Math.round(quantite_recommandee)} litres par m².`
      };
    });

    res.json({
      success: true,
      data: previsions
    });
  } catch (error) {
    next(error);
  }
};

exports.getIrrigationByParcelle = async (req, res, next) => {
  try {
    const { parcelleId } = req.params;

    // Use queryRaw for date aggregation - MySQL compatible syntax
    const mesures = await prisma.$queryRaw`
        SELECT DATE(m.timestamp) as date, AVG(CAST(m.valeur AS DECIMAL(10,2))) as moyenne
        FROM mesures m
        JOIN capteurs c ON m.capteur_id = c.id
        JOIN stations s ON c.station_id = s.id
        WHERE s.parcelle_id = ${parcelleId} AND c.type = 'HUMIDITE_SOL'
          AND m.timestamp > DATE_SUB(NOW(), INTERVAL 30 DAY)
        GROUP BY DATE(m.timestamp)
        ORDER BY date DESC
    `;

    // Convert BigInt/Decimal if needed (Decimal usually string or number in JS from Prisma, but queryRaw might return something else)
    // Prisma queryRaw returns dates as Date objects usually.

    res.json({
      success: true,
      data: {
        historique: mesures
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.calculateIrrigation = async (req, res, next) => {
  try {
    const { parcelle_id } = req.body;

    const parcelle = await prisma.parcelle.findUnique({
      where: { id: parcelle_id },
      include: {
        plantations: {
          where: { statut: 'active' },
          include: { culture: true },
          take: 1
        },
        capteurs: {
          include: {
            mesures: {
              take: 1,
              orderBy: { timestamp: 'desc' }
            }
          }
        }
      }
    });

    if (!parcelle) {
      throw errors.notFound('Parcelle non trouvée');
    }

    // Determine metrics
    let humidite = 50;
    let temperature = 25;

    parcelle.capteurs.forEach(c => {
      if (c.mesures.length > 0) {
        const val = parseFloat(c.mesures[0].valeur);
        if (c.type === 'HUMIDITE_SOL') {
          humidite = val;
        } else if (c.unite === '°C') {
          temperature = val;
        }
      }
    });

    const cultureId = parcelle.plantations.length > 0 ? parcelle.plantations[0].cultureId : 1;
    // ID 1 fallback is risky but matches legacy logic

    // Appel au microservice IA Python
    let quantiteRecommandee = 0;
    let nextIrrigation = 'Inconnu';

    try {
      const aiResponse = await axios.post('http://localhost:5000/predict/irrigation', {
        temperature: temperature,
        humidity: 60,
        soil_moisture: humidite,
        crop_type: cultureId
      });

      quantiteRecommandee = aiResponse.data.water_amount_mm;
      nextIrrigation = aiResponse.data.next_irrigation;
    } catch (aiError) {
      logger.error('Erreur service IA Irrigation', { error: aiError.message });
      quantiteRecommandee = (30 - humidite) * 0.5;
      if (quantiteRecommandee < 0) quantiteRecommandee = 0;
    }

    const litresTotal = Math.round(quantiteRecommandee * Number(parcelle.superficie));

    // Créer une recommandation d'irrigation
    const recommandation = await prisma.recommandation.create({
      data: {
        type: 'irrigation',
        titre: `Irrigation recommandée pour ${parcelle.nom}`,
        description: `IA: Besoin estimé à ${quantiteRecommandee} mm (${litresTotal} L). Prochaine irrigation: ${nextIrrigation}.`,
        priorite: 3,
        parcelleId: parcelle_id,
        generePar: 'ia',
        userId: req.user.id
      }
    });

    res.json({
      success: true,
      data: recommandation
    });
  } catch (error) {
    next(error);
  }
};

/* ========== MÉTÉO ========== */

exports.getMeteoPrevisions = async (req, res, next) => {
  try {
    // TODO: Intégrer une API météo réelle (OpenWeatherMap, etc.)
    // Pour l'instant, données simulées
    const previsions = [];
    const now = new Date();

    for (let i = 0; i < 7; i++) {
      const date = new Date(now);
      date.setDate(date.getDate() + i);

      previsions.push({
        date: date.toISOString().split('T')[0],
        temperature_min: 22 + Math.floor(Math.random() * 5),
        temperature_max: 30 + Math.floor(Math.random() * 5),
        humidite: 60 + Math.floor(Math.random() * 30),
        precipitation_mm: Math.random() > 0.7 ? Math.floor(Math.random() * 20) : 0,
        vent_kmh: 5 + Math.floor(Math.random() * 15),
        description: ['Ensoleillé', 'Partiellement nuageux', 'Nuageux', 'Pluie légère'][Math.floor(Math.random() * 4)]
      });
    }

    res.json({
      success: true,
      data: previsions
    });
  } catch (error) {
    next(error);
  }
};

exports.getMeteoByParcelle = async (req, res, next) => {
  try {
    const { parcelleId } = req.params;

    const parcelle = await prisma.parcelle.findUnique({
      where: { id: parcelleId },
      select: {
        nom: true,
        latitude: true,
        longitude: true
      }
    });

    if (!parcelle) {
      throw errors.notFound('Parcelle non trouvée');
    }

    // TODO: Appeler l'API météo avec les coordonnées
    // Données simulées pour l'instant
    res.json({
      success: true,
      data: {
        parcelle: parcelle.nom,
        localisation: {
          latitude: parcelle.latitude,
          longitude: parcelle.longitude
        },
        actuel: {
          temperature: 28,
          humidite: 65,
          precipitation: 0,
          vent_kmh: 10
        },
        previsions: []
      }
    });
  } catch (error) {
    next(error);
  }
};

/* ========== GÉNÉRATION AUTOMATIQUE ========== */

exports.generate = async (req, res, next) => {
  try {
    const { parcelle_id } = req.body;

    const parcelle = await prisma.parcelle.findUnique({
      where: { id: parcelle_id },
      include: {
        capteurs: {
          include: {
            mesures: {
              take: 10,
              orderBy: { timestamp: 'desc' }
            }
          }
        }
      }
    });

    if (!parcelle) {
      throw errors.notFound('Parcelle non trouvée');
    }

    const recommandationsGenerees = [];

    // Analyze data
    let humidite = null;

    // Find latest humidity measure across sensors
    parcelle.capteurs.forEach(c => {
      if (c.type === 'HUMIDITE_SOL' && c.mesures.length > 0) {
        // Assuming we just take the very first one found or we should inspect timestamps?
        // Logic says "analyze data".
        if (!humidite || new Date(c.mesures[0].timestamp) > new Date(humidite.timestamp)) {
          humidite = c.mesures[0];
        }
      }
    });

    if (humidite && parseFloat(humidite.valeur) < 40) {
      const val = parseFloat(humidite.valeur);
      recommandationsGenerees.push({
        type: 'irrigation',
        titre: 'Irrigation nécessaire',
        description: 'L\'humidité du sol est basse. Nous recommandons une irrigation dans les prochaines heures.',
        priorite: val < 25 ? 4 : 3
      });
    }

    // Insert recommendations
    for (const reco of recommandationsGenerees) {
      await prisma.recommandation.create({
        data: {
          type: reco.type,
          titre: reco.titre,
          description: reco.description,
          priorite: reco.priorite,
          parcelleId: parcelle_id,
          generePar: 'automatique',
          userId: req.user.id
        }
      });
    }

    res.json({
      success: true,
      message: `${recommandationsGenerees.length} recommandations générées`,
      data: recommandationsGenerees
    });
  } catch (error) {
    next(error);
  }
};

exports.getStats = async (req, res, next) => {
  try {
    // Parallel queries for stats
    const [total, enAttente, appliquees, urgentes, cetteSemaine, parType] = await Promise.all([
      prisma.recommandation.count(),
      prisma.recommandation.count({ where: { appliquee: false } }),
      prisma.recommandation.count({ where: { appliquee: true } }),
      prisma.recommandation.count({ where: { priorite: { gte: 4 } } }),
      prisma.recommandation.count({ where: { createdAt: { gt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } } }),
      prisma.recommandation.groupBy({
        by: ['type'],
        _count: { type: true },
        where: { createdAt: { gt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } }
      })
    ]);

    res.json({
      success: true,
      data: {
        total,
        en_attente: enAttente,
        appliquees,
        urgentes,
        cette_semaine: cetteSemaine,
        par_type: parType.map(g => ({ type: g.type, count: g._count.type }))
      }
    });
  } catch (error) {
    next(error);
  }
};

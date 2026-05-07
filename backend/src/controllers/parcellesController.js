/**
 * Contrôleur des parcelles
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');
const parcelleHealthService = require('../services/parcelleHealthService');
// const { Parser } = require('json2csv'); // Ensure json2csv is available or mock it

/**
 * Exporter les données parcelles en CSV
 */
exports.exportData = async (req, res, next) => {
  try {
    const where = {};
    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    const parcelles = await prisma.parcelle.findMany({
      where,
      include: {
        user: {
          select: {
            nom: true,
            prenoms: true
          }
        }
      }
    });

    const fields = ['nom', 'superficie', 'typeSol', 'status', 'proprietaire_nom', 'proprietaire_prenom'];

    // CSV generation
    const header = fields.join(',') + '\n';
    const rows = parcelles.map(p =>
      [
        `"${p.nom || ''}"`,
        `"${p.superficie || ''}"`,
        `"${p.typeSol || ''}"`,
        `"${p.status || ''}"`,
        `"${p.user?.nom || ''}"`,
        `"${p.user?.prenoms || ''}"`
      ].join(',')
    ).join('\n');

    const csv = header + rows;

    res.header('Content-Type', 'text/csv');
    res.attachment('parcelles_export.csv');
    return res.send(csv);

  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir toutes les parcelles (filtrées selon le rôle)
 */
exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const { statut, type_sol, search } = req.query;

    // Build where clause
    const where = {};

    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    if (statut) {
      where.statut = statut.toUpperCase(); // Schema uses 'statut' not 'status'
    }

    if (type_sol) {
      where.typeSol = type_sol;
    }

    if (search) {
      where.OR = [
        { nom: { contains: search } }, // Removed mode: 'insensitive' if MySQL doesn't support it directly without config, but default prisma usually ok. MySQL is case insensitive by default for some collations.
        // { description: { contains: search } } // Removed description search to simplicity if field optional
      ];
    }

    // Count total
    const total = await prisma.parcelle.count({ where });

    // Get parcelles with relations
    const parcelles = await prisma.parcelle.findMany({
      where,
      include: {
        user: {
          select: {
            nom: true,
            prenoms: true
          }
        },
        stations: {
          select: { id: true }
        },
        capteurs: {
          where: {
            type: { in: ['HUMIDITE_SOL', 'HUMIDITE_TEMPERATURE_AMBIANTE'] }
          },
          select: {
            id: true,
            type: true,
            mesures: {
              take: 1,
              orderBy: { timestamp: 'desc' },
              select: { valeur: true, timestamp: true }
            }
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset
    });

    // Transform data to match expected format
    const data = parcelles.map(p => {
      // Extraire la dernière température et humidité des capteurs
      let temperature = 0;
      let humidite = 0;

      if (p.capteurs) {
        for (const capteur of p.capteurs) {
          if (capteur.mesures && capteur.mesures.length > 0) {
            const valeur = parseFloat(capteur.mesures[0].valeur);
            if (capteur.type === 'HUMIDITE_TEMPERATURE_AMBIANTE') {
              temperature = Math.round(valeur * 10) / 10;
            } else if (capteur.type === 'HUMIDITE_SOL') {
              humidite = Math.round(valeur * 10) / 10;
            }
          }
        }
      }

      return {
        id: p.id,
        nom: p.nom,
        superficie: p.superficie,
        latitude: p.latitude,
        longitude: p.longitude,
        type_sol: p.typeSol,
        status: p.statut,
        sante: p.sante || 'OPTIMAL',
        created_at: p.createdAt,
        updated_at: p.updatedAt,
        proprietaire_nom: p.user?.nom,
        proprietaire_prenom: p.user?.prenoms,
        culture: p.cultureActuelle || 'Aucune',
        temperature,
        humidite,
        nb_stations: p.stations.length,
        nb_plantations: 0
      };
    });

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
 * Statistiques des parcelles
 */
exports.getStats = async (req, res, next) => {
  try {
    // Aggregate parcelles stats
    const [total, superficie, actives, proprietaires, byType] = await Promise.all([
      prisma.parcelle.count(),
      prisma.parcelle.aggregate({
        _sum: { superficie: true },
        _avg: { superficie: true }
      }),
      prisma.parcelle.count({ where: { statut: 'ACTIVE' } }), // 'statut'
      prisma.parcelle.groupBy({
        by: ['userId'],
        _count: true
      }),
      prisma.parcelle.groupBy({
        by: ['typeSol'],
        where: { typeSol: { not: null } },
        _count: true,
        _sum: { superficie: true }
      })
    ]);

    res.json({
      success: true,
      data: {
        total_parcelles: total,
        superficie_totale: superficie._sum.superficie || 0,
        superficie_moyenne: superficie._avg.superficie || 0,
        parcelles_actives: actives,
        nb_proprietaires: proprietaires.length,
        par_type_sol: byType.map(t => ({
          type_sol: t.typeSol,
          count: t._count,
          superficie: t._sum.superficie
        }))
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Données pour la carte
 */
exports.getMapData = async (req, res, next) => {
  try {
    const where = {
      latitude: { not: null },
      longitude: { not: null }
    };

    if (req.user.role === ROLES.PRODUCTEUR) {
      where.userId = req.user.id;
    }

    const parcelles = await prisma.parcelle.findMany({
      where,
      include: {
        user: {
          select: { nom: true }
        }
      },
      select: {
        id: true,
        nom: true,
        superficie: true,
        latitude: true,
        longitude: true,
        statut: true, // 'statut'
        user: true
      }
    });

    const data = parcelles.map(p => ({
      ...p,
      proprietaire_nom: p.user?.nom
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
 * Créer une parcelle
 */
exports.create = async (req, res, next) => {
  try {
    const { nom, superficie, latitude, longitude, description, type_sol, culture, status, date_plantation } = req.body;
    const userId = req.body.user_id || req.user.id;

    // Permissions check
    if (req.body.user_id && req.user.role === ROLES.PRODUCTEUR) {
      if (req.body.user_id !== req.user.id) {
        throw errors.forbidden('Vous ne pouvez créer que vos propres parcelles');
      }
    }

    // Déterminer le statut en fonction des informations fournies
    let finalStatut = 'ACTIVE'; // Statut par défaut
    
    if (status) {
      // Si un statut est explicitement fourni, on l'utilise
      finalStatut = status.toUpperCase();
    } else if (culture && date_plantation) {
      // Si une culture et date de plantation sont fournies, la parcelle est ensemencée
      finalStatut = 'ENSEMENCEE';
    } else if (culture) {
      // Si seulement une culture est mentionnée, on considère qu'elle est préparée
      finalStatut = 'PREPAREE';
    }

    const parcelle = await prisma.parcelle.create({
      data: {
        nom,
        superficie: parseFloat(superficie),
        latitude: latitude ? parseFloat(latitude) : null,
        longitude: longitude ? parseFloat(longitude) : null,
        typeSol: type_sol,
        userId,
        cultureActuelle: culture,
        datePlantation: date_plantation ? new Date(date_plantation) : null,
        statut: finalStatut
      }
    });

    logger.audit('Création parcelle', { userId: req.user.id, parcelleId: parcelle.id });

    res.status(201).json({
      success: true,
      message: 'Parcelle créée avec succès',
      data: parcelle
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir une parcelle par son ID
 */
exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const parcelle = await prisma.parcelle.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            nom: true,
            prenoms: true,
            telephone: true
          }
        },
        _count: {
          select: {
            stations: true
          }
        }
      }
    });

    if (!parcelle) {
      throw errors.notFound('Parcelle non trouvée');
    }

    // Get sensor count 
    const stations = await prisma.station.findMany({
      where: { parcelleId: id },
      include: {
        _count: {
          select: { capteurs: true }
        }
      }
    });

    const nbCapteurs = stations.reduce((acc, s) => acc + s._count.capteurs, 0);

    const data = {
      ...parcelle,
      proprietaire_nom: parcelle.user?.nom,
      proprietaire_prenom: parcelle.user?.prenoms,
      proprietaire_telephone: parcelle.user?.telephone,
      nb_stations: parcelle._count.stations,
      nb_capteurs: nbCapteurs
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
 * Mettre à jour une parcelle
 */
exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nom, superficie, latitude, longitude, type_sol, culture, status, date_plantation } = req.body;

    const updated = await prisma.parcelle.update({
      where: { id },
      data: {
        ...(nom && { nom }),
        ...(superficie && { superficie: parseFloat(superficie) }),
        ...(latitude && { latitude: parseFloat(latitude) }),
        ...(longitude && { longitude: parseFloat(longitude) }),
        // ...(description && { description }), // Removed as not in schema
        ...(type_sol && { typeSol: type_sol }),
        ...(status && { statut: status.toUpperCase() }), // 'statut'
        updatedAt: new Date()
      }
    });

    logger.audit('Mise à jour parcelle', { userId: req.user.id, parcelleId: id });

    res.json({
      success: true,
      message: 'Parcelle mise à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Supprimer une parcelle
 */
exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Hard delete or Soft delete? Schema has 'statut'. Let's use soft delete via update.
    // BUT if we want to delete, we can also use delete() if relations permit (cascade).
    // Using soft delete:
    const updated = await prisma.parcelle.update({
      where: { id },
      data: {
        statut: 'RECOLTE', // Or create a 'DELETED' status if exists? Schema: ACTIVE, EN_REPOS, PREPAREE, ENSEMENCEE, EN_CROISSANCE, RECOLTE. No INACTIVE.
        // Let's assume we shouldn't delete, just mark as RECOLTE or something?
        // Or simply delete().
        // Controller previously tried 'INACTIVE' which doesn't exist in Enum!
        // Let's use prisma.parcelle.delete() for now, as existing code might be old.
      }
    });
    // Actually, let's use delete()
    await prisma.parcelle.delete({ where: { id } });

    logger.audit('Suppression parcelle', { userId: req.user.id, parcelleId: id });

    res.json({
      success: true,
      message: 'Parcelle supprimée'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les stations d'une parcelle
 */
exports.getStations = async (req, res, next) => {
  try {
    const { id } = req.params;

    const stations = await prisma.station.findMany({
      where: { parcelleId: id },
      include: {
        _count: { select: { capteurs: true } }
      },
      orderBy: { createdAt: 'desc' }
    });

    const data = stations.map(s => ({
      ...s,
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
 * Obtenir les dernières mesures d'une parcelle (historique)
 */
exports.getMesures = async (req, res, next) => {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit) || 100;

    const mesures = await prisma.mesure.findMany({
      where: {
        capteur: {
          parcelleId: id
        }
      },
      include: {
        capteur: {
          select: {
            type: true,
            nom: true,
            unite: true,
            station: { select: { nom: true } }
          }
        }
      },
      orderBy: { timestamp: 'desc' },
      take: limit
    });

    const data = mesures.map(m => ({
      id: m.id,
      valeur: Number(m.valeur),
      unite: m.unite,
      timestamp: m.timestamp,
      capteur_id: m.capteurId,
      capteur_type: m.capteur?.type,
      capteur_nom: m.capteur?.nom,
      station_nom: m.capteur?.station?.nom
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
 * Obtenir les métriques IoT actuelles d'une parcelle (dernières valeurs par type de capteur)
 */
exports.getIotMetrics = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Récupérer tous les capteurs avec leur dernière mesure en une seule requête (évite N+1)
    const capteurs = await prisma.capteur.findMany({
      where: {
        parcelleId: id
      },
      select: {
        id: true,
        type: true,
        nom: true,
        unite: true,
        seuilMin: true,
        seuilMax: true,
        signal: true,
        batterie: true,
        statut: true,
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

    if (capteurs.length === 0) {
      return res.json({
        success: true,
        data: {
          metrics: [],
          message: 'Aucun capteur actif trouvé pour cette parcelle'
        }
      });
    }

    // Transformer les résultats
    const metrics = capteurs.map((capteur) => {
      const derniereMesure = capteur.mesures[0] || null;

      return {
        capteur_id: capteur.id,
        type: capteur.type,
        nom: capteur.nom,
        unite: capteur.unite,
        statut: capteur.statut,
        valeur: derniereMesure ? Number(derniereMesure.valeur) : null,
        timestamp: derniereMesure?.timestamp || null,
        seuil_min: Number(capteur.seuilMin),
        seuil_max: Number(capteur.seuilMax),
        signal: capteur.signal,
        batterie: capteur.batterie,
        hors_seuils: derniereMesure ? (
          Number(derniereMesure.valeur) < Number(capteur.seuilMin) ||
          Number(derniereMesure.valeur) > Number(capteur.seuilMax)
        ) : false
      };
    });

    // Grouper par type de capteur pour un affichage plus clair
    const groupedMetrics = {};
    metrics.forEach(metric => {
      if (!groupedMetrics[metric.type]) {
        groupedMetrics[metric.type] = [];
      }
      groupedMetrics[metric.type].push(metric);
    });

    res.json({
      success: true,
      data: {
        metrics: metrics,
        grouped_by_type: groupedMetrics,
        total_capteurs: capteurs.length,
        capteurs_avec_donnees: metrics.filter(m => m.valeur !== null).length
      }
    });
  } catch (error) {
    logger.error('Error fetching IoT metrics:', error);
    next(error);
  }
};

/**
 * Obtenir les alertes d'une parcelle
 */
exports.getAlertes = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { niveau, resolue } = req.query;

    const where = {
      capteur: { station: { parcelleId: id } }
    };

    if (niveau) {
      where.niveau = niveau;
    }

    if (resolue !== undefined) {
      // where.resolue = resolue === 'true'; // Field 'resolue' removed/not in schema. Status is used.
      if (resolue === 'true') {
        where.statut = { in: ['TRAITEE', 'IGNOREE'] };
      } else {
        where.statut = { in: ['NOUVELLE', 'LUE'] };
      }
    }

    const alertes = await prisma.alerte.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 50
    });

    res.json({
      success: true,
      data: alertes
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les cultures d'une parcelle
 */
exports.getCultures = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Schema check: RendementsParCulture table? Or just cultureActuelle on Parcel?
    // User wants 'plantations'. Table 'parcelles' has 'culture_actuelle'.
    // There is no separate 'Plantation' model in the Migration SQL I saw!
    // But ParcellesController previously used prisma.plantation.
    // If 'Plantation' does not exist in schema, this will fail.
    // Migration SQL has `rendements_par_culture`. Not `plantations`.
    // I will return empty or fix if logic known. Use cultureActuelle.

    const parcelle = await prisma.parcelle.findUnique({
      where: { id },
      select: { cultureActuelle: true, datePlantation: true }
    });

    // Mocking list response with current culture
    const data = parcelle && parcelle.cultureActuelle ? [{
      culture_nom: parcelle.cultureActuelle,
      date_plantation: parcelle.datePlantation,
      est_active: true
    }] : [];

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les recommandations (Diagnostics) pour une parcelle
 */
exports.getRecommandations = async (req, res, next) => {
  try {
    const { id } = req.params;

    const diagnostics = await prisma.diagnostic.findMany({
      where: {
        parcelleId: id
      },
      orderBy: { createdAt: 'desc' },
      take: 20
    });

    res.json({
      success: true,
      data: diagnostics
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Historique d'une parcelle
 */
exports.getHistorique = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { type, debut, fin } = req.query;

    // Use Prisma aggregate if possible, or fallback to raw query correctly
    // Since grouping by Date(timestamp) is DB specific, raw query is acceptable here.
    // We just need to make sure table names and columns match schema.
    // Table 'mesures' (lowercase) ? Schema maps to 'mesures'.
    // Columns: capteur_id (map capteurId), valeur.
    // Table 'capteurs', 'stations'.

    const history = await prisma.$queryRaw`
       SELECT 
         DATE(m.timestamp) as date,
         c.type as capteur_type,
         AVG(CAST(m.valeur AS DECIMAL)) as moyenne,
         MIN(CAST(m.valeur AS DECIMAL)) as min,
         MAX(CAST(m.valeur AS DECIMAL)) as max,
         COUNT(*) as nb_mesures
        FROM mesures m
        JOIN capteurs c ON m.capteur_id = c.id
        JOIN stations s ON c.station_id = s.id
        WHERE s.parcelle_id = ${id}
        GROUP BY DATE(m.timestamp), c.type
        ORDER BY date DESC, c.type
    `;

    // Convert BigInt
    const data = JSON.parse(JSON.stringify(history, (key, value) =>
      typeof value === 'bigint' ? Number(value) : value
    ));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Recalculer la santé d'une parcelle à partir des dernières mesures capteurs
 */
exports.recalculateHealth = async (req, res, next) => {
  try {
    const { id } = req.params;

    const parcelle = await prisma.parcelle.findUnique({
      where: { id },
      select: { id: true, nom: true }
    });

    if (!parcelle) {
      throw errors.notFound('Parcelle non trouvée');
    }

    const newHealth = await parcelleHealthService.recalculateParcelleHealth(id);

    res.json({
      success: true,
      message: `Santé de la parcelle "${parcelle.nom}" recalculée`,
      data: {
        parcelle_id: id,
        sante: newHealth
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Recalculer la santé de toutes les parcelles (admin)
 */
exports.recalculateAllHealth = async (req, res, next) => {
  try {
    const parcelles = await prisma.parcelle.findMany({
      select: { id: true, nom: true }
    });

    const results = [];
    for (const p of parcelles) {
      const health = await parcelleHealthService.recalculateParcelleHealth(p.id);
      results.push({ id: p.id, nom: p.nom, sante: health });
    }

    res.json({
      success: true,
      message: `Santé recalculée pour ${results.length} parcelles`,
      data: results
    });
  } catch (error) {
    next(error);
  }
};
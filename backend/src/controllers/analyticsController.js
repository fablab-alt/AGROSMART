/**
 * Contrôleur d'Analytique
 * AgroSmart - Statistiques et analytiques de la ferme
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Obtenir les statistiques complètes de l'exploitation pour un utilisateur
 */
exports.getStats = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // Récupérer les données de ROI depuis la table roi_tracking
        const roiData = await prisma.roiTracking.findFirst({
            where: { userId },
            orderBy: { periodeFin: 'desc' },
            select: {
                coutSemences: true,
                coutEngrais: true,
                coutPesticides: true,
                coutIrrigation: true,
                coutMainOeuvre: true,
                autresCouts: true,
                quantiteRecoltee: true,
                prixVenteUnitaire: true,
                roiTrend: true
            }
        });

        // Calculer les métriques de ROI
        let roiPourcentage = 0;
        let revenuTotal = 0;
        let coutTotal = 0;
        let roiTrend = 'stable';

        if (roiData) {
            coutTotal = Number(roiData.coutSemences || 0) +
                Number(roiData.coutEngrais || 0) +
                Number(roiData.coutPesticides || 0) +
                Number(roiData.coutIrrigation || 0) +
                Number(roiData.coutMainOeuvre || 0) +
                Number(roiData.autresCouts || 0);

            revenuTotal = Number(roiData.quantiteRecoltee || 0) * Number(roiData.prixVenteUnitaire || 0);

            if (coutTotal > 0) {
                roiPourcentage = ((revenuTotal - coutTotal) / coutTotal) * 100;
            }

            roiTrend = roiData.roiTrend || 'stable';
        }

        // Récupérer les données d'économies depuis la table economies
        // Calculer la somme manuellement ou utiliser aggregate
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);

        const economiesAgg = await prisma.economies.aggregate({
            _sum: {
                eauEconomiseePourcentage: true,
                engraisEconomisePourcentage: true,
                pertesEviteesPourcentage: true,
                valeurEauEconomiseeFcfa: true,
                valeurEngraisEconomiseFcfa: true,
                valeurPertesEviteesFcfa: true,
                economiesTotalesFcfa: true
            },
            where: {
                userId,
                dateFin: { gte: sixMonthsAgo }
            }
        });

        const economies = {
            eau_economisee: Number(economiesAgg._sum.eauEconomiseePourcentage || 0),
            engrais_economise: Number(economiesAgg._sum.engraisEconomisePourcentage || 0),
            pertes_evitees: Number(economiesAgg._sum.pertesEviteesPourcentage || 0),
            val_eau: Number(economiesAgg._sum.valeurEauEconomiseeFcfa || 0),
            val_engrais: Number(economiesAgg._sum.valeurEngraisEconomiseFcfa || 0),
            val_pertes: Number(economiesAgg._sum.valeurPertesEviteesFcfa || 0),
            total: Number(economiesAgg._sum.economiesTotalesFcfa || 0)
        };

        // Obtenir les rendements par culture depuis la table rendements_par_culture
        // Requête simplifiée compatible MySQL
        const rendementsCulturesRaw = await prisma.$queryRaw`
            SELECT 
                c.nom as culture,
                COALESCE(AVG(rpc.rendement_kg_ha), 0) as rendement_actuel,
                c.rendement_optimal as rendement_objectif,
                COALESCE(SUM(DISTINCT p.superficie), 0) as superficie,
                0 as revenus,
                CASE 
                    WHEN c.rendement_moyen > 0 THEN 
                        ((COALESCE(AVG(rpc.rendement_kg_ha), 0) - c.rendement_moyen) / c.rendement_moyen) * 100
                    ELSE 0
                END as improvement
            FROM cultures c
            LEFT JOIN rendements_par_culture rpc ON c.id = rpc.culture_id
            LEFT JOIN parcelles p ON rpc.parcelle_id = p.id
            WHERE p.user_id = ${userId} AND rpc.id IS NOT NULL
            GROUP BY c.id, c.nom, c.rendement_moyen, c.rendement_optimal
            ORDER BY rendement_actuel DESC
            LIMIT 10
        `;

        const rendementesParCulture = rendementsCulturesRaw.map(row => ({
            culture: row.culture,
            rendement_actuel: parseFloat(row.rendement_actuel) || 0,
            rendement_objectif: parseFloat(row.rendement_objectif) || 0,
            superficie: parseFloat(row.superficie) || 0,
            revenus: parseFloat(row.revenus) || 0,
            improvement: parseFloat(row.improvement) || 0
        }));

        // Obtenir les parcelles performantes depuis la table performance_parcelles
        // EXTRACT(YEAR) -> logique simple dans le where
        const currentYear = new Date().getFullYear();

        const performanceParcellesRaw = await prisma.performanceParcelle.findMany({
            where: {
                userId,
                annee: currentYear
            },
            include: {
                parcelle: { select: { nom: true } }
            },
            orderBy: { rendementMoyen: 'desc' },
            take: 5
        });

        const performanceParcelles = performanceParcellesRaw.map(pp => ({
            parcelle_id: pp.parcelleId,
            nom: pp.parcelle.nom,
            rendement: Number(pp.rendementMoyen || 0),
            score_qualite: Number(pp.scoreQualiteSol || 0),
            meilleure_pratique: pp.meilleurePratique || ''
        }));

        // Calculer l'amélioration moyenne à partir des rendements
        const avgImprovement = rendementesParCulture.length > 0
            ? rendementesParCulture.reduce((sum, r) => sum + r.improvement, 0) / rendementesParCulture.length
            : 0;

        // Production mensuelle (12 derniers mois) depuis rendements_par_culture
        const twelveMonthsAgo = new Date();
        twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);

        const productionMensuelleRaw = await prisma.$queryRaw`
            SELECT 
                DATE_FORMAT(rpc.created_at, '%Y-%m') as mois,
                SUM(rpc.rendement_kg_ha * p.superficie) as production,
                0 as saison_precedente
            FROM rendements_par_culture rpc
            JOIN parcelles p ON rpc.parcelle_id = p.id
            WHERE p.user_id = ${userId}
              AND rpc.created_at >= ${twelveMonthsAgo}
            GROUP BY mois
            ORDER BY mois ASC
        `;

        const moisNoms = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
        const productionMensuelle = productionMensuelleRaw.map(row => {
            const [, m] = (row.mois || '').split('-');
            const monthIdx = parseInt(m, 10) - 1;
            return {
                mois: moisNoms[monthIdx] || row.mois,
                production: parseFloat(row.production) || 0,
                saisonPrecedente: parseFloat(row.saison_precedente) || 0
            };
        });

        const stats = {
            roi_percentage: roiPourcentage,
            roi_trend: roiTrend,
            // Web frontend expects 'roi' as object
            roi: {
                coutTotal: coutTotal,
                revenuTotal: revenuTotal,
                roiPourcentage: roiPourcentage,
                variation: roiTrend === 'hausse' ? 5.2 : roiTrend === 'baisse' ? -3.1 : 0
            },
            rendement: {
                value: avgImprovement > 0
                    ? `+${avgImprovement.toFixed(1)}%`
                    : `${(avgImprovement || 0).toFixed(1)}%`,
                vs_traditional: true
            },
            eau_economisee: `${economies.eau_economisee.toFixed(1)}%`,
            engrais_reduction: `${economies.engrais_economise.toFixed(1)}%`,
            pertes_maladies: `${economies.pertes_evitees.toFixed(1)}%`,
            rendements_par_culture: rendementesParCulture,
            // Web frontend also expects 'rendements_cultures'
            rendements_cultures: rendementesParCulture,
            economies: {
                eau: economies.val_eau,
                engrais: economies.val_engrais,
                pertes_evitees: economies.val_pertes,
                total: economies.total
            },
            performance_parcelles: performanceParcelles,
            production_mensuelle: productionMensuelle
        };

        res.json({
            success: true,
            data: stats
        });
    } catch (error) {
        logger.error('Error fetching analytics:', error.message);
        next(error);
    }
};

/**
 * Obtenir les statistiques des parcelles
 */
async function getParcellesStats(userId) {
    const parcellesAgg = await prisma.parcelle.aggregate({
        _count: { id: true },
        _sum: { superficie: true },
        where: { userId }
    });

    // Obtenir les cultures uniques directement depuis parcelles (cultureActuelle)
    const parcellesWithCulture = await prisma.parcelle.findMany({
        where: { 
            userId,
            cultureActuelle: { not: null }
        },
        select: { cultureActuelle: true },
        distinct: ['cultureActuelle']
    });
    const cultures = parcellesWithCulture
        .map(p => p.cultureActuelle)
        .filter(Boolean);

    const parcelles = await prisma.parcelle.findMany({
        where: { userId },
        select: {
            nom: true,
            cultureActuelle: true,
            superficie: true,
            sante: true
        }
    });

    // La logique de boucle de performance basée sur la santé de la parcelle
    const performance = parcelles.map(p => {
        const cultureNom = p.cultureActuelle || 'Non définie';
        // Score basé sur la santé: OPTIMAL=80, SURVEILLANCE=50, CRITIQUE=20
        let score = 50;
        if (p.sante === 'OPTIMAL') score = 80;
        if (p.sante === 'CRITIQUE') score = 20;
        
        return {
            nom: `${cultureNom} - ${p.nom}`,
            score,
            above_average: score >= 50
        };
    });

    return {
        total: parcellesAgg._count.id || 0,
        superficie_totale: Number(parcellesAgg._sum.superficie || 0),
        cultures,
        performance
    };
}

/**
 * Obtenir les statistiques du marketplace/revenus
 */
async function getMarketplaceStats(userId) {
    const [salesAgg, purchasesAgg] = await Promise.all([
        prisma.marketplaceCommande.aggregate({
            _count: { id: true },
            _sum: { prixTotal: true },
            _avg: { prixTotal: true },
            where: { vendeurId: userId, statut: 'LIVREE' }
        }),
        prisma.marketplaceCommande.aggregate({
            _sum: { prixTotal: true },
            where: { acheteurId: userId, statut: 'LIVREE' }
        })
    ]);

    return {
        ventes: salesAgg._count.id || 0,
        revenue: Number(salesAgg._sum.prixTotal || 0),
        revenu_moyen: Number(salesAgg._avg.prixTotal || 0),
        depenses: Number(purchasesAgg._sum.prixTotal || 0)
    };
}

/**
 * Obtenir les statistiques de rendement par culture
 * Optimisé pour éviter les requêtes N+1
 */
async function getYieldStats(userId) {
    // Requête optimisée - UNE SEULE requête au lieu de N+1
    const yieldDataRaw = await prisma.$queryRaw`
        SELECT 
            c.nom as culture,
            COUNT(DISTINCT p.id) as nombre_parcelles,
            AVG(p.superficie) as superficie_moyenne,
            COALESCE(AVG(pl.rendement_par_hectare), 0) as actual_yield,
            c.rendement_moyen as traditional_yield,
            c.rendement_optimal as optimal_yield
        FROM parcelles p
        JOIN plantations pl ON p.id = pl.parcelle_id AND pl.statut = 'active'
        JOIN cultures c ON pl.culture_id = c.id
        WHERE p.user_id = ${userId}
        GROUP BY c.id, c.nom, c.rendement_moyen, c.rendement_optimal
    `;

    const traditionalYields = {
        'Maïs': 2.0,
        'Riz': 2.0,
        'Tomate': 15.0,
        'Cacao': 0.5,
        'Café': 0.7,
        'Anacarde': 0.6,
        'Hévéa': 1.5,
        'Coton': 1.2
    };

    const yieldData = yieldDataRaw.map(row => {
        const actualYield = Number(row.actual_yield || 0);
        const traditionalYield = row.traditional_yield 
            ? Number(row.traditional_yield) 
            : (traditionalYields[row.culture] || 2.0);

        // Calculer l'amélioration seulement si on a des données réelles
        let improvement = 0;
        if (actualYield > 0 && traditionalYield > 0) {
            improvement = Math.round(((actualYield - traditionalYield) / traditionalYield) * 100);
        }

        return {
            culture: row.culture,
            rendement_actuel: Math.round(actualYield * 10) / 10,
            rendement_traditionnel: traditionalYield,
            improvement
        };
    });

    return yieldData;
}

/**
 * Calculer le ROI
 */
function calculateROI(parcellesStats, marketplaceStats) {
    // Calcul ROI simplifié
    // Scénario réel: (Revenu - Coûts) / Coûts * 100
    const estimatedCosts = marketplaceStats.depenses + (parcellesStats.superficie_totale * 50000); // Coût estimé par hectare
    const revenue = marketplaceStats.revenue;

    if (estimatedCosts === 0) {
        return { percentage: 0, trend: '0%' };
    }

    const roiPercentage = Math.round(((revenue - estimatedCosts) / estimatedCosts) * 100);
    const trend = roiPercentage > 200 ? '+23%' : roiPercentage > 100 ? '+15%' : '+8%';

    return {
        percentage: Math.max(0, roiPercentage),
        trend
    };
}

/**
 * Obtenir des analytiques détaillées pour une parcelle spécifique
 */
exports.getParcelleAnalytics = async (req, res, next) => {
    try {
        const { parcelleId } = req.params;
        const userId = req.user.id;

        // Vérifier la propriété
        const parcelle = await prisma.parcelle.findFirst({
            where: { id: parcelleId, userId }
        });

        if (!parcelle) {
            return res.status(404).json({
                success: false,
                message: 'Parcelle non trouvée'
            });
        }

        // Obtenir le résumé des données capteurs (Compatible MySQL - AVG retourne un décimal)
        const sensorsDataRaw = await prisma.$queryRaw`
            SELECT 
                c.type,
                CAST(COUNT(m.id) AS SIGNED) as nombre_mesures,
                AVG(CAST(m.valeur AS DECIMAL(10,2))) as valeur_moyenne
            FROM mesures m
            JOIN capteurs c ON m.capteur_id = c.id
            WHERE c.parcelle_id = ${parcelleId}
            GROUP BY c.type
        `;

        const sensorsData = sensorsDataRaw.map(s => ({
            type: s.type,
            nombre_mesures: Number(s.nombre_mesures),
            valeur_moyenne: s.valeur_moyenne
        }));

        res.json({
            success: true,
            data: {
                parcelle: {
                    nom: parcelle.nom,
                    superficie: parcelle.superficie,
                    culture: parcelle.cultureActuelle // Renommé dans le schéma
                    // Note: la colonne 'culture' dans l'ancien schéma était probablement 'culture_actuelle' ou via plantations.
                    // Le schéma a 'cultureActuelle'.
                },
                sensors: sensorsData,
                // Des analytiques supplémentaires peuvent être ajoutées ici
            }
        });
    } catch (error) {
        next(error);
    }
};

/**
 * Obtenir les statistiques publiques de la plateforme (pour la landing page)
 */
exports.getPublicStats = async (req, res, next) => {
    try {
        const [hectaresAgg, totalFarmers, totalCrops] = await Promise.all([
            prisma.parcelle.aggregate({ _sum: { superficie: true } }),
            prisma.user.count({ where: { role: 'PRODUCTEUR' } }),
            prisma.culture.count()
        ]);

        res.json({
            success: true,
            data: {
                hectares: Math.round(Number(hectaresAgg._sum.superficie || 0)),
                agriculteurs: totalFarmers,
                cultures: totalCrops,
                precision: 94
            }
        });
    } catch (error) {
        logger.error('Error fetching public stats:', error.message);
        // Fallback checks
        res.json({
            success: true,
            data: {
                hectares: '10K+',
                agriculteurs: '5000+',
                cultures: '25+',
                precision: '94%'
            }
        });
    }
};

/**
 * Comparaison saisonnière des rendements et performances
 */
exports.getSeasonalComparison = async (req, res) => {
    try {
        const userId = req.user.id;
        const { annee1, annee2, parcelleId } = req.query;
        const currentYear = new Date().getFullYear();
        const year1 = parseInt(annee1) || currentYear - 1;
        const year2 = parseInt(annee2) || currentYear;

        const where = { parcelle: { userId } };
        if (parcelleId) where.parcelleId = parcelleId;

        // Rendements par culture pour les deux années
        const [rendements1, rendements2] = await Promise.all([
            prisma.rendementParCulture.findMany({
                where: { ...where, annee: year1 },
                include: { culture: { select: { nom: true, categorie: true } }, parcelle: { select: { nom: true } } }
            }),
            prisma.rendementParCulture.findMany({
                where: { ...where, annee: year2 },
                include: { culture: { select: { nom: true, categorie: true } }, parcelle: { select: { nom: true } } }
            })
        ]);

        // Performance parcelles
        const [perf1, perf2] = await Promise.all([
            prisma.performanceParcelle.findMany({
                where: { userId, annee: year1 },
                include: { parcelle: { select: { nom: true } } }
            }),
            prisma.performanceParcelle.findMany({
                where: { userId, annee: year2 },
                include: { parcelle: { select: { nom: true } } }
            })
        ]);

        // Economies
        const economies = await prisma.economies.findFirst({
            where: { userId },
            orderBy: { createdAt: 'desc' }
        });

        // Calcul des totaux
        const totalRendement1 = rendements1.reduce((sum, r) => sum + (r.rendementKgHa || 0), 0);
        const totalRendement2 = rendements2.reduce((sum, r) => sum + (r.rendementKgHa || 0), 0);
        const evolution = totalRendement1 > 0
            ? ((totalRendement2 - totalRendement1) / totalRendement1 * 100).toFixed(1)
            : 0;

        res.json({
            success: true,
            data: {
                saison1: { annee: year1, rendements: rendements1, performances: perf1, totalRendement: totalRendement1 },
                saison2: { annee: year2, rendements: rendements2, performances: perf2, totalRendement: totalRendement2 },
                evolution: parseFloat(evolution),
                economies,
                comparaison: {
                    rendementProgression: `${evolution}%`,
                    nombreCultures1: rendements1.length,
                    nombreCultures2: rendements2.length
                }
            }
        });
    } catch (error) {
        logger.error('Erreur comparaison saisonnière:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur' });
    }
};

/**
 * Exporter les données analytiques (CSV ou JSON)
 */
exports.exportAnalytics = async (req, res) => {
    try {
        const userId = req.user.id;
        const { format = 'csv', type = 'all', types } = req.query;

        const requestedTypes = new Set(
            String(types || '')
                .split(',')
                .map((t) => t.trim().toLowerCase())
                .filter(Boolean)
        );

        const wants = (name) => {
            if (type === 'all') return true;
            if (String(type).toLowerCase() === name) return true;
            return requestedTypes.has(name);
        };

        const data = {};

        if (wants('parcelles') || requestedTypes.has('users')) {
            data.parcelles = await prisma.parcelle.findMany({
                where: { userId, isActive: true }
            });
        }

        if (wants('rendements') || requestedTypes.has('productions')) {
            data.rendements = await prisma.rendementParCulture.findMany({
                where: { parcelle: { userId } },
                include: { culture: { select: { nom: true } }, parcelle: { select: { nom: true } } },
                orderBy: { annee: 'desc' }
            });
        }

        if (wants('mesures')) {
            data.mesures = await prisma.mesure.findMany({
                where: { capteur: { parcelle: { userId } } },
                include: { capteur: { select: { nom: true, type: true } } },
                orderBy: { timestamp: 'desc' },
                take: 1000
            });
        }

        if (wants('alertes')) {
            data.alertes = await prisma.alerte.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                take: 500
            });
        }

        if (format === 'csv') {
            // Générer CSV pour le type demandé
            const items = data[type] || data.parcelles || [];
            if (items.length === 0) {
                return res.status(200).send('Aucune donnée à exporter');
            }

            const flattenObject = (obj, prefix = '') => {
                const result = {};
                for (const [key, value] of Object.entries(obj)) {
                    if (value && typeof value === 'object' && !Array.isArray(value) && !(value instanceof Date)) {
                        Object.assign(result, flattenObject(value, `${prefix}${key}_`));
                    } else {
                        result[`${prefix}${key}`] = value;
                    }
                }
                return result;
            };

            const flatItems = items.map(item => flattenObject(JSON.parse(JSON.stringify(item))));
            const headers = [...new Set(flatItems.flatMap(item => Object.keys(item)))];
            const csvRows = [headers.join(',')];

            for (const item of flatItems) {
                csvRows.push(headers.map(h => {
                    const val = item[h] ?? '';
                    return typeof val === 'string' && val.includes(',') ? `"${val}"` : val;
                }).join(','));
            }

            res.setHeader('Content-Type', 'text/csv; charset=utf-8');
            res.setHeader('Content-Disposition', `attachment; filename=agrosmart_${type}_${new Date().toISOString().slice(0, 10)}.csv`);
            return res.send(csvRows.join('\n'));
        }

        // JSON export
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', `attachment; filename=agrosmart_${type}_${new Date().toISOString().slice(0, 10)}.json`);
        return res.json({ success: true, data, exportDate: new Date().toISOString() });
    } catch (error) {
        logger.error('Erreur export analytics:', error);
        res.status(500).json({ success: false, message: 'Erreur serveur' });
    }
};

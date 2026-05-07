/**
 * Contrôleur Calendrier Agricole
 * Gestion des activités planifiées
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Obtenir toutes les activités du calendrier
 * Avec filtres optionnels
 */
exports.getActivites = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { 
      parcelleId, 
      typeActivite, 
      statut, 
      priorite,
      dateDebut, 
      dateFin,
      page = 1, 
      limit = 50 
    } = req.query;

    const where = { userId };
    
    if (parcelleId) where.parcelleId = parcelleId;
    if (typeActivite) where.typeActivite = typeActivite;
    if (statut) where.statut = statut;
    if (priorite) where.priorite = priorite;
    
    // Filtrer par plage de dates
    if (dateDebut || dateFin) {
      where.dateDebut = {};
      if (dateDebut) where.dateDebut.gte = new Date(dateDebut);
      if (dateFin) where.dateDebut.lte = new Date(dateFin);
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [activites, total] = await Promise.all([
      prisma.calendrierActivite.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: [
          { dateDebut: 'asc' },
          { priorite: 'desc' }
        ],
        include: {
          parcelle: {
            select: {
              id: true,
              nom: true,
              superficie: true
            }
          }
        }
      }),
      prisma.calendrierActivite.count({ where })
    ]);

    res.json({
      success: true,
      data: activites,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    logger.error('Erreur récupération activités calendrier', { error: error.message });
    next(error);
  }
};

/**
 * Obtenir une activité par ID
 */
exports.getActiviteById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const activite = await prisma.calendrierActivite.findFirst({
      where: { id, userId },
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true,
            superficie: true,
            cultureActuelle: true
          }
        }
      }
    });

    if (!activite) {
      return res.status(404).json({
        success: false,
        message: 'Activité non trouvée'
      });
    }

    res.json({
      success: true,
      data: activite
    });
  } catch (error) {
    logger.error('Erreur récupération activité', { error: error.message });
    next(error);
  }
};

/**
 * Créer une nouvelle activité
 */
exports.createActivite = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      parcelleId,
      titre,
      description,
      typeActivite,
      priorite,
      dateDebut,
      dateFin,
      dateRappel,
      estRecurrente,
      frequenceJours,
      dateFinRecurrence,
      coutEstime,
      notesTechniques,
      produitsUtilises
    } = req.body;

    // Validation de la parcelle si fournie
    if (parcelleId) {
      const parcelle = await prisma.parcelle.findFirst({
        where: { id: parcelleId, userId }
      });
      
      if (!parcelle) {
        return res.status(404).json({
          success: false,
          message: 'Parcelle non trouvée'
        });
      }
    }

    const activite = await prisma.calendrierActivite.create({
      data: {
        userId,
        parcelleId,
        titre,
        description,
        typeActivite,
        priorite,
        dateDebut: new Date(dateDebut),
        dateFin: dateFin ? new Date(dateFin) : null,
        dateRappel: dateRappel ? new Date(dateRappel) : null,
        estRecurrente: estRecurrente || false,
        frequenceJours: estRecurrente ? frequenceJours : null,
        dateFinRecurrence: estRecurrente && dateFinRecurrence ? new Date(dateFinRecurrence) : null,
        coutEstime,
        notesTechniques,
        produitsUtilises: produitsUtilises ? JSON.stringify(produitsUtilises) : null
      },
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true
          }
        }
      }
    });

    logger.info('Activité calendrier créée', { activiteId: activite.id, userId });

    res.status(201).json({
      success: true,
      message: 'Activité créée avec succès',
      data: activite
    });
  } catch (error) {
    logger.error('Erreur création activité', { error: error.message });
    next(error);
  }
};

/**
 * Mettre à jour une activité
 */
exports.updateActivite = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const updateData = { ...req.body };

    // Vérifier l'existence et l'appartenance
    const existingActivite = await prisma.calendrierActivite.findFirst({
      where: { id, userId }
    });

    if (!existingActivite) {
      return res.status(404).json({
        success: false,
        message: 'Activité non trouvée'
      });
    }

    // Conversion des dates
    if (updateData.dateDebut) updateData.dateDebut = new Date(updateData.dateDebut);
    if (updateData.dateFin) updateData.dateFin = new Date(updateData.dateFin);
    if (updateData.dateRappel) updateData.dateRappel = new Date(updateData.dateRappel);
    if (updateData.dateFinRecurrence) updateData.dateFinRecurrence = new Date(updateData.dateFinRecurrence);
    
    // Gestion des produits utilisés
    if (updateData.produitsUtilises) {
      updateData.produitsUtilises = JSON.stringify(updateData.produitsUtilises);
    }

    const activite = await prisma.calendrierActivite.update({
      where: { id },
      data: updateData,
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true
          }
        }
      }
    });

    logger.info('Activité mise à jour', { activiteId: id, userId });

    res.json({
      success: true,
      message: 'Activité mise à jour avec succès',
      data: activite
    });
  } catch (error) {
    logger.error('Erreur mise à jour activité', { error: error.message });
    next(error);
  }
};

/**
 * Supprimer une activité
 */
exports.deleteActivite = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const activite = await prisma.calendrierActivite.findFirst({
      where: { id, userId }
    });

    if (!activite) {
      return res.status(404).json({
        success: false,
        message: 'Activité non trouvée'
      });
    }

    await prisma.calendrierActivite.delete({
      where: { id }
    });

    logger.info('Activité supprimée', { activiteId: id, userId });

    res.json({
      success: true,
      message: 'Activité supprimée avec succès'
    });
  } catch (error) {
    logger.error('Erreur suppression activité', { error: error.message });
    next(error);
  }
};

/**
 * Obtenir les activités à venir (prochains 7 jours)
 */
exports.getActivitesProchaines = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { jours = 7 } = req.query;

    const maintenant = new Date();
    const dateLimite = new Date();
    dateLimite.setDate(dateLimite.getDate() + parseInt(jours));

    const activites = await prisma.calendrierActivite.findMany({
      where: {
        userId,
        statut: { in: ['PLANIFIEE', 'EN_COURS'] },
        dateDebut: {
          gte: maintenant,
          lte: dateLimite
        }
      },
      orderBy: [
        { dateDebut: 'asc' },
        { priorite: 'desc' }
      ],
      include: {
        parcelle: {
          select: {
            id: true,
            nom: true
          }
        }
      }
    });

    res.json({
      success: true,
      data: activites,
      count: activites.length
    });
  } catch (error) {
    logger.error('Erreur récupération activités prochaines', { error: error.message });
    next(error);
  }
};

/**
 * Obtenir les statistiques du calendrier
 */
exports.getStatistiques = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const [
      totalActivites,
      activitesPlanifiees,
      activitesEnCours,
      activitesTerminees,
      activitesUrgentes,
      coutTotalEstime
    ] = await Promise.all([
      prisma.calendrierActivite.count({ where: { userId } }),
      prisma.calendrierActivite.count({ where: { userId, statut: 'PLANIFIEE' } }),
      prisma.calendrierActivite.count({ where: { userId, statut: 'EN_COURS' } }),
      prisma.calendrierActivite.count({ where: { userId, statut: 'TERMINEE' } }),
      prisma.calendrierActivite.count({ 
        where: { 
          userId, 
          priorite: 'URGENTE',
          statut: { in: ['PLANIFIEE', 'EN_COURS'] }
        } 
      }),
      prisma.calendrierActivite.aggregate({
        where: { userId },
        _sum: { coutEstime: true }
      })
    ]);

    // Répartition par type d'activité
    const repartitionParType = await prisma.calendrierActivite.groupBy({
      by: ['typeActivite'],
      where: { userId },
      _count: true
    });

    res.json({
      success: true,
      data: {
        totalActivites,
        activitesPlanifiees,
        activitesEnCours,
        activitesTerminees,
        activitesUrgentes,
        coutTotalEstime: coutTotalEstime._sum.coutEstime || 0,
        repartitionParType: repartitionParType.map(item => ({
          type: item.typeActivite,
          count: item._count
        }))
      }
    });
  } catch (error) {
    logger.error('Erreur récupération statistiques calendrier', { error: error.message });
    next(error);
  }
};

/**
 * Marquer une activité comme terminée
 */
exports.marquerTerminee = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const activite = await prisma.calendrierActivite.findFirst({
      where: { id, userId }
    });

    if (!activite) {
      return res.status(404).json({
        success: false,
        message: 'Activité non trouvée'
      });
    }

    const activiteUpdate = await prisma.calendrierActivite.update({
      where: { id },
      data: { 
        statut: 'TERMINEE',
        dateFin: new Date()
      }
    });

    logger.info('Activité marquée comme terminée', { activiteId: id, userId });

    res.json({
      success: true,
      message: 'Activité marquée comme terminée',
      data: activiteUpdate
    });
  } catch (error) {
    logger.error('Erreur marquage activité terminée', { error: error.message });
    next(error);
  }
};

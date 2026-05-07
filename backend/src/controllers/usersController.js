/**
 * Contrôleur des utilisateurs
 * AgroSmart - Système Agricole Intelligent
 */

const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const logger = require('../utils/logger');

/**
 * Obtenir tous les utilisateurs avec pagination
 */
exports.getAll = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;
    const { role, status, search } = req.query;

    // Build where clause
    const where = {};

    if (role) {
      where.role = role.toUpperCase();
    }

    if (status) {
      where.status = status.toUpperCase();
    }

    if (search) {
      where.OR = [
        { nom: { contains: search } }, // Removed mode: 'insensitive' for compatibility/simplicity
        { prenoms: { contains: search } },
        { email: { contains: search } },
        { telephone: { contains: search } }
      ];
    }

    // Count total
    const total = await prisma.user.count({ where });

    // Get paginated results
    const users = await prisma.user.findMany({
      where,
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        role: true,
        status: true,
        regionId: true,
        createdAt: true,
        derniereConnexion: true
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset
    });

    res.json({
      success: true,
      data: users,
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
 * Obtenir les statistiques des utilisateurs
 */
exports.getStats = async (req, res, next) => {
  try {
    // Get stats using Prisma aggregation
    const total = await prisma.user.count();
    const producteurs = await prisma.user.count({ where: { role: 'PRODUCTEUR' } });
    const conseillers = await prisma.user.count({ where: { role: 'CONSEILLER' } });
    const admins = await prisma.user.count({ where: { role: 'ADMIN' } });
    const partenaires = await prisma.user.count({ where: { role: 'PARTENAIRE' } });

    const actifs = await prisma.user.count({ where: { status: 'ACTIF' } });
    const en_attente = await prisma.user.count({ where: { status: 'EN_ATTENTE' } });
    const suspendus = await prisma.user.count({ where: { status: 'SUSPENDU' } });

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const actifs_7j = await prisma.user.count({
      where: { derniereConnexion: { gte: sevenDaysAgo } }
    });

    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const nouveaux_30j = await prisma.user.count({
      where: { createdAt: { gte: thirtyDaysAgo } }
    });

    res.json({
      success: true,
      data: {
        total,
        producteurs,
        conseillers,
        admins,
        partenaires,
        actifs,
        en_attente,
        suspendus,
        actifs_7j,
        nouveaux_30j
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les producteurs
 */
exports.getProducteurs = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    // Get producteurs with parcelles aggregation
    const producteurs = await prisma.user.findMany({
      where: { role: 'PRODUCTEUR' },
      include: {
        parcelles: {
          select: {
            id: true,
            superficie: true
          }
        },
        region: {
          select: { nom: true }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
      skip: offset
    });

    // Transform data to match expected format
    const data = producteurs.map(p => ({
      ...p,
      nb_parcelles: p.parcelles.length,
      superficie_totale: p.parcelles.reduce((sum, parc) => sum + Number(parc.superficie || 0), 0)
    }));

    const total = await prisma.user.count({
      where: { role: 'PRODUCTEUR' }
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
 * Obtenir un utilisateur par son ID
 */
exports.getById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        role: true,
        status: true,
        regionId: true,
        // village: true, // Removed if not in schema. Check schema? Default schema has no village.
        createdAt: true,
        derniereConnexion: true
      }
    });

    if (!user) {
      throw errors.notFound('Utilisateur non trouvé');
    }

    res.json({
      success: true,
      data: user
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Créer un nouvel utilisateur (par admin)
 */
exports.create = async (req, res, next) => {
  try {
    const { email, telephone, password, nom, prenoms, role = 'PRODUCTEUR' } = req.body;

    // Vérifier si l'utilisateur existe déjà
    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { email },
          { telephone }
        ]
      }
    });

    if (existing) {
      throw errors.conflict('Un utilisateur avec cet email ou ce téléphone existe déjà');
    }

    // Hasher le mot de passe
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = await prisma.user.create({
      data: {
        email,
        telephone,
        passwordHash: hashedPassword,
        nom,
        prenoms,
        role: role.toUpperCase(),
        status: 'ACTIF'
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        role: true,
        status: true,
        createdAt: true
      }
    });

    logger.audit('Création utilisateur par admin', {
      createdBy: req.user.id,
      newUserId: newUser.id
    });

    res.status(201).json({
      success: true,
      message: 'Utilisateur créé avec succès',
      data: newUser
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Mettre à jour un utilisateur
 */
exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nom, prenoms, role, region_id } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id },
      data: {
        ...(nom && { nom }),
        ...(prenoms && { prenoms }),
        ...(role && { role: role.toUpperCase() }),
        ...(region_id && { regionId: region_id }),
        updatedAt: new Date()
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        role: true,
        status: true
      }
    });

    logger.audit('Mise à jour utilisateur', { updatedBy: req.user.id, userId: id });

    res.json({
      success: true,
      message: 'Utilisateur mis à jour',
      data: updatedUser
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Mettre à jour le statut d'un utilisateur
 */
exports.updateStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!['ACTIF', 'EN_ATTENTE', 'SUSPENDU', 'INACTIF'].includes(status.toUpperCase())) {
      // Schema includes INACTIF as per Create Table lines 45: ENUM('ACTIF', 'INACTIF', 'SUSPENDU', 'EN_ATTENTE')
      throw errors.badRequest('Statut invalide');
    }

    const updatedUser = await prisma.user.update({
      where: { id },
      data: {
        status: status.toUpperCase(),
        updatedAt: new Date()
      },
      select: {
        id: true,
        email: true,
        nom: true,
        prenoms: true,
        status: true
      }
    });

    logger.audit('Changement statut utilisateur', {
      changedBy: req.user.id,
      userId: id,
      newStatus: status
    });

    res.json({
      success: true,
      message: `Statut changé en "${status}"`,
      data: updatedUser
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Supprimer un utilisateur
 */
exports.delete = async (req, res, next) => {
  try {
    const { id } = req.params;

    // Vérifier que l'utilisateur existe
    const user = await prisma.user.findUnique({
      where: { id },
      select: { id: true, email: true }
    });

    if (!user) {
      throw errors.notFound('Utilisateur non trouvé');
    }

    // Soft delete - on change le statut a SUSPENDU ou INACTIF
    await prisma.user.update({
      where: { id },
      data: {
        status: 'INACTIF', // Changed from SUPPRIME to INACTIF
        updatedAt: new Date()
      }
    });

    logger.audit('Suppression utilisateur', { deletedBy: req.user.id, userId: id });

    res.json({
      success: true,
      message: 'Utilisateur supprimé'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les parcelles d'un utilisateur
 */
exports.getParcelles = async (req, res, next) => {
  try {
    const { id } = req.params;

    const parcelles = await prisma.parcelle.findMany({
      where: { userId: id },
      select: {
        id: true,
        nom: true,
        superficie: true,
        latitude: true,
        longitude: true,
        // typeSol: true, // Check if logic is needed for mismatch
        // status: true, // use statut if needed? No, parcelle model uses typeSol and statut. Code uses defaults which usually map to camelCase in Prisma Client unless @map is used.
        // Schema @map("type_sol") -> typeSol property in client?
        // Let's assume Prisma naming conventions hold (camelCase property for snake_case column).
        // If my previous refactor on parcellesController used typeSol, then here it should be fine.
        typeSol: true,
        statut: true, // Corrected from status to statut
        createdAt: true
      },
      orderBy: { createdAt: 'desc' }
    });

    res.json({
      success: true,
      data: parcelles
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir les alertes d'un utilisateur
 */
exports.getAlertes = async (req, res, next) => {
  try {
    const { id } = req.params;
    const limit = parseInt(req.query.limit) || 50;

    const alertes = await prisma.alerte.findMany({
      where: { userId: id },
      // include: {
      //   parcelle: {          // Removed non-existent relation
      //     select: { nom: true }
      //   }
      // },
      orderBy: { createdAt: 'desc' },
      take: limit
    });

    // Transform to match expected format
    const data = alertes.map(a => ({
      ...a,
      parcelle_nom: null // a.parcelle?.nom -> null
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

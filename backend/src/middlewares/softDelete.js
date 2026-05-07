/**
 * Soft Delete Middleware pour Prisma
 * AgroSmart - Backend
 * 
 * Ce middleware intercepte les opérations de suppression et les convertit
 * en mises à jour de soft delete. Il filtre également automatiquement
 * les enregistrements supprimés des requêtes de lecture.
 * 
 * Tables avec soft delete:
 * - User
 * - Parcelle
 * - MarketplaceProduit
 * - ForumPost
 * - Badge
 * - Realisation
 */

const { Prisma } = require('@prisma/client');
const logger = require('../utils/logger');

/**
 * Liste des modèles avec soft delete
 */
const SOFT_DELETE_MODELS = [
  'User',
  'Parcelle',
  'MarketplaceProduit',
  'ForumPost',
  'Badge',
  'Realisation'
];

/**
 * Middleware pour transformer les delete en soft delete
 */
function softDeleteMiddleware(prisma) {
  prisma.$use(async (params, next) => {
    // =============================================
    // Soft Delete pour les suppressions
    // =============================================
    
    if (SOFT_DELETE_MODELS.includes(params.model)) {
      // delete -> update avec isActive = false
      if (params.action === 'delete') {
        params.action = 'update';
        params.args.data = {
          isActive: false,
          deletedAt: new Date()
        };
        
        logger.info(`[SoftDelete] ${params.model} soft deleted`, {
          model: params.model,
          where: params.args.where
        });
      }
      
      // deleteMany -> updateMany avec isActive = false
      if (params.action === 'deleteMany') {
        params.action = 'updateMany';
        if (params.args.data !== undefined) {
          params.args.data.isActive = false;
          params.args.data.deletedAt = new Date();
        } else {
          params.args.data = {
            isActive: false,
            deletedAt: new Date()
          };
        }
        
        logger.info(`[SoftDelete] ${params.model} batch soft deleted`, {
          model: params.model,
          where: params.args.where
        });
      }
    }

    // =============================================
    // Filtrage automatique des enregistrements supprimés
    // =============================================
    
    if (SOFT_DELETE_MODELS.includes(params.model)) {
      // Pour les lectures, filtrer par défaut les enregistrements supprimés
      // sauf si explicitement demandé avec includeDeleted: true
      
      if (params.action === 'findUnique' || params.action === 'findFirst') {
        // Convertir en findFirst pour ajouter le filtre isActive
        if (!params.args.where?.includeDeleted) {
          params.action = 'findFirst';
          params.args.where = {
            ...params.args.where,
            isActive: true
          };
        }
        // Supprimer le flag includeDeleted
        delete params.args.where?.includeDeleted;
      }
      
      if (params.action === 'findMany') {
        if (!params.args?.where?.includeDeleted) {
          params.args = params.args || {};
          params.args.where = params.args.where || {};
          params.args.where.isActive = true;
        }
        delete params.args?.where?.includeDeleted;
      }
      
      if (params.action === 'count') {
        if (!params.args?.where?.includeDeleted) {
          params.args = params.args || {};
          params.args.where = params.args.where || {};
          params.args.where.isActive = true;
        }
        delete params.args?.where?.includeDeleted;
      }
      
      if (params.action === 'aggregate') {
        if (!params.args?.where?.includeDeleted) {
          params.args = params.args || {};
          params.args.where = params.args.where || {};
          params.args.where.isActive = true;
        }
        delete params.args?.where?.includeDeleted;
      }
    }
    
    return next(params);
  });
}

/**
 * Extension Prisma pour restaurer un enregistrement soft-deleted
 * Usage: await prisma.user.restore({ where: { id: '...' } })
 */
function addRestoreExtension(prisma) {
  return prisma.$extends({
    model: {
      $allModels: {
        /**
         * Restaurer un enregistrement supprimé
         * @param {Object} args - Arguments Prisma (where clause)
         */
        async restore(args) {
          const modelName = this.constructor.name;
          
          if (!SOFT_DELETE_MODELS.includes(modelName)) {
            throw new Error(`Le modèle ${modelName} ne supporte pas le soft delete`);
          }
          
          const context = Prisma.getExtensionContext(this);
          
          return context.update({
            ...args,
            data: {
              isActive: true,
              deletedAt: null
            }
          });
        },
        
        /**
         * Trouver uniquement les enregistrements supprimés
         * @param {Object} args - Arguments Prisma (where clause)
         */
        async findDeleted(args = {}) {
          const modelName = this.constructor.name;
          
          if (!SOFT_DELETE_MODELS.includes(modelName)) {
            throw new Error(`Le modèle ${modelName} ne supporte pas le soft delete`);
          }
          
          const context = Prisma.getExtensionContext(this);
          
          return context.findMany({
            ...args,
            where: {
              ...args.where,
              isActive: false,
              includeDeleted: true
            }
          });
        },
        
        /**
         * Supprimer définitivement (hard delete)
         * @param {Object} args - Arguments Prisma (where clause)
         */
        async hardDelete(args) {
          const context = Prisma.getExtensionContext(this);
          
          // Utiliser la méthode delete native
          return context.$queryRaw`
            DELETE FROM ${Prisma.sql`${this.tableName}`}
            WHERE id = ${args.where.id}
          `;
        }
      }
    }
  });
}

/**
 * Service de gestion du soft delete
 */
const SoftDeleteService = {
  /**
   * Restaurer un utilisateur supprimé
   */
  async restoreUser(prisma, userId) {
    return prisma.user.update({
      where: { id: userId, includeDeleted: true },
      data: {
        isActive: true,
        deletedAt: null,
        deletedBy: null
      }
    });
  },
  
  /**
   * Restaurer une parcelle supprimée
   */
  async restoreParcelle(prisma, parcelleId) {
    return prisma.parcelle.update({
      where: { id: parcelleId, includeDeleted: true },
      data: {
        isActive: true,
        deletedAt: null
      }
    });
  },
  
  /**
   * Restaurer un produit marketplace supprimé
   */
  async restoreProduct(prisma, productId) {
    return prisma.marketplaceProduit.update({
      where: { id: productId, includeDeleted: true },
      data: {
        isActive: true,
        deletedAt: null
      }
    });
  },
  
  /**
   * Restaurer un post de forum supprimé
   */
  async restoreForumPost(prisma, postId) {
    return prisma.forumPost.update({
      where: { id: postId, includeDeleted: true },
      data: {
        isActive: true,
        deletedAt: null
      }
    });
  },
  
  /**
   * Lister les enregistrements supprimés pour un modèle
   */
  async listDeleted(prisma, modelName, options = {}) {
    const { page = 1, limit = 20, ...filters } = options;
    const skip = (page - 1) * limit;
    
    const model = prisma[modelName.toLowerCase()];
    if (!model) {
      throw new Error(`Modèle ${modelName} non trouvé`);
    }
    
    const [items, total] = await Promise.all([
      model.findMany({
        where: {
          isActive: false,
          includeDeleted: true,
          ...filters
        },
        skip,
        take: limit,
        orderBy: { deletedAt: 'desc' }
      }),
      model.count({
        where: {
          isActive: false,
          includeDeleted: true,
          ...filters
        }
      })
    ]);
    
    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit)
    };
  },
  
  /**
   * Purger les enregistrements supprimés depuis plus de X jours
   */
  async purgeOldDeleted(prisma, modelName, daysOld = 90) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysOld);
    
    const model = prisma[modelName.toLowerCase()];
    if (!model) {
      throw new Error(`Modèle ${modelName} non trouvé`);
    }
    
    // Attention: Cette opération est irréversible
    const result = await prisma.$executeRawUnsafe(`
      DELETE FROM ${modelName.toLowerCase()}s
      WHERE is_active = false
      AND deleted_at < ?
    `, cutoffDate);
    
    logger.security(`[SoftDelete] Purged old deleted records`, {
      model: modelName,
      daysOld,
      cutoffDate: cutoffDate.toISOString()
    });
    
    return result;
  }
};

module.exports = {
  softDeleteMiddleware,
  addRestoreExtension,
  SoftDeleteService,
  SOFT_DELETE_MODELS
};

/**
 * Contrôleur du Marketplace
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');
const cache = require('../utils/cache');
const { parsePaginationParams, buildPaginatedResponse, parseSortParams } = require('../utils/pagination');

/* ========== PRODUITS ========== */

exports.getAllProduits = async (req, res, next) => {
  try {
    const { page, limit, skip } = parsePaginationParams(req.query, { limit: 20, maxLimit: 100 });
    const { categorie, prix_min, prix_max, search } = req.query;
    
    // Options de tri
    const orderBy = parseSortParams(
      req.query, 
      ['createdAt', 'prix', 'nom'], 
      { createdAt: 'desc' }
    );

    const cacheKey = `marketplace:products:v1:${page}:${limit}:${categorie || 'all'}:${prix_min || '0'}:${prix_max || 'inf'}:${JSON.stringify(orderBy)}`;

    // Essayer de récupérer depuis le cache
    const cachedData = await cache.get(cacheKey);
    if (cachedData) {
      return res.json({
        success: true,
        ...cachedData,
        source: 'cache'
      });
    }

    const where = {
      actif: true,
      stock: { gt: 0 }
    };
    if (categorie) where.categorie = categorie;
    if (prix_min) where.prix = { ...where.prix, gte: parseFloat(prix_min) };
    if (prix_max) where.prix = { ...where.prix, lte: parseFloat(prix_max) };
    if (search) {
      where.OR = [
        { nom: { contains: search } },
        { description: { contains: search } }
      ];
    }

    // Compter le total pour la pagination
    const total = await prisma.marketplaceProduit.count({ where });

    const produits = await prisma.marketplaceProduit.findMany({
      where,
      include: {
        vendeur: {
          select: {
            nom: true,
            telephone: true,
            adresse: true
          }
        },
        _count: {
          select: { commandes: true }
        }
      },
      orderBy,
      take: limit,
      skip
    });

    const data = produits.map(p => ({
      ...p,
      quantite_disponible: p.stock,
      est_actif: p.actif,
      vendeur_id: p.vendeurId,
      created_at: p.createdAt,
      vendeur_nom: p.vendeur.nom,
      vendeur_telephone: p.vendeur.telephone,
      localisation: p.vendeur.adresse,
      nombre_ventes: p._count.commandes,
      vendeur: undefined, // Cleanup
      _count: undefined // Cleanup
    }));

    // Construire la réponse paginée standardisée
    const response = buildPaginatedResponse(data, page, limit, total);

    // Sauvegarder en cache (TTL 5 minutes)
    await cache.set(cacheKey, { data, pagination: response.pagination }, 300);

    res.json({
      ...response,
      source: 'db'
    });
  } catch (error) {
    next(error);
  }
};

exports.searchProduits = async (req, res, next) => {
  try {
    const { q, categorie } = req.query;

    const where = {
      actif: true,
      stock: { gt: 0 }
    };
    if (categorie) where.categorie = categorie;
    if (q) {
      where.OR = [
        { nom: { contains: q } }, // Case sensitive by default in Prisma, mode: 'insensitive' if postgres. MySQL is case insensitive by default for some collations.
        { description: { contains: q } }
      ];
    }

    const produits = await prisma.marketplaceProduit.findMany({
      where,
      include: {
        vendeur: {
          select: {
            nom: true,
            telephone: true,
            adresse: true
          }
        },
        _count: {
          select: { commandes: true }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: 50
    });

    const data = produits.map(p => ({
      ...p,
      quantite_disponible: p.stock,
      vendeur_id: p.vendeurId,
      created_at: p.createdAt,
      vendeur_nom: p.vendeur.nom,
      vendeur_telephone: p.vendeur.telephone,
      localisation: p.vendeur.adresse,
      nombre_ventes: p._count.commandes,
      vendeur: undefined,
      _count: undefined
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.getMyProduits = async (req, res, next) => {
  try {
    const produits = await prisma.marketplaceProduit.findMany({
      where: { vendeurId: req.user.id },
      orderBy: { createdAt: 'desc' }
    });

    const data = produits.map(p => ({
      ...p,
      quantite_disponible: p.stock,
      vendeur_id: p.vendeurId,
      created_at: p.createdAt
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.createProduit = async (req, res, next) => {
  try {
    const { nom, description, categorie, prix, unite, quantite_disponible, lieu_retrait, livraison_possible,
      type_offre, prix_location_jour, duree_min_location, caution } = req.body;

    // Traiter les images si présentes
    let images = [];
    if (req.files && req.files.length > 0) {
      // TODO: Upload vers stockage (S3, local, etc.)
      images = req.files.map(f => `/uploads/produits/${f.filename}`);
    }

    const type = type_offre || 'vente';
    // Si location, utiliser prix_location_jour comme prix principal si non fourni, ou gérer logique spécifique
    const finalPrix = type === 'location' ? (prix_location_jour || prix) : prix;

    const produit = await prisma.marketplaceProduit.create({
      data: {
        vendeurId: req.user.id,
        nom,
        description,
        categorie,
        prix: parseFloat(finalPrix),
        unite: unite || 'kg',
        stock: parseFloat(quantite_disponible), // using stock field
        // lieuRetrait: lieu_retrait, // Removed as not in schema
        // livraisonPossible: livraison_possible === 'true' || livraison_possible === true, // Removed as not in schema
        images,
        typeOffre: type,
        prixLocationJour: prix_location_jour ? parseFloat(prix_location_jour) : null,
        dureeMinLocation: duree_min_location ? parseInt(duree_min_location) : null,
        caution: caution ? parseFloat(caution) : null,
        actif: true
      }
    });

    // Invalidate cache
    // const cache = require('../utils/cache');
    // await cache.clearPattern('marketplace:products:*');

    logger.audit('Création produit marketplace', { userId: req.user.id, produitId: produit.id });

    res.status(201).json({
      success: true,
      message: 'Produit ajouté au marketplace',
      data: {
        ...produit,
        quantite_disponible: produit.stock,
        vendeur_id: produit.vendeurId,
        created_at: produit.createdAt
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getProduitById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const produit = await prisma.marketplaceProduit.findUnique({
      where: { id },
      include: {
        vendeur: {
          select: {
            nom: true,
            prenoms: true,
            telephone: true,
            // village: true // Removed as not in User schema ? User schema has adresse not village
          }
        }
      }
    });

    if (!produit) {
      throw errors.notFound('Produit non trouvé');
    }

    const data = {
      ...produit,
      quantite_disponible: produit.stock,
      vendeur_id: produit.vendeurId,
      created_at: produit.createdAt,
      vendeur_nom: produit.vendeur.nom,
      vendeur_prenom: produit.vendeur.prenoms,
      vendeur_telephone: produit.vendeur.telephone,
      // vendeur_village: produit.vendeur.village,
      vendeur: undefined
    };

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.updateProduit = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { nom, description, prix, quantite_disponible, statut, type_offre, prix_location_jour } = req.body;

    const produit = await prisma.marketplaceProduit.findUnique({ where: { id } });

    if (!produit) {
      throw errors.notFound('Produit non trouvé');
    }
    if (produit.vendeurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
      throw errors.forbidden('Vous n\'êtes pas autorisé à modifier ce produit');
    }

    const updated = await prisma.marketplaceProduit.update({
      where: { id },
      data: {
        nom,
        description,
        prix: prix ? parseFloat(prix) : undefined,
        stock: quantite_disponible ? parseFloat(quantite_disponible) : undefined,
        actif: statut === 'actif', // Mapping to boolean
        typeOffre: type_offre,
        prixLocationJour: prix_location_jour ? parseFloat(prix_location_jour) : undefined
      }
    });

    // Invalidate cache
    // const cache = require('../utils/cache');
    // await cache.clearPattern('marketplace:products:*');

    res.json({
      success: true,
      message: 'Produit mis à jour',
      data: updated
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteProduit = async (req, res, next) => {
  try {
    const { id } = req.params;

    const produit = await prisma.marketplaceProduit.findUnique({ where: { id } });

    if (!produit) {
      throw errors.notFound('Produit non trouvé');
    }
    if (produit.vendeurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
      throw errors.forbidden('Vous n\'êtes pas autorisé à supprimer ce produit');
    }

    await prisma.marketplaceProduit.update({
      where: { id },
      data: { actif: false }
    });

    // Invalidate cache
    // const cache = require('../utils/cache');
    // await cache.clearPattern('marketplace:products:*');

    res.json({
      success: true,
      message: 'Produit supprimé'
    });
  } catch (error) {
    next(error);
  }
};

/* ========== COMMANDES ========== */

exports.getCommandes = async (req, res, next) => {
  try {
    const { type = 'all' } = req.query;

    const where = {};
    if (type === 'achats') {
      where.acheteurId = req.user.id;
    } else if (type === 'ventes') {
      where.vendeurId = req.user.id;
    } else {
      where.OR = [
        { acheteurId: req.user.id },
        { vendeurId: req.user.id }
      ];
    }

    const commandes = await prisma.marketplaceCommande.findMany({
      where,
      include: {
        produit: {
          include: {
            vendeur: {
              select: { nom: true, telephone: true }
            }
          }
        },
        acheteur: {
          select: { nom: true, telephone: true }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    const data = commandes.map(c => ({
      ...c,
      produit_nom: c.produit.nom,
      produit_prix: c.produit.prix,
      acheteur_nom: c.acheteur.nom,
      acheteur_telephone: c.acheteur.telephone,
      vendeur_nom: c.produit.vendeur?.nom || null,
      vendeur_telephone: c.produit.vendeur?.telephone || null,
      produit: undefined,
      acheteur: undefined
    }));

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.createCommande = async (req, res, next) => {
  try {
    const { produit_id, quantite, adresse_livraison, mode_livraison, date_debut, date_fin } = req.body;
    const quantiteNumber = Number(quantite);

    const result = await prisma.$transaction(async (tx) => {
      // Vérifier le produit et la disponibilité
      const produit = await tx.marketplaceProduit.findFirst({
        where: { id: produit_id, actif: true }
      });

      if (!produit) throw errors.notFound('Produit non disponible');
      if (produit.stock < quantiteNumber) throw errors.badRequest('Quantité insuffisante en stock');
      if (produit.vendeurId === req.user.id) throw errors.badRequest('Vous ne pouvez pas acheter votre propre produit');

      let prix_unitaire = Number(produit.prix);
      let prix_total = 0;

      // Handle Rental Logic
      let debut = null;
      let fin = null;

      if (produit.typeOffre === 'location') {
        if (!date_debut || !date_fin) throw errors.badRequest('Dates de location requises');
        debut = new Date(date_debut);
        fin = new Date(date_fin);

        const diffTime = Math.abs(fin - debut);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays < (produit.dureeMinLocation || 1)) {
          throw errors.badRequest(`Durée minimum de location est de ${produit.dureeMinLocation || 1} jours`);
        }

        prix_unitaire = Number(produit.prixLocationJour || produit.prix);
        prix_total = prix_unitaire * diffDays * quantiteNumber;
      } else {
        prix_total = prix_unitaire * quantiteNumber;
      }

      // Créer la commande
      const commande = await tx.marketplaceCommande.create({
        data: {
          acheteurId: req.user.id,
          vendeurId: produit.vendeurId,
          produitId: produit_id,
          quantite: quantiteNumber,
          prixUnitaire: prix_unitaire,
          prixTotal: prix_total,
          adresseLivraison: adresse_livraison,
          modeLivraison: mode_livraison,
          dateDebut: debut,
          dateFin: fin,
          statutLocation: produit.typeOffre === 'location' ? 'EN_COURS' : null
        }
      });

      // Mettre à jour le stock
      await tx.marketplaceProduit.update({
        where: { id: produit_id },
        data: { stock: { decrement: quantiteNumber } }
      });

      return commande;
    });

    // Invalidate cache due to stock change
    // const cache = require('../utils/cache');
    // await cache.clearPattern('marketplace:products:*');

    logger.audit('Nouvelle commande marketplace', {
      userId: req.user.id,
      commandeId: result.id,
      produitId: produit_id
    });

    res.status(201).json({
      success: true,
      message: 'Commande passée avec succès',
      data: result
    });
  } catch (error) {
    next(error);
  }
};

exports.getCommandeById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const commande = await prisma.marketplaceCommande.findUnique({
      where: { id },
      include: {
        produit: true,
        acheteur: { select: { nom: true, telephone: true } },
        vendeur: { select: { nom: true, telephone: true } }
      }
    });

    if (!commande) {
      throw errors.notFound('Commande non trouvée');
    }

    const data = {
      ...commande,
      produit_nom: commande.produit.nom,
      produit_images: commande.produit.images, // Assumes model attribute name
      acheteur_nom: commande.acheteur.nom,
      acheteur_telephone: commande.acheteur.telephone,
      vendeur_nom: commande.vendeur.nom,
      vendeur_telephone: commande.vendeur.telephone,
      produit: undefined,
      acheteur: undefined,
      vendeur: undefined
    };

    res.json({
      success: true,
      data
    });
  } catch (error) {
    next(error);
  }
};

exports.updateCommandeStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;

    const statusMap = {
      en_attente: 'PENDING',
      confirmee: 'CONFIRMED',
      en_preparation: 'CONFIRMED',
      expediee: 'SHIPPED',
      livree: 'DELIVERED',
      annulee: 'CANCELLED'
    };

    const mappedStatut = statusMap[statut] || statut;

    // Use update directly, will throw P2025 if not found
    try {
      const updated = await prisma.marketplaceCommande.update({
        where: { id },
        data: { statut: mappedStatut }
      });

      logger.audit('Mise à jour statut commande', { userId: req.user.id, commandeId: id, statut: mappedStatut });

      res.json({
        success: true,
        message: 'Statut mis à jour',
        data: updated
      });
    } catch (e) {
      if (e.code === 'P2025') throw errors.notFound('Commande non trouvée');
      throw e;
    }
  } catch (error) {
    next(error);
  }
};

exports.cancelCommande = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { raison } = req.body || {};

    await prisma.$transaction(async (tx) => {
      // 1. Récupérer la commande
      const commande = await tx.marketplaceCommande.findUnique({
        where: { id },
        include: { produit: true }
      });

      if (!commande) throw errors.notFound('Commande non trouvée');

      // 2. Permissions
      if (commande.acheteurId !== req.user.id && commande.vendeurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
        throw errors.forbidden('Vous n\'êtes pas autorisé à annuler cette commande');
      }

      // 3. Mise à jour statut
      await tx.marketplaceCommande.update({
        where: { id },
        data: { statut: 'CANCELLED', notes: raison }
      });

      // 4. Restaurer Stock
      await tx.marketplaceProduit.update({
        where: { id: commande.produitId },
        data: { stock: { increment: commande.quantite } }
      });
    });

    // Invalidation cache non bloquante
    try {
      const cache = require('../utils/cache');
      await cache.clearPattern('marketplace:products:*');
    } catch (cacheError) {
      logger.warn('Cache clear failed after cancel commande', { error: cacheError.message });
    }

    logger.audit('Annulation commande', { userId: req.user.id, commandeId: id });

    res.json({
      success: true,
      message: 'Commande annulée'
    });
  } catch (error) {
    next(error);
  }
};

/* ========== STATISTIQUES ========== */

exports.getStats = async (req, res, next) => {
  try {
    const [produitsActifs, totalCommandes, commandesLivrees, volumeVentesAgg, vendeursActifsAgg] = await Promise.all([
      prisma.marketplaceProduit.count({ where: { actif: true } }),
      prisma.marketplaceCommande.count(),
      prisma.marketplaceCommande.count({ where: { statut: 'DELIVERED' } }),
      prisma.marketplaceCommande.aggregate({
        _sum: { prixTotal: true },
        where: { statut: 'DELIVERED' }
      }),
      prisma.marketplaceProduit.groupBy({
        by: ['vendeurId'],
        where: { actif: true }
      })
    ]);

    res.json({
      success: true,
      data: {
        produits_actifs: produitsActifs,
        total_commandes: totalCommandes,
        commandes_livrees: commandesLivrees,
        volume_ventes: Number(volumeVentesAgg._sum.prixTotal || 0),
        vendeurs_actifs: vendeursActifsAgg.length
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.getVendeurStats = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const [mesProduits, produitsActifs, commandesRecues, revenusAgg] = await Promise.all([
      prisma.marketplaceProduit.count({ where: { vendeurId: userId } }),
      prisma.marketplaceProduit.count({ where: { vendeurId: userId, actif: true } }),
      prisma.marketplaceCommande.count({ where: { vendeurId: userId } }),
      prisma.marketplaceCommande.aggregate({
        _sum: { prixTotal: true },
        where: { vendeurId: userId, statut: 'DELIVERED' }
      })
    ]);

    res.json({
      success: true,
      data: {
        mes_produits: mesProduits,
        produits_actifs: produitsActifs,
        commandes_recues: commandesRecues,
        revenus_total: Number(revenusAgg._sum.prixTotal || 0)
      }
    });
  } catch (error) {
    next(error);
  }
};

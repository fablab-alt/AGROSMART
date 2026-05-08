/**
 * Contrôleur de la Communauté (Forum)
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const { ROLES } = require('../middlewares/rbac');
const logger = require('../utils/logger');

exports.getPosts = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        const { categorie, tag, search, sort } = req.query;

        // Build where clause (exclut les soft-deleted)
        const where = { isActive: true };
        if (categorie) where.categorie = categorie;
        if (search) {
            where.OR = [
                { titre: { contains: search } },
                { contenu: { contains: search } }
            ];
        }

        // Build orderBy
        let orderBy = { createdAt: 'desc' };
        if (sort === 'vues') orderBy = { vues: 'desc' };
        else if (sort === 'likes') orderBy = { likes: 'desc' };

        const userId = req.user?.id;

        const posts = await prisma.forumPost.findMany({
            where,
            include: {
                auteur: { select: { nom: true, prenoms: true, photoProfil: true } },
                _count: { select: { reponses: true, postLikes: true } },
                ...(userId && { postLikes: { where: { userId }, select: { id: true } } })
            },
            take: limit,
            skip: offset,
            orderBy
        });

        const data = posts.map((p) => ({
            ...p,
            auteur_nom: p.auteur.nom,
            auteur_prenom: p.auteur.prenoms,
            auteur_photo: p.auteur.photoProfil,
            reponses_count: p._count.reponses,
            likes: p.likes || p._count.postLikes,
            isLikedByMe: !!(p.postLikes && p.postLikes.length > 0),
            postLikes: undefined  // ne pas leaker
        }));

        res.json({ success: true, data });
    } catch (error) {
        next(error);
    }
};

exports.createPost = async (req, res, next) => {
    try {
        const { titre, contenu, categorie, tags } = req.body;

        const post = await prisma.forumPost.create({
            data: {
                auteurId: req.user.id,
                titre,
                contenu,
                categorie,
                tags: tags // Assuming tags is array in schema
            }
        });

        res.status(201).json({
            success: true,
            message: 'Post créé avec succès',
            data: post
        });
    } catch (error) {
        next(error);
    }
};

exports.getPostById = async (req, res, next) => {
    try {
        const { id } = req.params;

        const userId = req.user?.id;

        // Vérifier que le post est actif
        const exists = await prisma.forumPost.findFirst({
            where: { id, isActive: true }
        });
        if (!exists) throw errors.notFound('Post non trouvé');

        // Incrémenter les vues
        await prisma.forumPost.update({
            where: { id },
            data: { vues: { increment: 1 } }
        });

        const post = await prisma.forumPost.findUnique({
            where: { id },
            include: {
                auteur: { select: { nom: true, prenoms: true, photoProfil: true } },
                reponses: {
                    where: { isActive: true },
                    include: {
                        auteur: { select: { nom: true, prenoms: true, photoProfil: true } },
                        ...(userId && { reponseUpvotes: { where: { userId }, select: { id: true } } })
                    },
                    orderBy: [
                        { estSolution: 'desc' },
                        { createdAt: 'asc' }
                    ]
                },
                ...(userId && { postLikes: { where: { userId }, select: { id: true } } })
            }
        });

        const reponsesFormatted = post.reponses.map((r) => ({
            ...r,
            auteur_nom: r.auteur.nom,
            auteur_prenom: r.auteur.prenoms,
            auteur_photo: r.auteur.photoProfil,
            isUpvotedByMe: !!(r.reponseUpvotes && r.reponseUpvotes.length > 0),
            reponseUpvotes: undefined
        }));

        res.json({
            success: true,
            data: {
                ...post,
                auteur_nom: post.auteur.nom,
                auteur_prenom: post.auteur.prenoms,
                auteur_photo: post.auteur.photoProfil,
                reponses: reponsesFormatted,
                isLikedByMe: !!(post.postLikes && post.postLikes.length > 0),
                postLikes: undefined
            }
        });
    } catch (error) {
        next(error);
    }
};

exports.createReponse = async (req, res, next) => {
    try {
        const { id } = req.params; // post_id
        const { contenu } = req.body;

        const reponse = await prisma.forumReponse.create({
            data: {
                postId: id,
                auteurId: req.user.id,
                contenu
            },
            include: {
                auteur: {
                    select: { nom: true, prenoms: true }
                }
            }
        });

        res.status(201).json({
            success: true,
            message: 'Réponse ajoutée',
            data: {
                ...reponse,
                auteur_nom: reponse.auteur.nom,
                auteur_prenom: reponse.auteur.prenoms
            }
        });
    } catch (error) {
        next(error);
    }
};

exports.markSolution = async (req, res, next) => {
    try {
        const { postId, reponseId } = req.params;

        // Vérifier si l'utilisateur est l'auteur du post ou admin
        const post = await prisma.forumPost.findUnique({
            where: { id: postId }
        });

        if (!post) throw errors.notFound('Post non trouvé');

        if (post.auteurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
            throw errors.forbidden('Vous ne pouvez pas marquer une solution sur ce post');
        }

        await prisma.$transaction([
            prisma.forumPost.update({
                where: { id: postId },
                data: { resolu: true }
            }),
            prisma.forumReponse.update({
                where: { id: reponseId },
                data: { estSolution: true }
            })
        ]);

        res.json({
            success: true,
            message: 'Solution marquée'
        });
    } catch (error) {
        next(error);
    }
};

exports.getStats = async (req, res, next) => {
    try {
        const [totalPosts, totalReponses, resolus, membres] = await prisma.$transaction([
            prisma.forumPost.count(),
            prisma.forumReponse.count(),
            prisma.forumPost.count({ where: { resolu: true } }),
            prisma.user.count()
        ]);

        res.json({
            success: true,
            data: {
                total_posts: totalPosts,
                total_reponses: totalReponses,
                resolus,
                membres
            }
        });
    } catch (error) {
        next(error);
    }
};

/* ========== EDIT POST (auteur ou admin) ========== */
exports.updatePost = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { titre, contenu, categorie, tags } = req.body;

        const post = await prisma.forumPost.findUnique({ where: { id } });
        if (!post) throw errors.notFound('Post non trouvé');

        if (post.auteurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
            throw errors.forbidden('Vous ne pouvez pas modifier ce post');
        }

        const updated = await prisma.forumPost.update({
            where: { id },
            data: {
                ...(titre && { titre }),
                ...(contenu && { contenu }),
                ...(categorie && { categorie }),
                ...(tags !== undefined && { tags })
            }
        });

        res.json({ success: true, message: 'Post modifié', data: updated });
    } catch (error) {
        next(error);
    }
};

/* ========== DELETE POST (soft delete, auteur ou admin) ========== */
exports.deletePost = async (req, res, next) => {
    try {
        const { id } = req.params;

        const post = await prisma.forumPost.findUnique({ where: { id } });
        if (!post) throw errors.notFound('Post non trouvé');

        if (post.auteurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
            throw errors.forbidden('Vous ne pouvez pas supprimer ce post');
        }

        await prisma.forumPost.update({
            where: { id },
            data: { isActive: false, deletedAt: new Date() }
        });

        res.json({ success: true, message: 'Post supprimé' });
    } catch (error) {
        next(error);
    }
};

/* ========== EDIT RÉPONSE (auteur ou admin) ========== */
exports.updateReponse = async (req, res, next) => {
    try {
        const { reponseId } = req.params;
        const { contenu } = req.body;

        const reponse = await prisma.forumReponse.findUnique({ where: { id: reponseId } });
        if (!reponse) throw errors.notFound('Réponse non trouvée');

        if (reponse.auteurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
            throw errors.forbidden('Vous ne pouvez pas modifier cette réponse');
        }

        const updated = await prisma.forumReponse.update({
            where: { id: reponseId },
            data: { contenu }
        });

        res.json({ success: true, message: 'Réponse modifiée', data: updated });
    } catch (error) {
        next(error);
    }
};

/* ========== DELETE RÉPONSE (soft delete) ========== */
exports.deleteReponse = async (req, res, next) => {
    try {
        const { reponseId } = req.params;

        const reponse = await prisma.forumReponse.findUnique({ where: { id: reponseId } });
        if (!reponse) throw errors.notFound('Réponse non trouvée');

        if (reponse.auteurId !== req.user.id && req.user.role !== ROLES.ADMIN) {
            throw errors.forbidden('Vous ne pouvez pas supprimer cette réponse');
        }

        await prisma.forumReponse.update({
            where: { id: reponseId },
            data: { isActive: false }
        });

        res.json({ success: true, message: 'Réponse supprimée' });
    } catch (error) {
        next(error);
    }
};

/* ========== TOGGLE LIKE POST ========== */
exports.toggleLikePost = async (req, res, next) => {
    try {
        const { id: postId } = req.params;
        const userId = req.user.id;

        const post = await prisma.forumPost.findUnique({ where: { id: postId } });
        if (!post) throw errors.notFound('Post non trouvé');

        const existing = await prisma.forumPostLike.findUnique({
            where: { unique_post_like: { postId, userId } }
        });

        if (existing) {
            // Unlike : supprimer + décrémenter
            await prisma.$transaction([
                prisma.forumPostLike.delete({ where: { id: existing.id } }),
                prisma.forumPost.update({
                    where: { id: postId },
                    data: { likes: { decrement: 1 } }
                })
            ]);
            res.json({ success: true, data: { liked: false, likes: Math.max(0, post.likes - 1) } });
        } else {
            // Like : créer + incrémenter
            await prisma.$transaction([
                prisma.forumPostLike.create({ data: { postId, userId } }),
                prisma.forumPost.update({
                    where: { id: postId },
                    data: { likes: { increment: 1 } }
                })
            ]);
            res.json({ success: true, data: { liked: true, likes: post.likes + 1 } });
        }
    } catch (error) {
        next(error);
    }
};

/* ========== TOGGLE UPVOTE RÉPONSE ========== */
exports.toggleUpvoteReponse = async (req, res, next) => {
    try {
        const { reponseId } = req.params;
        const userId = req.user.id;

        const reponse = await prisma.forumReponse.findUnique({ where: { id: reponseId } });
        if (!reponse) throw errors.notFound('Réponse non trouvée');

        const existing = await prisma.forumReponseUpvote.findUnique({
            where: { unique_reponse_upvote: { reponseId, userId } }
        });

        if (existing) {
            await prisma.$transaction([
                prisma.forumReponseUpvote.delete({ where: { id: existing.id } }),
                prisma.forumReponse.update({
                    where: { id: reponseId },
                    data: { upvotes: { decrement: 1 } }
                })
            ]);
            res.json({ success: true, data: { upvoted: false, upvotes: Math.max(0, reponse.upvotes - 1) } });
        } else {
            await prisma.$transaction([
                prisma.forumReponseUpvote.create({ data: { reponseId, userId } }),
                prisma.forumReponse.update({
                    where: { id: reponseId },
                    data: { upvotes: { increment: 1 } }
                })
            ]);
            res.json({ success: true, data: { upvoted: true, upvotes: reponse.upvotes + 1 } });
        }
    } catch (error) {
        next(error);
    }
};

/* ========== CATÉGORIES ========== */
exports.getCategories = async (req, res, next) => {
    try {
        // Liste statique + comptage dynamique
        const baseCategories = [
            'Cacao', 'Maïs', 'Riz', 'Hévéa', 'Banane', 'Tomate', 'Manioc',
            'Maladies', 'Irrigation', 'Bio', 'Marketplace',
            'Coopération', 'Maraîchage', 'Témoignages', 'Annonces', 'Général'
        ];

        // Comptage par catégorie via groupBy
        const counts = await prisma.forumPost.groupBy({
            by: ['categorie'],
            where: { isActive: true },
            _count: { categorie: true }
        });

        const countMap = Object.fromEntries(counts.map((c) => [c.categorie, c._count.categorie]));

        const categories = baseCategories.map((nom) => ({
            nom,
            count: countMap[nom] || 0
        }));

        // Ajouter les catégories dynamiques (créées par les users) qui ne sont pas dans la liste statique
        Object.keys(countMap).forEach((nom) => {
            if (!baseCategories.includes(nom)) {
                categories.push({ nom, count: countMap[nom] });
            }
        });

        res.json({ success: true, data: categories });
    } catch (error) {
        next(error);
    }
};

exports.getLeaderboard = async (req, res, next) => {
    try {
        // Leaderboard complex ranking
        // Prisma doesn't support complex ordering by relation counts easily in findMany
        // Using queryRaw for this specific complex query
        // "ORDER BY solutions_count DESC, reponses_count DESC, posts_count DESC"

        const leaderboard = await prisma.$queryRaw`
              SELECT u.id, u.nom, u.prenoms,
                     (SELECT COUNT(*) FROM forum_posts p WHERE p.auteur_id = u.id) as posts_count,
                     (SELECT COUNT(*) FROM forum_reponses r WHERE r.auteur_id = u.id) as reponses_count,
                     (SELECT COUNT(*) FROM forum_reponses r WHERE r.auteur_id = u.id AND r.est_solution = true) as solutions_count
              FROM users u
              WHERE u.role != 'ADMIN'
              ORDER BY solutions_count DESC, reponses_count DESC, posts_count DESC
              LIMIT 10
        `;
        // Note: Check Role Enum value in DB. Usually 'ADMIN' or 'admin'. 
        // RBAC.js uses 'ADMIN'. Schema uses 'UserRole' enum.
        // Prisma Enum filter in Raw query needs string matching DB value.
        // Assuming 'ADMIN'.

        // Convert BigInts from count to Number if necessary (Prisma returns BigInt for counts in raw)
        const formatted = leaderboard.map(row => ({
            ...row,
            posts_count: Number(row.posts_count),
            reponses_count: Number(row.reponses_count),
            solutions_count: Number(row.solutions_count)
        }));

        res.json({
            success: true,
            data: formatted
        });
    } catch (error) {
        next(error);
    }
};

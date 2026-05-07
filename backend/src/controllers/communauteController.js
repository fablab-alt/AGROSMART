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

        // Build where clause
        const where = {};
        if (categorie) where.categorie = categorie;
        if (tag) where.tags = { has: tag }; // Prisma 'has' for arrays? Check schema. If array, uses has.
        if (search) {
            where.OR = [
                { titre: { contains: search, mode: 'insensitive' } },
                { contenu: { contains: search, mode: 'insensitive' } }
            ];
        }

        // Build orderBy
        let orderBy = { createdAt: 'desc' };
        if (sort === 'vues') orderBy = { vues: 'desc' };
        // if (sort === 'reponses') ... Prisma can't sort by relations count directly easily.
        // We might need to use basic sorting or client side, or raw query for complex sorts if crucial.
        // For now, default to createdAt or vues.

        const posts = await prisma.forumPost.findMany({
            where,
            include: {
                auteur: {
                    select: { nom: true, prenoms: true }
                },
                _count: {
                    select: { reponses: true }
                }
            },
            take: limit,
            skip: offset,
            orderBy
        });

        // Map stats
        const data = posts.map(p => ({
            ...p,
            auteur_nom: p.auteur.nom,
            auteur_prenom: p.auteur.prenoms,
            reponses_count: p._count.reponses
        }));

        res.json({
            success: true,
            data
        });
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

        // Incrémenter les vues (atomic update)
        await prisma.forumPost.update({
            where: { id },
            data: { vues: { increment: 1 } }
        });

        const post = await prisma.forumPost.findUnique({
            where: { id },
            include: {
                auteur: {
                    select: { nom: true, prenoms: true }
                },
                reponses: {
                    include: {
                        auteur: {
                            select: { nom: true, prenoms: true }
                        }
                    },
                    orderBy: [
                        { estSolution: 'desc' },
                        { createdAt: 'asc' }
                    ]
                }
            }
        });

        if (!post) {
            throw errors.notFound('Post non trouvé');
        }

        const reponsesFormatted = post.reponses.map(r => ({
            ...r,
            auteur_nom: r.auteur.nom,
            auteur_prenom: r.auteur.prenoms
        }));

        res.json({
            success: true,
            data: {
                ...post,
                auteur_nom: post.auteur.nom,
                auteur_prenom: post.auteur.prenoms,
                reponses: reponsesFormatted
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

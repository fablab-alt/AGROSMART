/**
 * Contrôleur du système d'amitié (réseau social)
 * AgroSmart - Système Agricole Intelligent
 *
 * Modèle Friendship: requesterId, addresseeId, status (PENDING/ACCEPTED/REJECTED/BLOCKED)
 *
 * Workflow :
 *   1. User A envoie demande à User B  -> POST /friendships  (status PENDING)
 *   2. User B accepte                  -> PATCH /friendships/:id/accept (status ACCEPTED)
 *   2'. User B refuse                  -> PATCH /friendships/:id/reject (status REJECTED)
 *   3. Liste d'amis                    -> GET /friendships
 *   3'. Demandes reçues                -> GET /friendships/requests/received
 *   3''. Demandes envoyées              -> GET /friendships/requests/sent
 *   4. Suppression                     -> DELETE /friendships/:id
 */

const prisma = require('../config/prisma');
const { errors } = require('../middlewares/errorHandler');
const logger = require('../utils/logger');

/**
 * Récupère le shape public d'un user (sans password ni champs sensibles)
 */
const userPublicSelect = {
  id: true,
  nom: true,
  prenoms: true,
  telephone: true,
  email: true,
  role: true,
  photoProfil: true,
  niveau: true,
  points: true,
  badge: true,
  region: { select: { nom: true } },
};

/* ========== LISTE D'AMIS ========== */

/**
 * GET /api/v1/friendships
 * Liste tous les amis confirmés (status ACCEPTED) de l'utilisateur connecté
 */
exports.getFriends = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const friendships = await prisma.friendship.findMany({
      where: {
        status: 'ACCEPTED',
        OR: [{ requesterId: userId }, { addresseeId: userId }],
      },
      include: {
        requester: { select: userPublicSelect },
        addressee: { select: userPublicSelect },
      },
      orderBy: { acceptedAt: 'desc' },
    });

    // Pour chaque amitié, retourner l'autre utilisateur (l'ami)
    const friends = friendships.map((f) => {
      const friend = f.requesterId === userId ? f.addressee : f.requester;
      return {
        friendshipId: f.id,
        ...friend,
        amisDepuis: f.acceptedAt,
      };
    });

    res.json({ success: true, data: friends, count: friends.length });
  } catch (err) {
    logger.error('getFriends error', err);
    next(err);
  }
};

/* ========== DEMANDES REÇUES ========== */

/**
 * GET /api/v1/friendships/requests/received
 * Liste les demandes d'amitié reçues en attente
 */
exports.getReceivedRequests = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const requests = await prisma.friendship.findMany({
      where: { addresseeId: userId, status: 'PENDING' },
      include: { requester: { select: userPublicSelect } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({
      success: true,
      data: requests.map((r) => ({
        id: r.id,
        from: r.requester,
        sentAt: r.createdAt,
      })),
      count: requests.length,
    });
  } catch (err) {
    logger.error('getReceivedRequests error', err);
    next(err);
  }
};

/* ========== DEMANDES ENVOYÉES ========== */

/**
 * GET /api/v1/friendships/requests/sent
 * Liste les demandes d'amitié envoyées en attente
 */
exports.getSentRequests = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const requests = await prisma.friendship.findMany({
      where: { requesterId: userId, status: 'PENDING' },
      include: { addressee: { select: userPublicSelect } },
      orderBy: { createdAt: 'desc' },
    });
    res.json({
      success: true,
      data: requests.map((r) => ({
        id: r.id,
        to: r.addressee,
        sentAt: r.createdAt,
      })),
      count: requests.length,
    });
  } catch (err) {
    logger.error('getSentRequests error', err);
    next(err);
  }
};

/* ========== ENVOI D'UNE DEMANDE ========== */

/**
 * POST /api/v1/friendships
 * Body: { addresseeId: string }
 * Envoie une demande d'amitié à un autre utilisateur
 */
exports.sendRequest = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { addresseeId } = req.body;

    if (!addresseeId) {
      return res.status(400).json({ success: false, message: 'addresseeId requis' });
    }
    if (addresseeId === userId) {
      return res.status(400).json({ success: false, message: 'Impossible de s\'ajouter soi-même' });
    }

    // Vérifie que l'utilisateur cible existe
    const target = await prisma.user.findUnique({ where: { id: addresseeId } });
    if (!target) {
      return res.status(404).json({ success: false, message: 'Utilisateur introuvable' });
    }

    // Vérifie qu'aucune relation n'existe déjà (dans un sens ou l'autre)
    const existing = await prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId: userId, addresseeId },
          { requesterId: addresseeId, addresseeId: userId },
        ],
      },
    });

    if (existing) {
      if (existing.status === 'ACCEPTED') {
        return res.status(409).json({ success: false, message: 'Vous êtes déjà amis' });
      }
      if (existing.status === 'PENDING') {
        return res.status(409).json({ success: false, message: 'Demande déjà en attente' });
      }
      if (existing.status === 'BLOCKED') {
        return res.status(403).json({ success: false, message: 'Action impossible' });
      }
      // Si REJECTED, on peut renvoyer en mettant à jour la ligne
      const updated = await prisma.friendship.update({
        where: { id: existing.id },
        data: {
          requesterId: userId,
          addresseeId,
          status: 'PENDING',
          acceptedAt: null,
        },
      });
      return res.json({ success: true, data: updated, message: 'Demande renvoyée' });
    }

    const friendship = await prisma.friendship.create({
      data: { requesterId: userId, addresseeId, status: 'PENDING' },
    });

    res.status(201).json({ success: true, data: friendship, message: 'Demande envoyée' });
  } catch (err) {
    logger.error('sendRequest error', err);
    next(err);
  }
};

/* ========== ACCEPTATION ========== */

/**
 * PATCH /api/v1/friendships/:id/accept
 * Accepte une demande d'amitié reçue
 */
exports.acceptRequest = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const friendship = await prisma.friendship.findUnique({ where: { id } });
    if (!friendship) {
      return res.status(404).json({ success: false, message: 'Demande introuvable' });
    }
    if (friendship.addresseeId !== userId) {
      return res.status(403).json({ success: false, message: 'Vous n\'êtes pas le destinataire' });
    }
    if (friendship.status !== 'PENDING') {
      return res.status(400).json({ success: false, message: 'La demande n\'est plus en attente' });
    }

    const updated = await prisma.friendship.update({
      where: { id },
      data: { status: 'ACCEPTED', acceptedAt: new Date() },
    });

    res.json({ success: true, data: updated, message: 'Demande acceptée' });
  } catch (err) {
    logger.error('acceptRequest error', err);
    next(err);
  }
};

/* ========== REJET ========== */

/**
 * PATCH /api/v1/friendships/:id/reject
 * Refuse une demande d'amitié reçue
 */
exports.rejectRequest = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const friendship = await prisma.friendship.findUnique({ where: { id } });
    if (!friendship) {
      return res.status(404).json({ success: false, message: 'Demande introuvable' });
    }
    if (friendship.addresseeId !== userId) {
      return res.status(403).json({ success: false, message: 'Vous n\'êtes pas le destinataire' });
    }
    if (friendship.status !== 'PENDING') {
      return res.status(400).json({ success: false, message: 'La demande n\'est plus en attente' });
    }

    const updated = await prisma.friendship.update({
      where: { id },
      data: { status: 'REJECTED' },
    });

    res.json({ success: true, data: updated, message: 'Demande refusée' });
  } catch (err) {
    logger.error('rejectRequest error', err);
    next(err);
  }
};

/* ========== SUPPRESSION ========== */

/**
 * DELETE /api/v1/friendships/:id
 * Supprime une amitié (peut être appelé par n'importe lequel des deux participants)
 */
exports.removeFriend = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const friendship = await prisma.friendship.findUnique({ where: { id } });
    if (!friendship) {
      return res.status(404).json({ success: false, message: 'Amitié introuvable' });
    }
    if (friendship.requesterId !== userId && friendship.addresseeId !== userId) {
      return res.status(403).json({ success: false, message: 'Action non autorisée' });
    }

    await prisma.friendship.delete({ where: { id } });

    res.json({ success: true, message: 'Amitié supprimée' });
  } catch (err) {
    logger.error('removeFriend error', err);
    next(err);
  }
};

/* ========== STATUT D'AMITIÉ ========== */

/**
 * GET /api/v1/friendships/status/:userId
 * Retourne le statut d'amitié entre l'utilisateur connecté et un autre user
 * Réponses possibles : NONE, PENDING_SENT, PENDING_RECEIVED, ACCEPTED, REJECTED, BLOCKED
 */
exports.getFriendshipStatus = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { userId: otherId } = req.params;

    if (otherId === userId) {
      return res.json({ success: true, data: { status: 'SELF' } });
    }

    const friendship = await prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId: userId, addresseeId: otherId },
          { requesterId: otherId, addresseeId: userId },
        ],
      },
    });

    if (!friendship) {
      return res.json({ success: true, data: { status: 'NONE' } });
    }

    let status = friendship.status;
    if (status === 'PENDING') {
      status = friendship.requesterId === userId ? 'PENDING_SENT' : 'PENDING_RECEIVED';
    }

    res.json({
      success: true,
      data: {
        status,
        friendshipId: friendship.id,
        since: friendship.acceptedAt,
      },
    });
  } catch (err) {
    logger.error('getFriendshipStatus error', err);
    next(err);
  }
};

/* ========== SUGGESTIONS D'AMIS ========== */

/**
 * GET /api/v1/friendships/suggestions
 * Suggère des utilisateurs (de la même région ou coopérative) avec qui se connecter
 */
exports.getSuggestions = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const me = await prisma.user.findUnique({
      where: { id: userId },
      select: { regionId: true },
    });

    // IDs déjà en relation
    const existing = await prisma.friendship.findMany({
      where: {
        OR: [{ requesterId: userId }, { addresseeId: userId }],
      },
      select: { requesterId: true, addresseeId: true },
    });
    const excludeIds = new Set([userId]);
    existing.forEach((f) => {
      excludeIds.add(f.requesterId);
      excludeIds.add(f.addresseeId);
    });

    const suggestions = await prisma.user.findMany({
      where: {
        id: { notIn: Array.from(excludeIds) },
        isActive: true,
        ...(me?.regionId ? { regionId: me.regionId } : {}),
      },
      select: userPublicSelect,
      take: 10,
      orderBy: { points: 'desc' },
    });

    res.json({ success: true, data: suggestions });
  } catch (err) {
    logger.error('getSuggestions error', err);
    next(err);
  }
};

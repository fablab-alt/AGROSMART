/**
 * Chat/Messaging Controller
 * AgroSmart - Messagerie Temps Réel
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Get user's conversations
 * GET /api/chat/conversations
 */
exports.getConversations = async (req, res, next) => {
    try {
        const userId = req.user.id;

        // MySQL JSON_CONTAINS for participant filtering
        const conversations = await prisma.$queryRaw`
            SELECT * FROM conversations 
            WHERE JSON_CONTAINS(participants, JSON_QUOTE(${userId})) 
            AND est_actif = true 
            ORDER BY dernier_message_at DESC
        `;

        const conversationsWithUnread = await Promise.all(conversations.map(async (c) => {
            const unreadResult = await prisma.message.count({
                where: {
                    conversationId: c.id,
                    expediteurId: { not: userId },
                    lu: false
                }
            });
            return { ...c, unread_count: unreadResult };
        }));

        res.json({
            success: true,
            data: conversationsWithUnread
        });
    } catch (error) {
        logger.error('Error fetching conversations:', error);
        next(error);
    }
};

/**
 * Get conversation messages
 * GET /api/chat/conversations/:id/messages
 */
exports.getMessages = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const { limit = 50, offset = 0 } = req.query;

        // Verify user is participant using MySQL JSON_CONTAINS
        const conversations = await prisma.$queryRaw`
            SELECT * FROM conversations 
            WHERE id = ${id} 
            AND JSON_CONTAINS(participants, JSON_QUOTE(${userId}))
            LIMIT 1
        `;
        const conversation = conversations.length > 0 ? conversations[0] : null;

        if (!conversation) {
            return res.status(403).json({
                success: false,
                message: 'Non autorisé'
            });
        }

        const messages = await prisma.message.findMany({
            where: { conversationId: id },
            include: {
                expediteur: {
                    select: { nom: true }
                }
            },
            orderBy: { createdAt: 'desc' },
            take: parseInt(limit),
            skip: parseInt(offset)
        });

        // Mark as read
        await prisma.message.updateMany({
            where: {
                conversationId: id,
                destinataireId: userId,
                lu: false
            },
            data: {
                lu: true
            }
        });

        const formatted = messages.map(m => ({
            ...m,
            expediteur_nom: m.expediteur.nom
        }));

        res.json({
            success: true,
            data: formatted.reverse()
        });
    } catch (error) {
        logger.error('Error fetching messages:', error);
        next(error);
    }
};

/**
 * Send message
 * POST /api/chat/conversations/:id/messages
 */
exports.sendMessage = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const { message, destinataire_id } = req.body;

        const sentMessage = await prisma.message.create({
            data: {
                conversationId: id, // Assuming relation exists in Schema or scalar field
                expediteurId: userId,
                destinataireId: destinataire_id,
                contenu: message // Schema has `contenu`? Step 595 line 493 `contenu String`. Yes.
                // `sujet` is optional.
            }
        });

        // Update conversation
        await prisma.conversation.update({
            where: { id },
            data: {
                dernierMessageAt: new Date(),
                nbMessages: { increment: 1 }
            }
        });

        // TODO: Emit socket event for real-time
        // io.to(id).emit('new_message', result.rows[0]);

        res.status(201).json({
            success: true,
            data: sentMessage
        });
    } catch (error) {
        logger.error('Error sending message:', error);
        next(error);
    }
};

/**
 * Create conversation
 * POST /api/chat/conversations
 */
exports.createConversation = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { type, nom, participants } = req.body;

        const allParticipants = [userId, ...participants];

        const conversation = await prisma.conversation.create({
            data: {
                type: type || 'prive',
                nom,
                participants: allParticipants,
                adminId: userId
            }
        });

        res.status(201).json({
            success: true,
            data: conversation
        });
    } catch (error) {
        logger.error('Error creating conversation:', error);
        next(error);
    }
};

module.exports = exports;

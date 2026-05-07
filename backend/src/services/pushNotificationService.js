/**
 * Service de notifications push Firebase Cloud Messaging (FCM)
 * AgroSmart - Système Agricole Intelligent
 * 
 * Features:
 * - Envoi de notifications push aux appareils mobiles
 * - Support des topics (alertes globales, météo, etc.)
 * - Notifications personnalisées par utilisateur
 * - Gestion des tokens FCM
 */

const admin = require('firebase-admin');
const logger = require('../utils/logger');
const prisma = require('../config/prisma');
const config = require('../config');

// Initialiser Firebase Admin SDK
let firebaseInitialized = false;

const initFirebase = () => {
  if (firebaseInitialized) return;

  try {
    // Vérifier si les credentials Firebase sont disponibles
    if (!process.env.FIREBASE_SERVICE_ACCOUNT && !process.env.FIREBASE_PROJECT_ID) {
      logger.warn('[FCM] Firebase credentials not configured, push notifications disabled');
      return;
    }

    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
      ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
      : {
          projectId: process.env.FIREBASE_PROJECT_ID,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
          privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')
        };

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: serviceAccount.projectId
    });

    firebaseInitialized = true;
    logger.info('[FCM] Firebase Admin SDK initialized');
  } catch (error) {
    logger.error('[FCM] Failed to initialize Firebase', { error: error.message });
  }
};

// Types de notifications
const NOTIFICATION_TYPES = {
  ALERT_CRITICAL: 'alert_critical',
  ALERT_WARNING: 'alert_warning',
  ALERT_INFO: 'alert_info',
  DISEASE_DETECTED: 'disease_detected',
  IRRIGATION_REMINDER: 'irrigation_reminder',
  WEATHER_ALERT: 'weather_alert',
  MARKETPLACE_ORDER: 'marketplace_order',
  MESSAGE_NEW: 'message_new',
  FORUM_REPLY: 'forum_reply',
  FORMATION_NEW: 'formation_new',
  SYSTEM: 'system'
};

// Topics FCM
const TOPICS = {
  ALL_USERS: 'all_users',
  WEATHER_ALERTS: 'weather_alerts',
  MARKETPLACE_UPDATES: 'marketplace_updates',
  FORMATIONS: 'formations',
  SYSTEM_ANNOUNCEMENTS: 'system_announcements'
};

/**
 * Enregistre ou met à jour le token FCM d'un utilisateur
 * @param {string} userId - ID de l'utilisateur
 * @param {string} fcmToken - Token FCM
 * @param {string} deviceType - Type d'appareil (android/ios)
 */
const registerToken = async (userId, fcmToken, deviceType = 'android') => {
  try {
    // Stocker le token dans la base de données
    await prisma.user.update({
      where: { id: userId },
      data: {
        fcmToken,
        deviceType,
        fcmTokenUpdatedAt: new Date()
      }
    });

    // Abonner l'utilisateur aux topics par défaut
    if (firebaseInitialized) {
      await admin.messaging().subscribeToTopic(fcmToken, TOPICS.ALL_USERS);
      await admin.messaging().subscribeToTopic(fcmToken, TOPICS.WEATHER_ALERTS);
    }

    logger.info('[FCM] Token registered', { userId, deviceType });
    return true;
  } catch (error) {
    logger.error('[FCM] Failed to register token', { userId, error: error.message });
    return false;
  }
};

/**
 * Supprime le token FCM d'un utilisateur (lors de la déconnexion)
 * @param {string} userId - ID de l'utilisateur
 */
const unregisterToken = async (userId) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true }
    });

    if (user?.fcmToken && firebaseInitialized) {
      // Se désabonner de tous les topics
      await admin.messaging().unsubscribeFromTopic(user.fcmToken, TOPICS.ALL_USERS);
      await admin.messaging().unsubscribeFromTopic(user.fcmToken, TOPICS.WEATHER_ALERTS);
    }

    await prisma.user.update({
      where: { id: userId },
      data: { fcmToken: null }
    });

    logger.info('[FCM] Token unregistered', { userId });
    return true;
  } catch (error) {
    logger.error('[FCM] Failed to unregister token', { userId, error: error.message });
    return false;
  }
};

/**
 * Envoie une notification push à un utilisateur spécifique
 * @param {string} userId - ID de l'utilisateur
 * @param {Object} notification - Données de la notification
 * @param {string} notification.title - Titre
 * @param {string} notification.body - Corps du message
 * @param {string} notification.type - Type de notification
 * @param {Object} notification.data - Données supplémentaires
 */
const sendToUser = async (userId, notification) => {
  if (!firebaseInitialized) {
    logger.debug('[FCM] Firebase not initialized, skipping notification');
    return false;
  }

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true, prenoms: true }
    });

    if (!user?.fcmToken) {
      logger.debug('[FCM] User has no FCM token', { userId });
      return false;
    }

    const message = {
      token: user.fcmToken,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: {
        type: notification.type || NOTIFICATION_TYPES.SYSTEM,
        userId,
        ...formatDataForFCM(notification.data || {})
      },
      android: {
        priority: 'high',
        notification: {
          channelId: getChannelId(notification.type),
          color: getNotificationColor(notification.type),
          icon: 'ic_notification',
          sound: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: notification.title,
              body: notification.body
            },
            badge: 1,
            sound: 'default'
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    logger.info('[FCM] Notification sent', { userId, messageId: response });

    // Enregistrer la notification dans la base de données
    await saveNotificationToDb(userId, notification);

    return true;
  } catch (error) {
    logger.error('[FCM] Failed to send notification', { userId, error: error.message });

    // Si le token est invalide, le supprimer
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      await unregisterToken(userId);
    }

    return false;
  }
};

/**
 * Envoie une notification à plusieurs utilisateurs
 * @param {string[]} userIds - IDs des utilisateurs
 * @param {Object} notification - Données de la notification
 */
const sendToUsers = async (userIds, notification) => {
  if (!firebaseInitialized || userIds.length === 0) return { success: 0, failed: 0 };

  try {
    const users = await prisma.user.findMany({
      where: {
        id: { in: userIds },
        fcmToken: { not: null }
      },
      select: { id: true, fcmToken: true }
    });

    if (users.length === 0) return { success: 0, failed: userIds.length };

    const messages = users.map(user => ({
      token: user.fcmToken,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: {
        type: notification.type || NOTIFICATION_TYPES.SYSTEM,
        ...formatDataForFCM(notification.data || {})
      },
      android: {
        priority: 'high',
        notification: {
          channelId: getChannelId(notification.type)
        }
      }
    }));

    const response = await admin.messaging().sendAll(messages);
    
    logger.info('[FCM] Batch notification sent', { 
      total: users.length,
      success: response.successCount,
      failed: response.failureCount
    });

    // Sauvegarder les notifications
    for (const user of users) {
      await saveNotificationToDb(user.id, notification);
    }

    return {
      success: response.successCount,
      failed: response.failureCount
    };
  } catch (error) {
    logger.error('[FCM] Failed to send batch notification', { error: error.message });
    return { success: 0, failed: userIds.length };
  }
};

/**
 * Envoie une notification à un topic
 * @param {string} topic - Nom du topic
 * @param {Object} notification - Données de la notification
 */
const sendToTopic = async (topic, notification) => {
  if (!firebaseInitialized) return false;

  try {
    const message = {
      topic,
      notification: {
        title: notification.title,
        body: notification.body
      },
      data: {
        type: notification.type || NOTIFICATION_TYPES.SYSTEM,
        ...formatDataForFCM(notification.data || {})
      },
      android: {
        priority: 'high'
      }
    };

    const response = await admin.messaging().send(message);
    logger.info('[FCM] Topic notification sent', { topic, messageId: response });
    return true;
  } catch (error) {
    logger.error('[FCM] Failed to send topic notification', { topic, error: error.message });
    return false;
  }
};

/**
 * Envoie une alerte critique à un utilisateur
 */
const sendCriticalAlert = async (userId, alert) => {
  return sendToUser(userId, {
    title: '🚨 Alerte Critique',
    body: alert.message,
    type: NOTIFICATION_TYPES.ALERT_CRITICAL,
    data: {
      alertId: alert.id,
      parcelleId: alert.parcelleId,
      alertType: alert.type
    }
  });
};

/**
 * Envoie une alerte maladie détectée
 */
const sendDiseaseAlert = async (userId, diagnostic) => {
  return sendToUser(userId, {
    title: '🔬 Maladie Détectée',
    body: `${diagnostic.maladie} détectée avec ${Math.round(diagnostic.confiance * 100)}% de confiance`,
    type: NOTIFICATION_TYPES.DISEASE_DETECTED,
    data: {
      diagnosticId: diagnostic.id,
      parcelleId: diagnostic.parcelleId,
      maladie: diagnostic.maladie
    }
  });
};

/**
 * Envoie un rappel d'irrigation
 */
const sendIrrigationReminder = async (userId, parcelle) => {
  return sendToUser(userId, {
    title: '💧 Rappel Irrigation',
    body: `Il est temps d'irriguer votre parcelle "${parcelle.nom}"`,
    type: NOTIFICATION_TYPES.IRRIGATION_REMINDER,
    data: {
      parcelleId: parcelle.id,
      parcelleName: parcelle.nom
    }
  });
};

/**
 * Envoie une notification de commande marketplace
 */
const sendOrderNotification = async (userId, order, status) => {
  const statusMessages = {
    CONFIRMED: 'Votre commande a été confirmée',
    SHIPPED: 'Votre commande est en cours de livraison',
    DELIVERED: 'Votre commande a été livrée',
    CANCELLED: 'Votre commande a été annulée'
  };

  return sendToUser(userId, {
    title: '🛒 Mise à jour commande',
    body: statusMessages[status] || `Statut: ${status}`,
    type: NOTIFICATION_TYPES.MARKETPLACE_ORDER,
    data: {
      orderId: order.id,
      orderStatus: status
    }
  });
};

/**
 * Envoie une notification de nouveau message
 */
const sendNewMessageNotification = async (userId, message, sender) => {
  return sendToUser(userId, {
    title: `💬 Message de ${sender.prenoms}`,
    body: message.contenu.substring(0, 100) + (message.contenu.length > 100 ? '...' : ''),
    type: NOTIFICATION_TYPES.MESSAGE_NEW,
    data: {
      messageId: message.id,
      senderId: sender.id,
      senderName: sender.prenoms
    }
  });
};

/**
 * Envoie une alerte météo globale
 */
const sendWeatherAlert = async (alert) => {
  return sendToTopic(TOPICS.WEATHER_ALERTS, {
    title: '⛈️ Alerte Météo',
    body: alert.message,
    type: NOTIFICATION_TYPES.WEATHER_ALERT,
    data: {
      severity: alert.severity,
      region: alert.region
    }
  });
};

// ============================
// Fonctions utilitaires
// ============================

/**
 * Convertit les données en format string pour FCM
 */
const formatDataForFCM = (data) => {
  const formatted = {};
  for (const [key, value] of Object.entries(data)) {
    formatted[key] = typeof value === 'string' ? value : JSON.stringify(value);
  }
  return formatted;
};

/**
 * Retourne l'ID du canal Android selon le type de notification
 */
const getChannelId = (type) => {
  const channels = {
    [NOTIFICATION_TYPES.ALERT_CRITICAL]: 'critical_alerts',
    [NOTIFICATION_TYPES.ALERT_WARNING]: 'warnings',
    [NOTIFICATION_TYPES.DISEASE_DETECTED]: 'diagnostics',
    [NOTIFICATION_TYPES.MESSAGE_NEW]: 'messages',
    [NOTIFICATION_TYPES.MARKETPLACE_ORDER]: 'orders'
  };
  return channels[type] || 'default';
};

/**
 * Retourne la couleur de notification selon le type
 */
const getNotificationColor = (type) => {
  const colors = {
    [NOTIFICATION_TYPES.ALERT_CRITICAL]: '#FF0000',
    [NOTIFICATION_TYPES.ALERT_WARNING]: '#FFA500',
    [NOTIFICATION_TYPES.DISEASE_DETECTED]: '#9C27B0',
    [NOTIFICATION_TYPES.IRRIGATION_REMINDER]: '#2196F3'
  };
  return colors[type] || '#4CAF50';
};

/**
 * Sauvegarde la notification dans la base de données
 */
const saveNotificationToDb = async (userId, notification) => {
  try {
    await prisma.alerte.create({
      data: {
        userId,
        type: notification.type || 'NOTIFICATION',
        message: `${notification.title}: ${notification.body}`,
        niveau: notification.type?.includes('CRITICAL') ? 'CRITICAL' : 'INFO',
        source: 'PUSH_NOTIFICATION',
        metadata: notification.data ? JSON.stringify(notification.data) : null
      }
    });
  } catch (error) {
    logger.warn('[FCM] Failed to save notification to DB', { userId, error: error.message });
  }
};

// Initialiser Firebase au chargement du module
initFirebase();

module.exports = {
  registerToken,
  unregisterToken,
  sendToUser,
  sendToUsers,
  sendToTopic,
  sendCriticalAlert,
  sendDiseaseAlert,
  sendIrrigationReminder,
  sendOrderNotification,
  sendNewMessageNotification,
  sendWeatherAlert,
  NOTIFICATION_TYPES,
  TOPICS
};

/**
 * Service de notifications
 * AgroSmart - Système Agricole Intelligent
 */

const prisma = require('../config/prisma');
const smsService = require('./smsService');
const emailService = require('./emailService');
const logger = require('../utils/logger');

/**
 * Envoyer une alerte à un utilisateur (multi-canal)
 */
exports.sendAlert = async (userId, alerte) => {
  try {
    // Récupérer les informations de l'utilisateur
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        preferencesNotification: true
      }
    });

    if (!user) {
      logger.warn('Utilisateur non trouvé pour notification', { userId });
      return;
    }

    const prefs = user.preferencesNotification || {
      email: true,
      sms: true,
      push: true,
      whatsapp: false
    };

    const results = {
      email: false,
      sms: false,
      whatsapp: false
    };

    // Envoyer par email si activé
    if (prefs.email !== false && user.email) {
      try {
        await emailService.sendAlert(user.email, alerte, user.prenoms);
        results.email = true;
      } catch (error) {
        logger.warn('Échec notification email', { userId, error: error.message });
      }
    }

    // Envoyer par SMS si critique ou si activé
    if ((alerte.niveau === 'critical' || prefs.sms !== false) && user.telephone) {
      try {
        await smsService.sendAlert(user.telephone, alerte);
        results.sms = true;
      } catch (error) {
        logger.warn('Échec notification SMS', { userId, error: error.message });
      }
    }

    // Envoyer par WhatsApp si activé
    if (prefs.whatsapp && user.telephone) {
      try {
        await smsService.sendWhatsApp(user.telephone,
          `🌱 AgroSmart - ${alerte.titre}\n\n${alerte.message}`
        );
        results.whatsapp = true;
      } catch (error) {
        logger.warn('Échec notification WhatsApp', { userId, error: error.message });
      }
    }

    logger.info('Notifications envoyées', { userId, alerteId: alerte.id, results });

    // Update alert status in database
    if (alerte.id) {
      // Check if alerte exists before updating to avoid errors if it was just a memory object
      // But assuming it has ID it's in DB.
      try {
        await prisma.alerte.update({
          where: { id: alerte.id },
          data: {
            envoyeSms: results.sms,
            envoyeWhatsapp: results.whatsapp,
            envoyeEmail: results.email,
            dateEnvoi: new Date(),
            status: 'ENVOYEE' // Check Enum in Schema? Or String?
          }
        });
      } catch (e) {
        logger.warn('Could not update alert status', { id: alerte.id, error: e.message });
      }
    }

    return results;
  } catch (error) {
    logger.error('Erreur envoi notifications', { userId, error: error.message });
    throw error;
  }
};

/**
 * Envoyer une notification à tous les utilisateurs d'un rôle
 */
exports.sendToRole = async (role, titre, message, niveau = 'info') => {
  try {
    const users = await prisma.user.findMany({
      where: {
        role: role,
        status: 'ACTIF'
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true
      }
    });

    const alerte = { titre, message, niveau };
    const results = [];

    for (const user of users) {
      try {
        const result = await this.sendAlert(user.id, alerte);
        results.push({ userId: user.id, success: true, ...result });
      } catch (error) {
        results.push({ userId: user.id, success: false, error: error.message });
      }
    }

    logger.info('Notifications de masse envoyées', { role, total: results.length });

    return results;
  } catch (error) {
    logger.error('Erreur notifications de masse', { error: error.message });
    throw error;
  }
};

/**
 * Envoyer une notification aux propriétaires d'une parcelle
 */
exports.sendToParcelleOwner = async (parcelleId, titre, message, niveau = 'info') => {
  try {
    const parcelle = await prisma.parcelle.findUnique({
      where: { id: parcelleId },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            telephone: true,
            nom: true
          }
        }
      }
    });

    if (!parcelle || !parcelle.user) {
      logger.warn('Parcelle ou propriétaire non trouvé pour notification', { parcelleId });
      return null;
    }

    const alerte = {
      titre,
      message,
      niveau,
      parcelle_nom: parcelle.nom
    };

    return this.sendAlert(parcelle.user.id, alerte);
  } catch (error) {
    logger.error('Erreur notification propriétaire parcelle', { parcelleId, error: error.message });
    throw error;
  }
};

/**
 * Envoyer un rappel journalier
 */
exports.sendDailyReminder = async (userId, data) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) return null;

    const emailContent = `
      Bonjour ${user.prenoms},

      Voici votre résumé quotidien AgroSmart:

      📊 Parcelles: ${data.parcelles || 0}
      🌡️ Alertes actives: ${data.alertes || 0}
      💧 Irrigation recommandée: ${data.irrigation ? 'Oui' : 'Non'}
      📈 Mesures collectées: ${data.mesures || 0}

      Bonne journée !
      L'équipe AgroSmart
    `;

    if (user.email) {
      await emailService.sendEmail(
        user.email,
        '📊 Votre résumé quotidien AgroSmart',
        emailContent.replace(/\n/g, '<br>')
      );
    }

    return { success: true };
  } catch (error) {
    logger.error('Erreur rappel journalier', { userId, error: error.message });
    throw error;
  }
};

module.exports = exports;

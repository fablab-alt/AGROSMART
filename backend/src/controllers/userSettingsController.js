/**
 * Contrôleur pour les paramètres utilisateur
 * AgroSmart - Système Agricole Intelligent
 */

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient({ datasourceUrl: process.env.DATABASE_URL });
const logger = require('../utils/logger');

/**
 * @desc    Obtenir les paramètres de l'utilisateur connecté
 * @route   GET /api/users/settings
 * @access  Private
 */
exports.getSettings = async (req, res) => {
  try {
    const userId = req.user.id;
    
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        langue_preferee: true,
        preferencesNotification: true,
      }
    });

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Extraire les préférences avec valeurs par défaut
    const prefs = user.preferencesNotification || {};
    
    return res.json({
      success: true,
      data: {
        language: user.langue_preferee || 'fr',
        vocal_mode_enabled: prefs.vocal_mode_enabled ?? false,
        notifications_enabled: prefs.notifications_enabled ?? true,
        low_data_mode: prefs.low_data_mode ?? false,
        // Autres préférences possibles
        email_notifications: prefs.email_notifications ?? true,
        sms_notifications: prefs.sms_notifications ?? true,
        push_notifications: prefs.push_notifications ?? true,
      }
    });
  } catch (error) {
    logger.error('Erreur lors de la récupération des paramètres:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la récupération des paramètres'
    });
  }
};

/**
 * @desc    Mettre à jour les paramètres de l'utilisateur connecté
 * @route   PATCH /api/users/settings
 * @access  Private
 */
exports.updateSettings = async (req, res) => {
  try {
    const userId = req.user.id;
    const updates = req.body;

    // Récupérer l'utilisateur actuel
    const currentUser = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        langue_preferee: true,
        preferencesNotification: true,
      }
    });

    if (!currentUser) {
      return res.status(404).json({
        success: false,
        message: 'Utilisateur non trouvé'
      });
    }

    // Préparer les données à mettre à jour
    const updateData = {};
    const currentPrefs = currentUser.preferencesNotification || {};
    const newPrefs = { ...currentPrefs };

    // Mettre à jour la langue si fournie
    if (updates.language !== undefined) {
      // Mapper les noms de langue vers les codes
      const languageMap = {
        'Français': 'fr',
        'English': 'en',
        'Baoulé': 'bci',
        'Malinké': 'mlq',
        'Sénoufo': 'sef',
        'fr': 'fr',
        'en': 'en',
      };
      updateData.langue_preferee = languageMap[updates.language] || updates.language;
    }

    // Mettre à jour les préférences de notification
    if (updates.vocal_mode_enabled !== undefined) {
      newPrefs.vocal_mode_enabled = Boolean(updates.vocal_mode_enabled);
    }
    if (updates.notifications_enabled !== undefined) {
      newPrefs.notifications_enabled = Boolean(updates.notifications_enabled);
    }
    if (updates.low_data_mode !== undefined) {
      newPrefs.low_data_mode = Boolean(updates.low_data_mode);
    }
    if (updates.email_notifications !== undefined) {
      newPrefs.email_notifications = Boolean(updates.email_notifications);
    }
    if (updates.sms_notifications !== undefined) {
      newPrefs.sms_notifications = Boolean(updates.sms_notifications);
    }
    if (updates.push_notifications !== undefined) {
      newPrefs.push_notifications = Boolean(updates.push_notifications);
    }

    // Ajouter les préférences mises à jour
    updateData.preferencesNotification = newPrefs;

    // Effectuer la mise à jour
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        langue_preferee: true,
        preferencesNotification: true,
      }
    });

    const prefs = updatedUser.preferencesNotification || {};

    return res.json({
      success: true,
      message: 'Paramètres mis à jour avec succès',
      data: {
        language: updatedUser.langue_preferee || 'fr',
        vocal_mode_enabled: prefs.vocal_mode_enabled ?? false,
        notifications_enabled: prefs.notifications_enabled ?? true,
        low_data_mode: prefs.low_data_mode ?? false,
        email_notifications: prefs.email_notifications ?? true,
        sms_notifications: prefs.sms_notifications ?? true,
        push_notifications: prefs.push_notifications ?? true,
      }
    });
  } catch (error) {
    logger.error('Erreur lors de la mise à jour des paramètres:', error);
    return res.status(500).json({
      success: false,
      message: 'Erreur serveur lors de la mise à jour des paramètres'
    });
  }
};

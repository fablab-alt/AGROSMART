/**
 * Password Security Service
 * 
 * Gère l'historique des mots de passe et les validations de sécurité
 * pour empêcher la réutilisation des anciens mots de passe.
 */

const bcrypt = require('bcryptjs');
const logger = require('../utils/logger');
const prisma = require('../config/prisma');

const PASSWORD_HISTORY_LIMIT = 5; // Nombre de mots de passe à conserver

/**
 * Service de gestion des mots de passe
 */
class PasswordService {
  /**
   * Vérifie si le nouveau mot de passe a été utilisé récemment
   * 
   * @param {string} userId - ID de l'utilisateur
   * @param {string} newPassword - Nouveau mot de passe en clair
   * @returns {Promise<{isReused: boolean, message?: string}>}
   */
  static async checkPasswordHistory(userId, newPassword) {
    try {
      // Récupérer les N derniers mots de passe
      const history = await prisma.passwordHistory.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: PASSWORD_HISTORY_LIMIT,
      });

      // Vérifier contre chaque ancien mot de passe
      for (const record of history) {
        const match = await bcrypt.compare(newPassword, record.passwordHash);
        if (match) {
          return {
            isReused: true,
            message: `Vous ne pouvez pas réutiliser l'un de vos ${PASSWORD_HISTORY_LIMIT} derniers mots de passe.`,
          };
        }
      }

      // Vérifier aussi contre le mot de passe actuel
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { passwordHash: true },
      });

      if (user) {
        const matchCurrent = await bcrypt.compare(newPassword, user.passwordHash);
        if (matchCurrent) {
          return {
            isReused: true,
            message: 'Le nouveau mot de passe doit être différent de l\'actuel.',
          };
        }
      }

      return { isReused: false };
    } catch (error) {
      logger.error('Erreur lors de la vérification de l\'historique:', error);
      throw error;
    }
  }

  /**
   * Sauvegarde le mot de passe actuel dans l'historique avant changement
   * 
   * @param {string} userId - ID de l'utilisateur
   * @param {string} currentPasswordHash - Hash du mot de passe actuel
   */
  static async saveToHistory(userId, currentPasswordHash) {
    try {
      // Ajouter à l'historique
      await prisma.passwordHistory.create({
        data: {
          userId,
          passwordHash: currentPasswordHash,
        },
      });

      // Supprimer les anciens enregistrements au-delà de la limite
      const oldRecords = await prisma.passwordHistory.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip: PASSWORD_HISTORY_LIMIT,
        select: { id: true },
      });

      if (oldRecords.length > 0) {
        await prisma.passwordHistory.deleteMany({
          where: {
            id: { in: oldRecords.map(r => r.id) },
          },
        });
      }
    } catch (error) {
      logger.error('Erreur lors de la sauvegarde dans l\'historique:', error);
      throw error;
    }
  }

  /**
   * Change le mot de passe d'un utilisateur avec vérification d'historique
   * 
   * @param {string} userId - ID de l'utilisateur
   * @param {string} currentPassword - Mot de passe actuel en clair
   * @param {string} newPassword - Nouveau mot de passe en clair
   * @returns {Promise<{success: boolean, message: string}>}
   */
  static async changePassword(userId, currentPassword, newPassword) {
    try {
      // Vérifier l'utilisateur et son mot de passe actuel
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { passwordHash: true },
      });

      if (!user) {
        return { success: false, message: 'Utilisateur non trouvé' };
      }

      // Vérifier le mot de passe actuel
      const isCurrentValid = await bcrypt.compare(currentPassword, user.passwordHash);
      if (!isCurrentValid) {
        return { success: false, message: 'Mot de passe actuel incorrect' };
      }

      // Vérifier l'historique
      const historyCheck = await this.checkPasswordHistory(userId, newPassword);
      if (historyCheck.isReused) {
        return { success: false, message: historyCheck.message };
      }

      // Valider la force du nouveau mot de passe
      const strengthCheck = this.validatePasswordStrength(newPassword);
      if (!strengthCheck.isValid) {
        return { success: false, message: strengthCheck.message };
      }

      // Sauvegarder l'ancien mot de passe dans l'historique
      await this.saveToHistory(userId, user.passwordHash);

      // Hasher et mettre à jour le nouveau mot de passe
      const newPasswordHash = await bcrypt.hash(newPassword, 12);
      await prisma.user.update({
        where: { id: userId },
        data: { passwordHash: newPasswordHash },
      });

      return { success: true, message: 'Mot de passe modifié avec succès' };
    } catch (error) {
      logger.error('Erreur lors du changement de mot de passe:', error);
      throw error;
    }
  }

  /**
   * Valide la force d'un mot de passe
   * 
   * @param {string} password - Mot de passe à valider
   * @returns {{isValid: boolean, message?: string, score: number}}
   */
  static validatePasswordStrength(password) {
    const requirements = {
      minLength: 8,
      hasUppercase: /[A-Z]/,
      hasLowercase: /[a-z]/,
      hasNumber: /[0-9]/,
      hasSpecial: /[!@#$%^&*(),.?":{}|<>]/,
    };

    const errors = [];
    let score = 0;

    if (password.length < requirements.minLength) {
      errors.push(`Minimum ${requirements.minLength} caractères requis`);
    } else {
      score += 1;
    }

    if (!requirements.hasUppercase.test(password)) {
      errors.push('Au moins une majuscule requise');
    } else {
      score += 1;
    }

    if (!requirements.hasLowercase.test(password)) {
      errors.push('Au moins une minuscule requise');
    } else {
      score += 1;
    }

    if (!requirements.hasNumber.test(password)) {
      errors.push('Au moins un chiffre requis');
    } else {
      score += 1;
    }

    if (!requirements.hasSpecial.test(password)) {
      errors.push('Au moins un caractère spécial requis');
    } else {
      score += 1;
    }

    // Bonus pour longueur supplémentaire
    if (password.length >= 12) score += 1;
    if (password.length >= 16) score += 1;

    return {
      isValid: errors.length === 0,
      message: errors.length > 0 ? errors.join('. ') : undefined,
      score, // 0-7, où 5+ est considéré fort
    };
  }

  /**
   * Génère un mot de passe sécurisé aléatoire
   * 
   * @param {number} length - Longueur du mot de passe (défaut: 16)
   * @returns {string} Mot de passe généré
   */
  static generateSecurePassword(length = 16) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const special = '!@#$%^&*()_+-=[]{}|;:,.<>?';
    
    const all = uppercase + lowercase + numbers + special;
    
    // Garantir au moins un caractère de chaque type
    let password = '';
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += special[Math.floor(Math.random() * special.length)];
    
    // Compléter avec des caractères aléatoires
    for (let i = password.length; i < length; i++) {
      password += all[Math.floor(Math.random() * all.length)];
    }
    
    // Mélanger le mot de passe
    return password.split('').sort(() => Math.random() - 0.5).join('');
  }
}

module.exports = PasswordService;

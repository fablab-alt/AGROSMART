/**
 * Contrôleur d'authentification
 * AgroSmart - Système Agricole Intelligent
 */

const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const prisma = require('../config/prisma');
const config = require('../config');
const { errors } = require('../middlewares/errorHandler');
const {
  generateAccessToken,
  generateRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens
} = require('../middlewares/auth');
const logger = require('../utils/logger');
const authService = require('../services/authService');
const smsService = require('../services/smsService');
const emailService = require('../services/emailService');

/**
 * Générer un code OTP à 6 chiffres
 */
const generateOtp = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Inscription d'un nouvel utilisateur
 */
exports.register = async (req, res, next) => {
  try {
    const result = await authService.registerUser(req.body);

    if (result.isAutoLogin) {
      return res.status(201).json({
        success: true,
        message: 'Compte créé avec succès!',
        data: {
          user: result.user,
          accessToken: result.token,
          refreshToken: result.refreshToken,
          isDebug: result.isDebug
        }
      });
    }

    // Production: Envoi OTP (Simulation)
    // await smsService.sendVerificationCode(result.user.telephone, '123456');

    res.status(201).json({
      success: true,
      message: 'Inscription réussie. Veuillez vérifier votre téléphone pour activer votre compte.',
      data: {
        userId: result.user.id,
        requiresVerification: true,
        isDebug: result.isDebug
      }
    });

  } catch (error) {
    next(error);
  }
};

/**
 * Connexion (première étape - envoi OTP ou connexion directe en dev)
 */
exports.login = async (req, res, next) => {
  try {
    const { login, email, telephone, identifier, password } = req.body;
    const userIdentifier = identifier || login || email || telephone;

    if (!userIdentifier || !password) {
      throw errors.badRequest('Email/Téléphone et mot de passe requis');
    }

    const result = await authService.loginUser({ login: userIdentifier, password });

    res.json({
      success: true,
      message: 'Connexion réussie',
      data: {
        user: result.user,
        accessToken: result.token,
        refreshToken: result.refreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Vérification du code OTP
 */
exports.verifyOtp = async (req, res, next) => {
  try {
    const { identifier, otp } = req.body;

    // Rechercher l'utilisateur
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { telephone: identifier }
        ]
      }
    });

    if (!user) {
      throw errors.unauthorized('Utilisateur non trouvé');
    }

    // Vérifier l'OTP
    const otpData = await prisma.otpCode.findFirst({
      where: {
        userId: user.id,
        code: otp,
        used: false
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    if (!otpData) {
      throw errors.unauthorized('Code OTP invalide');
    }

    // Vérifier l'expiration
    if (new Date(otpData.expiresAt) < new Date()) {
      throw errors.unauthorized('Code OTP expiré');
    }

    // Marquer l'OTP comme utilisé
    await prisma.otpCode.update({
      where: { id: otpData.id },
      data: { used: true }
    });

    // Si c'est une vérification d'inscription, activer le compte
    if (otpData.type === 'REGISTER' && user.status === 'EN_ATTENTE') {
      await prisma.user.update({
        where: { id: user.id },
        data: { status: 'ACTIF' }
      });
      user.status = 'ACTIF';
    }

    // Générer les tokens
    const accessToken = generateAccessToken(user);
    const refreshToken = await generateRefreshToken(user.id);

    // Mettre à jour la dernière connexion
    await prisma.user.update({
      where: { id: user.id },
      data: { derniereConnexion: new Date() }
    });

    logger.audit('Connexion réussie', { userId: user.id });

    res.json({
      success: true,
      message: 'Connexion réussie',
      data: {
        user: {
          id: user.id,
          email: user.email,
          telephone: user.telephone,
          nom: user.nom,
          prenom: user.prenoms,
          role: user.role,
          langue: user.langue_preferee
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Rafraîchir le token d'accès avec rotation du refresh token
 * 
 * SÉCURITÉ: Implémente la rotation des refresh tokens
 * - L'ancien refresh token est révoqué
 * - Un nouveau refresh token est généré
 * - Cela limite la fenêtre d'attaque si un token est compromis
 */
exports.refreshToken = async (req, res, next) => {
  try {
    const user = req.user;
    const oldRefreshTokenId = req.refreshTokenId;

    // Révoquer l'ancien refresh token (rotation)
    if (oldRefreshTokenId) {
      await prisma.refreshToken.update({
        where: { id: oldRefreshTokenId },
        data: { revoked: true, revokedAt: new Date() }
      }).catch(() => {
        // Ignorer les erreurs si le token n'existe plus
      });
    }

    // Générer un nouveau token d'accès
    const accessToken = generateAccessToken(user);

    // Générer un nouveau refresh token (rotation)
    const newRefreshToken = await generateRefreshToken(user.id);

    logger.audit('Token rafraîchi avec rotation', { 
      userId: user.id,
      oldTokenRevoked: !!oldRefreshTokenId 
    });

    res.json({
      success: true,
      data: { 
        accessToken,
        refreshToken: newRefreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Déconnexion
 * 
 * SÉCURITÉ: Permet deux modes de déconnexion
 * - refreshToken fourni: révoque uniquement cette session
 * - allSessions=true: révoque toutes les sessions de l'utilisateur
 * - Par défaut: révoque toutes les sessions (comportement sécurisé)
 */
exports.logout = async (req, res, next) => {
  try {
    const { refreshToken, allSessions = true } = req.body || {};
    const { revokeTokenByString, revokeAllUserTokens } = require('../middlewares/auth');

    if (refreshToken && !allSessions) {
      // Révoquer uniquement le refresh token fourni (déconnexion d'une seule session)
      const revoked = await revokeTokenByString(refreshToken);
      
      logger.audit('Déconnexion session unique', { 
        userId: req.user.id,
        tokenRevoked: revoked
      });

      res.json({
        success: true,
        message: revoked ? 'Session déconnectée' : 'Session déjà déconnectée ou invalide'
      });
    } else {
      // Révoquer tous les refresh tokens de l'utilisateur (déconnexion globale)
      await revokeAllUserTokens(req.user.id);

      logger.audit('Déconnexion globale', { userId: req.user.id });

      res.json({
        success: true,
        message: 'Toutes les sessions déconnectées'
      });
    }
  } catch (error) {
    next(error);
  }
};

/**
 * Demande de réinitialisation du mot de passe
 */
exports.forgotPassword = async (req, res, next) => {
  try {
    const { identifier } = req.body;

    // Rechercher l'utilisateur
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { telephone: identifier }
        ]
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true
      }
    });

    // Ne pas révéler si l'utilisateur existe
    if (!user) {
      return res.json({
        success: true,
        message: 'Si un compte existe avec cet identifiant, un code de réinitialisation sera envoyé'
      });
    }

    // Générer l'OTP
    const otp = generateOtp();
    const otpExpires = new Date(Date.now() + config.otp.expiresIn);

    // Supprimer les anciens OTP et créer le nouveau
    await prisma.otpCode.deleteMany({
      where: {
        userId: user.id,
        type: 'RESET'
      }
    });
    await prisma.otpCode.create({
      data: {
        userId: user.id,
        code: otp,
        type: 'RESET',
        expiresAt: otpExpires
      }
    });

    // Envoyer l'OTP
    try {
      await smsService.sendOtp(user.telephone, otp);
      await emailService.sendPasswordReset(user.email, otp, user.nom);
    } catch (err) {
      logger.warn('Échec envoi OTP reset', { userId: user.id, error: err.message });
    }

    res.json({
      success: true,
      message: 'Si un compte existe avec cet identifiant, un code de réinitialisation sera envoyé'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Réinitialisation du mot de passe
 */
exports.resetPassword = async (req, res, next) => {
  try {
    const { identifier, otp, newPassword } = req.body;

    // Rechercher l'utilisateur
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { telephone: identifier }
        ]
      },
      select: { id: true }
    });

    if (!user) {
      throw errors.unauthorized('Requête invalide');
    }

    // Vérifier l'OTP
    const otpData = await prisma.otpCode.findFirst({
      where: {
        userId: user.id,
        code: otp,
        type: 'RESET',
        used: false
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    if (!otpData || new Date(otpData.expiresAt) < new Date()) {
      throw errors.unauthorized('Code invalide ou expiré');
    }

    // Hasher le nouveau mot de passe
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Mettre à jour le mot de passe
    await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash: hashedPassword }
    });

    // Marquer l'OTP comme utilisé
    await prisma.otpCode.update({
      where: { id: otpData.id },
      data: { used: true }
    });

    // Révoquer tous les refresh tokens
    await revokeAllUserTokens(user.id);

    logger.audit('Réinitialisation mot de passe', { userId: user.id });

    res.json({
      success: true,
      message: 'Mot de passe réinitialisé avec succès'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Renvoyer le code OTP
 */
exports.resendOtp = async (req, res, next) => {
  try {
    const { identifier } = req.body;

    // Rechercher l'utilisateur
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { telephone: identifier }
        ]
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true
      }
    });

    if (!user) {
      throw errors.notFound('Utilisateur non trouvé');
    }

    // Vérifier le rate limiting (max 5 renvois par heure)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentOtpsCount = await prisma.otpCode.count({
      where: {
        userId: user.id,
        createdAt: {
          gte: oneHourAgo
        }
      }
    });

    if (recentOtpsCount >= 5) {
      throw errors.forbidden('Trop de demandes. Réessayez dans une heure.');
    }

    // Générer et envoyer un nouvel OTP
    const otp = generateOtp();
    const otpExpires = new Date(Date.now() + config.otp.expiresIn);

    await prisma.otpCode.create({
      data: {
        userId: user.id,
        code: otp,
        type: 'LOGIN',
        expiresAt: otpExpires
      }
    });

    try {
      await smsService.sendOtp(user.telephone, otp);
    } catch (err) {
      logger.warn('Échec renvoi SMS OTP', { userId: user.id, error: err.message });
    }

    res.json({
      success: true,
      message: 'Nouveau code envoyé'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Obtenir le profil de l'utilisateur connecté
 */
exports.getMe = async (req, res, next) => {
  try {
    // Debug logs removed for security
    const userData = await prisma.user.findUnique({
      where: { id: req.user.id }
    });

    if (!userData) {
      throw errors.notFound('Utilisateur non trouvé');
    }

    // Compter les capteurs via les parcelles
    const capteursCount = await prisma.capteur.count({
      where: {
        parcelle: {
          userId: req.user.id
        }
      }
    });

    // Count parcelles separately
    const parcellesCount = await prisma.parcelle.count({
      where: { userId: req.user.id }
    });

    // Calculer la surface totale
    const surfaceTotale = await prisma.parcelle.aggregate({
      _sum: { superficie: true },
      where: { userId: req.user.id }
    });

    // Compter les capteurs actifs
    const capteursActifs = await prisma.capteur.count({
      where: {
        parcelle: { userId: req.user.id },
        statut: 'ACTIF'
      }
    });

    res.json({
      success: true,
      data: {
        id: userData.id,
        nom: userData.nom,
        prenoms: userData.prenoms,
        email: userData.email,
        telephone: userData.telephone,
        role: userData.role,
        status: userData.status,
        regionId: userData.regionId,
        // Champs agricoles
        type_producteur: userData.typeProducteur,
        superficie_exploitee: userData.superficieExploitee,
        unite_superficie: userData.uniteSuperficie,
        systeme_irrigation: userData.systemeIrrigation,
        production_mois1_kg: userData.productionMois1Kg,
        production_mois2_kg: userData.productionMois2Kg,
        production_mois3_kg: userData.productionMois3Kg,
        production_3_mois_precedents_kg: userData.production3MoisPrecedentsKg,

        parcelles_count: parcellesCount,
        capteurs_count: capteursCount,
        hectares_total: parseFloat(surfaceTotale._sum.superficie) || 0,
        
        // ✨ Nouvelles statistiques pour le profil
        statistics: {
          parcelles_count: parcellesCount,
          surface_totale: surfaceTotale._sum.superficie || 0,
          capteurs_count: capteursCount,
          capteurs_actifs: capteursActifs
        },
        
        updatedAt: userData.updatedAt
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Mettre à jour le profil
 */
exports.updateMe = async (req, res, next) => {
  try {
    const { nom, prenoms, langue_preferee, village, type_producteur, region, notifications_sms, notifications_whatsapp, notifications_push } = req.body;

    // Resolve region_id if region name is provided
    let regionId = undefined;
    if (region) {
      const regionData = await prisma.region.findFirst({
        where: { nom: region },
        select: { id: true }
      });
      if (regionData) {
        regionId = regionData.id;
      }
    }

    let photoUrl = undefined;
    if (req.file) {
      photoUrl = `/uploads/profiles/${req.file.filename}`;
    }

    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(nom && { nom }),
        ...(prenoms && { prenoms }),
        ...(regionId && { regionId }),
        ...(photoUrl && { photoProfil: photoUrl })
      },
      select: {
        id: true,
        email: true,
        telephone: true,
        nom: true,
        prenoms: true,
        role: true,
        regionId: true,
        photoProfil: true
      }
    });

    logger.audit('Mise à jour profil', { userId: req.user.id });

    res.json({
      success: true,
      message: 'Profil mis à jour',
      data: updatedUser
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Changer le mot de passe
 */
exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    // Récupérer le hash actuel
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { passwordHash: true }
    });

    if (!user) {
      throw errors.notFound('Utilisateur non trouvé');
    }

    // Vérifier l'ancien mot de passe
    const isValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isValid) {
      throw errors.unauthorized('Mot de passe actuel incorrect');
    }

    // Hasher et mettre à jour le nouveau mot de passe
    const salt = await bcrypt.genSalt(12);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await prisma.user.update({
      where: { id: req.user.id },
      data: {
        passwordHash: hashedPassword,
        updatedAt: new Date()
      }
    });

    // Révoquer tous les refresh tokens (force reconnexion)
    await revokeAllUserTokens(req.user.id);

    logger.audit('Changement mot de passe', { userId: req.user.id });

    res.json({
      success: true,
      message: 'Mot de passe modifié avec succès'
    });
  } catch (error) {
    next(error);
  }
};

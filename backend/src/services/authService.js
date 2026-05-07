/**
 * Service d'authentification
 * Contient toute la logique métier liée à l'auth
 */

const bcrypt = require('bcryptjs');
const prisma = require('../config/prisma');
const config = require('../config');
const { errors } = require('../middlewares/errorHandler');
const {
    generateAccessToken,
    generateRefreshToken,
    revokeRefreshToken
} = require('../middlewares/auth');
const logger = require('../utils/logger');
const { normalizePhoneNumber, getPhoneVariants } = require('../utils/phoneFormatter');

class AuthService {
    /**
     * Inscription d'un nouvel utilisateur
     */
    async registerUser(userData) {
        const { email, telephone, password, nom, prenoms, prenom, langue_preferee = 'fr', adresse,
            role = 'PRODUCTEUR', // Nouveau: rôle par défaut PRODUCTEUR pour compatibilité
            type_producteur,
            production_3_mois_precedents_kg, superficie_exploitee, unite_superficie, systeme_irrigation,
            production_mois1_kg, production_mois2_kg, production_mois3_kg } = userData;

        logger.info('Registration attempt', { telephone, email: email || 'none', role });

        // Normalisation du numéro de téléphone
        const normalizedPhone = normalizePhoneNumber(telephone);

        // Normalisation prenoms
        const userPrenoms = prenoms || prenom || '';
        const userEmail = email || null;

        // Validation du rôle (seulement ACHETEUR ou PRODUCTEUR autorisés à l'inscription)
        const validRoles = ['ACHETEUR', 'PRODUCTEUR'];
        const userRole = validRoles.includes(role) ? role : 'PRODUCTEUR';

        // Vérification existence avec variantes de téléphone
        const phoneVariants = getPhoneVariants(normalizedPhone);
        const existingUser = await prisma.user.findFirst({
            where: {
                OR: [
                    ...(userEmail ? [{ email: userEmail }] : []),
                    ...phoneVariants.map(variant => ({ telephone: variant }))
                ]
            }
        });

        if (existingUser) {
            throw errors.conflict('Un utilisateur avec cet email ou ce téléphone existe déjà');
        }

        // Hashage mot de passe
        const salt = await bcrypt.genSalt(12);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Statut initial : ACTIF par défaut
        // OTP/Twilio non configuré → on active directement le compte à l'inscription
        // TODO: Remettre EN_ATTENTE une fois que la vérification OTP/Email sera activée
        const initialStatus = 'ACTIF';

        // Insertion - Les champs agricoles ne sont pertinents que pour les producteurs
        const user = await prisma.user.create({
            data: {
                email: userEmail,
                telephone: normalizedPhone, // Utiliser le numéro normalisé
                passwordHash: hashedPassword,
                nom,
                prenoms: userPrenoms,
                adresse,
                langue_preferee: langue_preferee,
                status: initialStatus,
                role: userRole, // Utiliser le rôle validé
                // Champs profil agricole optionnels (uniquement pour les producteurs)
                ...(userRole === 'PRODUCTEUR' && type_producteur && { typeProducteur: type_producteur }),
                ...(userRole === 'PRODUCTEUR' && production_3_mois_precedents_kg && !isNaN(parseFloat(production_3_mois_precedents_kg)) && { production3MoisPrecedentsKg: parseFloat(production_3_mois_precedents_kg) }),
                ...(userRole === 'PRODUCTEUR' && superficie_exploitee && !isNaN(parseFloat(superficie_exploitee)) && { superficieExploitee: parseFloat(superficie_exploitee) }),
                ...(userRole === 'PRODUCTEUR' && unite_superficie && { uniteSuperficie: unite_superficie }),
                ...(userRole === 'PRODUCTEUR' && systeme_irrigation && { systemeIrrigation: systeme_irrigation }),
                ...(userRole === 'PRODUCTEUR' && production_mois1_kg && !isNaN(parseFloat(production_mois1_kg)) && { productionMois1Kg: parseFloat(production_mois1_kg) }),
                ...(userRole === 'PRODUCTEUR' && production_mois2_kg && !isNaN(parseFloat(production_mois2_kg)) && { productionMois2Kg: parseFloat(production_mois2_kg) }),
                ...(userRole === 'PRODUCTEUR' && production_mois3_kg && !isNaN(parseFloat(production_mois3_kg)) && { productionMois3Kg: parseFloat(production_mois3_kg) })
            },
            select: {
                id: true,
                email: true,
                telephone: true,
                nom: true,
                prenoms: true,
                role: true,
                status: true,
                createdAt: true
            }
        });

        // Gestion des Parcelles multiples (uniquement pour les producteurs)
        if (userRole === 'PRODUCTEUR' && userData.productions && Array.isArray(userData.productions)) {
            logger.info('Processing productions for producer', { userId: user.id, count: userData.productions.length });
            try {
                for (const prod of userData.productions) {
                    if (prod.type && prod.surface) {
                        logger.info('Creating parcelle', { type: prod.type, surface: prod.surface });
                        await prisma.parcelle.create({
                            data: {
                                userId: user.id,
                                nom: `Parcelle de ${prod.type}`,
                                superficie: parseFloat(prod.surface),
                                cultureActuelle: prod.type,
                                statut: 'ACTIVE',
                                sante: 'OPTIMAL'
                            }
                        });
                    }
                }
            } catch (err) {
                logger.error('Erreur lors de la création automatique des parcelles', { error: err.message, userId: user.id });
                // On ne bloque pas l'inscription pour ça, mais on log l'erreur
            }
        } else if (userRole === 'PRODUCTEUR') {
            logger.info('No productions array in userData for producer', { userId: user.id });
        }
        // Pour les acheteurs, pas besoin de parcelles
        if (userRole === 'ACHETEUR') {
            logger.info('Buyer account created - no parcelle needed', { userId: user.id });
        }

        // Auto-login à l'inscription (OTP/Twilio désactivé → on retourne directement un token)
        // TODO: Séparer ce comportement dev/prod quand la vérification OTP/Email sera activée
        const accessToken = generateAccessToken(user);
        const refreshToken = await generateRefreshToken(user.id);

        logger.audit('Inscription et connexion directe', { userId: user.id });

        return {
            user: {
                id: user.id,
                email: user.email,
                telephone: user.telephone,
                nom: user.nom,
                prenom: user.prenoms,
                role: user.role,
                status: user.status,
                // Champs agricoles
                type_producteur: user.typeProducteur,
                superficie_exploitee: user.superficieExploitee,
                unite_superficie: user.uniteSuperficie,
                systeme_irrigation: user.systemeIrrigation,
                production_mois1_kg: user.productionMois1Kg,
                production_mois2_kg: user.productionMois2Kg,
                production_mois3_kg: user.productionMois3Kg,
                production_3_mois_precedents_kg: user.production3MoisPrecedentsKg
            },
            token: accessToken,
            refreshToken,
            isAutoLogin: true
        };
    }

    /**
     * Connexion utilisateur
     */
    async loginUser(credentials) {
        const { login, password } = credentials;

        // Normaliser le numéro de téléphone si c'est un numéro
        // Accepte: 0701000001, +2250701000001, 2250701000001
        const phoneVariants = getPhoneVariants(login);

        // Recherche utilisateur (email ou téléphone avec variantes)
        const user = await prisma.user.findFirst({
            where: {
                OR: [
                    { email: login },
                    { telephone: login },
                    // Recherche avec toutes les variantes du numéro
                    ...phoneVariants.map(variant => ({ telephone: variant }))
                ]
            },
            select: {
                id: true,
                email: true,
                telephone: true,
                passwordHash: true,
                nom: true,
                prenoms: true,
                role: true,
                status: true
            }
        });

        if (!user) {
            throw errors.unauthorized('Identifiants incorrects');
        }

        // Vérification statut
        if (user.status !== 'ACTIF') {
            if (user.status === 'SUSPENDU') {
                throw errors.forbidden('Votre compte a été suspendu. Contactez le support.');
            }
            if (user.status === 'EN_ATTENTE') {
                throw errors.forbidden('Votre compte est en attente de validation.');
            }
        }

        // Vérification mot de passe
        const isMatch = await bcrypt.compare(password, user.passwordHash);
        if (!isMatch) {
            throw errors.unauthorized('Identifiants incorrects');
        }

        // Génération tokens
        const accessToken = generateAccessToken(user);
        const refreshToken = await generateRefreshToken(user.id);

        // Update last login
        await prisma.user.update({
            where: { id: user.id },
            data: { derniereConnexion: new Date() }
        });

        logger.audit('Connexion réussie', { userId: user.id });

        return {
            user: {
                id: user.id,
                email: user.email,
                telephone: user.telephone,
                nom: user.nom,
                prenom: user.prenoms,
                role: user.role,
                status: user.status
            },
            token: accessToken,
            refreshToken
        };
    }

    /**
     * Générer et envoyer un code OTP
     * @param {string} userId - ID de l'utilisateur
     * @param {string} telephone - Numéro de téléphone pour l'envoi
     * @param {string} type - Type d'OTP (REGISTER, LOGIN, PASSWORD_RESET)
     */
    async generateAndSendOtp(userId, telephone, type = 'LOGIN') {
        // Générer un code à 6 chiffres
        const code = Math.floor(100000 + Math.random() * 900000).toString();

        // Expiration dans 10 minutes
        const expiresAt = new Date();
        expiresAt.setMinutes(expiresAt.getMinutes() + 10);

        // Invalider les anciens OTP non utilisés de ce type
        await prisma.otpCode.updateMany({
            where: {
                userId,
                type,
                used: false
            },
            data: { used: true }
        });

        // Créer le nouvel OTP
        await prisma.otpCode.create({
            data: {
                userId,
                code,
                type,
                expiresAt
            }
        });

        // Envoyer par SMS (seulement si Twilio est configuré)
        const smsService = require('./smsService');
        try {
            await smsService.sendOtp(telephone, code);
            logger.info('OTP envoyé', { userId, type });
        } catch (error) {
            // En développement, logger le code pour les tests
            if (config.isDev) {
                logger.info('OTP (dev mode)', { userId, code, type });
            } else {
                logger.error('Erreur envoi OTP', { userId, error: error.message });
            }
        }

        return { success: true, expiresIn: 600 }; // 600 secondes = 10 minutes
    }

    /**
     * Vérifier un code OTP
     * @param {string} userId - ID de l'utilisateur
     * @param {string} code - Code OTP à vérifier
     * @param {string} type - Type d'OTP attendu (optionnel)
     */
    async verifyOtp(userId, code, type = null) {
        const whereClause = {
            userId,
            code,
            used: false
        };

        if (type) {
            whereClause.type = type;
        }

        const otpData = await prisma.otpCode.findFirst({
            where: whereClause,
            orderBy: { createdAt: 'desc' }
        });

        if (!otpData) {
            throw errors.unauthorized('Code OTP invalide');
        }

        if (new Date(otpData.expiresAt) < new Date()) {
            throw errors.unauthorized('Code OTP expiré');
        }

        // Marquer comme utilisé
        await prisma.otpCode.update({
            where: { id: otpData.id },
            data: { used: true }
        });

        return { valid: true, type: otpData.type };
    }
}

module.exports = new AuthService();

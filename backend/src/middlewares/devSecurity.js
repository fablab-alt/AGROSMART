/**
 * Middleware de sécurité pour l'environnement de développement
 * 
 * Ce middleware fournit des fonctionnalités de développement sécurisées
 * qui sont désactivées en production.
 */

const jwt = require('jsonwebtoken');
const prisma = require('../config/prisma');

const isDevelopment = process.env.NODE_ENV === 'development';
const isTest = process.env.NODE_ENV === 'test';

/**
 * Configuration des utilisateurs de développement
 * Ces utilisateurs sont créés automatiquement en environnement de dev
 */
const DEV_USERS = [
  {
    email: 'dev@agrosmart.ci',
    telephone: '+2250700000000',
    nom: 'Développeur',
    prenoms: 'Test',
    role: 'ADMIN',
    password: process.env.DEV_PASSWORD || 'DevPass123!',
  },
  {
    email: 'farmer@agrosmart.ci',
    telephone: '+2250700000001',
    nom: 'Producteur',
    prenoms: 'Test',
    role: 'PRODUCTEUR',
    password: process.env.DEV_PASSWORD || 'DevPass123!',
  },
];

/**
 * Middleware d'auto-login en développement
 * 
 * Permet de bypasser l'authentification en dev avec un header spécial.
 * JAMAIS actif en production.
 * 
 * Usage:
 * - Header: X-Dev-Auth: dev@agrosmart.ci
 * - Query: ?_dev_user=dev@agrosmart.ci
 */
const devAutoLogin = async (req, res, next) => {
  // Bloquer en production
  if (!isDevelopment && !isTest) {
    return next();
  }

  // Vérifier si l'auto-login est demandé
  const devUserEmail = req.headers['x-dev-auth'] || req.query._dev_user;
  
  if (!devUserEmail) {
    return next();
  }

  // Vérifier que c'est un utilisateur de dev autorisé
  const devUser = DEV_USERS.find(u => u.email === devUserEmail);
  if (!devUser) {
    console.warn(`[DEV-AUTH] Tentative d'auto-login avec utilisateur non autorisé: ${devUserEmail}`);
    return next();
  }

  try {
    // Chercher ou créer l'utilisateur de dev
    let user = await prisma.user.findUnique({
      where: { email: devUserEmail },
    });

    if (!user) {
      // Créer l'utilisateur de dev s'il n'existe pas
      const bcrypt = require('bcryptjs');
      const passwordHash = await bcrypt.hash(devUser.password, 10);
      
      user = await prisma.user.create({
        data: {
          email: devUser.email,
          telephone: devUser.telephone,
          nom: devUser.nom,
          prenoms: devUser.prenoms,
          role: devUser.role,
          passwordHash,
          status: 'ACTIF',
          emailVerifie: true,
        },
      });
      console.log(`[DEV-AUTH] Utilisateur de dev créé: ${devUser.email}`);
    }

    // Générer un token JWT
    const token = jwt.sign(
      { 
        userId: user.id, 
        role: user.role,
        isDev: true,
      },
      process.env.JWT_SECRET || 'dev-secret-key',
      { expiresIn: '24h' }
    );

    // Attacher l'utilisateur et le token à la requête
    req.user = user;
    req.userId = user.id;
    req.token = token;
    req.isDevAuth = true;

    console.log(`[DEV-AUTH] Auto-login réussi pour: ${devUser.email}`);
    
    // Si c'est une requête vers /api/auth/dev-token, retourner le token
    if (req.path === '/api/auth/dev-token' || req.path === '/auth/dev-token') {
      return res.json({
        success: true,
        token,
        user: {
          id: user.id,
          email: user.email,
          nom: user.nom,
          prenoms: user.prenoms,
          role: user.role,
        },
        expiresIn: '24h',
        warning: 'This endpoint is only available in development mode',
      });
    }

    next();
  } catch (error) {
    console.error('[DEV-AUTH] Erreur:', error);
    next(); // Continuer même en cas d'erreur
  }
};

/**
 * Route pour obtenir un token de développement
 * GET /api/auth/dev-token?email=dev@agrosmart.ci
 */
const devTokenRoute = async (req, res) => {
  if (!isDevelopment && !isTest) {
    return res.status(403).json({
      error: 'This endpoint is only available in development mode',
    });
  }

  const email = req.query.email || DEV_USERS[0].email;
  
  // Simuler la requête d'auto-login
  req.headers['x-dev-auth'] = email;
  req.path = '/auth/dev-token';
  
  await devAutoLogin(req, res, () => {
    res.status(400).json({ error: 'Failed to generate dev token' });
  });
};

/**
 * Middleware de logging détaillé en développement
 */
const devLogging = (req, res, next) => {
  if (!isDevelopment) {
    return next();
  }

  const startTime = Date.now();
  
  // Log de la requête entrante
  console.log(`[DEV] ${req.method} ${req.path}`, {
    query: req.query,
    body: req.body ? Object.keys(req.body) : undefined,
    headers: {
      'content-type': req.headers['content-type'],
      'authorization': req.headers.authorization ? 'Bearer [...]' : undefined,
    },
  });

  // Intercepter la fin de la réponse
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    const statusColor = res.statusCode >= 400 ? '\x1b[31m' : '\x1b[32m';
    console.log(
      `[DEV] ${statusColor}${res.statusCode}\x1b[0m ${req.method} ${req.path} - ${duration}ms`
    );
  });

  next();
};

/**
 * Middleware pour ajouter des headers de debug en développement
 */
const devHeaders = (req, res, next) => {
  if (!isDevelopment) {
    return next();
  }

  res.setHeader('X-Dev-Mode', 'true');
  res.setHeader('X-Request-Id', `dev-${Date.now()}`);
  
  next();
};

/**
 * Endpoint de santé détaillé pour le développement
 */
const devHealthCheck = async (req, res) => {
  if (!isDevelopment && !isTest) {
    return res.json({ status: 'ok' });
  }

  try {
    // Vérifier la connexion DB
    await prisma.$queryRaw`SELECT 1`;
    
    res.json({
      status: 'ok',
      environment: process.env.NODE_ENV,
      timestamp: new Date().toISOString(),
      database: 'connected',
      devUsers: DEV_USERS.map(u => ({ email: u.email, role: u.role })),
      features: {
        devAutoLogin: isDevelopment,
        detailedLogging: isDevelopment,
        debugHeaders: isDevelopment,
      },
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      error: error.message,
    });
  }
};

module.exports = {
  devAutoLogin,
  devTokenRoute,
  devLogging,
  devHeaders,
  devHealthCheck,
  DEV_USERS,
};

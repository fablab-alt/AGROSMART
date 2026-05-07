/**
 * Configuration générale de l'application
 * AgroSmart - Système Agricole Intelligent
 */

require('./loadEnv');

const config = {
  // Environnement
  env: process.env.NODE_ENV || 'development',
  isDev: process.env.NODE_ENV === 'development',
  isProd: process.env.NODE_ENV === 'production',
  isTest: process.env.NODE_ENV === 'test',

  // Serveur
  server: {
    port: parseInt(process.env.PORT || process.env.BACKEND_PORT) || 8000,
    apiVersion: process.env.API_VERSION || 'v1'
  },

  // Base de données
  database: {
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT) || 3306,
    name: process.env.DB_NAME || 'agrismart_ci',
    user: process.env.DB_USER || 'agrismart',
    password: process.env.DB_PASSWORD || '',
    ssl: process.env.DB_SSL === 'true',
    // Connection pool configuration for Prisma
    // These are passed via DATABASE_URL query params
    pool: {
      connectionLimit: parseInt(process.env.DB_POOL_SIZE) || 10,
      poolTimeout: parseInt(process.env.DB_POOL_TIMEOUT) || 20,
      connectTimeout: parseInt(process.env.DB_CONNECT_TIMEOUT) || 10
    }
  },

  // JWT
  jwt: {
    // Ne pas utiliser de valeur par défaut pour les secrets en production
    secret: process.env.JWT_SECRET || (process.env.NODE_ENV === 'production' ? null : 'dev-only-secret-not-for-production'),
    refreshSecret: process.env.JWT_REFRESH_SECRET || (process.env.NODE_ENV === 'production' ? null : 'dev-only-refresh-secret-not-for-production'),
    expiresIn: process.env.JWT_EXPIRES_IN || '1h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d'
  },

  // OTP
  otp: {
    expiresMinutes: parseInt(process.env.OTP_EXPIRES_MINUTES) || 10,
    expiresIn: (parseInt(process.env.OTP_EXPIRES_MINUTES) || 10) * 60 * 1000, // en millisecondes
    length: parseInt(process.env.OTP_LENGTH) || 6,
    maxAttempts: parseInt(process.env.OTP_MAX_ATTEMPTS) || 3
  },

  // Twilio (SMS/WhatsApp)
  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID,
    authToken: process.env.TWILIO_AUTH_TOKEN,
    phoneNumber: process.env.TWILIO_PHONE_NUMBER || '+1234567890',
    whatsappNumber: process.env.TWILIO_WHATSAPP_NUMBER
  },

  // Email
  email: {
    host: process.env.SMTP_HOST || '',
    port: parseInt(process.env.SMTP_PORT) || 587,
    user: process.env.SMTP_USER || '',
    pass: process.env.SMTP_PASSWORD || '',
    from: process.env.EMAIL_FROM || 'AgroSmart <noreply@agrosmart.ci>'
  },

  // API Météo
  weather: {
    apiUrl: process.env.WEATHER_API_URL || 'https://api.open-meteo.com/v1/forecast',
    apiKey: process.env.WEATHER_API_KEY
  },

  // Upload fichiers
  upload: {
    path: process.env.UPLOAD_PATH || './uploads',
    maxFileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024 // 10MB
  },

  // IoT
  iot: {
    gatewaySecret: process.env.IOT_GATEWAY_SECRET,
    loraNetworkKey: process.env.LORA_NETWORK_KEY
  },

  // Logs
  logs: {
    level: process.env.LOG_LEVEL || 'info',
    file: process.env.LOG_FILE || './logs/app.log'
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 1 * 60 * 1000, // 1 minute (reduced from 15 to clear bans faster)
    maxRequests: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 2000 // Increased limit
  },

  // CORS
  cors: {
    origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : '*'
  },

  // Seuils d'alerte par défaut
  alertThresholds: {
    humidity: {
      criticalLow: 20,
      warningLow: 30,
      warningHigh: 80,
      criticalHigh: 90
    },
    temperature: {
      criticalLow: 10,
      warningLow: 15,
      warningHigh: 40,
      criticalHigh: 45
    },
    ph: {
      criticalLow: 4.5,
      warningLow: 5.5,
      warningHigh: 7.5,
      criticalHigh: 8.5
    }
  },

  // Dev mode configuration
  dev: {
    password: process.env.DEV_PASSWORD || 'DevPass123!',
    autoLogin: process.env.DEV_AUTO_LOGIN === 'true'
  },

  // Langues supportées
  languages: ['fr', 'baoule', 'malinke', 'senoufo'],
  defaultLanguage: 'fr'
};

// Validation des configurations critiques en production
if (config.isProd) {
  const requiredEnvVars = [
    'JWT_SECRET',
    'JWT_REFRESH_SECRET',
    'DB_PASSWORD',
    // 'TWILIO_ACCOUNT_SID',  // Optionnel - SMS/WhatsApp non activé pour l'instant
    // 'TWILIO_AUTH_TOKEN',   // Optionnel - SMS/WhatsApp non activé pour l'instant
  ];

  const missingVars = requiredEnvVars.filter(v => !process.env[v]);
  if (missingVars.length > 0) {
    console.error(`❌ Variables d'environnement manquantes: ${missingVars.join(', ')}`);
    process.exit(1);
  }

  // Vérifier la force du JWT_SECRET
  if (config.jwt.secret && config.jwt.secret.length < 32) {
    console.error('❌ ERREUR CRITIQUE: JWT_SECRET doit contenir au moins 32 caractères en production');
    process.exit(1);
  }

  // Vérifier la force du JWT_REFRESH_SECRET
  if (config.jwt.refreshSecret && config.jwt.refreshSecret.length < 32) {
    console.error('❌ ERREUR CRITIQUE: JWT_REFRESH_SECRET doit contenir au moins 32 caractères en production');
    process.exit(1);
  }

  // Vérifier que les secrets ne sont pas les valeurs par défaut de développement
  const devSecrets = ['dev-only-secret-not-for-production', 'dev-only-refresh-secret-not-for-production'];
  if (devSecrets.includes(config.jwt.secret) || devSecrets.includes(config.jwt.refreshSecret)) {
    console.error('❌ ERREUR CRITIQUE: Les secrets JWT utilisent les valeurs par défaut. Configurez JWT_SECRET et JWT_REFRESH_SECRET!');
    process.exit(1);
  }

  // Vérifier CORS
  if (config.cors.origin === '*' || (Array.isArray(config.cors.origin) && config.cors.origin.includes('*'))) {
    console.error('⚠️  AVERTISSEMENT: CORS autorise tous les domaines (*). Configurez CORS_ORIGIN avec vos domaines autorisés.');
  }

  // Vérifier la connexion SSL à la base de données
  if (!config.database.ssl) {
    console.warn('⚠️  AVERTISSEMENT: La connexion à la base de données n\'utilise pas SSL. Configurez DB_SSL=true pour la production.');
  }
}

// Avertissements en développement
if (config.isDev) {
  if (!process.env.JWT_SECRET) {
    console.warn('⚠️  DÉVELOPPEMENT: Utilisation du JWT_SECRET par défaut. Configurez JWT_SECRET pour plus de sécurité.');
  }
  if (!process.env.JWT_REFRESH_SECRET) {
    console.warn('⚠️  DÉVELOPPEMENT: Utilisation du JWT_REFRESH_SECRET par défaut. Configurez JWT_REFRESH_SECRET pour plus de sécurité.');
  }
}

module.exports = config;

/**
 * Configuration Swagger/OpenAPI
 * AgroSmart - Système Agricole Intelligent
 * 
 * Documentation interactive de l'API REST
 * Accessible à /api/docs
 */

const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const config = require('../config');

// Options Swagger
const swaggerOptions = {
  definition: {
    openapi: '3.0.3',
    info: {
      title: 'AgroSmart API',
      version: '1.0.0',
      description: `
        API REST du système agricole intelligent pour la Côte d'Ivoire.
        
        ## Fonctionnalités principales
        - 🔐 Authentification JWT avec OTP
        - 🌾 Gestion des parcelles agricoles
        - 📡 Monitoring IoT (capteurs)
        - 🤖 Diagnostic IA des maladies
        - ☁️ Données météorologiques
        - 🛒 Marketplace agricole
        - 💬 Forum communautaire
        - 📚 Formations en ligne
        
        ## Authentification
        L'API utilise JWT Bearer tokens. Pour obtenir un token:
        1. POST /auth/login avec téléphone et mot de passe
        2. Vérifier le code OTP reçu par SMS
        3. Utiliser le token retourné dans le header Authorization
        
        ## Rate Limiting
        - Login: 5 tentatives / 15 min
        - Register: 3 créations / heure
        - OTP: 5 demandes / 10 min
        - API général: 100 requêtes / minute
      `,
      contact: {
        name: 'AgroSmart Support',
        email: 'support@agrosmart.ci',
        url: 'https://agrosmart.ci'
      },
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT'
      }
    },
    servers: [
      {
        url: config.isProd ? 'https://api.agrosmart.ci/api/v1' : `http://localhost:${config.port}/api/v1`,
        description: config.isProd ? 'Production' : 'Développement local'
      }
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Token JWT obtenu après vérification OTP'
        }
      },
      schemas: {
        // ============================
        // Modèles communs
        // ============================
        Error: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            error: {
              type: 'object',
              properties: {
                code: { type: 'string', example: 'VALIDATION_ERROR' },
                message: { type: 'string', example: 'Erreur de validation' },
                details: { type: 'array', items: { type: 'object' } }
              }
            }
          }
        },
        Pagination: {
          type: 'object',
          properties: {
            page: { type: 'integer', example: 1 },
            limit: { type: 'integer', example: 20 },
            total: { type: 'integer', example: 100 },
            totalPages: { type: 'integer', example: 5 }
          }
        },
        
        // ============================
        // Authentification
        // ============================
        User: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            nom: { type: 'string', example: 'Kouassi' },
            prenoms: { type: 'string', example: 'Jean-Baptiste' },
            email: { type: 'string', format: 'email' },
            telephone: { type: 'string', example: '+2250701020304' },
            role: { type: 'string', enum: ['USER', 'ADMIN', 'EXPERT', 'TECHNICIEN'] },
            status: { type: 'string', enum: ['PENDING', 'ACTIVE', 'INACTIVE', 'BLOCKED'] },
            photoUrl: { type: 'string', format: 'uri' },
            adresse: { type: 'string' },
            typeProducteur: { type: 'string' },
            superficie: { type: 'string' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },
        LoginRequest: {
          type: 'object',
          required: ['telephone', 'password'],
          properties: {
            telephone: { type: 'string', example: '+2250701020304' },
            password: { type: 'string', format: 'password', minLength: 8 }
          }
        },
        RegisterRequest: {
          type: 'object',
          required: ['nom', 'prenoms', 'telephone', 'password'],
          properties: {
            nom: { type: 'string', example: 'Kouassi' },
            prenoms: { type: 'string', example: 'Jean-Baptiste' },
            telephone: { type: 'string', example: '+2250701020304' },
            email: { type: 'string', format: 'email' },
            password: { type: 'string', format: 'password', minLength: 8 },
            adresse: { type: 'string' },
            typeProducteur: { type: 'string', example: 'Cacao' },
            superficie: { type: 'string', example: '5.5' }
          }
        },
        VerifyOtpRequest: {
          type: 'object',
          required: ['telephone', 'code'],
          properties: {
            telephone: { type: 'string', example: '+2250701020304' },
            code: { type: 'string', example: '123456', minLength: 6, maxLength: 6 }
          }
        },
        AuthResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            data: {
              type: 'object',
              properties: {
                user: { $ref: '#/components/schemas/User' },
                accessToken: { type: 'string' },
                refreshToken: { type: 'string' },
                expiresIn: { type: 'integer', example: 900 }
              }
            }
          }
        },

        // ============================
        // Parcelles
        // ============================
        Parcelle: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            nom: { type: 'string', example: 'Parcelle A' },
            superficie: { type: 'number', example: 2.5 },
            uniteSuperficie: { type: 'string', example: 'ha' },
            culture: { type: 'string', example: 'Cacao' },
            status: { type: 'string', enum: ['ACTIVE', 'INACTIVE', 'PREPARATION', 'RECOLTE'] },
            coordonnees: {
              type: 'object',
              properties: {
                latitude: { type: 'number', example: 5.3600 },
                longitude: { type: 'number', example: -4.0083 }
              }
            },
            capteurs: {
              type: 'array',
              items: { $ref: '#/components/schemas/Capteur' }
            },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },
        CreateParcelleRequest: {
          type: 'object',
          required: ['nom', 'superficie'],
          properties: {
            nom: { type: 'string' },
            superficie: { type: 'number' },
            uniteSuperficie: { type: 'string', default: 'ha' },
            culture: { type: 'string' },
            latitude: { type: 'number' },
            longitude: { type: 'number' }
          }
        },

        // ============================
        // Capteurs IoT
        // ============================
        Capteur: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            code: { type: 'string', example: 'SENSOR_001' },
            type: { type: 'string', enum: ['TEMPERATURE', 'HUMIDITY', 'PH', 'NPK', 'WATER_LEVEL'] },
            status: { type: 'string', enum: ['ONLINE', 'OFFLINE', 'MAINTENANCE'] },
            derniereLecture: {
              type: 'object',
              properties: {
                valeur: { type: 'number' },
                unite: { type: 'string' },
                timestamp: { type: 'string', format: 'date-time' }
              }
            },
            parcelleId: { type: 'string', format: 'uuid' }
          }
        },
        Mesure: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            capteurId: { type: 'string', format: 'uuid' },
            valeur: { type: 'number' },
            timestamp: { type: 'string', format: 'date-time' }
          }
        },

        // ============================
        // Alertes
        // ============================
        Alerte: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            type: { type: 'string', example: 'MALADIE' },
            niveau: { type: 'string', enum: ['INFO', 'WARNING', 'CRITICAL'] },
            message: { type: 'string' },
            lu: { type: 'boolean' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },

        // ============================
        // Diagnostic IA
        // ============================
        DiagnosticRequest: {
          type: 'object',
          properties: {
            parcelleId: { type: 'string', format: 'uuid' }
          }
        },
        Diagnostic: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            maladie: { type: 'string', example: 'Rouille du caféier' },
            confiance: { type: 'number', example: 0.95 },
            recommandations: {
              type: 'array',
              items: { type: 'string' }
            },
            imageUrl: { type: 'string', format: 'uri' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },

        // ============================
        // Météo
        // ============================
        Weather: {
          type: 'object',
          properties: {
            temperature: { type: 'number', example: 28.5 },
            humidity: { type: 'number', example: 75 },
            description: { type: 'string', example: 'Partiellement nuageux' },
            icon: { type: 'string' },
            windSpeed: { type: 'number' },
            precipitation: { type: 'number' }
          }
        },
        WeatherForecast: {
          type: 'object',
          properties: {
            current: { $ref: '#/components/schemas/Weather' },
            daily: {
              type: 'array',
              items: { $ref: '#/components/schemas/Weather' }
            }
          }
        },

        // ============================
        // Marketplace
        // ============================
        Produit: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            nom: { type: 'string', example: 'Engrais NPK' },
            description: { type: 'string' },
            prix: { type: 'number', example: 15000 },
            unite: { type: 'string', example: 'sac 50kg' },
            stock: { type: 'integer', example: 100 },
            categorie: { type: 'string' },
            images: { type: 'array', items: { type: 'string', format: 'uri' } },
            vendeur: { $ref: '#/components/schemas/User' }
          }
        },
        Commande: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            produit: { $ref: '#/components/schemas/Produit' },
            quantite: { type: 'integer' },
            prixTotal: { type: 'number' },
            statut: { type: 'string', enum: ['PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED'] },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },

        // ============================
        // Forum
        // ============================
        ForumPost: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            titre: { type: 'string' },
            contenu: { type: 'string' },
            auteur: { $ref: '#/components/schemas/User' },
            categorie: { type: 'string' },
            reponses: { type: 'integer' },
            createdAt: { type: 'string', format: 'date-time' }
          }
        },

        // ============================
        // Formations
        // ============================
        Formation: {
          type: 'object',
          properties: {
            id: { type: 'string', format: 'uuid' },
            titre: { type: 'string' },
            description: { type: 'string' },
            duree: { type: 'string', example: '2h30' },
            niveau: { type: 'string', enum: ['DEBUTANT', 'INTERMEDIAIRE', 'AVANCE'] },
            modules: { type: 'integer' },
            progression: { type: 'number', example: 75 }
          }
        }
      },
      responses: {
        Unauthorized: {
          description: 'Non authentifié',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        },
        Forbidden: {
          description: 'Accès refusé',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        },
        NotFound: {
          description: 'Ressource non trouvée',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        },
        ValidationError: {
          description: 'Erreur de validation',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        },
        RateLimitExceeded: {
          description: 'Limite de requêtes dépassée',
          content: {
            'application/json': {
              schema: { $ref: '#/components/schemas/Error' }
            }
          }
        }
      }
    },
    tags: [
      { name: 'Auth', description: 'Authentification et gestion des utilisateurs' },
      { name: 'Parcelles', description: 'Gestion des parcelles agricoles' },
      { name: 'Capteurs', description: 'Monitoring IoT et données des capteurs' },
      { name: 'Alertes', description: 'Système d\'alertes et notifications' },
      { name: 'Diagnostic', description: 'Diagnostic IA des maladies' },
      { name: 'Weather', description: 'Données météorologiques' },
      { name: 'Marketplace', description: 'Place de marché agricole' },
      { name: 'Forum', description: 'Forum communautaire' },
      { name: 'Formations', description: 'Formations en ligne' },
      { name: 'Health', description: 'Health checks et monitoring' }
    ]
  },
  apis: [
    './src/routes/*.js',
    './src/controllers/*.js'
  ]
};

// Générer la spec Swagger
const swaggerSpec = swaggerJsdoc(swaggerOptions);

/**
 * Configure Swagger UI sur l'application Express
 * @param {Express} app - Application Express
 */
const setupSwagger = (app) => {
  // Swagger UI
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
    customCss: `
      .swagger-ui .topbar { display: none; }
      .swagger-ui .info { margin: 20px 0; }
      .swagger-ui .info .title { color: #2e7d32; }
    `,
    customSiteTitle: 'AgroSmart API Documentation',
    customfavIcon: '/favicon.ico'
  }));

  // JSON spec endpoint
  app.get('/api/docs.json', (req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.send(swaggerSpec);
  });

  const logger = require('../utils/logger');
  logger.info('Swagger docs available at /api/docs');
};

module.exports = { setupSwagger, swaggerSpec };

/**
 * Routes principales - Agrégation de toutes les routes
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();

// Import de toutes les routes
const authRoutes = require('./auth');
const usersRoutes = require('./users');
const regionsRoutes = require('./regions');
const parcellesRoutes = require('./parcelles');
const capteursRoutes = require('./capteurs');
const mesuresRoutes = require('./mesures');
const alertesRoutes = require('./alertes');
const culturesRoutes = require('./cultures');
const maladiesRoutes = require('./maladies');
const recommandationsRoutes = require('./recommandations');
const marketplaceRoutes = require('./marketplace');
const formationsRoutes = require('./formations');
const messagesRoutes = require('./messages');
const weatherRoutes = require('./weather');
const analyticsRoutes = require('./analytics');
const diagnosticsRoutes = require('./diagnostics');
const adminRoutes = require('./admin');
const dashboardRoutes = require('./dashboard');
const communauteRoutes = require('./communaute');
const chatRoutes = require('./chat');
const chatbotRoutes = require('./chatbot');
const smsRoutes = require('./sms');
const gamificationRoutes = require('./gamification');
const groupPurchasesRoutes = require('./groupPurchases');
const paymentsRoutes = require('./payments');
const cartRoutes = require('./cart');
const favoritesRoutes = require('./favorites');
const stocksRoutes = require('./stocks');
const calendrierRoutes = require('./calendrier');
const uploadRoutes = require('./upload');
const reviewsRoutes = require('./reviews');
const wishlistRoutes = require('./wishlist');

// =====================================================
// MONTAGE DES ROUTES
// =====================================================

// Authentification & Utilisateurs
router.use('/auth', authRoutes);
router.use('/users', usersRoutes);
router.use('/regions', regionsRoutes);

// Dashboard & Administration
router.use('/dashboard', dashboardRoutes);
router.use('/admin', adminRoutes);

// Parcelles & Capteurs
router.use('/parcelles', parcellesRoutes);
router.use('/capteurs', capteursRoutes);
router.use('/mesures', mesuresRoutes);
router.use('/alertes', alertesRoutes);

// Cultures & Diagnostics
router.use('/cultures', culturesRoutes);
router.use('/maladies', maladiesRoutes);
router.use('/recommandations', recommandationsRoutes);
router.use('/diagnostics', diagnosticsRoutes);

// Marketplace & Commerce
router.use('/marketplace', marketplaceRoutes);
router.use('/cart', cartRoutes);
router.use('/favorites', favoritesRoutes);
router.use('/wishlist', wishlistRoutes);
router.use('/reviews', reviewsRoutes);
router.use('/payments', paymentsRoutes);
router.use('/group-purchases', groupPurchasesRoutes);

// Communication & Communauté
router.use('/messages', messagesRoutes);
router.use('/chat', chatRoutes);
router.use('/chatbot', chatbotRoutes);
router.use('/communaute', communauteRoutes);
router.use('/sms', smsRoutes);

// Équipement & Location
const equipmentRoutes = require('./equipment');
router.use('/equipment', equipmentRoutes);

// IA & Prédictions
const aiRoutes = require('./ai');
router.use('/ai', aiRoutes);

// Fiches Pratiques (Bibliothèque Agricole)
const fichesPratiquesRoutes = require('./fichesPratiques');
router.use('/fiches-pratiques', fichesPratiquesRoutes);

// Outils & Services
router.use('/formations', formationsRoutes);
router.use('/weather', weatherRoutes);
router.use('/analytics', analyticsRoutes);
router.use('/gamification', gamificationRoutes);
router.use('/stocks', stocksRoutes);
router.use('/calendrier', calendrierRoutes);
router.use('/upload', uploadRoutes);

// =====================================================
// ROUTES UTILITAIRES
// =====================================================

router.get('/health', (req, res) => {
  const config = require('../config');
  const response = {
    success: true,
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  };
  // N'exposer les détails serveur qu'en dev
  if (!config.isProd) {
    response.uptime = process.uptime();
    response.memory = process.memoryUsage();
  }
  res.json(response);
});

router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Bienvenue sur l\'API AgroSmart',
    version: '1.0.0',
    documentation: '/api/docs'
  });
});

module.exports = router;

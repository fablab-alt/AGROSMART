/**
 * Service SMS Gateway
 * AgroSmart - Backend
 * 
 * Utilise Africa's Talking API pour l'envoi de SMS en Côte d'Ivoire
 * Fallback vers Twilio si nécessaire
 */

const logger = require('../config/logger');

// Configuration des providers
const SMS_PROVIDERS = {
  AFRICAS_TALKING: 'africas_talking',
  TWILIO: 'twilio',
  ORANGE_CI: 'orange_ci', // Pour intégration future
};

// Templates de messages en langues locales
const SMS_TEMPLATES = {
  // Alertes météo
  weather_alert: {
    fr: "⚠️ ALERTE METEO AgroSmart: {message}. Parcelle: {parcelle}. Protégez vos cultures!",
    bci: "⚠️ ALERTE: {message}. {parcelle} su. Aw nian aw djué!",
    dyu: "⚠️ ALERTE: {message}. {parcelle} kɔnɔ. Aw ka sɛnɛ tanga!",
  },
  // Alertes maladies
  disease_alert: {
    fr: "🦠 ALERTE MALADIE: {disease} détectée sur {parcelle}. Traitez avec: {treatment}",
    bci: "🦠 MALADIE: {disease} {parcelle} su. Drogue: {treatment}",
    dyu: "🦠 BANA: {disease} {parcelle} la. Fura: {treatment}",
  },
  // Alertes irrigation
  irrigation_alert: {
    fr: "💧 IRRIGATION: {parcelle} nécessite arrosage. Humidité sol: {humidity}%",
    bci: "💧 ARROSAGE: {parcelle} klo su. Ji: {humidity}%",
    dyu: "💧 JI: {parcelle} bɛ ji fɛ. Dugukolo jiidiya: {humidity}%",
  },
  // Rappels récolte
  harvest_reminder: {
    fr: "🌾 RECOLTE: {culture} sur {parcelle} prête à récolter dans {days} jours",
    bci: "🌾 RECOLTE: {culture} {parcelle} su ti {days} lé nun",
    dyu: "🌾 SUMAN: {culture} {parcelle} kɔnɔ ka kan ka tigɛ tile {days} kɔnɔ",
  },
  // Prix marché
  market_price: {
    fr: "💰 PRIX: {product} à {price} FCFA/{unit} au marché de {market}",
    bci: "💰 SAN: {product} ti {price} FCFA/{unit} {market} su",
    dyu: "💰 SƆNGƆ: {product} ye {price} FCFA/{unit} ye {market} la",
  },
  // Confirmation inscription
  welcome: {
    fr: "Bienvenue sur AgroSmart! Votre compte agriculteur est activé. Appelez le 1234 pour aide.",
    bci: "Akwaba AgroSmart su! Aw compte ti kpa. Frapper 1234 aide ti.",
    dyu: "Aw ni sɔgɔma AgroSmart! Aw ka jatebila dabɔra. 1234 wele dɛmɛ fɛ.",
  },
  // Code OTP
  otp: {
    fr: "Votre code AgroSmart: {code}. Valide 10 minutes. Ne partagez pas ce code.",
    bci: "Aw AgroSmart code: {code}. Minute 10 kpa. Kan man fa sran be.",
    dyu: "Aw ka AgroSmart kode: {code}. Miniti 10 kɔnɔ. Kana a di mɔgɔ ma.",
  },
  // Alerte capteur
  sensor_alert: {
    fr: "📊 CAPTEUR: {sensor} sur {parcelle} - {parameter}: {value}{unit} (seuil: {threshold})",
    bci: "📊 CAPTEUR: {sensor} {parcelle} su - {parameter}: {value}{unit}",
    dyu: "📊 FEERE: {sensor} {parcelle} la - {parameter}: {value}{unit}",
  },
  // Rappel formation
  training_reminder: {
    fr: "📚 FORMATION: '{title}' commence demain à {time}. Lieu: {location}",
    bci: "📚 FORMATION: '{title}' ti siman {time}. Blo: {location}",
    dyu: "📚 KALANKO: '{title}' bɛna daminɛ sini {time}. Yɔrɔ: {location}",
  },
};

// Priorités des messages
const SMS_PRIORITY = {
  CRITICAL: 1,    // Alertes météo sévères, maladies graves
  HIGH: 2,        // Alertes capteurs, irrigation urgente
  NORMAL: 3,      // Rappels, prix
  LOW: 4,         // Marketing, informations
};

class SmsGatewayService {
  constructor() {
    this.provider = process.env.SMS_PROVIDER || SMS_PROVIDERS.AFRICAS_TALKING;
    this.apiKey = process.env.SMS_API_KEY;
    this.apiSecret = process.env.SMS_API_SECRET;
    this.senderId = process.env.SMS_SENDER_ID || 'AgroSmart';
    this.initialized = false;
    this.messageQueue = [];
    this.rateLimitPerSecond = 10;
    this.lastSendTime = 0;
  }

  /**
   * Initialise le service SMS
   */
  async initialize() {
    if (this.initialized) return;

    try {
      // Vérifier la configuration
      if (!this.apiKey) {
        logger.warn('[SMS] API key not configured - SMS disabled');
        return;
      }

      // Initialiser le provider
      switch (this.provider) {
        case SMS_PROVIDERS.AFRICAS_TALKING:
          await this._initAfricasTalking();
          break;
        case SMS_PROVIDERS.TWILIO:
          await this._initTwilio();
          break;
        default:
          logger.warn(`[SMS] Unknown provider: ${this.provider}`);
      }

      this.initialized = true;
      logger.info(`[SMS] Gateway initialized with provider: ${this.provider}`);
    } catch (error) {
      logger.error('[SMS] Initialization error:', error);
    }
  }

  /**
   * Initialise Africa's Talking
   */
  async _initAfricasTalking() {
    try {
      // Africa's Talking configuration
      const AfricasTalking = require('africastalking');
      this.at = AfricasTalking({
        apiKey: this.apiKey,
        username: process.env.AT_USERNAME || 'sandbox',
      });
      this.sms = this.at.SMS;
      logger.info('[SMS] Africa\'s Talking initialized');
    } catch (error) {
      logger.warn('[SMS] Africa\'s Talking not available:', error.message);
    }
  }

  /**
   * Initialise Twilio
   */
  async _initTwilio() {
    try {
      const twilio = require('twilio');
      this.twilioClient = twilio(
        process.env.TWILIO_ACCOUNT_SID,
        process.env.TWILIO_AUTH_TOKEN
      );
      this.twilioFrom = process.env.TWILIO_PHONE_NUMBER;
      logger.info('[SMS] Twilio initialized');
    } catch (error) {
      logger.warn('[SMS] Twilio not available:', error.message);
    }
  }

  /**
   * Envoie un SMS
   * @param {string} phoneNumber - Numéro de téléphone (format international)
   * @param {string} message - Message à envoyer
   * @param {object} options - Options supplémentaires
   */
  async sendSms(phoneNumber, message, options = {}) {
    if (!this.initialized) {
      await this.initialize();
    }

    // Formater le numéro
    const formattedNumber = this._formatPhoneNumber(phoneNumber);
    
    if (!formattedNumber) {
      logger.warn(`[SMS] Invalid phone number: ${phoneNumber}`);
      return { success: false, error: 'Invalid phone number' };
    }

    // Tronquer le message si nécessaire (160 caractères pour SMS standard)
    const truncatedMessage = this._truncateMessage(message, 160);

    try {
      // Rate limiting
      await this._respectRateLimit();

      let result;
      switch (this.provider) {
        case SMS_PROVIDERS.AFRICAS_TALKING:
          result = await this._sendViaAfricasTalking(formattedNumber, truncatedMessage);
          break;
        case SMS_PROVIDERS.TWILIO:
          result = await this._sendViaTwilio(formattedNumber, truncatedMessage);
          break;
        default:
          // Mode simulation pour le développement
          result = await this._sendSimulated(formattedNumber, truncatedMessage);
      }

      // Logger le résultat
      logger.info(`[SMS] Sent to ${formattedNumber.slice(-4)}: ${result.success ? 'OK' : 'FAILED'}`);
      
      return result;
    } catch (error) {
      logger.error(`[SMS] Send error to ${formattedNumber}:`, error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Envoie via Africa's Talking
   */
  async _sendViaAfricasTalking(phoneNumber, message) {
    if (!this.sms) {
      return this._sendSimulated(phoneNumber, message);
    }

    try {
      const result = await this.sms.send({
        to: [phoneNumber],
        message: message,
        from: this.senderId,
      });

      const recipient = result.SMSMessageData?.Recipients?.[0];
      return {
        success: recipient?.status === 'Success',
        messageId: recipient?.messageId,
        cost: recipient?.cost,
        provider: SMS_PROVIDERS.AFRICAS_TALKING,
      };
    } catch (error) {
      logger.error('[SMS] Africa\'s Talking error:', error);
      // Fallback to Twilio if available
      if (this.twilioClient) {
        return this._sendViaTwilio(phoneNumber, message);
      }
      throw error;
    }
  }

  /**
   * Envoie via Twilio
   */
  async _sendViaTwilio(phoneNumber, message) {
    if (!this.twilioClient) {
      return this._sendSimulated(phoneNumber, message);
    }

    try {
      const result = await this.twilioClient.messages.create({
        body: message,
        from: this.twilioFrom,
        to: phoneNumber,
      });

      return {
        success: result.status !== 'failed',
        messageId: result.sid,
        provider: SMS_PROVIDERS.TWILIO,
      };
    } catch (error) {
      logger.error('[SMS] Twilio error:', error);
      throw error;
    }
  }

  /**
   * Mode simulation pour le développement
   */
  async _sendSimulated(phoneNumber, message) {
    logger.info(`[SMS-SIM] To: ${phoneNumber}`);
    logger.info(`[SMS-SIM] Message: ${message}`);
    
    return {
      success: true,
      messageId: `sim_${Date.now()}`,
      provider: 'simulated',
      simulated: true,
    };
  }

  /**
   * Envoie un SMS à partir d'un template
   * @param {string} phoneNumber - Numéro de téléphone
   * @param {string} templateKey - Clé du template
   * @param {object} variables - Variables à remplacer
   * @param {string} language - Code de langue (fr, bci, dyu)
   */
  async sendFromTemplate(phoneNumber, templateKey, variables = {}, language = 'fr') {
    const template = SMS_TEMPLATES[templateKey];
    
    if (!template) {
      logger.warn(`[SMS] Template not found: ${templateKey}`);
      return { success: false, error: 'Template not found' };
    }

    // Obtenir le message dans la langue demandée (fallback vers français)
    let message = template[language] || template.fr;

    // Remplacer les variables
    for (const [key, value] of Object.entries(variables)) {
      message = message.replace(new RegExp(`{${key}}`, 'g'), value);
    }

    return this.sendSms(phoneNumber, message);
  }

  /**
   * Envoie des SMS en masse
   * @param {Array} recipients - Liste de {phoneNumber, message} ou {phoneNumber, templateKey, variables, language}
   * @param {object} options - Options (priority, scheduleAt)
   */
  async sendBulk(recipients, options = {}) {
    const results = {
      total: recipients.length,
      success: 0,
      failed: 0,
      errors: [],
    };

    // Trier par priorité si spécifié
    if (options.priority) {
      recipients.sort((a, b) => (a.priority || 3) - (b.priority || 3));
    }

    for (const recipient of recipients) {
      try {
        let result;
        
        if (recipient.templateKey) {
          result = await this.sendFromTemplate(
            recipient.phoneNumber,
            recipient.templateKey,
            recipient.variables || {},
            recipient.language || 'fr'
          );
        } else {
          result = await this.sendSms(recipient.phoneNumber, recipient.message);
        }

        if (result.success) {
          results.success++;
        } else {
          results.failed++;
          results.errors.push({
            phoneNumber: recipient.phoneNumber,
            error: result.error,
          });
        }
      } catch (error) {
        results.failed++;
        results.errors.push({
          phoneNumber: recipient.phoneNumber,
          error: error.message,
        });
      }
    }

    logger.info(`[SMS] Bulk send: ${results.success}/${results.total} successful`);
    return results;
  }

  /**
   * Envoie une alerte météo à une liste d'agriculteurs
   */
  async sendWeatherAlert(farmers, alertData) {
    const recipients = farmers.map(farmer => ({
      phoneNumber: farmer.telephone,
      templateKey: 'weather_alert',
      variables: {
        message: alertData.message,
        parcelle: alertData.parcelleName || 'votre parcelle',
      },
      language: farmer.preferredLanguage || 'fr',
      priority: SMS_PRIORITY.CRITICAL,
    }));

    return this.sendBulk(recipients, { priority: true });
  }

  /**
   * Envoie une alerte maladie
   */
  async sendDiseaseAlert(farmer, diseaseData) {
    return this.sendFromTemplate(
      farmer.telephone,
      'disease_alert',
      {
        disease: diseaseData.name,
        parcelle: diseaseData.parcelleName,
        treatment: diseaseData.treatment,
      },
      farmer.preferredLanguage || 'fr'
    );
  }

  /**
   * Envoie une alerte capteur
   */
  async sendSensorAlert(farmer, sensorData) {
    return this.sendFromTemplate(
      farmer.telephone,
      'sensor_alert',
      {
        sensor: sensorData.sensorName,
        parcelle: sensorData.parcelleName,
        parameter: sensorData.parameter,
        value: sensorData.value,
        unit: sensorData.unit || '',
        threshold: sensorData.threshold,
      },
      farmer.preferredLanguage || 'fr'
    );
  }

  /**
   * Envoie un rappel de récolte
   */
  async sendHarvestReminder(farmer, harvestData) {
    return this.sendFromTemplate(
      farmer.telephone,
      'harvest_reminder',
      {
        culture: harvestData.culture,
        parcelle: harvestData.parcelleName,
        days: harvestData.daysUntilHarvest,
      },
      farmer.preferredLanguage || 'fr'
    );
  }

  /**
   * Envoie une alerte prix de marché
   */
  async sendMarketPriceAlert(farmer, priceData) {
    return this.sendFromTemplate(
      farmer.telephone,
      'market_price',
      {
        product: priceData.product,
        price: priceData.price,
        unit: priceData.unit || 'kg',
        market: priceData.market,
      },
      farmer.preferredLanguage || 'fr'
    );
  }

  /**
   * Envoie un code OTP
   */
  async sendOtp(phoneNumber, code, language = 'fr') {
    return this.sendFromTemplate(phoneNumber, 'otp', { code }, language);
  }

  /**
   * Envoie un message de bienvenue
   */
  async sendWelcome(phoneNumber, language = 'fr') {
    return this.sendFromTemplate(phoneNumber, 'welcome', {}, language);
  }

  /**
   * Formate le numéro de téléphone au format international
   */
  _formatPhoneNumber(phoneNumber) {
    if (!phoneNumber) return null;

    // Nettoyer le numéro
    let cleaned = phoneNumber.replace(/\D/g, '');

    // Gestion des numéros ivoiriens
    if (cleaned.startsWith('225')) {
      // Déjà au format international
      return `+${cleaned}`;
    } else if (cleaned.startsWith('00225')) {
      return `+${cleaned.slice(2)}`;
    } else if (cleaned.length === 10 && (cleaned.startsWith('0') || cleaned.startsWith('07') || cleaned.startsWith('05'))) {
      // Numéro local ivoirien (10 chiffres avec 0 initial)
      return `+225${cleaned.slice(1)}`;
    } else if (cleaned.length === 10) {
      // Numéro à 10 chiffres (nouveau format CI)
      return `+225${cleaned}`;
    } else if (cleaned.length === 8) {
      // Ancien format 8 chiffres
      return `+225${cleaned}`;
    }

    // Retourner avec + si non géré
    return cleaned.startsWith('+') ? phoneNumber : `+${cleaned}`;
  }

  /**
   * Tronque le message à la longueur maximale
   */
  _truncateMessage(message, maxLength) {
    if (message.length <= maxLength) return message;
    return message.slice(0, maxLength - 3) + '...';
  }

  /**
   * Respecte le rate limit
   */
  async _respectRateLimit() {
    const now = Date.now();
    const minInterval = 1000 / this.rateLimitPerSecond;
    const elapsed = now - this.lastSendTime;

    if (elapsed < minInterval) {
      await new Promise(resolve => setTimeout(resolve, minInterval - elapsed));
    }

    this.lastSendTime = Date.now();
  }

  /**
   * Obtient le solde SMS
   */
  async getBalance() {
    if (!this.initialized) await this.initialize();

    try {
      if (this.provider === SMS_PROVIDERS.AFRICAS_TALKING && this.at) {
        const balance = await this.at.APPLICATION.fetchApplicationData();
        return { balance: balance.UserData?.balance, provider: this.provider };
      }
      return { balance: 'N/A', provider: this.provider };
    } catch (error) {
      logger.error('[SMS] Balance fetch error:', error);
      return { balance: 'Error', error: error.message };
    }
  }

  /**
   * Liste des templates disponibles
   */
  getTemplates() {
    return Object.keys(SMS_TEMPLATES);
  }

  /**
   * Langues supportées
   */
  getSupportedLanguages() {
    return ['fr', 'bci', 'dyu'];
  }
}

// Singleton instance
const smsGateway = new SmsGatewayService();

module.exports = {
  smsGateway,
  SmsGatewayService,
  SMS_TEMPLATES,
  SMS_PRIORITY,
  SMS_PROVIDERS,
};

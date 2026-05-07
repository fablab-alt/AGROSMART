/**
 * Index des Services
 * AgroSmart - Système Agricole Intelligent
 */

const smsService = require('./smsService');
const emailService = require('./emailService');
const notificationService = require('./notificationService');
const alertesService = require('./alertesService');
const weatherService = require('./weatherService');
const authService = require('./authService');
const passwordService = require('./passwordService');
const healthCheckService = require('./healthCheckService');
const predictionService = require('./predictionService');
const pushNotificationService = require('./pushNotificationService');
const queueService = require('./queueService');
const smsGatewayService = require('./smsGatewayService');

module.exports = {
  smsService,
  emailService,
  notificationService,
  alertesService,
  weatherService,
  authService,
  passwordService,
  healthCheckService,
  predictionService,
  pushNotificationService,
  queueService,
  smsGatewayService
};

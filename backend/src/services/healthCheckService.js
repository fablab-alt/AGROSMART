/**
 * Service de Health Checks Avancés
 * AgroSmart - Backend
 */

const os = require('os');
const logger = require('../utils/logger');

const HEALTH_THRESHOLDS = {
  database: {
    responseTimeMs: 500,
    connectionPool: 80
  },
  memory: {
    usagePercent: 85
  },
  cpu: {
    loadAverage: 80
  },
  aiService: {
    responseTimeMs: 5000
  },
  iotService: {
    responseTimeMs: 2000
  }
};

const HealthStatus = {
  HEALTHY: 'healthy',
  DEGRADED: 'degraded',
  UNHEALTHY: 'unhealthy',
  UNKNOWN: 'unknown'
};

class HealthCheckService {
  constructor(prisma) {
    this.prisma = prisma;
    this.startTime = Date.now();
  }

  async getFullHealth() {
    const checks = await Promise.allSettled([
      this.checkDatabase(),
      this.checkAIService(),
      this.checkIoTService(),
      this.checkExternalServices(),
      this.getSystemMetrics()
    ]);

    const [database, aiService, iotService, external, system] = checks.map((result, index) => {
      if (result.status === 'fulfilled') {
        return result.value;
      }
      logger.error(`Health check ${index} failed`, { error: result.reason });
      return {
        status: HealthStatus.UNHEALTHY,
        error: result.reason?.message || 'Check failed'
      };
    });

    const allStatuses = [database.status, aiService.status, iotService.status];

    let overallStatus = HealthStatus.HEALTHY;
    if (allStatuses.some((s) => s === HealthStatus.UNHEALTHY)) {
      overallStatus = HealthStatus.UNHEALTHY;
    } else if (allStatuses.some((s) => s === HealthStatus.DEGRADED)) {
      overallStatus = HealthStatus.DEGRADED;
    }

    const healthReport = {
      status: overallStatus,
      timestamp: new Date().toISOString(),
      uptime: this.getUptime(),
      version: process.env.APP_VERSION || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      services: {
        database,
        aiService,
        iotService,
        external
      },
      system
    };

    if (overallStatus === HealthStatus.UNHEALTHY) {
      logger.security('[HealthCheck] System unhealthy', healthReport);
    }

    return healthReport;
  }

  async getLivenessCheck() {
    try {
      return {
        status: HealthStatus.HEALTHY,
        timestamp: new Date().toISOString(),
        uptime: this.getUptime()
      };
    } catch (error) {
      return {
        status: HealthStatus.UNHEALTHY,
        error: error.message
      };
    }
  }

  async getReadinessCheck() {
    try {
      const dbOk = await this.isDatabaseReady();

      if (dbOk) {
        return {
          status: HealthStatus.HEALTHY,
          timestamp: new Date().toISOString(),
          ready: true
        };
      }

      return {
        status: HealthStatus.UNHEALTHY,
        timestamp: new Date().toISOString(),
        ready: false,
        details: {
          database: dbOk
        }
      };
    } catch (error) {
      return {
        status: HealthStatus.UNHEALTHY,
        ready: false,
        error: error.message
      };
    }
  }

  async checkDatabase() {
    const start = Date.now();

    try {
      await this.prisma.$queryRaw`SELECT 1`;
      const responseTime = Date.now() - start;

      const metrics = await this.prisma.$queryRaw`
        SHOW STATUS LIKE 'Threads_connected'
      `;
      const connectionCount = parseInt(metrics[0]?.Value || 0, 10);

      const dbSize = await this.prisma.$queryRaw`
        SELECT
          table_schema as 'database',
          ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) as 'size_mb'
        FROM information_schema.tables
        WHERE table_schema = DATABASE()
        GROUP BY table_schema
      `;

      const status = responseTime > HEALTH_THRESHOLDS.database.responseTimeMs
        ? HealthStatus.DEGRADED
        : HealthStatus.HEALTHY;

      return {
        status,
        responseTimeMs: responseTime,
        connections: connectionCount,
        sizeMb: parseFloat(dbSize[0]?.size_mb || 0),
        details: {
          type: 'MySQL',
          host: process.env.DB_HOST || 'localhost',
          database: process.env.DB_NAME || 'agrismart'
        }
      };
    } catch (error) {
      logger.error('[HealthCheck] Database check failed', { error: error.message });
      return {
        status: HealthStatus.UNHEALTHY,
        error: error.message,
        responseTimeMs: Date.now() - start
      };
    }
  }

  async checkAIService() {
    const start = Date.now();
    const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://ai_service:5002';

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 5000);

      const response = await fetch(`${aiServiceUrl}/health`, {
        signal: controller.signal
      });
      clearTimeout(timeout);

      const responseTime = Date.now() - start;
      const data = await response.json();

      const status = !response.ok
        ? HealthStatus.UNHEALTHY
        : responseTime > HEALTH_THRESHOLDS.aiService.responseTimeMs
          ? HealthStatus.DEGRADED
          : HealthStatus.HEALTHY;

      return {
        status,
        responseTimeMs: responseTime,
        url: aiServiceUrl,
        modelLoaded: data.model_loaded || false,
        gpuAvailable: data.gpu_available || false,
        version: data.version || 'unknown'
      };
    } catch (error) {
      return {
        status: HealthStatus.UNHEALTHY,
        error: error.message,
        url: aiServiceUrl,
        responseTimeMs: Date.now() - start
      };
    }
  }

  async checkIoTService() {
    const start = Date.now();
    const iotServiceUrl = process.env.IOT_SERVICE_URL || 'http://iot_service:3004';

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 3000);

      const response = await fetch(`${iotServiceUrl}/health`, {
        signal: controller.signal
      });
      clearTimeout(timeout);

      const responseTime = Date.now() - start;
      const data = await response.json();

      const status = !response.ok
        ? HealthStatus.UNHEALTHY
        : responseTime > HEALTH_THRESHOLDS.iotService.responseTimeMs
          ? HealthStatus.DEGRADED
          : HealthStatus.HEALTHY;

      return {
        status,
        responseTimeMs: responseTime,
        url: iotServiceUrl,
        mqttConnected: data.mqtt_connected || false,
        activeDevices: data.active_devices || 0,
        messageRate: data.message_rate || 0
      };
    } catch (error) {
      return {
        status: HealthStatus.UNHEALTHY,
        error: error.message,
        url: iotServiceUrl,
        responseTimeMs: Date.now() - start
      };
    }
  }

  async checkExternalServices() {
    const results = {};

    try {
      const weatherApiKey = process.env.OPENWEATHER_API_KEY;
      if (weatherApiKey) {
        const start = Date.now();
        const response = await fetch(
          `https://api.openweathermap.org/data/2.5/weather?lat=5.36&lon=-4.00&appid=${weatherApiKey}`,
          { timeout: 5000 }
        );
        results.weatherApi = {
          status: response.ok ? HealthStatus.HEALTHY : HealthStatus.UNHEALTHY,
          responseTimeMs: Date.now() - start
        };
      } else {
        results.weatherApi = { status: HealthStatus.UNKNOWN, message: 'Not configured' };
      }
    } catch (error) {
      results.weatherApi = { status: HealthStatus.UNHEALTHY, error: error.message };
    }

    try {
      const firebaseConfigured = !!(
        process.env.FIREBASE_PROJECT_ID &&
        process.env.FIREBASE_PRIVATE_KEY
      );
      results.firebase = {
        status: firebaseConfigured ? HealthStatus.HEALTHY : HealthStatus.UNKNOWN,
        configured: firebaseConfigured
      };
    } catch (error) {
      results.firebase = { status: HealthStatus.UNHEALTHY, error: error.message };
    }

    return results;
  }

  getSystemMetrics() {
    const totalMemory = os.totalmem();
    const freeMemory = os.freemem();
    const usedMemory = totalMemory - freeMemory;
    const memoryUsagePercent = Math.round((usedMemory / totalMemory) * 100);

    const cpus = os.cpus();
    const loadAvg = os.loadavg();
    const cpuUsage = process.cpuUsage();

    let status = HealthStatus.HEALTHY;
    if (memoryUsagePercent > HEALTH_THRESHOLDS.memory.usagePercent) {
      status = HealthStatus.DEGRADED;
    }

    return {
      status,
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch(),
      nodeVersion: process.version,
      memory: {
        total: this.formatBytes(totalMemory),
        used: this.formatBytes(usedMemory),
        free: this.formatBytes(freeMemory),
        usagePercent: memoryUsagePercent,
        heapUsed: this.formatBytes(process.memoryUsage().heapUsed),
        heapTotal: this.formatBytes(process.memoryUsage().heapTotal)
      },
      cpu: {
        cores: cpus.length,
        model: cpus[0]?.model || 'unknown',
        loadAverage: {
          '1min': loadAvg[0].toFixed(2),
          '5min': loadAvg[1].toFixed(2),
          '15min': loadAvg[2].toFixed(2)
        },
        processUsage: {
          user: cpuUsage.user,
          system: cpuUsage.system
        }
      },
      process: {
        pid: process.pid,
        uptime: this.getUptime(),
        memoryUsage: process.memoryUsage()
      }
    };
  }

  getUptime() {
    const uptimeMs = Date.now() - this.startTime;
    const seconds = Math.floor(uptimeMs / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (days > 0) return `${days}d ${hours % 24}h ${minutes % 60}m`;
    if (hours > 0) return `${hours}h ${minutes % 60}m ${seconds % 60}s`;
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
    return `${seconds}s`;
  }

  formatBytes(bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let unitIndex = 0;
    let value = bytes;

    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }

    return `${value.toFixed(2)} ${units[unitIndex]}`;
  }

  async isDatabaseReady() {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return true;
    } catch {
      return false;
    }
  }
}

function setupHealthRoutes(app, healthService) {
  app.get('/health', async (req, res) => {
    try {
      const health = await healthService.getFullHealth();
      const statusCode = health.status === HealthStatus.UNHEALTHY ? 503 : 200;
      res.status(statusCode).json(health);
    } catch (error) {
      logger.error('[HealthCheck] Error in /health', { error: error.message });
      res.status(503).json({
        status: HealthStatus.UNHEALTHY,
        error: error.message
      });
    }
  });

  app.get('/health/live', async (req, res) => {
    const result = await healthService.getLivenessCheck();
    const statusCode = result.status === HealthStatus.HEALTHY ? 200 : 503;
    res.status(statusCode).json(result);
  });

  app.get('/health/ready', async (req, res) => {
    const result = await healthService.getReadinessCheck();
    const statusCode = result.ready ? 200 : 503;
    res.status(statusCode).json(result);
  });

  app.get('/health/metrics', async (req, res) => {
    const metrics = healthService.getSystemMetrics();
    res.json(metrics);
  });

  app.get('/metrics', async (req, res) => {
    try {
      const health = await healthService.getFullHealth();
      const metrics = generatePrometheusMetrics(health);
      res.set('Content-Type', 'text/plain');
      res.send(metrics);
    } catch (error) {
      res.status(500).send(`# Error: ${error.message}`);
    }
  });
}

function generatePrometheusMetrics(health) {
  const lines = [
    '# HELP agrismart_up Application status (1 = up, 0 = down)',
    '# TYPE agrismart_up gauge',
    `agrismart_up ${health.status === HealthStatus.HEALTHY ? 1 : 0}`,
    '',
    '# HELP agrismart_database_response_time_ms Database response time in milliseconds',
    '# TYPE agrismart_database_response_time_ms gauge',
    `agrismart_database_response_time_ms ${health.services.database.responseTimeMs || 0}`,
    '',
    '# HELP agrismart_database_connections Number of database connections',
    '# TYPE agrismart_database_connections gauge',
    `agrismart_database_connections ${health.services.database.connections || 0}`,
    '',
    '# HELP agrismart_memory_usage_percent System memory usage percentage',
    '# TYPE agrismart_memory_usage_percent gauge',
    `agrismart_memory_usage_percent ${health.system?.memory?.usagePercent || 0}`,
    '',
    '# HELP agrismart_ai_service_up AI service status',
    '# TYPE agrismart_ai_service_up gauge',
    `agrismart_ai_service_up ${health.services.aiService.status === HealthStatus.HEALTHY ? 1 : 0}`,
    '',
    '# HELP agrismart_iot_service_up IoT service status',
    '# TYPE agrismart_iot_service_up gauge',
    `agrismart_iot_service_up ${health.services.iotService.status === HealthStatus.HEALTHY ? 1 : 0}`
  ];

  return lines.join('\n');
}

module.exports = {
  HealthCheckService,
  HealthStatus,
  setupHealthRoutes,
  HEALTH_THRESHOLDS
};

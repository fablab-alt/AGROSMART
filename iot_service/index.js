require('dotenv').config();
const mqtt = require('mqtt');
const http = require('http');

// ============================
// Constantes de sécurité
// ============================
const PUBLIC_BROKERS = ['test.mosquitto.org', 'broker.hivemq.com', 'broker.emqx.io'];
const isProd = process.env.NODE_ENV === 'production';

// Schéma de validation des payloads IoT
const VALID_MEASURE_TYPES = ['temperature', 'humidity', 'soil_moisture', 'ph', 'light', 'co2'];

// Rate-limit par device : max 60 messages par minute
const deviceMessageCount = new Map();
const DEVICE_RATE_LIMIT = parseInt(process.env.IOT_RATE_LIMIT) || 60;
setInterval(() => deviceMessageCount.clear(), 60 * 1000);

// ============================
// Health Check HTTP Server
// ============================
const PORT = process.env.PORT || 4000;
let mqttConnected = false;
let messagesReceived = 0;

const healthServer = http.createServer((req, res) => {
    if (req.url === '/health' && req.method === 'GET') {
        const healthy = mqttConnected;
        res.writeHead(healthy ? 200 : 503, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            status: healthy ? 'healthy' : 'unhealthy',
            mqtt: mqttConnected ? 'connected' : 'disconnected',
            queue: 'disabled',
            messagesReceived,
            timestamp: new Date().toISOString()
        }));
    } else if (req.url === '/' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            service: 'agrismart-iot',
            version: '1.0.0',
            description: 'IoT Gateway Service for AgroSmart'
        }));
    } else {
        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Not Found' }));
    }
});

healthServer.listen(PORT, () => {
    console.log(`[Health] HTTP server listening on port ${PORT}`);
});

// Configuration MQTT
const MQTT_BROKER = process.env.MQTT_BROKER_URL || process.env.MQTT_BROKER || 'mqtt://test.mosquitto.org';
const MQTT_TOPIC = process.env.MQTT_TOPIC || 'agrosmart/+/up';

// Refuser les brokers publics en production
if (isProd) {
    const brokerHost = MQTT_BROKER.replace(/^mqtt[s]?:\/\//, '').split(':')[0];
    if (PUBLIC_BROKERS.includes(brokerHost)) {
        console.error(`[SECURITY] Broker MQTT public interdit en production: ${MQTT_BROKER}`);
        console.error('[SECURITY] Configurez MQTT_BROKER_URL avec votre broker privé (ex: mqtt://localhost:1883)');
        process.exit(1);
    }
    if (!process.env.MQTT_USERNAME || !process.env.MQTT_PASSWORD) {
        console.error('[SECURITY] MQTT_USERNAME et MQTT_PASSWORD requis en production');
        process.exit(1);
    }
}

// MQTT Authentication
const mqttOptions = {
    username: process.env.MQTT_USERNAME,
    password: process.env.MQTT_PASSWORD,
    reconnectPeriod: 5000,
    connectTimeout: 30000,
};

console.log(`[MQTT] Connecting to Broker: ${MQTT_BROKER}`);
const client = mqtt.connect(MQTT_BROKER, mqttOptions);

client.on('connect', () => {
    mqttConnected = true;
    console.log('[MQTT] Connected to Broker');
    client.subscribe(MQTT_TOPIC, (err) => {
        if (!err) {
            console.log(`[MQTT] Subscribed to topic: ${MQTT_TOPIC}`);
        } else {
            console.error('[MQTT] Subscription error:', err);
        }
    });
});

client.on('close', () => {
    mqttConnected = false;
    console.log('[MQTT] Connection closed');
});

client.on('error', (err) => {
    mqttConnected = false;
    console.error('[MQTT] Error:', err.message);
});

client.on('message', async (topic, message) => {
    try {
        // Validation du format de topic: agrosmart/{device_id}/up
        const parts = topic.split('/');
        if (parts.length !== 3 || parts[0] !== 'agrosmart' || parts[2] !== 'up') {
            console.warn(`[IoT] Topic invalide ignoré: ${topic}`);
            return;
        }
        const deviceId = parts[1];

        // Validation du device ID (alphanumérique + tirets/underscores, 3-64 chars)
        if (!/^[a-zA-Z0-9_-]{3,64}$/.test(deviceId)) {
            console.warn(`[IoT] Device ID invalide ignoré: ${deviceId}`);
            return;
        }

        // Rate limiting par device
        const count = (deviceMessageCount.get(deviceId) || 0) + 1;
        deviceMessageCount.set(deviceId, count);
        if (count > DEVICE_RATE_LIMIT) {
            console.warn(`[IoT] Rate limit dépassé pour device ${deviceId}: ${count} msgs/min`);
            return;
        }

        const payload = message.toString();

        // Limite taille payload (max 4 KB)
        if (payload.length > 4096) {
            console.warn(`[IoT] Payload trop grand ignoré pour device ${deviceId}: ${payload.length} bytes`);
            return;
        }

        const data = decodePayload(payload);

        if (data && validatePayload(data)) {
            messagesReceived += 1;
            processMeasurement(deviceId, data);
        }
    } catch (error) {
        console.error('Error processing message:', error);
    }
});

function decodePayload(payload) {
    try {
        return JSON.parse(payload);
    } catch (e) {
        console.warn('[IoT] Payload non-JSON ignoré');
        return null;
    }
}

/**
 * Valide le schéma d'un payload de mesure IoT.
 * Retourne true si valide, false sinon.
 */
function validatePayload(data) {
    if (typeof data !== 'object' || data === null || Array.isArray(data)) {
        console.warn('[IoT] Payload invalide: doit être un objet JSON');
        return false;
    }

    // Au moins un champ de mesure reconnu doit être présent
    const hasKnownField = VALID_MEASURE_TYPES.some(k => k in data);
    if (!hasKnownField) {
        console.warn('[IoT] Payload invalide: aucun champ de mesure connu', Object.keys(data));
        return false;
    }

    // Validation des types et plages pour chaque champ présent
    if ('temperature' in data && (typeof data.temperature !== 'number' || data.temperature < -50 || data.temperature > 70)) {
        console.warn(`[IoT] Valeur temperature invalide: ${data.temperature}`);
        return false;
    }
    if ('humidity' in data && (typeof data.humidity !== 'number' || data.humidity < 0 || data.humidity > 100)) {
        console.warn(`[IoT] Valeur humidity invalide: ${data.humidity}`);
        return false;
    }
    if ('soil_moisture' in data && (typeof data.soil_moisture !== 'number' || data.soil_moisture < 0 || data.soil_moisture > 100)) {
        console.warn(`[IoT] Valeur soil_moisture invalide: ${data.soil_moisture}`);
        return false;
    }
    if ('ph' in data && (typeof data.ph !== 'number' || data.ph < 0 || data.ph > 14)) {
        console.warn(`[IoT] Valeur ph invalide: ${data.ph}`);
        return false;
    }

    return true;
}

function processMeasurement(deviceCode, data) {
    // Logguer uniquement les champs connus (pas dump complet pour éviter fuite de données)
    const knownFields = Object.fromEntries(
        VALID_MEASURE_TYPES.filter(k => k in data).map(k => [k, data[k]])
    );
    console.log(`[IoT] Mesure reçue de ${deviceCode}:`, JSON.stringify(knownFields));
}

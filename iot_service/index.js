require('dotenv').config();
const mqtt = require('mqtt');
const http = require('http');

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

// MQTT Authentication
const mqttOptions = {
    username: process.env.MQTT_USERNAME,
    password: process.env.MQTT_PASSWORD,
    reconnectPeriod: 5000, // Reconnect every 5 seconds
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
        const payload = message.toString();
        // Extract device ID from topic (assuming format agrosmart/{device_id}/up)
        const parts = topic.split('/');
        const deviceId = parts[1]; // e.g. "sensor_001"

        // Decode Payload
        const data = decodePayload(payload);

        if (data) {
            messagesReceived += 1;
            // Traitement local immédiat: le service reste autonome et observable.
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
        console.log('Payload is not JSON, skipping');
        return null;
    }
}

function processMeasurement(deviceCode, data) {
    console.log(`[IoT] Measurement received from ${deviceCode}: ${JSON.stringify(data)}`);
}

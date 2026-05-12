require('dotenv').config();
const mqtt = require('mqtt');
const http = require('http');

// ─── Config ───────────────────────────────────────────────────────────────────

const PORT         = process.env.PORT || 4000;
const MQTT_BROKER  = process.env.MQTT_BROKER_URL || process.env.MQTT_BROKER || 'mqtt://test.mosquitto.org';
const MQTT_TOPIC   = process.env.MQTT_TOPIC || 'agrosmart/+/up';
const API_BASE_URL = process.env.IOT_GATEWAY_URL || 'http://localhost:3600/api/v1';
const API_SECRET   = process.env.IOT_GATEWAY_SECRET || '';

// ─── État ─────────────────────────────────────────────────────────────────────

let mqttConnected   = false;
let messagesReceived = 0;
let messagesForwarded = 0;
let messagesErrored   = 0;

// Cache capteur_code → { id, type } pour éviter une requête API à chaque mesure
const capteurRegistry = new Map();
const REGISTRY_TTL = 5 * 60 * 1000; // 5 minutes
let registryLastRefresh = 0;

// ─── Payload → valeur par type de capteur ─────────────────────────────────────

/**
 * Formate la valeur brute du payload selon le type de capteur.
 * Les capteurs multi-valeurs (NPK, HUMIDITE_TEMPERATURE_AMBIANTE, DIRECTION_VENT)
 * sont sérialisés en JSON pour être stockés dans le champ `valeur` (TEXT).
 *
 * Formats attendus par type :
 *   HUMIDITE_TEMPERATURE_AMBIANTE : { temperature: 28.3, humidite: 65 }
 *   HUMIDITE_SOL                  : { humidite: 45 } | valeur numérique directe
 *   UV                            : { uv_index: 8 } | valeur numérique directe
 *   NPK                           : { N: 12, P: 8, K: 15 }
 *   DIRECTION_VENT                : { direction: 225, vitesse: 12.5 }
 *   TRANSPIRATION_PLANTE          : { transpiration: 1.8 } | valeur numérique directe
 */
function extractValeur(type, data) {
  switch (type) {
    case 'HUMIDITE_TEMPERATURE_AMBIANTE':
      return JSON.stringify({
        temperature: data.temperature ?? data.temp ?? null,
        humidite:    data.humidite    ?? data.humidity ?? null,
      });

    case 'HUMIDITE_SOL':
      return String(data.humidite ?? data.humidity ?? data.humidite_sol ?? data.valeur ?? data.value ?? 0);

    case 'UV':
      return String(data.uv_index ?? data.uv ?? data.valeur ?? data.value ?? 0);

    case 'NPK':
      return JSON.stringify({
        N: data.N ?? data.nitrogen  ?? data.azote      ?? 0,
        P: data.P ?? data.phosphorus ?? data.phosphore ?? 0,
        K: data.K ?? data.potassium  ?? 0,
      });

    case 'DIRECTION_VENT':
      return JSON.stringify({
        direction: data.direction ?? data.bearing ?? 0,
        vitesse:   data.vitesse   ?? data.speed   ?? data.wind_speed ?? 0,
      });

    case 'TRANSPIRATION_PLANTE':
      return String(data.transpiration ?? data.transpiration_rate ?? data.valeur ?? data.value ?? 0);

    default:
      // Type inconnu : on sérialise tout le payload
      return typeof data === 'object' ? JSON.stringify(data) : String(data);
  }
}

function extractUnite(type) {
  const UNITES = {
    HUMIDITE_TEMPERATURE_AMBIANTE: 'JSON',
    HUMIDITE_SOL:                  '%',
    UV:                            'UV index',
    NPK:                           'JSON(mg/kg)',
    DIRECTION_VENT:                'JSON(°/km·h)',
    TRANSPIRATION_PLANTE:          'mm/h',
  };
  return UNITES[type] || '';
}

// ─── Registry (cache capteur_code → id) ───────────────────────────────────────

async function refreshRegistry() {
  try {
    const res = await fetch(`${API_BASE_URL}/capteurs?limit=500`, {
      headers: { 'x-iot-secret': API_SECRET }
    });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const body = await res.json();
    capteurRegistry.clear();
    for (const c of body.data || []) {
      if (c.code) capteurRegistry.set(c.code, { id: c.id, type: c.type });
    }
    registryLastRefresh = Date.now();
    console.log(`[IoT] Registry refreshed — ${capteurRegistry.size} capteurs`);
  } catch (err) {
    console.error('[IoT] Impossible de rafraîchir le registry:', err.message);
  }
}

async function getRegistryEntry(deviceCode) {
  if (Date.now() - registryLastRefresh > REGISTRY_TTL) await refreshRegistry();
  return capteurRegistry.get(deviceCode) || null;
}

// ─── Ingestion vers le backend ─────────────────────────────────────────────────

async function sendMesure(capteurId, valeur, unite) {
  const res = await fetch(`${API_BASE_URL}/mesures`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-iot-secret': API_SECRET,
    },
    body: JSON.stringify({ capteur_id: capteurId, valeur, unite }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Backend ${res.status}: ${body}`);
  }
  return res.json();
}

// ─── Traitement principal par message MQTT ────────────────────────────────────

async function processMeasurement(deviceCode, data) {
  const entry = await getRegistryEntry(deviceCode);

  if (!entry) {
    console.warn(`[IoT] Capteur inconnu : ${deviceCode} — ignoré (enregistrez d'abord ce capteur dans AgroSmart)`);
    messagesErrored += 1;
    return;
  }

  const { id: capteurId, type } = entry;

  try {
    const valeur = extractValeur(type, data);
    const unite  = extractUnite(type);

    await sendMesure(capteurId, valeur, unite);

    messagesForwarded += 1;
    console.log(`[IoT] ✓ ${deviceCode} (${type}) → mesure ingérée (valeur: ${valeur})`);
  } catch (err) {
    messagesErrored += 1;
    console.error(`[IoT] ✗ ${deviceCode} — erreur ingestion:`, err.message);
  }
}

// ─── Health Check HTTP ─────────────────────────────────────────────────────────

const healthServer = http.createServer((req, res) => {
  if (req.url === '/health' && req.method === 'GET') {
    const healthy = mqttConnected;
    res.writeHead(healthy ? 200 : 503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status:            healthy ? 'healthy' : 'unhealthy',
      mqtt:              mqttConnected ? 'connected' : 'disconnected',
      messagesReceived,
      messagesForwarded,
      messagesErrored,
      registrySize:      capteurRegistry.size,
      timestamp:         new Date().toISOString(),
    }));
  } else if (req.url === '/' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      service:     'agrosmart-iot',
      version:     '1.1.0',
      description: 'IoT Gateway Service for AgroSmart',
      typesSupported: [
        'HUMIDITE_TEMPERATURE_AMBIANTE',
        'HUMIDITE_SOL',
        'UV',
        'NPK',
        'DIRECTION_VENT',
        'TRANSPIRATION_PLANTE',
      ],
    }));
  } else {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not Found' }));
  }
});

healthServer.listen(PORT, () => {
  console.log(`[Health] HTTP server listening on port ${PORT}`);
});

// ─── MQTT ──────────────────────────────────────────────────────────────────────

const mqttOptions = {
  username:        process.env.MQTT_USERNAME,
  password:        process.env.MQTT_PASSWORD,
  reconnectPeriod: 5000,
  connectTimeout:  30000,
};

console.log(`[MQTT] Connecting to Broker: ${MQTT_BROKER}`);
const client = mqtt.connect(MQTT_BROKER, mqttOptions);

client.on('connect', () => {
  mqttConnected = true;
  console.log('[MQTT] Connected to Broker');
  client.subscribe(MQTT_TOPIC, (err) => {
    if (!err) console.log(`[MQTT] Subscribed to topic: ${MQTT_TOPIC}`);
    else console.error('[MQTT] Subscription error:', err);
  });
  // Premier chargement du registry
  refreshRegistry();
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
    const parts   = topic.split('/');
    const deviceCode = parts[1]; // format: agrosmart/{device_code}/up

    const data = JSON.parse(payload);
    messagesReceived += 1;
    await processMeasurement(deviceCode, data);
  } catch (error) {
    console.error('[MQTT] Error processing message:', error.message);
    messagesErrored += 1;
  }
});

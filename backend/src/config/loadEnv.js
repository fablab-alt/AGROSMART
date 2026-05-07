/**
 * Charge les variables d'environnement une seule fois pour éviter
 * les relectures multiples de dotenv dans les différents modules.
 */
const path = require('path');
const fs = require('fs');

if (!global.__agrosmartEnvLoaded) {
  const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
  const backendEnvPath = path.resolve(__dirname, '../../', envFile);
  const rootEnvPath = path.resolve(__dirname, '../../../', envFile);

  const envPath = fs.existsSync(backendEnvPath) ? backendEnvPath : rootEnvPath;

  require('dotenv').config({
    path: envPath,
    quiet: true
  });

  global.__agrosmartEnvLoaded = true;
}

module.exports = true;

/**
 * PM2 Ecosystem Configuration - AgriSmart CI
 * Déploiement sans Docker (Nginx + PM2)
 *
 * Architecture :
 *   Backend  (Node/Express) → port 3600 (cluster mode)
 *   Frontend (Next.js)      → port 3603
 *   IoT      (Node/MQTT)    → port 4000 (optional - requires MQTT)
 *   AI       (Python/Flask) → port 5001 (optional - requires TensorFlow)
 *
 * Usage :
 *   pm2 start ecosystem.config.js            # Start all
 *   pm2 start ecosystem.config.js --only agrismart-backend
 *   pm2 stop ecosystem.config.js
 *   pm2 restart ecosystem.config.js
 *   pm2 save && pm2 startup                  # Auto-start on boot
 */

module.exports = {
    apps: [
        // =============================================
        // BACKEND - Node.js / Express / Prisma
        // =============================================
        {
            name: 'agrismart-backend',
            script: 'src/server.js',
            cwd: './backend',
            instances: 'max',          // Cluster mode : utilise tous les CPU
            exec_mode: 'cluster',
            watch: false,
            max_memory_restart: '500M',
            env: {
                NODE_ENV: 'production',
                PORT: 3600
            },
            error_file: './logs/pm2/backend-error.log',
            out_file: './logs/pm2/backend-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            merge_logs: true,
            // Redémarrage automatique en cas de crash
            autorestart: true,
            restart_delay: 4000,
            max_restarts: 10,
            // Graceful startup
            wait_ready: false,
            listen_timeout: 10000,
            kill_timeout: 5000
        },

        // =============================================
        // FRONTEND - Next.js
        // =============================================
        {
            name: 'agrismart-frontend',
            script: 'node_modules/.bin/next',
            args: 'start -p 3603',
            cwd: './frontend',
            instances: 1,              // Next.js gère sa propre concurrence
            exec_mode: 'fork',
            watch: false,
            max_memory_restart: '400M',
            env: {
                NODE_ENV: 'production',
                PORT: 3603
            },
            error_file: './logs/pm2/frontend-error.log',
            out_file: './logs/pm2/frontend-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            autorestart: true,
            restart_delay: 3000,
            max_restarts: 10
        },

        // =============================================
        // IOT SERVICE - Node.js / MQTT
        // =============================================
        {
            name: 'agrismart-iot',
            script: 'index.js',
            cwd: './iot_service',
            instances: 1,
            exec_mode: 'fork',
            watch: false,
            max_memory_restart: '200M',
            env: {
                NODE_ENV: 'production',
                PORT: 4000
            },
            error_file: './logs/pm2/iot-error.log',
            out_file: './logs/pm2/iot-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            autorestart: true,
            restart_delay: 5000,
            max_restarts: 5
        },

        // =============================================
        // AI SERVICE - Python / Flask / Gunicorn
        // =============================================
        // IMPORTANT : Créer le venv depuis la racine avant de démarrer :
        //   cd ai_service && python3 -m venv .venv && source .venv/bin/activate
        //   pip install -r requirements.txt && pip install gunicorn && deactivate
        // Le chemin `interpreter` est TOUJOURS résolu depuis la racine du projet.
        {
            name: 'agrismart-ai',
            script: './ai_service/.venv/bin/gunicorn',
            args: '--workers 2 --bind 127.0.0.1:5001 --timeout 120 app:app',
            cwd: './ai_service',
            instances: 1,
            exec_mode: 'fork',
            watch: false,
            max_memory_restart: '600M',
            env: {
                NODE_ENV: 'production',
                PYTHONUNBUFFERED: '1',
                FLASK_ENV: 'production'
            },
            error_file: './logs/pm2/ai-error.log',
            out_file: './logs/pm2/ai-out.log',
            log_date_format: 'YYYY-MM-DD HH:mm:ss',
            autorestart: true,
            restart_delay: 5000,
            max_restarts: 5
        }
    ]
};

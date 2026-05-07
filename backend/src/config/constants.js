/**
 * Backend Constants
 * AgroSmart - Centralized constants for better maintainability
 */

module.exports = {
    // ==================== OTP ====================
    OTP: {
        LENGTH: 6,
        EXPIRY_MINUTES: 10,
        MAX_ATTEMPTS: 3,
        RESEND_COOLDOWN_SECONDS: 60
    },

    // ==================== PAGINATION ====================
    PAGINATION: {
        DEFAULT_PAGE_SIZE: 20,
        MAX_PAGE_SIZE: 100,
        DEFAULT_PAGE: 1
    },

    // ==================== RATE LIMITING ====================
    RATE_LIMIT: {
        WINDOW_MS: 15 * 60 * 1000, // 15 minutes
        MAX_REQUESTS: 100,
        MAX_REQUESTS_AUTH: 5, // For sensitive auth endpoints
        SKIP_SUCCESSFUL_REQUESTS: false
    },

    // ==================== SENSORS & MONITORING ====================
    SENSORS: {
        OFFLINE_THRESHOLD_MINUTES: 30,
        BATTERY_LOW_THRESHOLD: 20,
        BATTERY_CRITICAL_THRESHOLD: 10,
        SIGNAL_LOW_THRESHOLD: 30
    },

    // ==================== FILE UPLOAD ====================
    FILES: {
        MAX_SIZE_MB: 5,
        MAX_SIZE_BYTES: 5 * 1024 * 1024,
        ALLOWED_IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'],
        ALLOWED_DOCUMENT_TYPES: ['application/pdf', 'application/msword'],
        MAX_IMAGES_PER_UPLOAD: 5
    },

    // ==================== DISTANCES & LOCATION ====================
    LOCATION: {
        SEARCH_RADIUS_KM: 50,
        DEFAULT_LATITUDE: 5.3599, // Côte d'Ivoire center
        DEFAULT_LONGITUDE: -4.0083,
        COORDINATE_PRECISION: 6 // Decimal places
    },

    // ==================== CACHE ====================
    CACHE: {
        WEATHER_DURATION_MS: 30 * 60 * 1000, // 30 minutes
        STATS_DURATION_MS: 5 * 60 * 1000, // 5 minutes
        USER_PROFILE_DURATION_MS: 15 * 60 * 1000 // 15 minutes
    },

    // ==================== JWT & SECURITY ====================
    JWT: {
        ACCESS_TOKEN_EXPIRY: '24h',
        REFRESH_TOKEN_EXPIRY: '7d',
        ALGORITHM: 'HS256'
    },

    // ==================== PASSWORD ====================
    PASSWORD: {
        MIN_LENGTH: 8,
        MAX_LENGTH: 128,
        REQUIRE_UPPERCASE: true,
        REQUIRE_LOWERCASE: true,
        REQUIRE_NUMBER: true,
        REQUIRE_SPECIAL_CHAR: false,
        SALT_ROUNDS: 12
    },

    // ==================== ALERTS ====================
    ALERTS: {
        MAX_ACTIVE_PER_USER: 100,
        AUTO_READ_AFTER_DAYS: 30,
        CRITICAL_NOTIFICATION_CHANNELS: ['sms', 'push', 'email'],
        WARNING_NOTIFICATION_CHANNELS: ['push', 'email'],
        INFO_NOTIFICATION_CHANNELS: ['push']
    },

    // ==================== MARKETPLACE ====================
    MARKETPLACE: {
        MIN_PRICE: 0,
        MAX_PRICE: 999999999,
        DEFAULT_CURRENCY: 'XOF',
        FEATURED_DURATION_DAYS: 30,
        MAX_IMAGES: 5,
        RENTAL_MIN_DAYS: 1,
        RENTAL_MAX_DAYS: 365
    },

    // ==================== MEASUREMENTS ====================
    MEASUREMENTS: {
        BATCH_MAX_SIZE: 100,
        RETENTION_DAYS: 365,
        AGGREGATION_INTERVAL_MINUTES: 15
    },

    // ==================== NOTIFICATIONS ====================
    NOTIFICATIONS: {
        MAX_RETRIES: 3,
        RETRY_DELAY_MS: 1000,
        BATCH_SIZE: 50
    },

    // ==================== VALIDATION ====================
    VALIDATION: {
        PHONE_REGEX: /^\+225\d{10}$/,
        EMAIL_MAX_LENGTH: 150,
        NAME_MAX_LENGTH: 100,
        DESCRIPTION_MAX_LENGTH: 1000,
        COORDINATE_REGEX: /^-?\d+(\.\d+)?$/
    },

    // ==================== STATUS VALUES ====================
    STATUS: {
        SENSOR: {
            ACTIVE: 'actif',
            INACTIVE: 'inactif',
            MAINTENANCE: 'maintenance',
            ERROR: 'erreur'
        },
        USER: {
            PENDING: 'en_attente',
            ACTIVE: 'actif',
            SUSPENDED: 'suspendu',
            INACTIVE: 'inactif'
        },
        PARCEL: {
            ACTIVE: 'active',
            RESTING: 'en_repos',
            PREPARED: 'preparee',
            SEEDED: 'ensemencee',
            GROWING: 'en_croissance',
            HARVEST: 'recolte',
            NEWLY_DEVELOPED: 'mise_en_valeur_recemment'
        },
        ALERT: {
            NEW: 'nouvelle',
            READ: 'lue',
            PROCESSED: 'traitee',
            IGNORED: 'ignoree'
        }
    },

    // ==================== ERROR CODES ====================
    ERROR_CODES: {
        VALIDATION_ERROR: 'VALIDATION_ERROR',
        UNAUTHORIZED: 'UNAUTHORIZED',
        FORBIDDEN: 'FORBIDDEN',
        NOT_FOUND: 'NOT_FOUND',
        CONFLICT: 'CONFLICT',
        RATE_LIMIT_EXCEEDED: 'RATE_LIMIT_EXCEEDED',
        INTERNAL_ERROR: 'INTERNAL_ERROR',
        INVALID_OTP: 'INVALID_OTP',
        OTP_EXPIRED: 'OTP_EXPIRED',
        OTP_MAX_ATTEMPTS: 'OTP_MAX_ATTEMPTS'
    }
}

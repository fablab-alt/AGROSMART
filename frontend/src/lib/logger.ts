/**
 * Centralized Frontend Logger
 * AgriSmart CI - Production-ready logging system
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error'

class Logger {
    private isDev = process.env.NODE_ENV === 'development'

    /**
     * Log debug message (development only)
     */
    debug(message: string, context?: Record<string, unknown>) {
        this.log('debug', message, context)
    }

    /**
     * Log informational message
     */
    info(message: string, context?: Record<string, unknown>) {
        this.log('info', message, context)
    }

    /**
     * Log warning message
     */
    warn(message: string, context?: Record<string, unknown>) {
        this.log('warn', message, context)
    }

    /**
     * Log error message
     */
    error(message: string, error?: Error, context?: Record<string, unknown>) {
        const errorContext = error ? { ...context, errorMessage: error.message, errorStack: error.stack } : context
        this.log('error', message, errorContext)
    }

    /**
     * Internal logging method
     */
    private log(level: LogLevel, message: string, context?: Record<string, unknown>) {
        // Console output in development only
        if (this.isDev) {
            const style = this.getConsoleStyle(level)
            const timestamp = new Date().toISOString().split('T')[1].split('.')[0]
            console.log(
                `%c[${timestamp}] [${level.toUpperCase()}] ${message}`,
                style,
                context || ''
            )
        }
    }

    /**
     * Get console styling based on log level
     */
    private getConsoleStyle(level: LogLevel): string {
        const styles = {
            debug: 'color: #888; font-weight: normal',
            info: 'color: #0ea5e9; font-weight: normal',
            warn: 'color: #f59e0b; font-weight: bold',
            error: 'color: #ef4444; font-weight: bold'
        }
        return styles[level]
    }
}

// Export singleton instance
export const logger = new Logger()

// Export type for external use
export type { LogLevel }

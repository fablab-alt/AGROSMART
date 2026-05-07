/**
 * Centralized Frontend Logger
 * AgriSmart CI - Production-ready logging system
 */

type LogLevel = 'debug' | 'info' | 'warn' | 'error'

interface LogEntry {
    level: LogLevel
    message: string
    timestamp: Date
    context?: Record<string, unknown>
    error?: Error
}

class Logger {
    private isDev = process.env.NODE_ENV === 'development'
    private logs: LogEntry[] = []
    private maxLogs = 100

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

        // Send to monitoring service in production
        if (!this.isDev && error) {
            this.sendToMonitoring({ level: 'error', message, error, context: errorContext })
        }
    }

    /**
     * Internal logging method
     */
    private log(level: LogLevel, message: string, context?: Record<string, unknown>) {
        const entry: LogEntry = {
            level,
            message,
            timestamp: new Date(),
            context
        }

        // Store logs in memory
        this.logs.push(entry)
        if (this.logs.length > this.maxLogs) {
            this.logs.shift()
        }

        // Console output in development only
        if (this.isDev) {
            const style = this.getConsoleStyle(level)
            const timestamp = entry.timestamp.toISOString().split('T')[1].split('.')[0]
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

    /**
     * Send error logs to monitoring service
     */
    private sendToMonitoring(entry: Partial<LogEntry>) {
        // Future integration with Sentry, LogRocket, or custom monitoring
        // For now, send to backend API
        try {
            fetch('/api/logs', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    ...entry,
                    timestamp: new Date().toISOString(),
                    userAgent: navigator.userAgent,
                    url: window.location.href
                })
            }).catch(() => {
                // Silent fail to avoid infinite loop
            })
        } catch {
            // Silent fail
        }
    }

    /**
     * Get all stored logs
     */
    getLogs(): LogEntry[] {
        return [...this.logs]
    }

    /**
     * Clear all stored logs
     */
    clearLogs() {
        this.logs = []
    }

    /**
     * Export logs as JSON string
     */
    exportLogs(): string {
        return JSON.stringify(this.logs, null, 2)
    }
}

// Export singleton instance
export const logger = new Logger()

// Export type for external use
export type { LogLevel, LogEntry }

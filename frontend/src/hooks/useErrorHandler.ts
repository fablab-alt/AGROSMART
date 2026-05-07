/**
 * useErrorHandler Hook
 * AgriSmart CI - Consistent error handling across the application
 */

import { useCallback } from 'react'
import { toast } from 'react-hot-toast'
import { logger } from '@/lib/logger'
import { useRouter } from 'next/navigation'

interface ErrorHandlerOptions {
    showToast?: boolean
    toastMessage?: string
    logLevel?: 'warn' | 'error'
    onError?: (error: Error) => void
    redirectOn401?: boolean
}

interface ErrorResponse {
    response?: {
        data?: {
            message?: string
            code?: string
        }
        status?: number
    }
    message?: string
}

/**
 * Hook for consistent error handling throughout the application
 * 
 * @example
 * ```tsx
 * const { handleError } = useErrorHandler()
 * 
 * try {
 *   await api.get('/data')
 * } catch (error) {
 *   handleError(error, 'Failed to fetch data')
 * }
 * ```
 */
export function useErrorHandler() {
    const router = useRouter()

    const handleError = useCallback((
        error: unknown,
        context?: string,
        options: ErrorHandlerOptions = {}
    ) => {
        const {
            showToast = true,
            toastMessage,
            logLevel = 'error',
            onError,
            redirectOn401 = true
        } = options

        const err = error instanceof Error ? error : new Error(String(error))
        const errorResponse = error as ErrorResponse

        // Extract status code and API message if available
        const statusCode = errorResponse?.response?.status
        const apiMessage = errorResponse?.response?.data?.message
        const errorCode = errorResponse?.response?.data?.code

        // Log the error with context
        const logContext = {
            statusCode,
            errorCode,
            apiMessage,
            url: typeof window !== 'undefined' ? window.location.href : undefined
        }

        if (logLevel === 'error') {
            logger.error(context || 'Error occurred', err, logContext)
        } else {
            logger.warn(context || 'Warning occurred', { ...logContext, error: err.message })
        }

        // Handle 401 - Unauthorized (redirect to login)
        if (statusCode === 401 && redirectOn401) {
            toast.error('Session expirée. Veuillez vous reconnecter.')
            router.push('/login')
            return
        }

        // Show user-friendly toast message
        if (showToast) {
            const message = toastMessage || getUserFriendlyMessage(err, statusCode, apiMessage)
            toast.error(message, {
                duration: 5000,
                position: 'top-right'
            })
        }

        // Call custom error callback if provided
        if (onError) {
            onError(err)
        }
    }, [router])

    /**
     * Get user-friendly error message based on error type and status code
     */
    const getUserFriendlyMessage = useCallback((
        error: Error,
        statusCode?: number,
        apiMessage?: string
    ): string => {
        // Use API message if available and user-friendly
        if (apiMessage && !apiMessage.includes('Error:') && apiMessage.length < 100) {
            return apiMessage
        }

        // Handle by status code
        if (statusCode) {
            switch (statusCode) {
                case 400:
                    return 'Données invalides. Veuillez vérifier vos saisies.'
                case 401:
                    return 'Session expirée. Veuillez vous reconnecter.'
                case 403:
                    return "Vous n'avez pas les permissions nécessaires."
                case 404:
                    return 'Ressource introuvable.'
                case 409:
                    return 'Cette ressource existe déjà.'
                case 422:
                    return 'Erreur de validation. Vérifiez vos données.'
                case 429:
                    return 'Trop de requêtes. Attendez un moment.'
                case 500:
                    return 'Erreur serveur. Réessayez plus tard.'
                case 503:
                    return 'Service temporairement indisponible.'
            }
        }

        // Handle by error message patterns
        const message = error.message.toLowerCase()

        if (message.includes('network') || message.includes('fetch')) {
            return 'Problème de connexion. Vérifiez votre internet.'
        }

        if (message.includes('timeout')) {
            return 'La requête a pris trop de temps. Réessayez.'
        }

        if (message.includes('cors')) {
            return 'Erreur de communication avec le serveur.'
        }

        // Default fallback
        return 'Une erreur est survenue. Veuillez réessayer.'
    }, [])

    /**
     * Handle async operations with automatic error handling
     */
    const withErrorHandling = useCallback(async <T,>(
        operation: () => Promise<T>,
        context?: string,
        options?: ErrorHandlerOptions
    ): Promise<T | null> => {
        try {
            return await operation()
        } catch (error) {
            handleError(error, context, options)
            return null
        }
    }, [handleError])

    return {
        handleError,
        withErrorHandling,
        getUserFriendlyMessage
    }
}

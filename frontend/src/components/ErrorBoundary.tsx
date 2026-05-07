/**
 * Error Boundary Component
 * AgriSmart CI - Catch and handle React errors gracefully
 */

import React, { Component, ErrorInfo, ReactNode } from 'react'
import { logger } from '@/lib/logger'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { AlertTriangle, RefreshCw, Home } from 'lucide-react'

interface Props {
    children: ReactNode
    fallback?: ReactNode
    onError?: (error: Error, errorInfo: ErrorInfo) => void
}

interface State {
    hasError: boolean
    error?: Error
    errorInfo?: ErrorInfo
}

/**
 * ErrorBoundary - Catches React errors and displays fallback UI
 * 
 * Usage:
 * ```tsx
 * <ErrorBoundary>
 *   <YourComponent />
 * </ErrorBoundary>
 * ```
 */
export class ErrorBoundary extends Component<Props, State> {
    constructor(props: Props) {
        super(props)
        this.state = { hasError: false }
    }

    static getDerivedStateFromError(error: Error): State {
        return { hasError: true, error }
    }

    componentDidCatch(error: Error, errorInfo: ErrorInfo) {
        // Log to our centralized logger
        logger.error('React Error Boundary caught error', error, {
            componentStack: errorInfo.componentStack
        })

        // Store error info in state
        this.setState({ errorInfo })

        // Call custom error handler if provided
        if (this.props.onError) {
            this.props.onError(error, errorInfo)
        }
    }

    handleReset = () => {
        this.setState({ hasError: false, error: undefined, errorInfo: undefined })
    }

    handleGoHome = () => {
        window.location.href = '/'
    }

    render() {
        if (this.state.hasError) {
            // Use custom fallback if provided
            if (this.props.fallback) {
                return this.props.fallback
            }

            // Default error UI
            return (
                <div className="flex items-center justify-center min-h-screen p-4 bg-gray-50">
                    <Card className="w-full max-w-md">
                        <CardHeader className="text-center">
                            <div className="mx-auto mb-4 h-16 w-16 rounded-full bg-red-100 flex items-center justify-center">
                                <AlertTriangle className="h-8 w-8 text-red-600" />
                            </div>
                            <CardTitle className="text-2xl">Une erreur est survenue</CardTitle>
                            <CardDescription>
                                {this.state.error?.message || "Quelque chose s'est mal passé"}
                            </CardDescription>
                        </CardHeader>
                        <CardContent className="space-y-4">
                            {process.env.NODE_ENV === 'development' && this.state.errorInfo && (
                                <details className="text-sm">
                                    <summary className="cursor-pointer font-medium text-gray-700 hover:text-gray-900">
                                        Détails techniques
                                    </summary>
                                    <pre className="mt-2 overflow-auto rounded bg-gray-100 p-2 text-xs">
                                        {this.state.errorInfo.componentStack}
                                    </pre>
                                </details>
                            )}

                            <div className="flex gap-2">
                                <Button
                                    onClick={this.handleReset}
                                    className="flex-1 gap-2"
                                    variant="outline"
                                >
                                    <RefreshCw className="h-4 w-4" />
                                    Réessayer
                                </Button>
                                <Button
                                    onClick={this.handleGoHome}
                                    className="flex-1 gap-2"
                                >
                                    <Home className="h-4 w-4" />
                                    Accueil
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            )
        }

        return this.props.children
    }
}

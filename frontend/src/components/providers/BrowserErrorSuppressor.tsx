'use client'

import { useEffect } from 'react'

/**
 * Composant qui supprime les erreurs non-critiques causées par les extensions de navigateur
 * L'erreur "message channel closed" est causée par des extensions comme React DevTools,
 * GitGuardian, ou d'autres extensions qui interceptent les messages du navigateur.
 */
export function BrowserErrorSuppressor() {
  useEffect(() => {
    // Sauvegarder le handler d'erreur original
    const originalOnError = window.onerror
    const originalOnUnhandledRejection = window.onunhandledrejection

    // Handler personnalisé pour supprimer les erreurs d'extensions
    window.onerror = function (message, source, lineno, colno, error) {
      // Ignorer les erreurs de message channel (causées par extensions)
      if (
        typeof message === 'string' &&
        (message.includes('message channel closed') ||
          message.includes('A listener indicated an asynchronous response'))
      ) {
        return true // Supprime l'erreur
      }
      // Appeler le handler original pour les autres erreurs
      if (originalOnError) {
        return originalOnError.call(window, message, source, lineno, colno, error)
      }
      return false
    }

    // Handler pour les promesses rejetées non gérées
    window.onunhandledrejection = function (event) {
      const message = event.reason?.message || String(event.reason)
      // Ignorer les erreurs de message channel
      if (
        message.includes('message channel closed') ||
        message.includes('A listener indicated an asynchronous response')
      ) {
        event.preventDefault()
        return
      }
      // Appeler le handler original
      if (originalOnUnhandledRejection) {
        originalOnUnhandledRejection.call(window, event)
      }
    }

    // Cleanup
    return () => {
      window.onerror = originalOnError
      window.onunhandledrejection = originalOnUnhandledRejection
    }
  }, [])

  return null
}

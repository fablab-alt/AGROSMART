/**
 * Helpers pour entrer/sortir du mode visiteur AgroSmart CI.
 * Importés par les composants landing (Navbar, HeroSection, CTASection)
 * et le composant VisitorBanner.
 */

import { useAuthStore } from '@/lib/store'
import type { AppRouterInstance } from 'next/dist/shared/lib/app-router-context.shared-runtime'

/**
 * Démarre le mode démo et redirige vers le dashboard.
 */
export function enterVisitorMode(router: AppRouterInstance): void {
  useAuthStore.getState().enableVisitorMode()
  router.push('/dashboard')
}

/**
 * Quitte le mode démo et redirige vers la landing page.
 */
export function exitVisitorMode(router: AppRouterInstance): void {
  useAuthStore.getState().disableVisitorMode()
  router.push('/')
}

/**
 * Quitte le mode démo et redirige vers la page d'inscription.
 */
export function exitVisitorModeToRegister(router: AppRouterInstance): void {
  useAuthStore.getState().disableVisitorMode()
  router.push('/register')
}

/**
 * Retourne true si la méthode HTTP est une mutation (POST/PUT/PATCH/DELETE).
 */
export function isMutation(method?: string): boolean {
  return ['POST', 'PUT', 'PATCH', 'DELETE'].includes((method ?? '').toUpperCase())
}

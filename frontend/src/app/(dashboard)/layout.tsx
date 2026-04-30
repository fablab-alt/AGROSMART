'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Sidebar, Header, BottomNav } from '@/components/layout'
import { useAuthStore, useUIStore } from '@/lib/store'
import { LoadingOverlay } from '@/components/ui'
import { isDiscoveryModeEnabled, setDiscoveryMode } from '@/lib/discoveryMode'
import { Eye, LogIn, UserPlus, X } from 'lucide-react'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const router = useRouter()
  const { isAuthenticated, isLoading, token } = useAuthStore()
  const { theme } = useUIStore()
  const [mounted, setMounted] = useState(false)
  const [discoveryMode, setDiscoveryModeState] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    if (!mounted) return

    const forceDiscovery = new URLSearchParams(window.location.search).get('discover') === '1'
    if (forceDiscovery) {
      setDiscoveryMode(true)
      setDiscoveryModeState(true)
      return
    }

    setDiscoveryModeState(isDiscoveryModeEnabled())
  }, [mounted])

  // Appliquer le thème au document
  useEffect(() => {
    if (mounted) {
      const root = document.documentElement
      if (theme === 'dark') {
        root.classList.add('dark')
      } else {
        root.classList.remove('dark')
      }
    }
  }, [theme, mounted])

  useEffect(() => {
    if (mounted && !isLoading) {
      if (!discoveryMode && !isAuthenticated && !token) {
        router.push('/login')
      }
    }
  }, [mounted, discoveryMode, isAuthenticated, isLoading, token, router])

  if (!mounted) {
    return <LoadingOverlay message="Chargement..." />
  }

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900">
      {/* Sidebar */}
      <Sidebar />

      {/* Main content area */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Header */}
        <Header />

        {/* Page content */}
        <main className="flex-1 overflow-y-auto pb-16 lg:pb-0 dark:bg-gray-900">
          <div className="container mx-auto px-4 py-6 lg:px-6">
            {discoveryMode && (
              <div className="mb-4 rounded-xl border border-amber-200 bg-gradient-to-r from-amber-50 to-orange-50 px-4 py-3 shadow-sm">
                <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                  <div className="flex items-center gap-2">
                    <Eye className="h-4 w-4 text-amber-600 shrink-0" />
                    <p className="text-sm font-medium text-amber-900">
                      Mode découverte — navigation libre, actions en lecture seule uniquement.
                    </p>
                  </div>
                  <div className="flex items-center gap-2">
                    <Link href="/login">
                      <button className="inline-flex items-center gap-1.5 rounded-lg bg-green-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-green-700 transition-colors">
                        <LogIn className="h-3.5 w-3.5" />
                        Se connecter
                      </button>
                    </Link>
                    <Link href="/register">
                      <button className="inline-flex items-center gap-1.5 rounded-lg border border-green-300 bg-white px-3 py-1.5 text-xs font-semibold text-green-700 hover:bg-green-50 transition-colors">
                        <UserPlus className="h-3.5 w-3.5" />
                        Créer un compte
                      </button>
                    </Link>
                    <Link href="/">
                      <button
                        className="inline-flex items-center justify-center rounded-lg p-1.5 text-amber-500 hover:bg-amber-100 transition-colors"
                        title="Quitter le mode découverte"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </Link>
                  </div>
                </div>
              </div>
            )}
            {children}
          </div>
        </main>
      </div>

      {/* Bottom navigation for mobile */}
      <BottomNav />
    </div>
  )
}

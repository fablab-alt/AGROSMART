'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { Sidebar, Header, BottomNav } from '@/components/layout'
import { useAuthStore, useUIStore } from '@/lib/store'
import { LoadingOverlay } from '@/components/ui'
import { VisitorBanner } from '@/components/visitor/VisitorBanner'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const router = useRouter()
  const { isAuthenticated, isLoading, token, visitorMode } = useAuthStore()
  const { theme } = useUIStore()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

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
      // Le mode visiteur est accepté sans authentification réelle
      if (!isAuthenticated && !token && !visitorMode) {
        router.push('/login')
      }
    }
  }, [mounted, isAuthenticated, isLoading, token, visitorMode, router])

  if (!mounted) {
    return <LoadingOverlay message="Chargement..." />
  }

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900 flex-col">
      {/* Bannière mode visiteur (affichée uniquement en mode démo) */}
      {visitorMode && <VisitorBanner />}

      <div className="flex flex-1 overflow-hidden">
        {/* Sidebar */}
        <Sidebar />

        {/* Main content area */}
        <div className="flex flex-1 flex-col overflow-hidden">
          {/* Header */}
          <Header />

          {/* Page content */}
          <main className="flex-1 overflow-y-auto pb-16 lg:pb-0 dark:bg-gray-900">
            <div className="container mx-auto px-4 py-6 lg:px-6">
              {children}
            </div>
          </main>
        </div>
      </div>

      {/* Bottom navigation for mobile */}
      <BottomNav />
    </div>
  )
}

'use client'

import { useEffect, useState } from 'react'
import { useUIStore } from '@/lib/store'

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const { theme } = useUIStore()
  const [mounted, setMounted] = useState(false)

  // Attendre que le composant soit monté pour éviter les problèmes d'hydratation
  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    if (!mounted) return
    
    // Appliquer le thème au document
    const root = document.documentElement
    
    if (theme === 'dark') {
      root.classList.add('dark')
      root.classList.remove('light')
    } else {
      root.classList.remove('dark')
      root.classList.add('light')
    }
  }, [theme, mounted])

  // Éviter le flash de contenu non stylé
  useEffect(() => {
    // Appliquer immédiatement le thème stocké
    const storedUI = localStorage.getItem('ui-storage')
    if (storedUI) {
      try {
        const parsed = JSON.parse(storedUI)
        const storedTheme = parsed?.state?.theme
        if (storedTheme === 'dark') {
          document.documentElement.classList.add('dark')
        }
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    }
  }, [])

  return <>{children}</>
}

'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import Image from 'next/image'
import { usePathname } from 'next/navigation'
import { useAuthStore, useUIStore } from '@/lib/store'
import { LoadingOverlay } from '@/components/ui'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  Users,
  Settings,
  LogOut,
  Menu,
  X,
  Moon,
  Sun,
  Cpu,
  BarChart3,
  Download,
  Activity,
  Wrench,
} from 'lucide-react'

const adminNavigation = [
  { name: 'Tableau de bord', href: '/admin', icon: LayoutDashboard },
  { name: 'Utilisateurs', href: '/admin/users', icon: Users },
  { name: 'Agriculteurs', href: '/admin/agriculteurs', icon: Users },
  { name: 'Capteurs', href: '/admin/capteurs', icon: Cpu },
  { name: 'Productions', href: '/admin/productions', icon: Activity },
  { name: 'Rapports', href: '/admin/rapports', icon: BarChart3 },
  { name: 'Export Données', href: '/admin/export', icon: Download },
  { name: 'Mises à jour', href: '/admin/software-updates', icon: Wrench },
]

const bottomNavigation = [
  { name: 'Paramètres', href: '/admin/system-settings', icon: Settings },
]

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const router = useRouter()
  const pathname = usePathname()
  const { isAuthenticated, user, logout, token } = useAuthStore()
  const { theme, setTheme } = useUIStore()
  const [mounted, setMounted] = useState(false)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  // Appliquer le thème
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

  // Vérifier l'authentification et le rôle admin
  useEffect(() => {
    if (mounted) {
      if (!isAuthenticated && !token) {
        router.push('/login')
        return
      }

      // Vérifier si l'utilisateur est admin
      if (user && !['admin', 'super_admin', 'ADMIN', 'SUPER_ADMIN'].includes(user.role)) {
        router.push('/dashboard')
      }
    }
  }, [mounted, isAuthenticated, token, user, router])

  const handleLogout = () => {
    logout()
    router.push('/login')
  }

  if (!mounted) {
    return <LoadingOverlay message="Chargement..." />
  }

  // Vérifier le rôle
  if (user && !['admin', 'super_admin', 'ADMIN', 'SUPER_ADMIN'].includes(user.role)) {
    return <LoadingOverlay message="Accès non autorisé..." />
  }

  return (
    <div className="flex h-screen bg-gray-100 dark:bg-gray-900">
      {/* Mobile menu overlay */}
      {mobileMenuOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setMobileMenuOpen(false)}
        />
      )}

      {/* Sidebar - toujours visible sur desktop */}
      <aside
        className={cn(
          "fixed left-0 top-0 z-50 flex h-full flex-col bg-slate-900 text-white transition-all duration-300",
          // Mobile: caché par défaut, visible si mobileMenuOpen
          mobileMenuOpen ? "translate-x-0" : "-translate-x-full",
          // Desktop: toujours visible
          "lg:translate-x-0 lg:relative lg:z-0",
          // Largeur
          "w-64"
        )}
      >
        {/* Logo */}
        <div className="flex h-16 items-center justify-between px-4 border-b border-slate-700">
          <Link href="/admin" className="flex items-center gap-2">
            <div className="flex h-12 w-32 items-center justify-start overflow-hidden">
              <Image 
                src="/logo.png" 
                alt="AgroSmart" 
                width={128} 
                height={48} 
                className="object-contain object-left h-full w-auto" 
              />
            </div>
          </Link>
          <button
            onClick={() => setMobileMenuOpen(false)}
            className="lg:hidden flex items-center justify-center h-8 w-8 rounded-lg hover:bg-slate-700"
            title="Fermer le menu"
            aria-label="Fermer le menu"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4">
          <ul className="space-y-1 px-2">
            {adminNavigation.map((item) => {
              const isActive = pathname === item.href || (item.href !== '/admin' && pathname.startsWith(item.href))
              return (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className={cn(
                      "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                      isActive
                        ? "bg-green-600 text-white"
                        : "text-slate-300 hover:bg-slate-800 hover:text-white"
                    )}
                  >
                    <item.icon className="h-5 w-5 shrink-0" />
                    <span>{item.name}</span>
                  </Link>
                </li>
              )
            })}
          </ul>
        </nav>

        {/* Bottom navigation */}
        <div className="border-t border-slate-700 py-4">
          <ul className="space-y-1 px-2">
            {bottomNavigation.map((item) => {
              const isActive = pathname === item.href
              return (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    className={cn(
                      "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                      isActive
                        ? "bg-green-600 text-white"
                        : "text-slate-300 hover:bg-slate-800 hover:text-white"
                    )}
                  >
                    <item.icon className="h-5 w-5 shrink-0" />
                    <span>{item.name}</span>
                  </Link>
                </li>
              )
            })}
            <li>
              <button
                onClick={handleLogout}
                className="flex w-full items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium text-red-400 hover:bg-red-900/20 hover:text-red-300 transition-colors"
              >
                <LogOut className="h-5 w-5 shrink-0" />
                <span>Déconnexion</span>
              </button>
            </li>
          </ul>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col overflow-hidden">
        {/* Header */}
        <header className="flex h-16 items-center justify-between border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-4 lg:px-6">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setMobileMenuOpen(true)}
              className="lg:hidden p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
              title="Ouvrir le menu"
              aria-label="Ouvrir le menu"
            >
              <Menu className="h-6 w-6 text-gray-600 dark:text-gray-300" />
            </button>
            <h1 className="text-lg font-semibold text-gray-900 dark:text-white">
              Panneau d&apos;administration
            </h1>
          </div>

          <div className="flex items-center gap-4">
            {/* Theme toggle */}
            <button
              onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
              title="Changer de thème"
              aria-label="Changer de thème"
            >
              {theme === 'light' ? (
                <Moon className="h-5 w-5 text-gray-600" />
              ) : (
                <Sun className="h-5 w-5 text-yellow-500" />
              )}
            </button>

            {/* User info */}
            <div className="flex items-center gap-3">
              <div className="hidden md:block text-right">
                <p className="text-sm font-medium text-gray-900 dark:text-white">
                  {user?.prenom || user?.prenoms} {user?.nom}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400 capitalize">
                  {user?.role}
                </p>
              </div>
              <div className="h-10 w-10 rounded-full bg-green-600 flex items-center justify-center text-white font-medium">
                {user?.nom?.charAt(0) || 'A'}
              </div>
            </div>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-y-auto bg-gray-50 dark:bg-gray-900">
          <div className="container mx-auto px-4 py-6 lg:px-6">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}

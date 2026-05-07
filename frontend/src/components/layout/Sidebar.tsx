'use client'

import Link from 'next/link'
import Image from 'next/image'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { useUIStore } from '@/lib/store'
import {
  LayoutDashboard,
  MapPin,
  Thermometer,
  Bell,
  ShoppingCart,
  GraduationCap,
  MessageSquare,
  User,
  Settings,
  ChevronLeft,
  ChevronRight,
  BarChart3,
  Camera,
  Cloud,
  Lightbulb,
  TrendingUp,
  Users,
  Package,
  CalendarDays,
  BookOpen,
} from 'lucide-react'

const navigation = [
  { name: 'Tableau de bord', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Performance & ROI', href: '/performance', icon: TrendingUp },
  { name: 'Parcelles', href: '/parcelles', icon: MapPin },
  { name: 'Capteurs', href: '/capteurs', icon: Thermometer },
  { name: 'Mesures', href: '/mesures', icon: BarChart3 },
  { name: 'Météo', href: '/meteo', icon: Cloud },
  { name: 'Alertes', href: '/alertes', icon: Bell },
  { name: 'Recommandations', href: '/recommandations', icon: Lightbulb },
  { name: 'Diagnostic IA', href: '/diagnostic', icon: Camera },
  { name: 'Marketplace', href: '/marketplace', icon: ShoppingCart },
  { name: 'Formations', href: '/formations', icon: GraduationCap },
  { name: 'Stocks', href: '/stocks', icon: Package },
  { name: 'Calendrier', href: '/calendrier', icon: CalendarDays },
  { name: 'Fiches Pratiques', href: '/fiches-pratiques', icon: BookOpen },
  { name: 'Communauté', href: '/communaute', icon: Users },
  { name: 'Messages', href: '/messages', icon: MessageSquare },
]

const bottomNavigation = [
  { name: 'Profil', href: '/profil', icon: User },
  { name: 'Paramètres', href: '/settings', icon: Settings },
]

export function Sidebar() {
  const pathname = usePathname()
  const { sidebarOpen, setSidebarOpen } = useUIStore()

  return (
    <>
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed left-0 top-0 z-50 flex h-full flex-col bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 transition-all duration-300 lg:relative lg:z-0",
          sidebarOpen ? "w-64" : "w-0 lg:w-20",
          !sidebarOpen && "overflow-hidden lg:overflow-visible"
        )}
      >
        {/* Logo */}
        <div className="flex h-16 items-center justify-between px-4 border-b border-gray-200 dark:border-gray-700">
          <Link href="/dashboard" className="flex items-center gap-2">
             <div className={`flex items-center overflow-hidden transition-all duration-300 ${sidebarOpen ? 'w-48 justify-start' : 'w-10 justify-center'}`}>
              <div className={`relative ${sidebarOpen ? 'h-12 w-full' : 'h-10 w-10'}`}>
                 <Image 
                   src="/logo.png" 
                   alt="AgroSmart" 
                   width={160} 
                   height={48} 
                   className={`object-contain h-full w-auto ${sidebarOpen ? 'object-left' : 'object-center'}`} 
                 />
              </div>
            </div>
          </Link>
          <button
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="hidden lg:flex items-center justify-center h-8 w-8 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
          >
            {sidebarOpen ? (
              <ChevronLeft className="h-5 w-5 text-gray-500 dark:text-gray-400" />
            ) : (
              <ChevronRight className="h-5 w-5 text-gray-500 dark:text-gray-400" />
            )}
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4">
          <ul className="space-y-1 px-2">
            {navigation.map((item) => {
              const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
              return (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    className={cn(
                      "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                      isActive
                        ? "bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-400"
                        : "text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                    )}
                    title={!sidebarOpen ? item.name : undefined}
                  >
                    <item.icon
                      className={cn(
                        "h-5 w-5 shrink-0",
                        isActive ? "text-green-600 dark:text-green-400" : "text-gray-500 dark:text-gray-400"
                      )}
                    />
                    {sidebarOpen && <span>{item.name}</span>}
                  </Link>
                </li>
              )
            })}
          </ul>
        </nav>

        {/* Bottom navigation */}
        <div className="border-t border-gray-200 dark:border-gray-700 py-4">
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
                        ? "bg-green-50 dark:bg-green-900/30 text-green-700 dark:text-green-400"
                        : "text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                    )}
                    title={!sidebarOpen ? item.name : undefined}
                  >
                    <item.icon
                      className={cn(
                        "h-5 w-5 shrink-0",
                        isActive ? "text-green-600 dark:text-green-400" : "text-gray-500 dark:text-gray-400"
                      )}
                    />
                    {sidebarOpen && <span>{item.name}</span>}
                  </Link>
                </li>
              )
            })}
          </ul>
        </div>
      </aside>
    </>
  )
}

'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import { useAlertesStore } from '@/lib/store'
import {
  LayoutDashboard,
  MapPin,
  Bell,
  ShoppingCart,
  User,
} from 'lucide-react'
import { Badge } from '@/components/ui/badge'

const navigation = [
  { name: 'Accueil', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Parcelles', href: '/parcelles', icon: MapPin },
  { name: 'Alertes', href: '/alertes', icon: Bell },
  { name: 'Marché', href: '/marketplace', icon: ShoppingCart },
  { name: 'Profil', href: '/profil', icon: User },
]

export function BottomNav() {
  const pathname = usePathname()
  const { unreadCount } = useAlertesStore()

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 lg:hidden">
      <ul className="flex items-center justify-around">
        {navigation.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + '/')
          const isAlertTab = item.href === '/alertes'

          return (
            <li key={item.name}>
              <Link
                href={item.href}
                className={cn(
                  "flex flex-col items-center gap-1 px-3 py-2 text-xs font-medium transition-colors",
                  isActive
                    ? "text-green-600 dark:text-green-400"
                    : "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
                )}
              >
                <div className="relative">
                  <item.icon
                    className={cn(
                      "h-5 w-5",
                      isActive ? "text-green-600 dark:text-green-400" : "text-gray-500 dark:text-gray-400"
                    )}
                  />
                  {isAlertTab && unreadCount > 0 && (
                    <Badge
                      variant="danger"
                      className="absolute -top-2 -right-2 h-4 w-4 flex items-center justify-center p-0 text-[10px]"
                    >
                      {unreadCount > 9 ? '9+' : unreadCount}
                    </Badge>
                  )}
                </div>
                <span>{item.name}</span>
              </Link>
            </li>
          )
        })}
      </ul>
    </nav>
  )
}

'use client'

import { useState, useEffect, useRef } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { 
  Bell, 
  Menu, 
  Search, 
  User,
  LogOut,
  Settings,
  Globe,
  Moon,
  Sun,
  ChevronDown,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useAuthStore, useUIStore, useAlertesStore } from '@/lib/store'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'

const languages = [
  { code: 'fr', name: 'Français' },
  { code: 'baoule', name: 'Baoulé' },
  { code: 'malinke', name: 'Malinké/Dioula' },
  { code: 'senoufo', name: 'Sénoufo' },
]

export function Header() {
  const router = useRouter()
  const { user, logout } = useAuthStore()
  const { sidebarOpen, setSidebarOpen, language, setLanguage, theme, setTheme } = useUIStore()
  const { unreadCount } = useAlertesStore()
  const [searchQuery, setSearchQuery] = useState('')
  const [showSearch, setShowSearch] = useState(false)
  const searchRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (showSearch && searchRef.current) {
      searchRef.current.focus()
    }
  }, [showSearch])

  const handleLogout = () => {
    logout()
    router.push('/login')
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      router.push(`/search?q=${encodeURIComponent(searchQuery)}`)
    }
  }

  const getInitials = (nom: string, prenoms: string) => {
    return `${nom?.[0] || ''}${prenoms?.[0] || ''}`.toUpperCase()
  }

  return (
    <header className="sticky top-0 z-40 flex h-16 items-center justify-between border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 px-4 lg:px-6">
      {/* Left section */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="flex items-center justify-center h-10 w-10 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 lg:hidden"
          aria-label="Toggle menu"
        >
          <Menu className="h-5 w-5 text-gray-600 dark:text-gray-300" />
        </button>

        {/* Search */}
        <form onSubmit={handleSearch} className="hidden md:flex">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Rechercher..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="h-10 w-64 rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 dark:text-white pl-10 pr-4 text-sm focus:border-green-500 focus:outline-none focus:ring-1 focus:ring-green-500"
            />
          </div>
        </form>

        {/* Mobile search toggle */}
        <button
          onClick={() => setShowSearch(!showSearch)}
          className="flex items-center justify-center h-10 w-10 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 md:hidden"
          aria-label="Toggle search"
        >
          <Search className="h-5 w-5 text-gray-600" />
        </button>
      </div>

      {/* Right section */}
      <div className="flex items-center gap-2">
        {/* Language selector */}
        <DropdownMenu>
          <DropdownMenuTrigger className="flex items-center gap-1 px-3 py-2 rounded-lg hover:bg-gray-100">
            <Globe className="h-4 w-4 text-gray-600" />
            <span className="hidden sm:inline text-sm font-medium text-gray-700">
              {languages.find(l => l.code === language)?.name || 'Français'}
            </span>
            <ChevronDown className="h-4 w-4 text-gray-400" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>Langue</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {languages.map((lang) => (
              <DropdownMenuItem
                key={lang.code}
                onClick={() => setLanguage(lang.code as 'fr' | 'baoule' | 'malinke' | 'senoufo')}
                className={cn(language === lang.code && "bg-green-50 text-green-700")}
              >
                {lang.name}
              </DropdownMenuItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Theme toggle */}
        <button
          onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')}
          className="flex items-center justify-center h-10 w-10 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          {theme === 'light' ? (
            <Moon className="h-5 w-5 text-gray-600 dark:text-gray-300" />
          ) : (
            <Sun className="h-5 w-5 text-yellow-500" />
          )}
        </button>

        {/* Notifications */}
        <Link
          href="/alertes"
          className="relative flex items-center justify-center h-10 w-10 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
        >
          <Bell className="h-5 w-5 text-gray-600 dark:text-gray-300" />
          {unreadCount > 0 && (
            <Badge
              variant="danger"
              className="absolute -top-1 -right-1 h-5 w-5 flex items-center justify-center p-0 text-xs"
            >
              {unreadCount > 9 ? '9+' : unreadCount}
            </Badge>
          )}
        </Link>

        {/* User menu */}
        <DropdownMenu>
          <DropdownMenuTrigger className="flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700">
            <Avatar className="h-8 w-8">
              <AvatarImage src="" />
              <AvatarFallback>
                {user ? getInitials(user.nom, user.prenom || user.prenoms || '') : 'U'}
              </AvatarFallback>
            </Avatar>
            <div className="hidden md:block text-left">
              <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                {user ? `${user.prenom || user.prenoms || ''} ${user.nom}` : 'Utilisateur'}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400 capitalize">
                {user?.role || 'Producteur'}
              </p>
            </div>
            <ChevronDown className="hidden md:block h-4 w-4 text-gray-400" />
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56 dark:bg-gray-800 dark:border-gray-700">
            <DropdownMenuLabel className="dark:text-gray-200">Mon compte</DropdownMenuLabel>
            <DropdownMenuSeparator className="dark:bg-gray-700" />
            <DropdownMenuItem asChild className="dark:text-gray-300 dark:focus:bg-gray-700">
              <Link href="/profil" className="flex items-center gap-2 cursor-pointer">
                <User className="h-4 w-4" />
                <span>Profil</span>
              </Link>
            </DropdownMenuItem>
            <DropdownMenuItem asChild className="dark:text-gray-300 dark:focus:bg-gray-700">
              <Link href="/settings" className="flex items-center gap-2 cursor-pointer">
                <Settings className="h-4 w-4" />
                <span>Paramètres</span>
              </Link>
            </DropdownMenuItem>
            <DropdownMenuSeparator className="dark:bg-gray-700" />
            <DropdownMenuItem
              onClick={handleLogout}
              className="text-red-600 focus:text-red-600 focus:bg-red-50 dark:text-red-400 dark:focus:text-red-400 dark:focus:bg-red-900/20"
            >
              <LogOut className="h-4 w-4 mr-2" />
              <span>Déconnexion</span>
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* Mobile search overlay */}
      {showSearch && (
        <div className="absolute inset-x-0 top-full bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 p-4 md:hidden">
          <form onSubmit={handleSearch}>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <input
                ref={searchRef}
                type="text"
                placeholder="Rechercher..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="h-10 w-full rounded-lg border border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 pl-10 pr-4 text-sm dark:text-gray-200 focus:border-green-500 focus:outline-none focus:ring-1 focus:ring-green-500"
              />
            </div>
          </form>
        </div>
      )}
    </header>
  )
}

import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatDate(date: string | Date | null | undefined): string {
  if (!date) return 'N/A'
  try {
    const d = new Date(date)
    if (isNaN(d.getTime())) return 'Date invalide'
    return d.toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    })
  } catch {
    return 'Date invalide'
  }
}

export function formatDateTime(date: string | Date | null | undefined): string {
  if (!date) return 'N/A'
  try {
    const d = new Date(date)
    if (isNaN(d.getTime())) return 'Date invalide'
    return d.toLocaleString('fr-FR', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  } catch {
    return 'Date invalide'
  }
}

/**
 * Safe date handling - returns valid Date or null
 */
export function safeDate(date: string | Date | null | undefined): Date | null {
  if (!date) return null
  try {
    const d = new Date(date)
    return isNaN(d.getTime()) ? null : d
  } catch {
    return null
  }
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'XOF',
    minimumFractionDigits: 0,
  }).format(amount)
}

export function formatNumber(num: number, decimals: number = 2): string {
  return num.toFixed(decimals)
}

export function getStatusColor(status: string): string {
  const colors: Record<string, string> = {
    // Statuts généraux
    actif: 'bg-green-100 text-green-800',
    active: 'bg-green-100 text-green-800',
    inactif: 'bg-gray-100 text-gray-800',
    inactive: 'bg-gray-100 text-gray-800',
    maintenance: 'bg-yellow-100 text-yellow-800',
    defaillant: 'bg-red-100 text-red-800',
    
    // Alertes
    critique: 'bg-red-100 text-red-800',
    important: 'bg-orange-100 text-orange-800',
    info: 'bg-blue-100 text-blue-800',
    
    // Sol
    bon: 'bg-green-100 text-green-800',
    moyen: 'bg-yellow-100 text-yellow-800',
    mauvais: 'bg-red-100 text-red-800',
  }
  return colors[status.toLowerCase()] || 'bg-gray-100 text-gray-800'
}

export function getSoilQualityIndicator(value: number, type: 'humidite' | 'ph' | 'temperature'): {
  status: 'bon' | 'moyen' | 'mauvais'
  color: string
  message: string
} {
  switch (type) {
    case 'humidite':
      if (value < 20) return { status: 'mauvais', color: 'text-red-500', message: 'Sol trop sec' }
      if (value > 80) return { status: 'mauvais', color: 'text-red-500', message: 'Sol trop humide' }
      if (value < 40 || value > 70) return { status: 'moyen', color: 'text-yellow-500', message: 'Humidité acceptable' }
      return { status: 'bon', color: 'text-green-500', message: 'Humidité optimale' }
    
    case 'ph':
      if (value < 4.5 || value > 8.5) return { status: 'mauvais', color: 'text-red-500', message: 'pH critique' }
      if (value < 5.5 || value > 7.5) return { status: 'moyen', color: 'text-yellow-500', message: 'pH acceptable' }
      return { status: 'bon', color: 'text-green-500', message: 'pH optimal' }
    
    case 'temperature':
      if (value < 10 || value > 45) return { status: 'mauvais', color: 'text-red-500', message: 'Température extrême' }
      if (value < 18 || value > 35) return { status: 'moyen', color: 'text-yellow-500', message: 'Température acceptable' }
      return { status: 'bon', color: 'text-green-500', message: 'Température optimale' }
    
    default:
      return { status: 'moyen', color: 'text-gray-500', message: '' }
  }
}

export function truncate(str: string, length: number): string {
  if (str.length <= length) return str
  return str.slice(0, length) + '...'
}

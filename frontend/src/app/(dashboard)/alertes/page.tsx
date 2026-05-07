'use client'

import { useEffect, useState, useCallback } from 'react'
import {
  Bell,
  AlertTriangle,
  AlertCircle,
  Info,
  CheckCircle,
  Search,
  MapPin,
  Clock,
  Eye,
  Check,
} from 'lucide-react'
import {
  Card,
  CardContent,
  Button,
  Input,
  Badge,
  Skeleton,
  Tabs,
  TabsList,
  TabsTrigger,
} from '@/components/ui'
import { cn, safeDate } from '@/lib/utils'
import { useAlertesStore, Alerte } from '@/lib/store'
import api from '@/lib/api'
import toast from 'react-hot-toast'
import { format } from 'date-fns'
import { fr } from 'date-fns/locale'

export default function AlertesPage() {
  const { alertes, setAlertes, markAsRead, setUnreadCount } = useAlertesStore()
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [filter, setFilter] = useState<'all' | 'unread' | 'read'>('all')
  const [markingAsRead, setMarkingAsRead] = useState<string | null>(null)

  const fetchAlertes = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get('/alertes')
      if (response.data.success) {
        setAlertes(response.data.data)
        const isAlertUnread = (a: Alerte) => {
          const s = (a.status || '').toUpperCase()
          return s !== 'LUE' && s !== 'TRAITEE' && !a.lu_at
        }
        setUnreadCount(response.data.data.filter(isAlertUnread).length)
      }
    } catch (error) {
      console.error('Error fetching alertes:', error)
      toast.error('Erreur lors du chargement des alertes')
    } finally {
      setLoading(false)
    }
  }, [setAlertes, setUnreadCount])

  useEffect(() => {
    fetchAlertes()
  }, [fetchAlertes])

  const handleMarkAsRead = async (id: string) => {
    setMarkingAsRead(id)
    try {
      const response = await api.put(`/alertes/${id}/read`)
      if (response.data.success) {
        markAsRead(id)
        toast.success('Alerte marquée comme lue')
      }
    } catch (error) {
      console.error('Error marking alert as read:', error)
      toast.error('Erreur lors de la mise à jour')
    } finally {
      setMarkingAsRead(null)
    }
  }

  const handleMarkAllAsRead = async () => {
    try {
      // Mark all unread alerts as read
      const isUnread = (a: Alerte) => {
        const s = (a.status || '').toUpperCase()
        return s !== 'LUE' && s !== 'TRAITEE' && !a.lu_at
      }
      const unreadAlertes = alertes.filter(isUnread)
      for (const alerte of unreadAlertes) {
        await api.put(`/alertes/${alerte.id}/read`)
        markAsRead(alerte.id)
      }
      toast.success('Toutes les alertes ont été marquées comme lues')
    } catch (error) {
      console.error('Error marking all alerts as read:', error)
      toast.error('Erreur lors de la mise à jour')
    }
  }

  const filteredAlertes = alertes.filter(a => {
    const matchesSearch = a.titre.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.message.toLowerCase().includes(searchQuery.toLowerCase())
    
    // Filter by read status using statut field (NOUVELLE = unread, LUE/TRAITEE = read)
    const isRead = a.status === 'lue' || a.status === 'LUE' || a.status === 'TRAITEE' || a.lu_at
    const matchesFilter = filter === 'all' || 
      (filter === 'unread' && !isRead) || 
      (filter === 'read' && isRead)
    return matchesSearch && matchesFilter
  })

  const getAlertIcon = (niveau: string) => {
    switch (niveau?.toLowerCase()) {
      case 'critique':
        return <AlertCircle className="h-5 w-5 text-red-500" />
      case 'important':
        return <AlertTriangle className="h-5 w-5 text-orange-500" />
      default:
        return <Info className="h-5 w-5 text-blue-500" />
    }
  }

  const getAlertBgColor = (niveau: string, status: string) => {
    const isRead = status === 'lue' || status === 'LUE' || status === 'TRAITEE'
    if (isRead) {
      return 'bg-gray-50 border-gray-200'
    }
    switch (niveau?.toLowerCase()) {
      case 'critique':
        return 'bg-red-50 border-red-200'
      case 'important':
        return 'bg-orange-50 border-orange-200'
      default:
        return 'bg-blue-50 border-blue-200'
    }
  }

  const getNiveauBadge = (niveau: string) => {
    switch (niveau?.toLowerCase()) {
      case 'critique':
        return <Badge variant="danger">Critique</Badge>
      case 'important':
        return <Badge variant="warning">Important</Badge>
      default:
        return <Badge variant="info">Info</Badge>
    }
  }

  const unreadCount = alertes.filter(a => {
    const isRead = a.status === 'lue' || a.status === 'LUE' || a.status === 'TRAITEE' || a.lu_at
    return !isRead
  }).length

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Bell className="h-6 w-6 text-green-600" />
            Alertes
          </h1>
          <p className="text-gray-500">
            Gérez vos alertes et notifications
          </p>
        </div>
        {unreadCount > 0 && (
          <Button variant="outline" onClick={handleMarkAllAsRead}>
            <Check className="h-4 w-4 mr-2" />
            Tout marquer comme lu ({unreadCount})
          </Button>
        )}
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-red-100 flex items-center justify-center">
              <AlertCircle className="h-5 w-5 text-red-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {alertes.filter(a => a.niveau?.toLowerCase() === 'critique').length}
              </p>
              <p className="text-sm text-gray-500">Critiques</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-orange-100 flex items-center justify-center">
              <AlertTriangle className="h-5 w-5 text-orange-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {alertes.filter(a => a.niveau?.toLowerCase() === 'important').length}
              </p>
              <p className="text-sm text-gray-500">Importantes</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
              <Info className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {alertes.filter(a => a.niveau?.toLowerCase() === 'info').length}
              </p>
              <p className="text-sm text-gray-500">Informations</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Rechercher une alerte..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <Tabs value={filter} onValueChange={(v) => setFilter(v as typeof filter)} className="w-full sm:w-auto">
          <TabsList>
            <TabsTrigger value="all">Toutes</TabsTrigger>
            <TabsTrigger value="unread">Non lues</TabsTrigger>
            <TabsTrigger value="lue">Lues</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {/* Alertes list */}
      <div className="space-y-3">
        {loading ? (
          <>
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
            <Skeleton className="h-24 w-full" />
          </>
        ) : filteredAlertes.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <CheckCircle className="h-12 w-12 mx-auto text-green-500 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {searchQuery ? 'Aucune alerte trouvée' : 'Aucune alerte'}
              </h3>
              <p className="text-gray-500">
                {searchQuery
                  ? 'Essayez avec d\'autres termes de recherche'
                  : 'Vous n\'avez aucune alerte pour le moment'
                }
              </p>
            </CardContent>
          </Card>
        ) : (
          filteredAlertes.map((alerte) => (
            <Card
              key={alerte.id}
              className={cn(
                "border transition-colors",
                getAlertBgColor(alerte.niveau, alerte.status)
              )}
            >
              <CardContent className="p-4">
                <div className="flex items-start gap-4">
                  <div className="shrink-0 mt-1">
                    {getAlertIcon(alerte.niveau)}
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className={cn(
                        "font-semibold",
                        alerte.status === 'lue' ? 'text-gray-600' : 'text-gray-900'
                      )}>
                        {alerte.titre}
                      </h3>
                      {getNiveauBadge(alerte.niveau)}
                      {(() => {
                        const s = (alerte.status || '').toUpperCase()
                        const isUnread = s !== 'LUE' && s !== 'TRAITEE' && !alerte.lu_at
                        return isUnread ? <span className="inline-flex h-2 w-2 rounded-full bg-green-500" /> : null
                      })()}
                    </div>

                    <p className={cn(
                      "text-sm mb-2",
                      alerte.status === 'lue' ? 'text-gray-500' : 'text-gray-700'
                    )}>
                      {alerte.message}
                    </p>

                    <div className="flex flex-wrap items-center gap-4 text-xs text-gray-500">
                      <div className="flex items-center gap-1">
                        <Clock className="h-3 w-3" />
                        {(() => {
                          const date = safeDate(alerte.created_at)
                          return date 
                            ? format(date, 'dd MMM yyyy à HH:mm', { locale: fr })
                            : 'Date non disponible'
                        })()}
                      </div>
                      {alerte.parcelle_nom && (
                        <div className="flex items-center gap-1">
                          <MapPin className="h-3 w-3" />
                          {alerte.parcelle_nom}
                        </div>
                      )}
                      <Badge variant="secondary" className="text-xs">
                        {alerte.categorie}
                      </Badge>
                    </div>
                  </div>

                  {(() => {
                    const s = (alerte.status || '').toUpperCase()
                    return s !== 'LUE' && s !== 'TRAITEE' && !alerte.lu_at
                  })() && (
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleMarkAsRead(alerte.id)}
                      disabled={markingAsRead === alerte.id}
                    >
                      {markingAsRead === alerte.id ? (
                        <span className="animate-spin h-4 w-4 border-2 border-gray-400 border-t-transparent rounded-full" />
                      ) : (
                        <Eye className="h-4 w-4" />
                      )}
                    </Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>
    </div>
  )
}

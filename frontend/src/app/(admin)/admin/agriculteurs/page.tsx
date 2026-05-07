'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import {
  Users,
  Search,
  Filter,
  Eye,
  MapPin,
  Thermometer,
  Calendar,
  Phone,
  Mail,
  ChevronRight,
  RefreshCw,
} from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import api from '@/lib/api'
import { logger } from '@/lib/logger'

interface Agriculteur {
  id: string
  nom: string
  prenoms: string
  telephone: string
  email: string
  role: string
  status: string
  created_at: string
  derniere_connexion: string | null
  parcelles_count?: number
  capteurs_count?: number
  nb_parcelles?: number
  superficie_totale?: number
}

interface Parcelle {
  id: string
  nom: string
  user_id: string
}

interface Capteur {
  id: string
  parcelle_id: string
}

export default function AgriculteursPage() {
  const [agriculteurs, setAgriculteurs] = useState<Agriculteur[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    setLoading(true)
    try {
      const [usersRes, parcellesRes, capteursRes] = await Promise.all([
        api.get('/users/producteurs'),
        api.get('/parcelles').catch(() => ({ data: { data: [] } })),
        api.get('/capteurs').catch(() => ({ data: { data: [] } })),
      ])

      const users = usersRes.data?.data || []
      const parcellesData = parcellesRes.data?.data || []
      const capteursData = capteursRes.data?.data || []

      // Les producteurs sont déjà filtrés par l'API
      const agriculteursList = users
        .map((u: Agriculteur) => ({
          ...u,
          parcelles_count: u.nb_parcelles || parcellesData.filter((p: Parcelle) => p.user_id === u.id).length,
          capteurs_count: parcellesData
            .filter((p: Parcelle) => p.user_id === u.id)
            .reduce((acc: number, p: Parcelle) => {
              return acc + capteursData.filter((c: Capteur) => c.parcelle_id === p.id).length
            }, 0),
        }))

      setAgriculteurs(agriculteursList)
    } catch (error) {
      logger.error('Erreur chargement agriculteurs admin', error instanceof Error ? error : undefined)
      setAgriculteurs([])
    } finally {
      setLoading(false)
    }
  }


  const filteredAgriculteurs = agriculteurs.filter((a) => {
    const matchesSearch =
      a.nom.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.prenoms.toLowerCase().includes(searchQuery.toLowerCase()) ||
      a.telephone.includes(searchQuery) ||
      a.email?.toLowerCase().includes(searchQuery.toLowerCase())

    const normalizedStatus = String(a.status || '').toLowerCase()
    const matchesStatus = statusFilter === 'all' || normalizedStatus === statusFilter

    return matchesSearch && matchesStatus
  })

  const getStatusBadge = (status: string) => {
    switch (String(status || '').toLowerCase()) {
      case 'actif':
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">Actif</Badge>
      case 'inactif':
        return <Badge className="bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">Inactif</Badge>
      case 'suspendu':
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">Suspendu</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
            Gestion des Agriculteurs
          </h2>
          <p className="text-gray-500 dark:text-gray-400">
            {agriculteurs.length} agriculteurs enregistrés
          </p>
        </div>
        <Button onClick={fetchData} variant="outline" className="dark:border-gray-600 dark:text-gray-300">
          <RefreshCw className="h-4 w-4 mr-2" />
          Actualiser
        </Button>
      </div>

      {/* Filters */}
      <Card className="dark:bg-gray-800 dark:border-gray-700">
        <CardContent className="p-4">
          <div className="flex flex-col md:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Rechercher par nom, téléphone, email..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10 dark:bg-gray-700 dark:border-gray-600 dark:text-white"
              />
            </div>
            <div className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-gray-400" />
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-2 rounded-lg border border-gray-200 dark:border-gray-600 dark:bg-gray-700 dark:text-white text-sm"
                title="Filtrer par statut"
                aria-label="Filtrer par statut"
              >
                <option value="all">Tous les statuts</option>
                <option value="actif">Actif</option>
                <option value="inactif">Inactif</option>
                <option value="suspendu">Suspendu</option>
              </select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Agriculteurs List */}
      <div className="grid gap-4">
        {filteredAgriculteurs.length > 0 ? (
          filteredAgriculteurs.map((agriculteur) => (
            <Card key={agriculteur.id} className="dark:bg-gray-800 dark:border-gray-700 hover:shadow-lg transition-shadow">
              <CardContent className="p-6">
                <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
                  <div className="flex items-start gap-4">
                    <div className="h-14 w-14 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center shrink-0">
                      <span className="text-xl font-bold text-blue-600 dark:text-blue-400">
                        {agriculteur.nom.charAt(0)}
                      </span>
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                        {agriculteur.prenoms} {agriculteur.nom}
                      </h3>
                      <div className="flex flex-wrap items-center gap-4 mt-2 text-sm text-gray-500 dark:text-gray-400">
                        <span className="flex items-center gap-1">
                          <Phone className="h-4 w-4" />
                          {agriculteur.telephone}
                        </span>
                        {agriculteur.email && (
                          <span className="flex items-center gap-1">
                            <Mail className="h-4 w-4" />
                            {agriculteur.email}
                          </span>
                        )}
                        <span className="flex items-center gap-1">
                          <Calendar className="h-4 w-4" />
                          Inscrit le {(() => {
                            if (!agriculteur.created_at) return 'Date inconnue'
                            const date = new Date(agriculteur.created_at)
                            return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleDateString('fr-FR')
                          })()}
                        </span>
                      </div>
                      <div className="flex items-center gap-4 mt-3">
                        {getStatusBadge(agriculteur.status)}
                        <span className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400">
                          <MapPin className="h-4 w-4 text-green-500" />
                          {agriculteur.parcelles_count || 0} parcelles
                        </span>
                        <span className="flex items-center gap-1 text-sm text-gray-600 dark:text-gray-400">
                          <Thermometer className="h-4 w-4 text-purple-500" />
                          {agriculteur.capteurs_count || 0} capteurs
                        </span>
                      </div>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Link href={`/admin/agriculteurs/${agriculteur.id}`}>
                      <Button variant="outline" className="dark:border-gray-600 dark:text-gray-300">
                        <Eye className="h-4 w-4 mr-2" />
                        Voir détails
                        <ChevronRight className="h-4 w-4 ml-2" />
                      </Button>
                    </Link>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        ) : (
          <Card className="dark:bg-gray-800 dark:border-gray-700">
            <CardContent className="p-12 text-center">
              <Users className="h-16 w-16 mx-auto text-gray-300 dark:text-gray-600 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                Aucun agriculteur trouvé
              </h3>
              <p className="text-gray-500 dark:text-gray-400">
                {searchQuery || statusFilter !== 'all'
                  ? 'Essayez de modifier vos critères de recherche'
                  : 'Aucun agriculteur n\'est encore enregistré'}
              </p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-gray-900 dark:text-white">
              {agriculteurs.length}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Total agriculteurs</p>
          </CardContent>
        </Card>
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-green-600 dark:text-green-400">
              {agriculteurs.filter(a => String(a.status || '').toLowerCase() === 'actif').length}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Actifs</p>
          </CardContent>
        </Card>
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-blue-600 dark:text-blue-400">
              {agriculteurs.reduce((acc, a) => acc + (a.parcelles_count || 0), 0)}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Total parcelles</p>
          </CardContent>
        </Card>
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold text-purple-600 dark:text-purple-400">
              {agriculteurs.reduce((acc, a) => acc + (a.capteurs_count || 0), 0)}
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">Total capteurs</p>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

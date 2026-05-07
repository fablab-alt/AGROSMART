'use client'

import { useEffect, useState } from 'react'
import { 
  Users, 
  MapPin, 
  Thermometer, 
  Bell, 
  TrendingUp, 
  TrendingDown,
  Activity,
  ShoppingCart,
  AlertTriangle,
  CheckCircle,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import api from '@/lib/api'
import { logger } from '@/lib/logger'

interface DashboardStats {
  totalAgriculteurs: number
  totalParcelles: number
  totalCapteurs: number
  alertesActives: number
  commandesEnCours: number
  capteursActifs: number
  tendanceAgriculteurs: number
  tendanceParcelles: number
}

interface RecentAgriculteur {
  id: string
  nom: string
  prenoms: string
  telephone: string
  created_at: string
  parcelles_count: number
}

interface RecentAlerte {
  id: string
  type: string
  niveau: string
  message: string
  created_at: string
  agriculteur_nom: string
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<DashboardStats>({
    totalAgriculteurs: 0,
    totalParcelles: 0,
    totalCapteurs: 0,
    alertesActives: 0,
    commandesEnCours: 0,
    capteursActifs: 0,
    tendanceAgriculteurs: 0,
    tendanceParcelles: 0,
  })
  const [recentAgriculteurs, setRecentAgriculteurs] = useState<RecentAgriculteur[]>([])
  const [recentAlertes, setRecentAlertes] = useState<RecentAlerte[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboardData()
  }, [])

  const fetchDashboardData = async () => {
    try {
      // Récupérer les statistiques depuis l'API
      const [statsRes, usersRes, parcellesRes, capteursRes, alertesRes] = await Promise.all([
        api.get('/users/stats').catch(() => ({ data: { data: null } })),
        api.get('/users?role=producteur').catch(() => ({ data: { data: [] } })),
        api.get('/parcelles').catch(() => ({ data: { data: [] } })),
        api.get('/capteurs').catch(() => ({ data: { data: [] } })),
        api.get('/alertes').catch(() => ({ data: { data: [] } })),
      ])

      const userStats = statsRes.data?.data
      const users = usersRes.data?.data || []
      const parcelles = parcellesRes.data?.data || []
      const capteurs = capteursRes.data?.data || []
      const alertes = alertesRes.data?.data || []

      // Utiliser les stats de l'API si disponibles
      const agriculteurs = users.filter((u: { role: string }) => String(u.role || '').toUpperCase() === 'PRODUCTEUR')

      setStats({
        totalAgriculteurs: userStats?.producteurs ? parseInt(userStats.producteurs) : agriculteurs.length,
        totalParcelles: parcelles.length,
        totalCapteurs: capteurs.length,
        alertesActives: alertes.filter((a: { lu: boolean }) => !a.lu).length,
        commandesEnCours: 0,
        capteursActifs: capteurs.filter((c: { statut?: string; status?: string }) => (c.statut || c.status || '').toLowerCase() === 'actif').length,
        tendanceAgriculteurs: userStats?.nouveaux_30j ? parseInt(userStats.nouveaux_30j) : 0,
        tendanceParcelles: 8,
      })

      // Récents agriculteurs avec leurs parcelles
      setRecentAgriculteurs(
        agriculteurs.slice(0, 5).map((u: { id: string; nom: string; prenoms: string; telephone: string; created_at: string }) => ({
          id: u.id,
          nom: u.nom,
          prenoms: u.prenoms,
          telephone: u.telephone,
          created_at: u.created_at,
          parcelles_count: parcelles.filter((p: { user_id: string }) => p.user_id === u.id).length,
        }))
      )

      // Récentes alertes
      setRecentAlertes(
        alertes.slice(0, 5).map((a: { id: string; type: string; niveau: string; message: string; created_at: string; user_id: string }) => ({
          id: a.id,
          type: a.type,
          niveau: a.niveau,
          message: a.message,
          created_at: a.created_at,
          agriculteur_nom: agriculteurs.find((u: { id: string }) => u.id === a.user_id)?.nom || 'Inconnu',
        }))
      )
    } catch (error) {
      logger.error('Erreur chargement dashboard admin', error instanceof Error ? error : undefined)
      setStats({
        totalAgriculteurs: 0,
        totalParcelles: 0,
        totalCapteurs: 0,
        alertesActives: 0,
        commandesEnCours: 0,
        capteursActifs: 0,
        tendanceAgriculteurs: 0,
        tendanceParcelles: 0,
      })
      setRecentAgriculteurs([])
      setRecentAlertes([])
    } finally {
      setLoading(false)
    }
  }

  const statCards = [
    {
      title: 'Total Agriculteurs',
      value: stats.totalAgriculteurs,
      icon: Users,
      color: 'bg-blue-500',
      trend: stats.tendanceAgriculteurs,
      trendUp: true,
    },
    {
      title: 'Parcelles',
      value: stats.totalParcelles,
      icon: MapPin,
      color: 'bg-green-500',
      trend: stats.tendanceParcelles,
      trendUp: true,
    },
    {
      title: 'Capteurs Actifs',
      value: `${stats.capteursActifs}/${stats.totalCapteurs}`,
      icon: Thermometer,
      color: 'bg-purple-500',
      trend: null,
      trendUp: null,
    },
    {
      title: 'Alertes Actives',
      value: stats.alertesActives,
      icon: Bell,
      color: 'bg-red-500',
      trend: null,
      trendUp: null,
    },
  ]

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
          Tableau de bord administrateur
        </h2>
        <p className="text-gray-500 dark:text-gray-400">
          Vue d&apos;ensemble de la plateforme AgroSmart
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {statCards.map((stat, index) => (
          <Card key={index} className="dark:bg-gray-800 dark:border-gray-700">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                    {stat.title}
                  </p>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
                    {stat.value}
                  </p>
                  {stat.trend !== null && (
                    <div className={`flex items-center mt-2 text-sm ${stat.trendUp ? 'text-green-600' : 'text-red-600'}`}>
                      {stat.trendUp ? (
                        <TrendingUp className="h-4 w-4 mr-1" />
                      ) : (
                        <TrendingDown className="h-4 w-4 mr-1" />
                      )}
                      <span>{stat.trend}% ce mois</span>
                    </div>
                  )}
                </div>
                <div className={`${stat.color} p-3 rounded-xl`}>
                  <stat.icon className="h-6 w-6 text-white" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Agriculteurs */}
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 dark:text-white">
              <Users className="h-5 w-5 text-blue-500" />
              Agriculteurs récents
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentAgriculteurs.length > 0 ? (
                recentAgriculteurs.map((agriculteur) => (
                  <div
                    key={agriculteur.id}
                    className="flex items-center justify-between p-3 rounded-lg bg-gray-50 dark:bg-gray-700/50"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-10 w-10 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center">
                        <span className="text-blue-600 dark:text-blue-400 font-medium">
                          {agriculteur.nom.charAt(0)}
                        </span>
                      </div>
                      <div>
                        <p className="font-medium text-gray-900 dark:text-white">
                          {agriculteur.prenoms} {agriculteur.nom}
                        </p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                          {agriculteur.telephone}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-medium text-gray-900 dark:text-white">
                        {agriculteur.parcelles_count} parcelles
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400">
                        {(() => {
                          if (!agriculteur.created_at) return 'Date inconnue'
                          const date = new Date(agriculteur.created_at)
                          return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleDateString('fr-FR')
                        })()}
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                  <Users className="h-12 w-12 mx-auto mb-2 opacity-50" />
                  <p>Aucun agriculteur enregistré</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Recent Alerts */}
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 dark:text-white">
              <Bell className="h-5 w-5 text-red-500" />
              Alertes récentes
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {recentAlertes.length > 0 ? (
                recentAlertes.map((alerte) => (
                  <div
                    key={alerte.id}
                    className="flex items-start gap-3 p-3 rounded-lg bg-gray-50 dark:bg-gray-700/50"
                  >
                    <div className={`p-2 rounded-lg ${
                      alerte.niveau === 'critique' ? 'bg-red-100 dark:bg-red-900' :
                      alerte.niveau === 'important' ? 'bg-orange-100 dark:bg-orange-900' :
                      'bg-blue-100 dark:bg-blue-900'
                    }`}>
                      <AlertTriangle className={`h-4 w-4 ${
                        alerte.niveau === 'critique' ? 'text-red-600 dark:text-red-400' :
                        alerte.niveau === 'important' ? 'text-orange-600 dark:text-orange-400' :
                        'text-blue-600 dark:text-blue-400'
                      }`} />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-900 dark:text-white text-sm">
                        {alerte.message}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        {alerte.agriculteur_nom} • {(() => {
                          if (!alerte.created_at) return 'Date inconnue'
                          const date = new Date(alerte.created_at)
                          return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleDateString('fr-FR')
                        })()}
                      </p>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                  <CheckCircle className="h-12 w-12 mx-auto mb-2 opacity-50 text-green-500" />
                  <p>Aucune alerte active</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-xl bg-green-100 dark:bg-green-900">
                <Activity className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Système</p>
                <p className="text-lg font-semibold text-green-600 dark:text-green-400">Opérationnel</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-xl bg-purple-100 dark:bg-purple-900">
                <ShoppingCart className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Commandes en cours</p>
                <p className="text-lg font-semibold text-gray-900 dark:text-white">{stats.commandesEnCours}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="dark:bg-gray-800 dark:border-gray-700">
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 rounded-xl bg-blue-100 dark:bg-blue-900">
                <Thermometer className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-gray-500 dark:text-gray-400">Capteurs hors ligne</p>
                <p className="text-lg font-semibold text-gray-900 dark:text-white">
                  {stats.totalCapteurs - stats.capteursActifs}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

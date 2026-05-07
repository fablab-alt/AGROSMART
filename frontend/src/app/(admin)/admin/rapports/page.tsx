'use client'

import { useEffect, useState } from 'react'
import {
  BarChart3,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Activity,
  Database,
  RefreshCw,
  Download,
  Calendar,
  Filter,
  Eye,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  Cell,
} from 'recharts'
import api from '@/lib/api'
import { logger } from '@/lib/logger'

interface QualityMetric {
  name: string
  score: number
  status: 'good' | 'warning' | 'critical'
  details: string
}

interface DataAnomaly {
  id: string
  type: string
  capteur: string
  date: string
  valeur: number
  valeur_attendue: string
  status: 'nouvelle' | 'en_cours' | 'resolue'
}

interface SystemHealth {
  component: string
  status: 'operational' | 'degraded' | 'down'
  uptime: number
  lastCheck: string
}

export default function AdminRapportsPage() {
  const [loading, setLoading] = useState(true)
  const [selectedPeriod, setSelectedPeriod] = useState('7')
  const [qualityMetrics, setQualityMetrics] = useState<QualityMetric[]>([])
  const [anomalies, setAnomalies] = useState<DataAnomaly[]>([])
  const [systemHealth, setSystemHealth] = useState<SystemHealth[]>([])
  const [dataVolume, setDataVolume] = useState<{ jour: string; mesures: number; alertes: number }[]>([])

  /* eslint-disable @typescript-eslint/no-explicit-any */
  useEffect(() => {
    fetchData()
  }, [selectedPeriod])

  const fetchData = async () => {
    setLoading(true)
    try {
      const [alertesRes, statsRes, capteursStatsRes, mesuresStatsRes, dashboardRes] = await Promise.all([
        api.get('/alertes'),
        api.get('/analytics/stats').catch(() => ({ data: { data: {} } })),
        api.get('/capteurs/stats').catch(() => ({ data: { data: {} } })),
        api.get('/mesures/stats').catch(() => ({ data: { data: {} } })),
        api.get('/dashboard/stats').catch(() => ({ data: { data: {} } })),
      ])

      const alertes = alertesRes.data?.data || []
      const analyticsStats = statsRes.data?.data || {}
      const capteursStats = capteursStatsRes.data?.data || {}
      const mesuresStats = mesuresStatsRes.data?.data || {}
      const dashboardStats = dashboardRes.data?.data || {}

      // Map Alertes to Anomalies interface for compatibility
      const anomaliesData = alertes.map((a: any) => {
        let dateStr = 'Date invalide';
        const sourceDate = a.date_creation || a.created_at
        if (sourceDate) {
          const date = new Date(sourceDate);
          dateStr = isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleString('fr-FR');
        }
        return {
          id: a.id,
          type: a.type,
          capteur: a.parcelle_nom || 'Système',
          date: dateStr,
          valeur: 0, // Pas toujours pertinent pour une alerte générique
          valeur_attendue: '-',
          status: String(a.statut || '').toUpperCase() === 'TRAITEE' ? 'resolue' : 'nouvelle'
        };
      });
      setAnomalies(anomaliesData)

      const totalAlertes = Number(alertes.length || 0)
      const unresolvedAlertes = alertes.filter((a: any) => String(a.statut || '').toUpperCase() !== 'TRAITEE').length
      const capteursTotal = Number(capteursStats.total || 0)
      const capteursActifs = Number(capteursStats.actifs || 0)
      const mesures24h = Number(mesuresStats.mesures_24h || 0)
      const totalMesures = Number(mesuresStats.total_mesures || 0)

      const sensorAvailability = capteursTotal > 0 ? (capteursActifs / capteursTotal) * 100 : 0
      const alertQuality = totalAlertes > 0 ? ((totalAlertes - unresolvedAlertes) / totalAlertes) * 100 : 100
      const ingestionQuality = totalMesures > 0 ? Math.min(100, (mesures24h / totalMesures) * 1000) : 0

      const mappedMetrics: QualityMetric[] = [
        {
          name: 'Disponibilité capteurs',
          score: Number(sensorAvailability.toFixed(1)),
          status: sensorAvailability >= 85 ? 'good' : sensorAvailability >= 60 ? 'warning' : 'critical',
          details: `${capteursActifs}/${capteursTotal} capteurs actifs`,
        },
        {
          name: 'Résolution des alertes',
          score: Number(alertQuality.toFixed(1)),
          status: alertQuality >= 85 ? 'good' : alertQuality >= 60 ? 'warning' : 'critical',
          details: `${totalAlertes - unresolvedAlertes}/${totalAlertes} alertes traitées`,
        },
        {
          name: 'Fraîcheur des mesures',
          score: Number(ingestionQuality.toFixed(1)),
          status: ingestionQuality >= 70 ? 'good' : ingestionQuality >= 40 ? 'warning' : 'critical',
          details: `${mesures24h} mesures sur les dernières 24h`,
        },
      ]
      setQualityMetrics(mappedMetrics)

      const mappedSystemHealth: SystemHealth[] = [
        {
          component: 'API Backend',
          status: dashboardStats.utilisateursTotal !== undefined ? 'operational' : 'degraded',
          uptime: 99,
          lastCheck: new Date().toISOString(),
        },
        {
          component: 'Collecte IoT',
          status: capteursActifs > 0 ? 'operational' : 'degraded',
          uptime: capteursTotal > 0 ? Math.round(sensorAvailability) : 0,
          lastCheck: new Date().toISOString(),
        },
        {
          component: 'Moteur Analytics',
          status: analyticsStats.production_mensuelle ? 'operational' : 'degraded',
          uptime: analyticsStats.production_mensuelle ? 98 : 70,
          lastCheck: new Date().toISOString(),
        },
      ]
      setSystemHealth(mappedSystemHealth)

      const monthlyProduction = Array.isArray(analyticsStats.production_mensuelle)
        ? analyticsStats.production_mensuelle
        : []

      const volumeData = monthlyProduction.slice(-7).map((item: any) => ({
        jour: String(item.mois || ''),
        mesures: Number(item.production || 0),
        alertes: unresolvedAlertes,
      }))
      setDataVolume(volumeData)

    } catch (error) {
      logger.error('Erreur chargement rapports admin', error instanceof Error ? error : undefined)
      setAnomalies([])
      setQualityMetrics([])
      setSystemHealth([])
      setDataVolume([])
    } finally {
      setLoading(false)
    }
  }

  const getScoreColor = (score: number) => {
    if (score >= 90) return 'text-green-600'
    if (score >= 70) return 'text-yellow-600'
    return 'text-red-600'
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'good':
      case 'operational':
        return <CheckCircle className="h-4 w-4 text-green-500" />
      case 'warning':
      case 'degraded':
        return <AlertTriangle className="h-4 w-4 text-yellow-500" />
      case 'critical':
      case 'down':
        return <XCircle className="h-4 w-4 text-red-500" />
      default:
        return null
    }
  }

  const getAnomalyStatusBadge = (status: string) => {
    switch (status) {
      case 'nouvelle':
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">Nouvelle</Badge>
      case 'en_cours':
        return <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">En cours</Badge>
      case 'resolue':
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">Résolue</Badge>
      default:
        return <Badge>Inconnu</Badge>
    }
  }

  const globalScore = qualityMetrics.length > 0
    ? qualityMetrics.reduce((acc, m) => acc + m.score, 0) / qualityMetrics.length
    : 0

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Rapports & Qualité des Données
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Surveillez la qualité des données et l'état du système
          </p>
        </div>
        <div className="flex gap-2">
          <Select value={selectedPeriod} onValueChange={setSelectedPeriod}>
            <SelectTrigger className="w-40">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="1">Aujourd'hui</SelectItem>
              <SelectItem value="7">7 derniers jours</SelectItem>
              <SelectItem value="30">30 derniers jours</SelectItem>
              <SelectItem value="90">3 mois</SelectItem>
            </SelectContent>
          </Select>
          <Button onClick={fetchData} variant="outline">
            <RefreshCw className="h-4 w-4" />
          </Button>
          <Button variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Rapport PDF
          </Button>
        </div>
      </div>

      {/* Score global */}
      <Card className="bg-linear-to-r from-green-500 to-emerald-600 text-white">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100">Score de qualité global</p>
              <p className="text-5xl font-bold mt-2">{globalScore.toFixed(1)}%</p>
              <p className="text-green-100 mt-2">
                <TrendingUp className="h-4 w-4 inline mr-1" />
                +2.3% par rapport à la semaine dernière
              </p>
            </div>
            <div className="p-4 bg-white/20 rounded-full">
              <BarChart3 className="h-12 w-12" />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Métriques de qualité */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {qualityMetrics.map((metric, idx) => (
          <Card key={idx}>
            <CardContent className="p-4">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    {getStatusIcon(metric.status)}
                    <span className="font-medium text-gray-900 dark:text-white">{metric.name}</span>
                  </div>
                  <div className="mt-3 flex items-center gap-3">
                    <span className={`text-3xl font-bold ${getScoreColor(metric.score)}`}>
                      {metric.score}%
                    </span>
                    <Progress value={metric.score} className="flex-1 h-2" />
                  </div>
                  <p className="text-sm text-gray-500 mt-2">{metric.details}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Volume de données */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Database className="h-5 w-5 text-blue-600" />
              Volume de données collectées
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-72">
              <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={288}>
                <BarChart data={dataVolume}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.2} />
                  <XAxis dataKey="jour" stroke="#6B7280" />
                  <YAxis stroke="#6B7280" />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: 'rgba(17, 24, 39, 0.9)',
                      border: 'none',
                      borderRadius: '8px',
                      color: '#fff',
                    }}
                  />
                  <Bar dataKey="mesures" fill="#3B82F6" radius={[4, 4, 0, 0]} name="Mesures" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* État du système */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Activity className="h-5 w-5 text-green-600" />
              État des services
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              {systemHealth.map((service, idx) => (
                <div key={idx} className="flex items-center justify-between p-3 border rounded-lg dark:border-gray-700">
                  <div className="flex items-center gap-3">
                    {getStatusIcon(service.status)}
                    <div>
                      <p className="font-medium text-gray-900 dark:text-white">{service.component}</p>
                      <p className="text-xs text-gray-500">{service.lastCheck}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className={`font-medium ${service.uptime >= 99 ? 'text-green-600' : service.uptime >= 95 ? 'text-yellow-600' : 'text-red-600'}`}>
                      {service.uptime}% uptime
                    </p>
                    <Badge
                      className={
                        service.status === 'operational'
                          ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
                          : service.status === 'degraded'
                            ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
                            : 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                      }
                    >
                      {service.status === 'operational' ? 'Opérationnel' : service.status === 'degraded' ? 'Dégradé' : 'Hors service'}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Anomalies détectées */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <AlertTriangle className="h-5 w-5 text-yellow-600" />
                Anomalies détectées
              </CardTitle>
              <CardDescription>
                Données nécessitant une vérification manuelle
              </CardDescription>
            </div>
            <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">
              {anomalies.filter((a) => a.status === 'nouvelle').length} nouvelles
            </Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b dark:border-gray-700">
                  <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Type</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Capteur</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Date</th>
                  <th className="text-right py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Valeur</th>
                  <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Attendue</th>
                  <th className="text-center py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Statut</th>
                  <th className="text-center py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Actions</th>
                </tr>
              </thead>
              <tbody>
                {anomalies.map((anomaly) => (
                  <tr key={anomaly.id} className="border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                    <td className="py-3 px-4">
                      <span className="font-medium text-gray-900 dark:text-white">{anomaly.type}</span>
                    </td>
                    <td className="py-3 px-4 text-gray-600 dark:text-gray-400">{anomaly.capteur}</td>
                    <td className="py-3 px-4 text-gray-600 dark:text-gray-400">{anomaly.date}</td>
                    <td className="py-3 px-4 text-right">
                      <span className="font-medium text-red-600">{anomaly.valeur}</span>
                    </td>
                    <td className="py-3 px-4 text-gray-600 dark:text-gray-400">{anomaly.valeur_attendue}</td>
                    <td className="py-3 px-4 text-center">{getAnomalyStatusBadge(anomaly.status)}</td>
                    <td className="py-3 px-4 text-center">
                      <Button variant="ghost" size="sm">
                        <Eye className="h-4 w-4" />
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts'
import {
  MapPin,
  Thermometer,
  Droplets,
  Wind,
  Sun,
  Bell,
  TrendingUp,
  AlertTriangle,
  CheckCircle,
  Cloud,
  ChevronRight,
  Leaf,
  ShoppingCart,
  GraduationCap,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle, Badge, Skeleton } from '@/components/ui'
import { cn } from '@/lib/utils'
import { useAuthStore, useParcellesStore, useAlertesStore } from '@/lib/store'
import api from '@/lib/api'

// Types
interface DashboardStats {
  totalParcelles: number
  totalCapteurs: number
  alertesActives: number
  productionEstimee: number
}

interface WeatherData {
  temperature: number
  humidite: number
  vent: number
  condition: string
  previsions: Array<{
    jour: string
    temp_min: number
    temp_max: number
    condition: string
  }>
}

interface MesureRecente {
  date: string
  humidite: number
  temperature: number
  ph: number
}

// Color scheme for charts
const COLORS = ['#10B981', '#F59E0B', '#EF4444', '#3B82F6', '#8B5CF6']

export default function DashboardPage() {
  const { user } = useAuthStore()
  const { parcelles, setParcelles } = useParcellesStore()
  const { alertes, setAlertes, setUnreadCount } = useAlertesStore()

  const [stats, setStats] = useState<DashboardStats>({
    totalParcelles: 0,
    totalCapteurs: 0,
    alertesActives: 0,
    productionEstimee: 0,
  })
  const [loading, setLoading] = useState(true)
  const [weather, setWeather] = useState<WeatherData | null>(null)
  const [mesures, setMesures] = useState<MesureRecente[]>([])
  const [cultureData, setCultureData] = useState<any[]>([])

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)
      try {
        // Fetch aggregated dashboard stats
        const statsRes = await api.get('/dashboard/stats')
        if (statsRes.data.success) {
          const d = statsRes.data.data
          setStats({
            totalParcelles: d.parcelles.count,
            totalCapteurs: d.capteurs,
            alertesActives: d.alertes,
            productionEstimee: d.production.volume_tonnes
          })
        }

        // Fetch parcelles list for store (optional if not used elsewhere on this page, but good for cache)
        const parcellesRes = await api.get('/parcelles')
        if (parcellesRes.data.success) {
          setParcelles(parcellesRes.data.data)
        }

        // Fetch Alertes for list (keep separate as we need the list, not just count)
        const alertesRes = await api.get('/alertes?statut=NOUVELLE&limit=5')
        if (alertesRes.data.success) {
          setAlertes(alertesRes.data.data)
          // Unread count might come from metadata or separate call, assuming stats has it covers count
          setUnreadCount(statsRes.data.data.alertes)
        }

        // Fetch Culture Distribution
        const culturesRes = await api.get('/dashboard/cultures')
        if (culturesRes.data.success) {
          setCultureData(culturesRes.data.data)
        }

        // Fetch weather
        try {
          const weatherRes = await api.get('/weather/current')
          let weatherData = null

          if (weatherRes.data.success) {
            const wd = weatherRes.data.data
            weatherData = {
              temperature: Math.round(wd.temperature || 0),
              humidite: wd.humidity || wd.humidite || 0,
              vent: Math.round(wd.wind_speed || wd.vent || 0),
              condition: wd.condition || wd.description || 'Ensoleillé',
              previsions: [] as WeatherData['previsions']
            }
          }

          // Fetch forecast
          try {
            const forecastRes = await api.get('/weather/forecast')
            if (forecastRes.data.success && weatherData) {
              const forecastData = forecastRes.data.data
              if (Array.isArray(forecastData)) {
                weatherData.previsions = forecastData.slice(0, 5).map((d: any) => {
                  const date = d.date ? new Date(d.date) : null;
                  return {
                    jour: d.jour || (date && !isNaN(date.getTime()) ? date.toLocaleDateString('fr-FR', { weekday: 'short' }) : '-'),
                    temp_min: Math.round(d.temp_min || d.temperature_min || 0),
                    temp_max: Math.round(d.temp_max || d.temperature_max || 0),
                    condition: d.condition || d.description || 'Nuageux'
                  };
                });
              }
            }
          } catch (e) {
            console.warn('Forecast API failed', e)
            if (weatherData) {
              weatherData.previsions = []
            }
          }

          if (weatherData) {
            setWeather(weatherData)
          }
        } catch (e) {
          console.warn('Weather API not ready yet')
        }

        // Fetch recent measures
        try {
          const mesuresRes = await api.get('/mesures/recent')
          if (mesuresRes.data.success) {
            setMesures(mesuresRes.data.data)
          }
        } catch (e) {
          console.warn('Mesures API not ready yet')
        }

      } catch (error) {
        console.error('Error fetching dashboard data:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const getAlertColor = (niveau: string) => {
    switch (niveau) {
      case 'critique':
        return 'bg-red-100 text-red-800 border-red-200'
      case 'important':
      case 'warning':
        return 'bg-orange-100 text-orange-800 border-orange-200'
      default:
        return 'bg-blue-100 text-blue-800 border-blue-200'
    }
  }

  const getWeatherIcon = (condition: string) => {
    switch (condition?.toLowerCase()) {
      case 'sunny':
      case 'ensoleillé':
        return <Sun className="h-6 w-6 text-yellow-500" />
      case 'cloudy':
      case 'nuageux':
        return <Cloud className="h-6 w-6 text-gray-500" />
      case 'rainy':
      case 'pluvieux':
        return <Droplets className="h-6 w-6 text-blue-500" />
      default:
        return <Sun className="h-6 w-6 text-yellow-500" />
    }
  }

  return (
    <div className="space-y-6">
      {/* Welcome header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            Bonjour, {user?.prenoms || 'Agriculteur'} 👋
          </h1>
          <p className="text-gray-500">
            Voici un aperçu de vos cultures et de votre exploitation
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="success" className="py-1 px-3">
            <CheckCircle className="h-3 w-3 mr-1" />
            Système opérationnel
          </Badge>
        </div>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500">Parcelles</p>
                {loading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-gray-900">{stats.totalParcelles}</p>
                )}
              </div>
              <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center">
                <MapPin className="h-6 w-6 text-green-600" />
              </div>
            </div>
            <div className="mt-2 flex items-center text-sm text-green-600">
              <TrendingUp className="h-4 w-4 mr-1" />
              <span>+0 ce mois</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500">Capteurs</p>
                {loading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-gray-900">{stats.totalCapteurs}</p>
                )}
              </div>
              <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                <Thermometer className="h-6 w-6 text-blue-600" />
              </div>
            </div>
            <div className="mt-2 flex items-center text-sm text-blue-600">
              <CheckCircle className="h-4 w-4 mr-1" />
              <span>Tous actifs</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500">Alertes</p>
                {loading ? (
                  <Skeleton className="h-8 w-16 mt-1" />
                ) : (
                  <p className="text-2xl font-bold text-gray-900">{stats.alertesActives}</p>
                )}
              </div>
              <div className="h-12 w-12 rounded-full bg-orange-100 flex items-center justify-center">
                <Bell className="h-6 w-6 text-orange-600" />
              </div>
            </div>
            <div className="mt-2 flex items-center text-sm text-orange-600">
              <AlertTriangle className="h-4 w-4 mr-1" />
              <span>À traiter</span>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-500">ROI estimé</p>
                <p className="text-2xl font-bold text-gray-900">+0%</p>
              </div>
              <div className="h-12 w-12 rounded-full bg-purple-100 flex items-center justify-center">
                <TrendingUp className="h-6 w-6 text-purple-600" />
              </div>
            </div>
            <div className="mt-2 flex items-center text-sm text-purple-600">
              <TrendingUp className="h-4 w-4 mr-1" />
              <span>vs. saison passée</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Weather and alerts row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Weather card */}
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg font-semibold">Météo</CardTitle>
            <Link
              href="/meteo"
              className="text-sm text-green-600 hover:text-green-700 flex items-center"
            >
              Voir détails
              <ChevronRight className="h-4 w-4" />
            </Link>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-32 w-full" />
            ) : weather ? (
              <>
                <div className="flex flex-col sm:flex-row items-start sm:items-center gap-6">
                  {/* Current weather */}
                  <div className="flex items-center gap-4">
                    <div className="h-20 w-20 rounded-full bg-linear-to-br from-yellow-400 to-orange-500 flex items-center justify-center">
                      <Sun className="h-10 w-10 text-white" />
                    </div>
                    <div>
                      <p className="text-4xl font-bold text-gray-900">{weather.temperature}°C</p>
                      <p className="text-gray-500">{weather.condition}</p>
                    </div>
                  </div>

                  {/* Weather details */}
                  <div className="flex gap-6 flex-wrap">
                    <div className="flex items-center gap-2">
                      <Droplets className="h-5 w-5 text-blue-500" />
                      <div>
                        <p className="text-sm text-gray-500">Humidité</p>
                        <p className="font-semibold">{weather.humidite}%</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <Wind className="h-5 w-5 text-gray-500" />
                      <div>
                        <p className="text-sm text-gray-500">Vent</p>
                        <p className="font-semibold">{weather.vent} km/h</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* 5-day forecast */}
                <div className="mt-6 grid grid-cols-5 gap-2">
                  {weather.previsions.map((prev, index) => (
                    <div
                      key={index}
                      className="flex flex-col items-center p-3 rounded-lg bg-gray-50 hover:bg-gray-100 transition-colors"
                    >
                      <p className="text-sm font-medium text-gray-600">{prev.jour}</p>
                      {getWeatherIcon(prev.condition)}
                      <p className="text-sm font-semibold mt-1">
                        {prev.temp_max}° / {prev.temp_min}°
                      </p>
                    </div>
                  ))}
                </div>
              </>
            ) : (
              <div className="flex flex-col items-center justify-center h-32 text-gray-500">
                <Cloud className="h-10 w-10 mb-2 text-gray-400" />
                <p>Données météo non disponibles</p>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Recent alerts */}
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-lg font-semibold">Alertes récentes</CardTitle>
            <Link
              href="/alertes"
              className="text-sm text-green-600 hover:text-green-700 flex items-center"
            >
              Voir tout
              <ChevronRight className="h-4 w-4" />
            </Link>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {loading ? (
                <>
                  <Skeleton className="h-16 w-full" />
                  <Skeleton className="h-16 w-full" />
                  <Skeleton className="h-16 w-full" />
                </>
              ) : alertes.length > 0 ? (
                alertes.slice(0, 3).map((alerte) => (
                  <div
                    key={alerte.id}
                    className={cn(
                      "p-3 rounded-lg border",
                      getAlertColor(alerte.niveau)
                    )}
                  >
                    <div className="flex items-start gap-2">
                      <AlertTriangle className="h-4 w-4 mt-0.5 shrink-0" />
                      <div>
                        <p className="font-medium text-sm">{alerte.titre}</p>
                        <p className="text-xs mt-0.5 opacity-80">
                          {alerte.parcelle_nom || 'Général'}
                        </p>
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="text-center py-8 text-gray-500">
                  <CheckCircle className="h-10 w-10 mx-auto mb-2 text-green-500" />
                  <p>Aucune alerte active</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Soil parameters chart */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg font-semibold">Paramètres du sol (7 jours)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-75">
              <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={300}>
                {mesures.length > 0 ? (
                  <LineChart data={mesures}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                    <XAxis dataKey="date" stroke="#6B7280" fontSize={12} />
                    <YAxis stroke="#6B7280" fontSize={12} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: 'white',
                        border: '1px solid #E5E7EB',
                        borderRadius: '8px',
                      }}
                    />
                    <Line
                      type="monotone"
                      dataKey="humidite"
                      stroke="#3B82F6"
                      strokeWidth={2}
                      dot={{ r: 4 }}
                      name="Humidité (%)"
                    />
                    <Line
                      type="monotone"
                      dataKey="temperature"
                      stroke="#EF4444"
                      strokeWidth={2}
                      dot={{ r: 4 }}
                      name="Température (°C)"
                    />
                    <Line
                      type="monotone"
                      dataKey="ph"
                      stroke="#10B981"
                      strokeWidth={2}
                      dot={{ r: 4 }}
                      name="pH"
                    />
                  </LineChart>
                ) : (
                  <div className="flex items-center justify-center h-full text-gray-500">
                    <p>Aucune donnée récente</p>
                  </div>
                )}
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Culture distribution */}
        <Card>
          <CardHeader>
            <CardTitle className="text-lg font-semibold">Répartition des cultures</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-75 flex items-center">
              <div className="w-1/2 h-full">
                <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={300}>
                  <PieChart>
                    <Pie
                      data={cultureData}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={100}
                      fill="#8884d8"
                      paddingAngle={2}
                      dataKey="value"
                    >
                      {cultureData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color || COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="flex-1 space-y-2">
                {cultureData.length > 0 ? cultureData.map((culture, index) => (
                  <div key={culture.name} className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <div
                        ref={(el) => { if (el) el.style.backgroundColor = culture.color || COLORS[index % COLORS.length] }}
                        className="h-3 w-3 rounded-full"
                      />
                      <span className="text-sm text-gray-600">{culture.name}</span>
                    </div>
                    <span className="text-sm font-medium">{culture.value > 100 ? culture.value.toFixed(0) : culture.value.toFixed(1)} ha</span>
                  </div>
                )) : (
                  <div className="text-center text-gray-500 py-4">Pas de données de culture</div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick actions */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Link href="/parcelles/new">
          <Card className="hover:shadow-md transition-shadow cursor-pointer">
            <CardContent className="p-4 flex flex-col items-center text-center">
              <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center mb-2">
                <MapPin className="h-6 w-6 text-green-600" />
              </div>
              <p className="font-medium text-gray-900">Nouvelle parcelle</p>
              <p className="text-xs text-gray-500">Ajouter une parcelle</p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/diagnostic">
          <Card className="hover:shadow-md transition-shadow cursor-pointer">
            <CardContent className="p-4 flex flex-col items-center text-center">
              <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center mb-2">
                <Leaf className="h-6 w-6 text-blue-600" />
              </div>
              <p className="font-medium text-gray-900">Diagnostic IA</p>
              <p className="text-xs text-gray-500">Analyser une plante</p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/marketplace">
          <Card className="hover:shadow-md transition-shadow cursor-pointer">
            <CardContent className="p-4 flex flex-col items-center text-center">
              <div className="h-12 w-12 rounded-full bg-orange-100 flex items-center justify-center mb-2">
                <ShoppingCart className="h-6 w-6 text-orange-600" />
              </div>
              <p className="font-medium text-gray-900">Marketplace</p>
              <p className="text-xs text-gray-500">Acheter/Vendre</p>
            </CardContent>
          </Card>
        </Link>
        <Link href="/formations">
          <Card className="hover:shadow-md transition-shadow cursor-pointer">
            <CardContent className="p-4 flex flex-col items-center text-center">
              <div className="h-12 w-12 rounded-full bg-purple-100 flex items-center justify-center mb-2">
                <GraduationCap className="h-6 w-6 text-purple-600" />
              </div>
              <p className="font-medium text-gray-900">Formations</p>
              <p className="text-xs text-gray-500">Apprendre</p>
            </CardContent>
          </Card>
        </Link>
      </div>
    </div>
  )
}

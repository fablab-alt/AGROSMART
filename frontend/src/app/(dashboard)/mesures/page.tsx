'use client'

import { useState, useEffect, useCallback } from 'react'
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts'
import {
  Thermometer,
  Droplets,
  Sun,
  Gauge,
  Calendar,
  Download,
  Filter,
  TrendingUp,
  TrendingDown,
  Minus,
  RefreshCw,
  BarChart3,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Spinner } from '@/components/ui/spinner'
import toast from 'react-hot-toast'
import api from '@/lib/api'

// Types pour les données de mesures
interface MesureData {
  date?: string
  heure?: string
  dateComplete?: string
  temperature: number
  humidite_sol: number
  humidite_air?: number
  luminosite: number
  ph?: number
  precipitation?: number
}

interface StatCard {
  label: string
  value: string | number
  unit: string
  trend: 'up' | 'down' | 'stable'
  change: string
  icon: React.ElementType
  color: string
}

export default function MesuresPage() {
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [selectedPeriod, setSelectedPeriod] = useState<'24h' | '7j' | '30j' | '90j'>('7j')
  const [selectedParcelle, setSelectedParcelle] = useState<string>('all')
  const [chartData, setChartData] = useState<MesureData[]>([])
  const [activeMetric, setActiveMetric] = useState<'temperature' | 'humidite_sol' | 'luminosite' | 'ph'>('temperature')

  const [parcelles, setParcelles] = useState<{ id: string; nom: string }[]>([])

  // Fetch parcelles for the dropdown
  useEffect(() => {
    const fetchParcelles = async () => {
      try {
        const response = await api.get('/parcelles')
        const data = response.data?.data || response.data
        if (Array.isArray(data)) {
          setParcelles(data.map((p: { id: string; nom: string }) => ({ id: p.id, nom: p.nom })))
        }
      } catch (e) {
        console.error('Erreur chargement parcelles:', e)
      }
    }
    fetchParcelles()
  }, [])

  // Calculate date range from period
  const getDateRange = useCallback((period: string) => {
    const fin = new Date()
    const debut = new Date()
    switch (period) {
      case '24h': debut.setHours(debut.getHours() - 24); break
      case '7j': debut.setDate(debut.getDate() - 7); break
      case '30j': debut.setDate(debut.getDate() - 30); break
      case '90j': debut.setDate(debut.getDate() - 90); break
    }
    return { debut: debut.toISOString(), fin: fin.toISOString() }
  }, [])

  const fetchData = useCallback(async () => {
    try {
      setLoading(true)
      const { debut, fin } = getDateRange(selectedPeriod)
      const params: Record<string, string | number> = { debut, fin, limit: 500 }
      if (selectedParcelle !== 'all') {
        params.parcelle_id = selectedParcelle
      }
      const response = await api.get('/mesures', { params })
      // Handle API response structure: {success: true, data: [...]}
      const data = response.data?.data || response.data
      if (Array.isArray(data) && data.length > 0) {
        // Backend returns individual sensor readings with valeur + capteur_type
        // Group by date and aggregate by sensor type
        const groupedByDate: Record<string, {
          temperature: number[]; humidite_sol: number[]; luminosite: number[];
          ph: number[]; precipitation: number[]; humidite_air: number[];
          timestamp: string;
        }> = {}

        for (const m of data) {
          const ts = m.timestamp || m.createdAt
          const dateKey = selectedPeriod === '24h'
            ? new Date(ts).toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })
            : new Date(ts).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' })

          if (!groupedByDate[dateKey]) {
            groupedByDate[dateKey] = {
              temperature: [], humidite_sol: [], luminosite: [],
              ph: [], precipitation: [], humidite_air: [], timestamp: ts
            }
          }

          const val = parseFloat(m.valeur) || 0
          const capteurType = (m.capteur_type || m.capteur?.type || '').toLowerCase()

          if (capteurType.includes('humidite_temperature') || capteurType.includes('temperature')) {
            // Temperature/humidity combo sensor - value could be temp or humidity
            if (m.unite === '°C' || m.unite === 'C') {
              groupedByDate[dateKey].temperature.push(val)
            } else if (m.unite === '%') {
              groupedByDate[dateKey].humidite_air.push(val)
            } else {
              groupedByDate[dateKey].temperature.push(val)
            }
          } else if (capteurType.includes('humidite_sol')) {
            groupedByDate[dateKey].humidite_sol.push(val)
          } else if (capteurType.includes('uv') || capteurType.includes('luminosite')) {
            groupedByDate[dateKey].luminosite.push(val)
          } else if (capteurType.includes('npk') || capteurType.includes('ph')) {
            groupedByDate[dateKey].ph.push(val)
          } else if (capteurType.includes('pluie') || capteurType.includes('pluvio')) {
            groupedByDate[dateKey].precipitation.push(val)
          }
        }

        const avg = (arr: number[]) => arr.length > 0 ? arr.reduce((a, b) => a + b, 0) / arr.length : 0

        const formattedData = Object.entries(groupedByDate)
          .sort((a, b) => new Date(a[1].timestamp).getTime() - new Date(b[1].timestamp).getTime())
          .map(([dateKey, values]) => ({
            date: dateKey,
            heure: dateKey,
            dateComplete: values.timestamp,
            temperature: Math.round(avg(values.temperature) * 10) / 10,
            humidite_sol: Math.round(avg(values.humidite_sol) * 10) / 10,
            humidite_air: Math.round(avg(values.humidite_air) * 10) / 10,
            luminosite: Math.round(avg(values.luminosite)),
            ph: Math.round(avg(values.ph) * 10) / 10,
            precipitation: Math.round(avg(values.precipitation) * 10) / 10,
          }))

        setChartData(formattedData)
      } else {
        setChartData([])
      }
    } catch (error) {
      console.error('Erreur chargement mesures:', error)
      setChartData([])
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [selectedPeriod, selectedParcelle, getDateRange])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const handleRefresh = async () => {
    setRefreshing(true)
    await fetchData()
    toast.success('Données actualisées')
  }

  const handleExport = () => {
    // Export CSV
    const headers = ['Date', 'Température', 'Humidité Sol', 'Luminosité', 'pH']
    const csvContent = [
      headers.join(','),
      ...chartData.map(row => [
        'date' in row ? row.date : '',
        row.temperature,
        row.humidite_sol,
        row.luminosite,
        'ph' in row ? row.ph : ''
      ].join(','))
    ].join('\n')

    const blob = new Blob([csvContent], { type: 'text/csv' })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `mesures_${selectedPeriod}_${new Date().toISOString().split('T')[0]}.csv`
    a.click()
    toast.success('Export CSV téléchargé')
  }

  // Calculate stats from data
  const calculateStats = (): StatCard[] => {
    if (!chartData || chartData.length === 0) return []

    const lastValue = chartData[chartData.length - 1]
    const firstValue = chartData[0]

    // Vérifier que les valeurs existent
    if (!lastValue || !firstValue) return []

    const tempChange = (lastValue.temperature ?? 0) - (firstValue.temperature ?? 0)
    const humChange = (lastValue.humidite_sol ?? 0) - (firstValue.humidite_sol ?? 0)
    const lumLast = lastValue.luminosite ?? 0
    const lumFirst = firstValue.luminosite ?? 0
    const lumChangePercent = lumFirst > 0 ? ((lumLast - lumFirst) / lumFirst * 100) : 0

    return [
      {
        label: 'Température moyenne',
        value: (chartData.reduce((acc, d) => acc + d.temperature, 0) / chartData.length).toFixed(1),
        unit: '°C',
        trend: tempChange > 0.5 ? 'up' : tempChange < -0.5 ? 'down' : 'stable',
        change: `${tempChange > 0 ? '+' : ''}${tempChange.toFixed(1)}°C`,
        icon: Thermometer,
        color: 'bg-red-100 text-red-600',
      },
      {
        label: 'Humidité sol moyenne',
        value: (chartData.reduce((acc, d) => acc + d.humidite_sol, 0) / chartData.length).toFixed(1),
        unit: '%',
        trend: humChange > 2 ? 'up' : humChange < -2 ? 'down' : 'stable',
        change: `${humChange > 0 ? '+' : ''}${humChange.toFixed(1)}%`,
        icon: Droplets,
        color: 'bg-blue-100 text-blue-600',
      },
      {
        label: 'Luminosité moyenne',
        value: Math.round(chartData.reduce((acc, d) => acc + d.luminosite, 0) / chartData.length).toLocaleString(),
        unit: 'lux',
        trend: lumChangePercent > 5 ? 'up' : lumChangePercent < -5 ? 'down' : 'stable',
        change: `${lumChangePercent > 0 ? '+' : ''}${lumChangePercent.toFixed(0)}%`,
        icon: Sun,
        color: 'bg-yellow-100 text-yellow-600',
      },
      {
        label: 'pH moyen',
        value: chartData.length > 0 && chartData[0]?.ph !== undefined
          ? (chartData.reduce((acc, d) => acc + (d.ph || 0), 0) / chartData.length).toFixed(1)
          : '6.5',
        unit: 'pH',
        trend: 'stable',
        change: '±0.1',
        icon: Gauge,
        color: 'bg-green-100 text-green-600',
      },
    ]
  }

  const stats = calculateStats()

  const getTrendIcon = (trend: string) => {
    switch (trend) {
      case 'up': return <TrendingUp className="h-4 w-4 text-green-500" />
      case 'down': return <TrendingDown className="h-4 w-4 text-red-500" />
      default: return <Minus className="h-4 w-4 text-gray-500" />
    }
  }

  const getMetricConfig = (metric: string) => {
    switch (metric) {
      case 'temperature':
        return { label: 'Température', color: '#ef4444', unit: '°C' }
      case 'humidite_sol':
        return { label: 'Humidité Sol', color: '#3b82f6', unit: '%' }
      case 'luminosite':
        return { label: 'Luminosité', color: '#eab308', unit: 'lux' }
      case 'ph':
        return { label: 'pH', color: '#22c55e', unit: '' }
      default:
        return { label: metric, color: '#6b7280', unit: '' }
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-100">
        <Spinner className="h-8 w-8" />
      </div>
    )
  }

  return (
    <div className="p-4 md:p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900">
            Mesures & Analyses
          </h1>
          <p className="text-gray-500 mt-1">
            Visualisez les données de vos capteurs en temps réel
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button
            variant="outline"
            onClick={handleRefresh}
            disabled={refreshing}
            className="gap-2"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            Actualiser
          </Button>
          <Button variant="outline" onClick={handleExport} className="gap-2">
            <Download className="h-4 w-4" />
            Exporter
          </Button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-4">
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-gray-500" />
          <div className="flex rounded-lg border overflow-hidden">
            {(['24h', '7j', '30j', '90j'] as const).map((period) => (
              <button
                key={period}
                onClick={() => setSelectedPeriod(period)}
                className={`px-4 py-2 text-sm font-medium transition-colors ${
                  selectedPeriod === period
                    ? 'bg-primary text-white'
                    : 'bg-white hover:bg-gray-50'
                }`}
              >
                {period}
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <Filter className="h-4 w-4 text-gray-500" />
          <select
            value={selectedParcelle}
            onChange={(e) => setSelectedParcelle(e.target.value)}
            className="px-4 py-2 border rounded-lg bg-white"
            title="Sélectionner une parcelle"
          >
            <option value="all">Toutes les parcelles</option>
            {parcelles.map((p) => (
              <option key={p.id} value={p.id}>{p.nom}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {stats.map((stat, index) => (
          <Card key={index}>
            <CardContent className="p-4">
              <div className="flex items-start justify-between">
                <div className={`p-2 rounded-lg ${stat.color}`}>
                  <stat.icon className="h-5 w-5" />
                </div>
                <div className="flex items-center gap-1">
                  {getTrendIcon(stat.trend)}
                  <span className="text-xs text-gray-500">{stat.change}</span>
                </div>
              </div>
              <div className="mt-3">
                <p className="text-2xl font-bold">
                  {stat.value}
                  <span className="text-sm font-normal text-gray-500 ml-1">{stat.unit}</span>
                </p>
                <p className="text-sm text-gray-500">{stat.label}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Main Chart */}
      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <CardTitle className="flex items-center gap-2">
                <BarChart3 className="h-5 w-5 text-primary" />
                Évolution des mesures
              </CardTitle>
              <CardDescription>
                {selectedPeriod === '24h' ? 'Dernières 24 heures' :
                 selectedPeriod === '7j' ? '7 derniers jours' :
                 selectedPeriod === '30j' ? '30 derniers jours' : '90 derniers jours'}
              </CardDescription>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-sm text-gray-500">Métrique:</span>
              <select
                value={activeMetric}
                onChange={(e) => setActiveMetric(e.target.value as typeof activeMetric)}
                className="px-3 py-1.5 border rounded-lg text-sm bg-white"
                title="Sélectionner une métrique"
              >
                <option value="temperature">Température</option>
                <option value="humidite_sol">Humidité Sol</option>
                <option value="luminosite">Luminosité</option>
                <option value="ph">pH</option>
              </select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="h-100">
            <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={300}>
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="colorMetric" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={getMetricConfig(activeMetric).color} stopOpacity={0.3}/>
                    <stop offset="95%" stopColor={getMetricConfig(activeMetric).color} stopOpacity={0}/>
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis 
                  dataKey={selectedPeriod === '24h' ? 'heure' : 'date'} 
                  tick={{ fontSize: 12 }}
                  stroke="#9ca3af"
                />
                <YAxis 
                  tick={{ fontSize: 12 }}
                  stroke="#9ca3af"
                  domain={activeMetric === 'ph' ? [5, 8] : undefined}
                />
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'white',
                    border: '1px solid #e5e7eb',
                    borderRadius: '8px',
                  }}
                  formatter={(value?: number) => [
                    `${value ?? 0} ${getMetricConfig(activeMetric).unit}`,
                    getMetricConfig(activeMetric).label
                  ]}
                />
                <Area
                  type="monotone"
                  dataKey={activeMetric}
                  stroke={getMetricConfig(activeMetric).color}
                  strokeWidth={2}
                  fill="url(#colorMetric)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </CardContent>
      </Card>

      {/* Comparison Charts */}
      <Tabs defaultValue="comparison" className="space-y-4">
        <TabsList>
          <TabsTrigger value="comparison">Comparaison</TabsTrigger>
          <TabsTrigger value="precipitation">Précipitations</TabsTrigger>
          <TabsTrigger value="correlation">Corrélation</TabsTrigger>
        </TabsList>

        <TabsContent value="comparison">
          <Card>
            <CardHeader>
              <CardTitle>Comparaison des métriques</CardTitle>
              <CardDescription>
                Vue d&apos;ensemble de toutes les mesures
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="h-87.5">
                <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={300}>
                  <LineChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis 
                      dataKey={selectedPeriod === '24h' ? 'heure' : 'date'} 
                      tick={{ fontSize: 12 }}
                    />
                    <YAxis yAxisId="left" tick={{ fontSize: 12 }} />
                    <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 12 }} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: 'white',
                        border: '1px solid #e5e7eb',
                        borderRadius: '8px',
                      }}
                    />
                    <Legend />
                    <Line
                      yAxisId="left"
                      type="monotone"
                      dataKey="temperature"
                      name="Température (°C)"
                      stroke="#ef4444"
                      strokeWidth={2}
                      dot={false}
                    />
                    <Line
                      yAxisId="left"
                      type="monotone"
                      dataKey="humidite_sol"
                      name="Humidité Sol (%)"
                      stroke="#3b82f6"
                      strokeWidth={2}
                      dot={false}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="precipitation">
          <Card>
            <CardHeader>
              <CardTitle>Précipitations</CardTitle>
              <CardDescription>
                Historique des précipitations sur la période
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="h-87.5">
                <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={300}>
                  <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis 
                      dataKey={selectedPeriod === '24h' ? 'heure' : 'date'} 
                      tick={{ fontSize: 12 }}
                    />
                    <YAxis tick={{ fontSize: 12 }} />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: 'white',
                        border: '1px solid #e5e7eb',
                        borderRadius: '8px',
                      }}
                      formatter={(value?: number) => [`${value ?? 0} mm`, 'Précipitations']}
                    />
                    <Bar
                      dataKey="precipitation"
                      name="Précipitations (mm)"
                      fill="#3b82f6"
                      radius={[4, 4, 0, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="correlation">
          <Card>
            <CardHeader>
              <CardTitle>Analyse de corrélation</CardTitle>
              <CardDescription>
                Relation entre température et humidité du sol
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <h4 className="font-medium">Observations</h4>
                  <div className="space-y-3">
                    <div className="p-4 bg-blue-50 rounded-lg">
                      <p className="font-medium text-blue-900">Corrélation négative</p>
                      <p className="text-sm text-blue-700 mt-1">
                        Quand la température augmente, l&apos;humidité du sol tend à diminuer
                      </p>
                    </div>
                    <div className="p-4 bg-green-50 rounded-lg">
                      <p className="font-medium text-green-900">Plage optimale</p>
                      <p className="text-sm text-green-700 mt-1">
                        Température: 24-28°C, Humidité sol: 55-70%
                      </p>
                    </div>
                    <div className="p-4 bg-orange-50 rounded-lg">
                      <p className="font-medium text-orange-900">Recommandation</p>
                      <p className="text-sm text-orange-700 mt-1">
                        Irriguer lorsque l&apos;humidité descend sous 50% et la température dépasse 30°C
                      </p>
                    </div>
                  </div>
                </div>
                <div className="h-75">
                  <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={300}>
                    <LineChart data={chartData}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                      <XAxis dataKey={selectedPeriod === '24h' ? 'heure' : 'date'} tick={{ fontSize: 10 }} />
                      <YAxis tick={{ fontSize: 12 }} />
                      <Tooltip />
                      <Legend />
                      <Line
                        type="monotone"
                        dataKey="temperature"
                        name="Temp (°C)"
                        stroke="#ef4444"
                        strokeWidth={2}
                        dot={false}
                      />
                      <Line
                        type="monotone"
                        dataKey="humidite_sol"
                        name="Humid (%)"
                        stroke="#3b82f6"
                        strokeWidth={2}
                        dot={false}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Historical Analysis */}
      <Card>
        <CardHeader>
          <CardTitle>Analyse historique</CardTitle>
          <CardDescription>
            Statistiques détaillées pour la période sélectionnée
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { label: 'Temp. max', value: Math.max(...chartData.map(d => d.temperature)).toFixed(1), unit: '°C', color: 'text-red-600' },
              { label: 'Temp. min', value: Math.min(...chartData.map(d => d.temperature)).toFixed(1), unit: '°C', color: 'text-blue-600' },
              { label: 'Humid. max', value: Math.max(...chartData.map(d => d.humidite_sol)).toFixed(1), unit: '%', color: 'text-blue-600' },
              { label: 'Humid. min', value: Math.min(...chartData.map(d => d.humidite_sol)).toFixed(1), unit: '%', color: 'text-orange-600' },
            ].map((item, index) => (
              <div key={index} className="p-4 bg-gray-50 rounded-lg text-center">
                <p className={`text-2xl font-bold ${item.color}`}>
                  {item.value}
                  <span className="text-sm font-normal ml-1">{item.unit}</span>
                </p>
                <p className="text-sm text-gray-500">{item.label}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

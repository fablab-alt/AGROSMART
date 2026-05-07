'use client'

import { useEffect, useState } from 'react'
import {
  TrendingUp,
  TrendingDown,
  Leaf,
  Calendar,
  MapPin,
  BarChart3,
  PieChart,
  RefreshCw,
  Filter,
  ChevronRight,
  ArrowUpRight,
  ArrowDownRight,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
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
  PieChart as RechartsPieChart,
  Pie,
  Cell,
  Legend,
} from 'recharts'
import api from '@/lib/api'
import { logger } from '@/lib/logger'

interface ProductionData {
  culture: string
  superficie_ha: number
  rendement_estime: number
  rendement_reel?: number
  progression: number
  statut: 'en_croissance' | 'recolte' | 'terminee'
  region: string
}

interface TrendData {
  mois: string
  rendement: number
  objectif: number
}

interface CultureRepartition {
  name: string
  value: number
  color: string
  [key: string]: string | number
}

const COLORS = ['#10B981', '#3B82F6', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899']

export default function AdminProductionsPage() {
  const [productions, setProductions] = useState<ProductionData[]>([])
  const [trendData, setTrendData] = useState<TrendData[]>([])
  const [repartition, setRepartition] = useState<CultureRepartition[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedPeriod, setSelectedPeriod] = useState('2024')
  const [selectedRegion, setSelectedRegion] = useState('all')
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    fetchData()
  }, [selectedPeriod, selectedRegion])

  const fetchData = async () => {
    setLoading(true)
    try {
      // Récupérer les données depuis l'API
      const [parcellesRes, analyticsRes] = await Promise.all([
        api.get('/parcelles'),
        api.get('/analytics/stats').catch(() => ({ data: { data: {} } })),
      ])

      const parcelles = parcellesRes.data?.data || []
      const analytics = analyticsRes.data?.data || {}

      // Transformer les données réelles
      let productionsData = parcelles.map((p: any) => ({
        culture: p.nom || 'Culture inconnue',
        superficie_ha: parseFloat(p.superficie_hectares) || 0,
        rendement_estime: parseFloat(p.rendement_estime) || 0,
        rendement_reel: parseFloat(p.rendement_reel) || 0,
        progression: parseFloat(p.progression) || 0,
        statut: p.status || 'en_croissance',
        region: p.region_nom || 'Non définie',
      }))

      if (selectedRegion !== 'all') {
        productionsData = productionsData.filter(
          (p: ProductionData) => p.region.toLowerCase().includes(selectedRegion.toLowerCase())
        )
      }

      setProductions(productionsData)

      // Calculer la répartition réelle
      const repartitionData = productionsData.reduce((acc: CultureRepartition[], curr: ProductionData) => {
        const existing = acc.find(item => item.name === curr.culture)
        if (existing) {
          existing.value += curr.superficie_ha
        } else {
          acc.push({
            name: curr.culture,
            value: curr.superficie_ha,
            color: COLORS[acc.length % COLORS.length]
          })
        }
        return acc
      }, [])
      setRepartition(repartitionData)

      const rawTrend = analytics?.production_mensuelle || []
      const mappedTrend = Array.isArray(rawTrend)
        ? rawTrend.map((row: any) => ({
            mois: String(row.mois || ''),
            rendement: Number(row.production || 0),
            objectif: Number(row.saisonPrecedente || 0),
          }))
        : []
      setTrendData(mappedTrend)

    } catch (error) {
      logger.error('Erreur chargement productions admin', error instanceof Error ? error : undefined)
      setProductions([])
      setRepartition([])
      setTrendData([])
    } finally {
      setLoading(false)
    }
  }

  const getStatusBadge = (statut: string) => {
    switch (statut) {
      case 'en_croissance':
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">En croissance</Badge>
      case 'recolte':
        return <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">Récolte</Badge>
      case 'terminee':
        return <Badge className="bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">Terminée</Badge>
      default:
        return <Badge>Inconnu</Badge>
    }
  }

  const totalSuperficie = productions.reduce((acc, p) => acc + p.superficie_ha, 0)
  const avgProgression = productions.length > 0
    ? productions.reduce((acc, p) => acc + p.progression, 0) / productions.length
    : 0

  if (!mounted) return null

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Suivi des Productions
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Suivez l'évolution des productions agricoles par culture et région
          </p>
        </div>
        <div className="flex gap-2">
          <Select value={selectedPeriod} onValueChange={setSelectedPeriod}>
            <SelectTrigger className="w-32">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="2024">2024</SelectItem>
              <SelectItem value="2023">2023</SelectItem>
              <SelectItem value="2022">2022</SelectItem>
            </SelectContent>
          </Select>
          <Select value={selectedRegion} onValueChange={setSelectedRegion}>
            <SelectTrigger className="w-40">
              <SelectValue placeholder="Région" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Toutes les régions</SelectItem>
              <SelectItem value="abengourou">Abengourou</SelectItem>
              <SelectItem value="man">Man</SelectItem>
              <SelectItem value="bouake">Bouaké</SelectItem>
              <SelectItem value="korhogo">Korhogo</SelectItem>
            </SelectContent>
          </Select>
          <Button onClick={fetchData} variant="outline">
            <RefreshCw className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Stats globales */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Superficie totale</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white">{totalSuperficie.toLocaleString()}</p>
                <p className="text-sm text-gray-500">hectares</p>
              </div>
              <div className="p-3 rounded-full bg-green-100 dark:bg-green-900">
                <MapPin className="h-6 w-6 text-green-600 dark:text-green-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Cultures actives</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white">{productions.length}</p>
                <p className="text-sm text-green-600 flex items-center">
                  <ArrowUpRight className="h-3 w-3 mr-1" /> Données réelles
                </p>
              </div>
              <div className="p-3 rounded-full bg-blue-100 dark:bg-blue-900">
                <Leaf className="h-6 w-6 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Progression moyenne</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white">{avgProgression.toFixed(0)}%</p>
                <Progress value={avgProgression} className="h-2 mt-2 w-24" />
              </div>
              <div className="p-3 rounded-full bg-yellow-100 dark:bg-yellow-900">
                <TrendingUp className="h-6 w-6 text-yellow-600 dark:text-yellow-400" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Rendement moyen</p>
                <p className="text-3xl font-bold text-gray-900 dark:text-white">
                  {(productions.reduce((acc, p) => acc + (p.rendement_reel || 0), 0) / (productions.length || 1)).toFixed(1)}
                </p>
                <p className="text-sm text-gray-500">tonnes/ha</p>
              </div>
              <div className="p-3 rounded-full bg-purple-100 dark:bg-purple-900">
                <BarChart3 className="h-6 w-6 text-purple-600 dark:text-purple-400" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Graphiques */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Évolution des rendements */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
              Évolution des rendements
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-80">
              {trendData.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={320}>
                  <LineChart data={trendData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#374151" opacity={0.2} />
                    <XAxis dataKey="mois" stroke="#6B7280" />
                    <YAxis stroke="#6B7280" />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: 'rgba(17, 24, 39, 0.9)',
                        border: 'none',
                        borderRadius: '8px',
                        color: '#fff',
                      }}
                    />
                    <Legend />
                    <Line
                      type="monotone"
                      dataKey="rendement"
                      stroke="#10B981"
                      strokeWidth={2}
                      dot={{ fill: '#10B981' }}
                      name="Rendement réel"
                    />
                    <Line
                      type="monotone"
                      dataKey="objectif"
                      stroke="#6B7280"
                      strokeWidth={2}
                      strokeDasharray="5 5"
                      name="Objectif"
                    />
                  </LineChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex items-center justify-center h-full text-gray-400">
                  Pas de données de tendance disponibles
                </div>
              )}
            </div>
          </CardContent>
        </Card>

        {/* Répartition par culture */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <PieChart className="h-5 w-5 text-blue-600" />
              Répartition des superficies
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-80">
              {repartition.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%" minWidth={0} minHeight={320}>
                  <RechartsPieChart>
                    <Pie
                      data={repartition}
                      cx="50%"
                      cy="50%"
                      innerRadius={60}
                      outerRadius={100}
                      paddingAngle={5}
                      dataKey="value"
                      label={({ name, percent }) => `${name} (${((percent || 0) * 100).toFixed(0)}%)`}
                    >
                      {repartition.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </RechartsPieChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex items-center justify-center h-full text-gray-400">
                  Pas de données de répartition disponibles
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Liste des productions */}
      <Card>
        <CardHeader>
          <CardTitle>Détail des productions</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <RefreshCw className="h-8 w-8 animate-spin text-gray-400" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b dark:border-gray-700">
                    <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Culture</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Région</th>
                    <th className="text-right py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Superficie</th>
                    <th className="text-right py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Rendement estimé</th>
                    <th className="text-right py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Rendement réel</th>
                    <th className="text-center py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Progression</th>
                    <th className="text-center py-3 px-4 font-medium text-gray-600 dark:text-gray-400">Statut</th>
                  </tr>
                </thead>
                <tbody>
                  {productions.length > 0 ? (
                    productions.map((prod, idx) => (
                      <tr key={idx} className="border-b dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800">
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-2">
                            <Leaf className="h-4 w-4 text-green-600" />
                            <span className="font-medium text-gray-900 dark:text-white">{prod.culture}</span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-gray-600 dark:text-gray-400">{prod.region}</td>
                        <td className="py-3 px-4 text-right text-gray-900 dark:text-white">{prod.superficie_ha} ha</td>
                        <td className="py-3 px-4 text-right text-gray-900 dark:text-white">{prod.rendement_estime.toFixed(1)} t/ha</td>
                        <td className="py-3 px-4 text-right">
                          {prod.rendement_reel ? (
                            <span className={prod.rendement_reel >= prod.rendement_estime ? 'text-green-600' : 'text-red-600'}>
                              {prod.rendement_reel.toFixed(1)} t/ha
                              {prod.rendement_reel >= prod.rendement_estime ? (
                                <ArrowUpRight className="h-3 w-3 inline ml-1" />
                              ) : (
                                <ArrowDownRight className="h-3 w-3 inline ml-1" />
                              )}
                            </span>
                          ) : (
                            <span className="text-gray-400">-</span>
                          )}
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center justify-center gap-2">
                            <Progress value={prod.progression} className="h-2 w-20" />
                            <span className="text-sm text-gray-600 dark:text-gray-400">{prod.progression}%</span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-center">{getStatusBadge(prod.statut)}</td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-gray-500">
                        Aucune donnée de production disponible
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

'use client'

import { useState } from 'react'
import {
  Download,
  FileSpreadsheet,
  Calendar,
  Filter,
  CheckCircle,
  Clock,
  AlertCircle,
  RefreshCw,
  Database,
  Users,
  MapPin,
  Cpu,
  Bell,
  TrendingUp,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Checkbox } from '@/components/ui/checkbox'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import api from '@/lib/api'
import toast from 'react-hot-toast'
import { logger } from '@/lib/logger'

interface ExportConfig {
  type: string
  label: string
  icon: React.ElementType
  description: string
  fields: string[]
}

const exportConfigs: ExportConfig[] = [
  {
    type: 'users',
    label: 'Agriculteurs',
    icon: Users,
    description: 'Liste des producteurs et leurs informations',
    fields: ['nom', 'prenoms', 'telephone', 'email', 'region', 'cooperative', 'date_inscription', 'statut'],
  },
  {
    type: 'parcelles',
    label: 'Parcelles',
    icon: MapPin,
    description: 'Données des parcelles agricoles',
    fields: ['nom', 'proprietaire', 'superficie', 'type_sol', 'culture', 'coordonnees', 'statut'],
  },
  {
    type: 'capteurs',
    label: 'Capteurs',
    icon: Cpu,
    description: 'État et configuration des capteurs',
    fields: ['nom', 'type', 'parcelle', 'statut', 'batterie', 'derniere_mesure', 'firmware'],
  },
  {
    type: 'mesures',
    label: 'Mesures',
    icon: TrendingUp,
    description: 'Historique des mesures des capteurs',
    fields: ['date', 'capteur', 'parcelle', 'humidite', 'temperature', 'ph', 'npk'],
  },
  {
    type: 'alertes',
    label: 'Alertes',
    icon: Bell,
    description: 'Historique des alertes générées',
    fields: ['date', 'type', 'niveau', 'message', 'parcelle', 'agriculteur', 'statut'],
  },
  {
    type: 'productions',
    label: 'Productions',
    icon: Database,
    description: 'Données de production et rendements',
    fields: ['culture', 'saison', 'superficie', 'rendement_estime', 'rendement_reel', 'region'],
  },
]

interface ExportHistory {
  id: string
  type: string
  date: string
  status: 'completed' | 'pending' | 'failed'
  size?: string
  downloadUrl?: string
}

export default function AdminExportPage() {
  /* eslint-disable @typescript-eslint/no-explicit-any */
  const [selectedTypes, setSelectedTypes] = useState<string[]>([])
  const [dateRange, setDateRange] = useState('30')
  const [format, setFormat] = useState('xlsx')
  const [exporting, setExporting] = useState(false)
  const [exportHistory, setExportHistory] = useState<ExportHistory[]>([])

  const handleTypeToggle = (type: string) => {
    setSelectedTypes((prev) =>
      prev.includes(type) ? prev.filter((t) => t !== type) : [...prev, type]
    )
  }

  const handleSelectAll = () => {
    if (selectedTypes.length === exportConfigs.length) {
      setSelectedTypes([])
    } else {
      setSelectedTypes(exportConfigs.map((c) => c.type))
    }
  }

  const handleExport = async () => {
    if (selectedTypes.length === 0) {
      toast.error('Sélectionnez au moins un type de données')
      return
    }

    setExporting(true)
    try {
      const calls: Promise<unknown>[] = []

      // Export spécifique des mesures si demandé.
      if (selectedTypes.includes('mesures')) {
        calls.push(api.get('/mesures/export', { params: { format } }))
      }

      // Export analytique global pour le reste des données admin.
      calls.push(
        api.get('/analytics/export', {
          params: {
            format,
            period: dateRange,
            types: selectedTypes.join(','),
          },
        })
      )

      await Promise.all(calls)

      toast.success('Export lancé. Vous recevrez un lien par email.')
      // En l'absence d'historique réel venant du backend, on ne rajoute pas de fausse entrée

    } catch (error) {
      logger.error('Erreur export admin', error instanceof Error ? error : undefined)
      toast.error('Service d\'export indisponible pour le moment')
    } finally {
      setExporting(false)
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return (
          <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
            <CheckCircle className="h-3 w-3 mr-1" />
            Terminé
          </Badge>
        )
      case 'pending':
        return (
          <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">
            <Clock className="h-3 w-3 mr-1" />
            En cours
          </Badge>
        )
      case 'failed':
        return (
          <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">
            <AlertCircle className="h-3 w-3 mr-1" />
            Échec
          </Badge>
        )
      default:
        return <Badge>Inconnu</Badge>
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          Export des Données
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Exportez vos données vers Excel pour des analyses avancées
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Configuration de l'export */}
        <div className="lg:col-span-2 space-y-6">
          {/* Sélection des données */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Données à exporter</CardTitle>
                  <CardDescription>
                    Sélectionnez les types de données à inclure dans l'export
                  </CardDescription>
                </div>
                <Button variant="outline" size="sm" onClick={handleSelectAll}>
                  {selectedTypes.length === exportConfigs.length ? 'Désélectionner tout' : 'Tout sélectionner'}
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {exportConfigs.map((config) => {
                  const Icon = config.icon
                  const isSelected = selectedTypes.includes(config.type)
                  return (
                    <div
                      key={config.type}
                      className={`flex items-start gap-3 p-4 border rounded-lg cursor-pointer transition-colors ${isSelected
                          ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
                          : 'border-gray-200 dark:border-gray-700 hover:border-gray-300'
                        }`}
                      onClick={() => handleTypeToggle(config.type)}
                    >
                      <Checkbox checked={isSelected} onChange={() => { }} />
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <Icon className={`h-4 w-4 ${isSelected ? 'text-green-600' : 'text-gray-500'}`} />
                          <span className="font-medium text-gray-900 dark:text-white">
                            {config.label}
                          </span>
                        </div>
                        <p className="text-sm text-gray-500 mt-1">{config.description}</p>
                        <div className="flex flex-wrap gap-1 mt-2">
                          {config.fields.slice(0, 4).map((field) => (
                            <span
                              key={field}
                              className="text-xs px-2 py-0.5 bg-gray-100 dark:bg-gray-700 rounded"
                            >
                              {field}
                            </span>
                          ))}
                          {config.fields.length > 4 && (
                            <span className="text-xs text-gray-500">
                              +{config.fields.length - 4} champs
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </CardContent>
          </Card>

          {/* Options d'export */}
          <Card>
            <CardHeader>
              <CardTitle>Options d'export</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label>Période</Label>
                  <Select value={dateRange} onValueChange={setDateRange}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="7">7 derniers jours</SelectItem>
                      <SelectItem value="30">30 derniers jours</SelectItem>
                      <SelectItem value="90">3 derniers mois</SelectItem>
                      <SelectItem value="365">Dernière année</SelectItem>
                      <SelectItem value="all">Toutes les données</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label>Format de fichier</Label>
                  <Select value={format} onValueChange={setFormat}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="xlsx">Excel (.xlsx)</SelectItem>
                      <SelectItem value="csv">CSV (.csv)</SelectItem>
                      <SelectItem value="json">JSON (.json)</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <Button
                className="w-full mt-6"
                onClick={handleExport}
                disabled={exporting || selectedTypes.length === 0}
              >
                {exporting ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Export en cours...
                  </>
                ) : (
                  <>
                    <Download className="h-4 w-4 mr-2" />
                    Générer l'export ({selectedTypes.length} type{selectedTypes.length > 1 ? 's' : ''})
                  </>
                )}
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Historique des exports */}
        <div>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-5 w-5" />
                Historique des exports
              </CardTitle>
            </CardHeader>
            <CardContent>
              {exportHistory.length === 0 ? (
                <p className="text-center text-gray-500 py-4">Aucun export récent</p>
              ) : (
                <div className="space-y-3">
                  {exportHistory.map((exp) => (
                    <div
                      key={exp.id}
                      className="flex items-center justify-between p-3 border rounded-lg dark:border-gray-700"
                    >
                      <div>
                        <div className="flex items-center gap-2">
                          <FileSpreadsheet className="h-4 w-4 text-green-600" />
                          <span className="font-medium text-sm text-gray-900 dark:text-white capitalize">
                            {exp.type}
                          </span>
                        </div>
                        <p className="text-xs text-gray-500 mt-1">{exp.date}</p>
                        {exp.size && (
                          <p className="text-xs text-gray-400">{exp.size}</p>
                        )}
                      </div>
                      <div className="flex items-center gap-2">
                        {getStatusBadge(exp.status)}
                        {exp.status === 'completed' && (
                          <Button size="sm" variant="ghost">
                            <Download className="h-4 w-4" />
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

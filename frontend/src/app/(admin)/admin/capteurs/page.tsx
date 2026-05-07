'use client'

import { useEffect, useState } from 'react'
import {
  Cpu,
  Activity,
  AlertTriangle,
  CheckCircle,
  XCircle,
  RefreshCw,
  Settings,
  Thermometer,
  Droplets,
  Gauge,
  Battery,
  Wifi,
  WifiOff,
  Search,
  Filter,
  MoreVertical,
  Wrench,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import api from '@/lib/api'
import toast from 'react-hot-toast'
import { logger } from '@/lib/logger'

interface Capteur {
  id: string
  nom: string
  type: string
  statut: string
  status?: string
  parcelle_nom?: string
  agriculteur_nom?: string
  derniere_mesure?: string
  batterie?: number
  signal?: number
  firmware_version?: string
  created_at: string
}

interface CapteurStats {
  total: number
  actifs: number
  inactifs: number
  maintenance: number
  defaillants: number
}

export default function AdminCapteursPage() {
  const [capteurs, setCapteurs] = useState<Capteur[]>([])
  const [stats, setStats] = useState<CapteurStats>({
    total: 0,
    actifs: 0,
    inactifs: 0,
    maintenance: 0,
    defaillants: 0,
  })
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<string>('all')
  const [typeFilter, setTypeFilter] = useState<string>('all')
  const [selectedCapteur, setSelectedCapteur] = useState<Capteur | null>(null)
  const [showMaintenanceDialog, setShowMaintenanceDialog] = useState(false)

  useEffect(() => {
    fetchData()
  }, [])

  const fetchData = async () => {
    setLoading(true)
    try {
      const [capteursRes] = await Promise.all([
        api.get('/capteurs').catch(() => ({ data: { data: [] } })),
      ])

      const capteursData = (capteursRes.data?.data || []).map((c: Record<string, unknown>) => ({
        ...c,
        statut: ((c.statut || c.status || '') as string).toLowerCase(),
      }))
      setCapteurs(capteursData)

      // Calculer les stats
      const calculatedStats = {
        total: capteursData.length,
        actifs: capteursData.filter((c: Capteur) => (c.statut || c.status || '').toLowerCase() === 'actif').length,
        inactifs: capteursData.filter((c: Capteur) => (c.statut || c.status || '').toLowerCase() === 'inactif').length,
        maintenance: capteursData.filter((c: Capteur) => (c.statut || c.status || '').toLowerCase() === 'maintenance').length,
        defaillants: capteursData.filter((c: Capteur) => (c.statut || c.status || '').toLowerCase() === 'defaillant').length,
      }
      setStats(calculatedStats)
    } catch (error) {
      logger.error('Erreur chargement capteurs admin', error instanceof Error ? error : undefined)
      setCapteurs([])
      setStats({
        total: 0,
        actifs: 0,
        inactifs: 0,
        maintenance: 0,
        defaillants: 0,
      })
    } finally {
      setLoading(false)
    }
  }

  const handleMaintenance = async (capteurId: string, action: 'start' | 'end') => {
    try {
      const status = action === 'start' ? 'MAINTENANCE' : 'ACTIF'
      await api.put(`/capteurs/${capteurId}`, { status })
      toast.success(action === 'start' ? 'Maintenance démarrée' : 'Maintenance terminée')
      fetchData()
    } catch {
      toast.error('Erreur lors de la mise à jour')
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'actif':
        return 'bg-green-500'
      case 'inactif':
        return 'bg-gray-500'
      case 'maintenance':
        return 'bg-yellow-500'
      case 'defaillant':
        return 'bg-red-500'
      default:
        return 'bg-gray-500'
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'actif':
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">Actif</Badge>
      case 'inactif':
        return <Badge className="bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">Inactif</Badge>
      case 'maintenance':
        return <Badge className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">Maintenance</Badge>
      case 'defaillant':
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">Défaillant</Badge>
      default:
        return <Badge>Inconnu</Badge>
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'humidite':
        return <Droplets className="h-4 w-4" />
      case 'temperature':
        return <Thermometer className="h-4 w-4" />
      case 'ph':
        return <Gauge className="h-4 w-4" />
      case 'npk':
        return <Activity className="h-4 w-4" />
      default:
        return <Cpu className="h-4 w-4" />
    }
  }

  const filteredCapteurs = capteurs.filter((capteur) => {
    const matchesSearch =
      capteur.nom.toLowerCase().includes(searchQuery.toLowerCase()) ||
      capteur.parcelle_nom?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      capteur.agriculteur_nom?.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesStatus = statusFilter === 'all' || (capteur.statut || capteur.status || '').toLowerCase() === statusFilter
    const matchesType = typeFilter === 'all' || capteur.type === typeFilter
    return matchesSearch && matchesStatus && matchesType
  })

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'Jamais'
    const date = new Date(dateString)
    if (isNaN(date.getTime())) return 'Date invalide'
    
    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)

    if (minutes < 1) return 'À l\'instant'
    if (minutes < 60) return `Il y a ${minutes} min`
    if (hours < 24) return `Il y a ${hours}h`
    return `Il y a ${days}j`
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            Supervision des Capteurs
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            Gérez et surveillez l'état de tous les capteurs du réseau
          </p>
        </div>
        <Button onClick={fetchData} variant="outline">
          <RefreshCw className="h-4 w-4 mr-2" />
          Actualiser
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-blue-100 dark:bg-blue-900">
                <Cpu className="h-5 w-5 text-blue-600 dark:text-blue-400" />
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Total</p>
                <p className="text-2xl font-bold text-gray-900 dark:text-white">{stats.total}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-green-100 dark:bg-green-900">
                <CheckCircle className="h-5 w-5 text-green-600 dark:text-green-400" />
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Actifs</p>
                <p className="text-2xl font-bold text-green-600 dark:text-green-400">{stats.actifs}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-gray-100 dark:bg-gray-700">
                <XCircle className="h-5 w-5 text-gray-600 dark:text-gray-400" />
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Inactifs</p>
                <p className="text-2xl font-bold text-gray-600 dark:text-gray-400">{stats.inactifs}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-yellow-100 dark:bg-yellow-900">
                <Wrench className="h-5 w-5 text-yellow-600 dark:text-yellow-400" />
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Maintenance</p>
                <p className="text-2xl font-bold text-yellow-600 dark:text-yellow-400">{stats.maintenance}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 rounded-lg bg-red-100 dark:bg-red-900">
                <AlertTriangle className="h-5 w-5 text-red-600 dark:text-red-400" />
              </div>
              <div>
                <p className="text-sm text-gray-600 dark:text-gray-400">Défaillants</p>
                <p className="text-2xl font-bold text-red-600 dark:text-red-400">{stats.defaillants}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="p-4">
          <div className="flex flex-col sm:flex-row gap-4">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <Input
                placeholder="Rechercher un capteur..."
                className="pl-10"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
            <Select value={statusFilter} onValueChange={setStatusFilter}>
              <SelectTrigger className="w-full sm:w-40">
                <SelectValue placeholder="Statut" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous les statuts</SelectItem>
                <SelectItem value="actif">Actif</SelectItem>
                <SelectItem value="inactif">Inactif</SelectItem>
                <SelectItem value="maintenance">Maintenance</SelectItem>
                <SelectItem value="defaillant">Défaillant</SelectItem>
              </SelectContent>
            </Select>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger className="w-full sm:w-40">
                <SelectValue placeholder="Type" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Tous les types</SelectItem>
                <SelectItem value="humidite">Humidité</SelectItem>
                <SelectItem value="temperature">Température</SelectItem>
                <SelectItem value="ph">pH</SelectItem>
                <SelectItem value="npk">NPK</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Capteurs List */}
      <Card>
        <CardHeader>
          <CardTitle>Liste des capteurs ({filteredCapteurs.length})</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center py-8">
              <RefreshCw className="h-8 w-8 animate-spin text-gray-400" />
            </div>
          ) : filteredCapteurs.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              Aucun capteur trouvé
            </div>
          ) : (
            <div className="space-y-4">
              {filteredCapteurs.map((capteur) => (
                <div
                  key={capteur.id}
                  className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-4 border rounded-lg dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors"
                >
                  <div className="flex items-start gap-4 flex-1">
                    <div className={`p-3 rounded-lg ${getStatusColor((capteur.statut || capteur.status || '').toLowerCase())} bg-opacity-20`}>
                      {getTypeIcon(capteur.type)}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h3 className="font-medium text-gray-900 dark:text-white">{capteur.nom}</h3>
                        {getStatusBadge((capteur.statut || capteur.status || '').toLowerCase())}
                      </div>
                      <p className="text-sm text-gray-600 dark:text-gray-400">
                        {capteur.parcelle_nom} • {capteur.agriculteur_nom}
                      </p>
                      <p className="text-xs text-gray-500 dark:text-gray-500 mt-1">
                        Dernière mesure: {formatDate(capteur.derniere_mesure)}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-6 mt-4 sm:mt-0">
                    {/* Batterie */}
                    <div className="flex items-center gap-2">
                      <Battery className={`h-4 w-4 ${(capteur.batterie || 0) < 20 ? 'text-red-500' : 'text-gray-500'}`} />
                      <div className="w-16">
                        <Progress value={capteur.batterie || 0} className="h-2" />
                      </div>
                      <span className="text-xs text-gray-500">{capteur.batterie || 0}%</span>
                    </div>

                    {/* Signal */}
                    <div className="flex items-center gap-2">
                      {(capteur.signal || 0) > 50 ? (
                        <Wifi className="h-4 w-4 text-green-500" />
                      ) : (
                        <WifiOff className="h-4 w-4 text-red-500" />
                      )}
                      <span className="text-xs text-gray-500">{capteur.signal || 0}%</span>
                    </div>

                    {/* Actions */}
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm">
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => setSelectedCapteur(capteur)}>
                          <Settings className="h-4 w-4 mr-2" />
                          Détails
                        </DropdownMenuItem>
                        {(capteur.statut || capteur.status || '').toLowerCase() !== 'maintenance' && (
                          <DropdownMenuItem onClick={() => handleMaintenance(capteur.id, 'start')}>
                            <Wrench className="h-4 w-4 mr-2" />
                            Mettre en maintenance
                          </DropdownMenuItem>
                        )}
                        {(capteur.statut || capteur.status || '').toLowerCase() === 'maintenance' && (
                          <DropdownMenuItem onClick={() => handleMaintenance(capteur.id, 'end')}>
                            <CheckCircle className="h-4 w-4 mr-2" />
                            Terminer maintenance
                          </DropdownMenuItem>
                        )}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Capteur Detail Dialog */}
      <Dialog open={!!selectedCapteur} onOpenChange={() => setSelectedCapteur(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{selectedCapteur?.nom}</DialogTitle>
            <DialogDescription>
              Informations détaillées du capteur
            </DialogDescription>
          </DialogHeader>
          {selectedCapteur && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-500">Type</p>
                  <p className="font-medium capitalize">{selectedCapteur.type}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Statut</p>
                  {getStatusBadge((selectedCapteur.statut || selectedCapteur.status || '').toLowerCase())}
                </div>
                <div>
                  <p className="text-sm text-gray-500">Parcelle</p>
                  <p className="font-medium">{selectedCapteur.parcelle_nom || '-'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Agriculteur</p>
                  <p className="font-medium">{selectedCapteur.agriculteur_nom || '-'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Version Firmware</p>
                  <p className="font-medium">{selectedCapteur.firmware_version || '-'}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Installé le</p>
                  <p className="font-medium">{new Date(selectedCapteur.created_at).toLocaleDateString('fr-FR')}</p>
                </div>
              </div>
              <div className="pt-4 border-t">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm text-gray-500">Batterie</span>
                  <span className="font-medium">{selectedCapteur.batterie || 0}%</span>
                </div>
                <Progress value={selectedCapteur.batterie || 0} className="h-2" />
              </div>
              <div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm text-gray-500">Signal</span>
                  <span className="font-medium">{selectedCapteur.signal || 0}%</span>
                </div>
                <Progress value={selectedCapteur.signal || 0} className="h-2" />
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  )
}

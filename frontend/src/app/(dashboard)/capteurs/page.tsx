'use client'

import { useState, useEffect, useCallback } from 'react'
import {
  Radio,
  RadioTower,
  Battery,
  Thermometer,
  Droplets,
  Sun,
  Wind,
  Gauge,
  Plus,
  Settings,
  RefreshCw,
  MoreVertical,
  MapPin,
  Clock,
  AlertTriangle,
  CheckCircle2,
  Trash2,
  Edit,
  Power,
  Activity,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { Spinner } from '@/components/ui/spinner'
import toast from 'react-hot-toast'
import api from '@/lib/api'
import SensorDetailDialog from '@/components/capteurs/SensorDetailDialog'

interface Capteur {
  id: string
  nom: string
  type: 'humidite_temperature_ambiante' | 'humidite_sol' | 'uv' | 'npk' | 'direction_vent' | 'transpiration_plante'
  parcelleId: string
  parcelleNom: string
  statut: 'actif' | 'inactif' | 'maintenance' | 'erreur'
  batterie: number
  signal: number
  derniereMesure: {
    valeur: number | string
    unite: string
    date: string
  }
  seuilMin: number
  seuilMax: number
  coordonnees: {
    latitude: number
    longitude: number
  }
}

export default function CapteursPage() {
  const [capteurs, setCapteurs] = useState<Capteur[]>([])
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [filterType, setFilterType] = useState<string>('all')
  const [filterStatus, setFilterStatus] = useState<string>('all')
  const [showAddDialog, setShowAddDialog] = useState(false)
  const [selectedCapteur, setSelectedCapteur] = useState<Capteur | null>(null)
  const [detailCapteur, setDetailCapteur] = useState<Capteur | null>(null)
  const [parcelles, setParcelles] = useState<any[]>([])
  const [creating, setCreating] = useState(false)
  const [newSensorData, setNewSensorData] = useState({
    nom: '',
    type: 'humidite_temperature_ambiante',
    parcelle_id: '',
    seuil_min: '0',
    seuil_max: '100',
    identifiant: ''
  })

  // Fetch parcelles for dropdown
  useEffect(() => {
    const fetchParcelles = async () => {
      try {
        const res = await api.get('/parcelles');
        if (res.data.success) {
          setParcelles(res.data.data);
          // Set default parcelle if available
          if (res.data.data.length > 0) {
            setNewSensorData(prev => ({ ...prev, parcelle_id: res.data.data[0].id }));
          }
        }
      } catch (e) {
        console.error('Error fetching parcelles', e);
      }
    };
    fetchParcelles();
  }, []);

  const fetchCapteurs = useCallback(async () => {
    try {
      const response = await api.get('/capteurs')
      // Handle API response structure: {success: true, data: [...]}
      const data = response.data?.data || response.data
      if (Array.isArray(data)) {
        setCapteurs(data)
      } else {
        setCapteurs([])
      }
    } catch (error) {
      console.error('Erreur lors du chargement des capteurs:', error)
      toast.error('Impossible de charger les capteurs')
      setCapteurs([])
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [])

  useEffect(() => {
    fetchCapteurs()
  }, [fetchCapteurs])

  const handleRefresh = async () => {
    setRefreshing(true)
    await fetchCapteurs()
    toast.success('Données actualisées')
  }

  const handleToggleStatus = async (capteur: Capteur) => {
    try {
      const newStatus = capteur.statut?.toLowerCase() === 'actif' ? 'inactif' : 'actif'
      await api.patch(`/capteurs/${capteur.id}/toggle`, { status: newStatus })
      toast.success(`Capteur ${newStatus === 'actif' ? 'activé' : 'désactivé'} avec succès`)
      await fetchCapteurs()
    } catch (error) {
      console.error('Erreur toggle status:', error)
      toast.error('Erreur lors de la modification du statut')
    }
  }

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'humidite_temperature_ambiante': return <Thermometer className="h-5 w-5" />
      case 'humidite_sol': return <Droplets className="h-5 w-5" />
      case 'uv': return <Sun className="h-5 w-5" />
      case 'npk': return <Gauge className="h-5 w-5" />
      case 'direction_vent': return <Wind className="h-5 w-5" />
      case 'transpiration_plante': return <Activity className="h-5 w-5" />
      default: return <Activity className="h-5 w-5" />
    }
  }

  const getTypeLabel = (type: string) => {
    switch (type) {
      case 'humidite_temperature_ambiante': return 'Humidité & Température'
      case 'humidite_sol': return 'Humidité Sol'
      case 'uv': return 'UV'
      case 'npk': return 'NPK (Nutriments)'
      case 'direction_vent': return 'Direction du vent'
      case 'transpiration_plante': return 'Transpiration plante'
      default: return type
    }
  }

  const getStatusBadge = (statut: string) => {
    switch (statut?.toLowerCase()) {
      case 'actif':
        return <Badge className="bg-green-100 text-green-800">Actif</Badge>
      case 'inactif':
        return <Badge className="bg-gray-100 text-gray-800">Inactif</Badge>
      case 'maintenance':
        return <Badge className="bg-orange-100 text-orange-800">Maintenance</Badge>
      case 'erreur':
        return <Badge className="bg-red-100 text-red-800">Erreur</Badge>
      default:
        return <Badge>{statut}</Badge>
    }
  }

  const getBatteryColor = (level: number) => {
    if (level > 50) return 'text-green-500'
    if (level > 20) return 'text-orange-500'
    return 'text-red-500'
  }

  const getSignalColor = (level: number) => {
    if (level > 70) return 'text-green-500'
    if (level > 40) return 'text-orange-500'
    return 'text-red-500'
  }

  const isValueAlert = (capteur: Capteur) => {
    // Safety check: return false if derniereMesure is undefined
    if (!capteur.derniereMesure) return false

    const { valeur } = capteur.derniereMesure
    // Handle NPK which returns string format (N|P|K)
    if (typeof valeur === 'string') return false
    return valeur < capteur.seuilMin || valeur > capteur.seuilMax
  }

  const filteredCapteurs = capteurs.filter(capteur => {
    const matchesSearch = (capteur.nom?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
      (capteur.parcelleNom?.toLowerCase() || '').includes(searchQuery.toLowerCase())
    const matchesType = filterType === 'all' || capteur.type === filterType
    const matchesStatus = filterStatus === 'all' || capteur.statut?.toLowerCase() === filterStatus
    return matchesSearch && matchesType && matchesStatus
  })

  const normalize = (s: string) => s?.toLowerCase() || ''
  const stats = {
    total: capteurs.length,
    actifs: capteurs.filter(c => normalize(c.statut) === 'actif').length,
    alertes: capteurs.filter(c => normalize(c.statut) === 'erreur' || c.batterie < 20).length,
    maintenance: capteurs.filter(c => normalize(c.statut) === 'maintenance').length,
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
            Capteurs IoT
          </h1>
          <p className="text-gray-500 mt-1">
            Gérez vos capteurs connectés et surveillez leurs données
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
          <Button onClick={() => setShowAddDialog(true)} className="gap-2">
            <Plus className="h-4 w-4" />
            Ajouter
          </Button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Activity className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold">{stats.total}</p>
                <p className="text-sm text-gray-500">Total capteurs</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-100 rounded-lg">
                <CheckCircle2 className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-green-600">{stats.actifs}</p>
                <p className="text-sm text-gray-500">Actifs</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-red-100 rounded-lg">
                <AlertTriangle className="h-5 w-5 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-red-600">{stats.alertes}</p>
                <p className="text-sm text-gray-500">Alertes</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-orange-100 rounded-lg">
                <Settings className="h-5 w-5 text-orange-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-orange-600">{stats.maintenance}</p>
                <p className="text-sm text-gray-500">Maintenance</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Filters */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="flex-1">
          <Input
            placeholder="Rechercher un capteur..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
        <select
          value={filterType}
          onChange={(e) => setFilterType(e.target.value)}
          className="px-4 py-2 border rounded-lg bg-white"
          title="Filtrer par type"
        >
          <option value="all">Tous les types</option>
          <option value="humidite_temperature_ambiante">Humidité & Température</option>
          <option value="humidite_sol">Humidité Sol</option>
          <option value="uv">UV</option>
          <option value="npk">NPK (Nutriments)</option>
          <option value="direction_vent">Direction du vent</option>
          <option value="transpiration_plante">Transpiration plante</option>
        </select>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="px-4 py-2 border rounded-lg bg-white"
          title="Filtrer par statut"
        >
          <option value="all">Tous les statuts</option>
          <option value="actif">Actif</option>
          <option value="inactif">Inactif</option>
          <option value="maintenance">Maintenance</option>
          <option value="erreur">Erreur</option>
        </select>
      </div>

      {/* Capteurs Grid */}
      {filteredCapteurs.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center text-gray-500">
            <Activity className="h-16 w-16 mx-auto mb-4 opacity-20" />
            <p className="font-medium">Aucun capteur trouvé</p>
            <p className="text-sm mt-1">Modifiez vos filtres ou ajoutez un nouveau capteur</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredCapteurs.map((capteur) => (
            <Card
              key={capteur.id}
              className={`hover:shadow-lg transition-shadow cursor-pointer ${capteur.statut?.toLowerCase() === 'erreur' ? 'border-red-200 bg-red-50/50' :
                capteur.statut?.toLowerCase() === 'maintenance' ? 'border-orange-200 bg-orange-50/50' : ''
                }`}
              onClick={() => setDetailCapteur(capteur)}
            >
              <CardHeader className="pb-2">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${capteur.statut?.toLowerCase() === 'actif' ? 'bg-primary/10 text-primary' :
                      capteur.statut?.toLowerCase() === 'erreur' ? 'bg-red-100 text-red-600' :
                        'bg-gray-100 text-gray-600'
                      }`}>
                      {getTypeIcon(capteur.type)}
                    </div>
                    <div>
                      <CardTitle className="text-base">{capteur.nom}</CardTitle>
                      <CardDescription className="flex items-center gap-1">
                        <MapPin className="h-3 w-3" />
                        {capteur.parcelleNom}
                      </CardDescription>
                    </div>
                  </div>
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <button className="p-1 hover:bg-gray-100 rounded" aria-label="Options" onClick={(e) => e.stopPropagation()}>
                        <MoreVertical className="h-4 w-4 text-gray-500" />
                      </button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => setSelectedCapteur(capteur)}>
                        <Settings className="h-4 w-4 mr-2" />
                        Configurer
                      </DropdownMenuItem>
                      <DropdownMenuItem>
                        <Edit className="h-4 w-4 mr-2" />
                        Modifier
                      </DropdownMenuItem>
                      <DropdownMenuItem onClick={() => handleToggleStatus(capteur)}>
                        <Power className="h-4 w-4 mr-2" />
                        {capteur.statut?.toLowerCase() === 'actif' ? 'Désactiver' : 'Activer'}
                      </DropdownMenuItem>
                      <DropdownMenuItem className="text-red-600">
                        <Trash2 className="h-4 w-4 mr-2" />
                        Supprimer
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Mesure actuelle */}
                <div className={`p-4 rounded-lg ${isValueAlert(capteur) ? 'bg-red-100' : 'bg-gray-50'
                  }`}>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">{getTypeLabel(capteur.type)}</span>
                    {isValueAlert(capteur) && (
                      <AlertTriangle className="h-4 w-4 text-red-500" />
                    )}
                  </div>
                  {capteur.derniereMesure ? (
                    <>
                      <p className={`text-3xl font-bold ${isValueAlert(capteur) ? 'text-red-600' : 'text-gray-900'
                        }`}>
                        {capteur.derniereMesure.valeur}
                        <span className="text-lg font-normal ml-1">
                          {capteur.derniereMesure.unite}
                        </span>
                      </p>
                      <p className="text-xs text-gray-500 mt-1">
                        Seuils: {capteur.seuilMin} - {capteur.seuilMax} {capteur.derniereMesure.unite}
                      </p>
                    </>
                  ) : (
                    <p className="text-lg text-gray-500 italic">Aucune mesure disponible</p>
                  )}
                </div>

                {/* Status & Signal */}
                <div className="flex items-center justify-between">
                  {getStatusBadge(capteur.statut)}
                  <div className="flex items-center gap-1" title={`Signal: ${capteur.signal}%`}>
                    {capteur.signal > 0 ? (
                      <Radio className={`h-4 w-4 ${getSignalColor(capteur.signal)}`} />
                    ) : (
                      <RadioTower className="h-4 w-4 text-red-500" />
                    )}
                    <span className="text-xs">{capteur.signal}%</span>
                  </div>
                </div>

                {/* Last update */}
                {capteur.derniereMesure?.date && (
                  <div className="flex items-center gap-2 text-xs text-gray-500 pt-2 border-t">
                    <Clock className="h-3 w-3" />
                    Dernière mesure: {(() => {
                      const date = new Date(capteur.derniereMesure.date);
                      return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleString('fr-FR');
                    })()}
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Sensor Detail Dialog */}
      <SensorDetailDialog
        capteur={detailCapteur}
        open={!!detailCapteur}
        onClose={() => setDetailCapteur(null)}
      />

      {/* Add Dialog */}
      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Ajouter un capteur</DialogTitle>
            <DialogDescription>
              Configurez un nouveau capteur IoT pour votre exploitation
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Nom du capteur *</label>
              <Input
                placeholder="Ex: Capteur Température Zone A"
                value={newSensorData.nom}
                onChange={e => setNewSensorData({ ...newSensorData, nom: e.target.value })}
              />
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Type de capteur *</label>
              <select
                className="w-full px-4 py-2 border rounded-lg"
                value={newSensorData.type}
                onChange={e => setNewSensorData({ ...newSensorData, type: e.target.value })}
                aria-label="Type de capteur"
              >
                <option value="humidite_temperature_ambiante">Humidité & Température Ambiante</option>
                <option value="humidite_sol">Humidité du sol</option>
                <option value="uv">UV</option>
                <option value="npk">NPK</option>
                <option value="direction_vent">Direction du vent</option>
                <option value="transpiration_plante">Transpiration plante</option>
              </select>
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Parcelle associée *</label>
              <select
                className="w-full px-4 py-2 border rounded-lg"
                value={newSensorData.parcelle_id}
                onChange={e => setNewSensorData({ ...newSensorData, parcelle_id: e.target.value })}
                aria-label="Parcelle associée"
              >
                {parcelles.map(p => (
                  <option key={p.id} value={p.id}>{p.nom}</option>
                ))}
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <label className="text-sm font-medium">Seuil minimum</label>
                <Input
                  type="number"
                  value={newSensorData.seuil_min}
                  onChange={e => setNewSensorData({ ...newSensorData, seuil_min: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Seuil maximum</label>
                <Input
                  type="number"
                  value={newSensorData.seuil_max}
                  onChange={e => setNewSensorData({ ...newSensorData, seuil_max: e.target.value })}
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowAddDialog(false)}>
              Annuler
            </Button>
            <Button onClick={async () => {
              if (!newSensorData.nom || !newSensorData.type || !newSensorData.parcelle_id) {
                toast.error('Veuillez remplir les champs obligatoires');
                return;
              }

              setCreating(true);
              try {
                const response = await api.post('/capteurs', {
                  ...newSensorData,
                  seuil_min: Number(newSensorData.seuil_min),
                  seuil_max: Number(newSensorData.seuil_max),
                });

                if (response.data.success) {
                  toast.success('Capteur ajouté avec succès');
                  setShowAddDialog(false);
                  fetchCapteurs();
                  setNewSensorData({
                    nom: '',
                    type: 'humidite_temperature_ambiante',
                    parcelle_id: '',
                    seuil_min: '0',
                    seuil_max: '100',
                    identifiant: ''
                  });
                }
              } catch (error) {
                console.error(error);
                toast.error('Erreur lors de la création du capteur');
              } finally {
                setCreating(false);
              }
            }} disabled={creating}>
              {creating ? <Spinner className="h-4 w-4 mr-2" /> : null}
              Ajouter
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Config Dialog */}
      <Dialog open={!!selectedCapteur} onOpenChange={() => setSelectedCapteur(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Configuration du capteur</DialogTitle>
            <DialogDescription>
              {selectedCapteur?.nom}
            </DialogDescription>
          </DialogHeader>
          {selectedCapteur && (
            <div className="space-y-4 py-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-2">
                  <label className="text-sm font-medium">Seuil minimum</label>
                  <Input type="number" defaultValue={selectedCapteur.seuilMin} />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium">Seuil maximum</label>
                  <Input type="number" defaultValue={selectedCapteur.seuilMax} />
                </div>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Fréquence de mesure</label>
                <select className="w-full px-4 py-2 border rounded-lg" title="Fréquence de mesure">
                  <option value="5">Toutes les 5 minutes</option>
                  <option value="15">Toutes les 15 minutes</option>
                  <option value="30">Toutes les 30 minutes</option>
                  <option value="60">Toutes les heures</option>
                </select>
              </div>
              <div className="space-y-2">
                <label className="text-sm font-medium">Alertes</label>
                <div className="flex items-center gap-2">
                  <input type="checkbox" id="alertSms" defaultChecked />
                  <label htmlFor="alertSms" className="text-sm">SMS</label>
                </div>
                <div className="flex items-center gap-2">
                  <input type="checkbox" id="alertPush" defaultChecked />
                  <label htmlFor="alertPush" className="text-sm">Notification push</label>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={() => setSelectedCapteur(null)}>
              Annuler
            </Button>
            <Button onClick={() => {
              toast.success('Configuration sauvegardée')
              setSelectedCapteur(null)
            }}>
              Sauvegarder
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

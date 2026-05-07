'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { 
  ArrowLeft,
  User,
  Phone,
  Mail,
  Calendar,
  MapPin,
  Thermometer,
  BarChart3,
  Bell,
  Activity,
  Edit,
  MoreVertical,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import api from '@/lib/api'
import toast from 'react-hot-toast'
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
  langue_preferee: string
  region_id: string | null
  cooperative_id: string | null
}

interface Parcelle {
  id: string
  nom: string
  description: string
  surface: number
  latitude: number
  longitude: number
  type_sol: string
  status: string
  created_at: string
}

interface Capteur {
  id: string
  nom: string
  type: string
  status: string
  parcelle_id: string
  derniere_mesure: string | null
}

interface Mesure {
  id: string
  capteur_id: string
  valeur: number
  unite: string
  created_at: string
}

interface Alerte {
  id: string
  type: string
  niveau: string
  message: string
  lu: boolean
  created_at: string
}

export default function AgriculteurDetailPage() {
  const params = useParams()
  const agriculteurId = params.id as string

  const [agriculteur, setAgriculteur] = useState<Agriculteur | null>(null)
  const [parcelles, setParcelles] = useState<Parcelle[]>([])
  const [capteurs, setCapteurs] = useState<Capteur[]>([])
  const [mesures, setMesures] = useState<Mesure[]>([])
  const [alertes, setAlertes] = useState<Alerte[]>([])
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'parcelles' | 'capteurs' | 'mesures' | 'alertes'>('parcelles')

  useEffect(() => {
    if (agriculteurId) {
      fetchAgriculteurData()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [agriculteurId])

  const fetchAgriculteurData = async () => {
    setLoading(true)
    try {
      // Récupérer les données de l'agriculteur
      const userRes = await api.get(`/users/${agriculteurId}`)
      setAgriculteur(userRes.data?.data || null)

      // Récupérer les parcelles de l'agriculteur
      const parcellesRes = await api.get('/parcelles').catch(() => ({ data: { data: [] } }))
      const userParcelles = (parcellesRes.data?.data || []).filter(
        (p: { user_id: string }) => p.user_id === agriculteurId
      )
      setParcelles(userParcelles)

      // Récupérer les capteurs des parcelles de l'agriculteur
      const capteursRes = await api.get('/capteurs').catch(() => ({ data: { data: [] } }))
      const parcelleIds = userParcelles.map((p: Parcelle) => p.id)
      const userCapteurs = (capteursRes.data?.data || []).filter(
        (c: { parcelle_id: string }) => parcelleIds.includes(c.parcelle_id)
      )
      setCapteurs(userCapteurs)

      // Récupérer les mesures des capteurs
      const mesuresRes = await api.get('/mesures').catch(() => ({ data: { data: [] } }))
      const capteurIds = userCapteurs.map((c: Capteur) => c.id)
      const userMesures = (mesuresRes.data?.data || []).filter(
        (m: { capteur_id: string }) => capteurIds.includes(m.capteur_id)
      )
      setMesures(userMesures.slice(0, 50)) // Limiter à 50 mesures

      // Récupérer les alertes de l'agriculteur
      const alertesRes = await api.get('/alertes').catch(() => ({ data: { data: [] } }))
      const userAlertes = (alertesRes.data?.data || []).filter(
        (a: { user_id: string }) => a.user_id === agriculteurId
      )
      setAlertes(userAlertes)

    } catch (error) {
      logger.error('Erreur chargement détail agriculteur admin', error instanceof Error ? error : undefined)
      toast.error('Erreur lors du chargement des données')
      setAgriculteur(null)
      setParcelles([])
      setCapteurs([])
      setMesures([])
      setAlertes([])
    } finally {
      setLoading(false)
    }
  }

  const handleStatusChange = async (newStatus: string) => {
    try {
      const normalizedStatus = newStatus.toUpperCase()
      await api.put(`/users/${agriculteurId}/status`, { status: normalizedStatus })
      setAgriculteur(prev => prev ? { ...prev, status: normalizedStatus } : null)
      toast.success(`Statut mis à jour: ${newStatus}`)
    } catch {
      toast.error('Erreur lors de la mise à jour du statut')
    }
  }

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'actif':
      case 'ACTIF':
      case 'active':
        return <Badge className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">Actif</Badge>
      case 'inactif':
      case 'INACTIF':
      case 'inactive':
        return <Badge className="bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300">Inactif</Badge>
      case 'suspendu':
      case 'SUSPENDU':
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">Suspendu</Badge>
      default:
        return <Badge>{status}</Badge>
    }
  }

  const getNiveauBadge = (niveau: string) => {
    switch (niveau) {
      case 'critique':
        return <Badge className="bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300">Critique</Badge>
      case 'important':
        return <Badge className="bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300">Important</Badge>
      default:
        return <Badge className="bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300">Info</Badge>
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
      </div>
    )
  }

  if (!agriculteur) {
    return (
      <div className="text-center py-12">
        <User className="h-16 w-16 mx-auto text-gray-300 mb-4" />
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
          Agriculteur non trouvé
        </h2>
        <Link href="/admin/agriculteurs">
          <Button>Retour à la liste</Button>
        </Link>
      </div>
    )
  }

  const tabs = [
    { id: 'parcelles', label: 'Parcelles', count: parcelles.length, icon: MapPin },
    { id: 'capteurs', label: 'Capteurs', count: capteurs.length, icon: Thermometer },
    { id: 'mesures', label: 'Mesures', count: mesures.length, icon: BarChart3 },
    { id: 'alertes', label: 'Alertes', count: alertes.length, icon: Bell },
  ]

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/admin/agriculteurs">
          <Button variant="outline" size="sm" className="dark:border-gray-600 dark:text-gray-300">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
        </Link>
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
          Détails de l&apos;agriculteur
        </h2>
      </div>

      {/* Profile Card */}
      <Card className="dark:bg-gray-800 dark:border-gray-700">
        <CardContent className="p-6">
          <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-6">
            <div className="flex items-start gap-4">
              <div className="h-20 w-20 rounded-full bg-blue-100 dark:bg-blue-900 flex items-center justify-center shrink-0">
                <span className="text-3xl font-bold text-blue-600 dark:text-blue-400">
                  {agriculteur.nom.charAt(0)}
                </span>
              </div>
              <div>
                <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {agriculteur.prenoms} {agriculteur.nom}
                </h3>
                <div className="flex items-center gap-2 mt-2">
                  {getStatusBadge(agriculteur.status)}
                  <Badge variant="outline" className="dark:border-gray-600 dark:text-gray-300">
                    {agriculteur.role}
                  </Badge>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4 text-sm">
                  <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                    <Phone className="h-4 w-4" />
                    {agriculteur.telephone}
                  </div>
                  {agriculteur.email && (
                    <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                      <Mail className="h-4 w-4" />
                      {agriculteur.email}
                    </div>
                  )}
                  <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                    <Calendar className="h-4 w-4" />
                    Inscrit le {(() => {
                      if (!agriculteur.created_at) return 'Date inconnue';
                      const date = new Date(agriculteur.created_at);
                      return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleDateString('fr-FR');
                    })()}
                  </div>
                  {agriculteur.derniere_connexion && (
                    <div className="flex items-center gap-2 text-gray-600 dark:text-gray-400">
                      <Activity className="h-4 w-4" />
                      Dernière connexion: {(() => {
                        const date = new Date(agriculteur.derniere_connexion);
                        return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleDateString('fr-FR');
                      })()}
                    </div>
                  )}
                </div>
              </div>
            </div>
            <div className="flex gap-2">
              <Button variant="outline" className="dark:border-gray-600 dark:text-gray-300">
                <Edit className="h-4 w-4 mr-2" />
                Modifier
              </Button>
              <div className="relative group">
                <Button variant="outline" className="dark:border-gray-600 dark:text-gray-300">
                  <MoreVertical className="h-4 w-4" />
                </Button>
                <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border dark:border-gray-700 hidden group-hover:block z-10">
                  <button
                    onClick={() => handleStatusChange('actif')}
                    className="w-full text-left px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700 text-green-600"
                  >
                    Activer
                  </button>
                  <button
                    onClick={() => handleStatusChange('suspendu')}
                    className="w-full text-left px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700 text-red-600"
                  >
                    Suspendre
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6 pt-6 border-t dark:border-gray-700">
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{parcelles.length}</p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Parcelles</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{capteurs.length}</p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Capteurs</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900 dark:text-white">{mesures.length}</p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Mesures</p>
            </div>
            <div className="text-center">
              <p className="text-2xl font-bold text-gray-900 dark:text-white">
                {alertes.filter(a => !a.lu).length}
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400">Alertes non lues</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tabs */}
      <div className="border-b dark:border-gray-700">
        <nav className="flex gap-4">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id as typeof activeTab)}
              className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab.id
                  ? 'border-green-600 text-green-600 dark:text-green-400'
                  : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300'
              }`}
            >
              <tab.icon className="h-4 w-4" />
              {tab.label}
              <Badge variant="outline" className="ml-1">{tab.count}</Badge>
            </button>
          ))}
        </nav>
      </div>

      {/* Tab Content */}
      <div>
        {activeTab === 'parcelles' && (
          <div className="grid gap-4">
            {parcelles.length > 0 ? (
              parcelles.map((parcelle) => (
                <Card key={parcelle.id} className="dark:bg-gray-800 dark:border-gray-700">
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white">{parcelle.nom}</h4>
                        <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">{parcelle.description}</p>
                        <div className="flex items-center gap-4 mt-2 text-sm text-gray-600 dark:text-gray-400">
                          <span>{parcelle.surface} ha</span>
                          <span>Sol: {parcelle.type_sol}</span>
                          <span>
                            GPS: {parcelle.latitude?.toFixed(4)}, {parcelle.longitude?.toFixed(4)}
                          </span>
                        </div>
                      </div>
                      {getStatusBadge(parcelle.status)}
                    </div>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card className="dark:bg-gray-800 dark:border-gray-700">
                <CardContent className="p-8 text-center">
                  <MapPin className="h-12 w-12 mx-auto text-gray-300 dark:text-gray-600 mb-2" />
                  <p className="text-gray-500 dark:text-gray-400">Aucune parcelle enregistrée</p>
                </CardContent>
              </Card>
            )}
          </div>
        )}

        {activeTab === 'capteurs' && (
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {capteurs.length > 0 ? (
              capteurs.map((capteur) => (
                <Card key={capteur.id} className="dark:bg-gray-800 dark:border-gray-700">
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <h4 className="font-semibold text-gray-900 dark:text-white">{capteur.nom}</h4>
                        <p className="text-sm text-gray-500 dark:text-gray-400 capitalize">{capteur.type}</p>
                      </div>
                      {getStatusBadge(capteur.status)}
                    </div>
                    {capteur.derniere_mesure && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                        Dernière mesure: {(() => {
                          const date = new Date(capteur.derniere_mesure);
                          return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleString('fr-FR');
                        })()}
                      </p>
                    )}
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card className="dark:bg-gray-800 dark:border-gray-700 md:col-span-2 lg:col-span-3">
                <CardContent className="p-8 text-center">
                  <Thermometer className="h-12 w-12 mx-auto text-gray-300 dark:text-gray-600 mb-2" />
                  <p className="text-gray-500 dark:text-gray-400">Aucun capteur enregistré</p>
                </CardContent>
              </Card>
            )}
          </div>
        )}

        {activeTab === 'mesures' && (
          <Card className="dark:bg-gray-800 dark:border-gray-700">
            <CardHeader>
              <CardTitle className="dark:text-white">Historique des mesures</CardTitle>
            </CardHeader>
            <CardContent>
              {mesures.length > 0 ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-b dark:border-gray-700">
                        <th className="text-left py-3 px-4 text-gray-500 dark:text-gray-400">Date</th>
                        <th className="text-left py-3 px-4 text-gray-500 dark:text-gray-400">Capteur</th>
                        <th className="text-left py-3 px-4 text-gray-500 dark:text-gray-400">Valeur</th>
                        <th className="text-left py-3 px-4 text-gray-500 dark:text-gray-400">Unité</th>
                      </tr>
                    </thead>
                    <tbody>
                      {mesures.map((mesure) => (
                        <tr key={mesure.id} className="border-b dark:border-gray-700">
                          <td className="py-3 px-4 text-gray-900 dark:text-white">
                            {new Date(mesure.created_at).toLocaleString('fr-FR')}
                          </td>
                          <td className="py-3 px-4 text-gray-600 dark:text-gray-400">
                            {capteurs.find(c => c.id === mesure.capteur_id)?.nom || mesure.capteur_id}
                          </td>
                          <td className="py-3 px-4 font-medium text-gray-900 dark:text-white">
                            {mesure.valeur}
                          </td>
                          <td className="py-3 px-4 text-gray-600 dark:text-gray-400">{mesure.unite}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="text-center py-8">
                  <BarChart3 className="h-12 w-12 mx-auto text-gray-300 dark:text-gray-600 mb-2" />
                  <p className="text-gray-500 dark:text-gray-400">Aucune mesure enregistrée</p>
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {activeTab === 'alertes' && (
          <div className="grid gap-4">
            {alertes.length > 0 ? (
              alertes.map((alerte) => (
                <Card key={alerte.id} className={`dark:bg-gray-800 dark:border-gray-700 ${!alerte.lu ? 'border-l-4 border-l-orange-500' : ''}`}>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between">
                      <div className="flex items-start gap-3">
                        <Bell className={`h-5 w-5 mt-0.5 ${!alerte.lu ? 'text-orange-500' : 'text-gray-400'}`} />
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-gray-900 dark:text-white capitalize">{alerte.type}</span>
                            {getNiveauBadge(alerte.niveau)}
                            {!alerte.lu && <Badge className="bg-orange-100 text-orange-800 text-xs">Non lu</Badge>}
                          </div>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">{alerte.message}</p>
                          <p className="text-xs text-gray-500 dark:text-gray-500 mt-2">
                            {(() => {
                              if (!alerte.created_at) return 'Date inconnue';
                              const date = new Date(alerte.created_at);
                              return isNaN(date.getTime()) ? 'Date invalide' : date.toLocaleString('fr-FR');
                            })()}
                          </p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            ) : (
              <Card className="dark:bg-gray-800 dark:border-gray-700">
                <CardContent className="p-8 text-center">
                  <Bell className="h-12 w-12 mx-auto text-gray-300 dark:text-gray-600 mb-2" />
                  <p className="text-gray-500 dark:text-gray-400">Aucune alerte</p>
                </CardContent>
              </Card>
            )}
          </div>
        )}
      </div>
    </div>
  )
}

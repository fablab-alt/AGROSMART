'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import {
  ArrowLeft,
  MapPin,
  Droplets,
  Thermometer,
  AlertCircle,
  CheckCircle2,
  Leaf,
  TrendingUp,
  Send,
  Loader2,
  Eye,
  EyeOff,
  Navigation,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import toast from 'react-hot-toast'
import { useGeolocation } from '@/hooks/useGeolocation'

interface DemoParcel {
  id: string
  nom: string
  superficie: number
  latitude: number
  longitude: number
  culture: string
  humidite: number
  temperature: number
  ph: number
  status: 'optimal' | 'alerte' | 'critique'
}

interface DemoAlert {
  id: string
  type: 'humidité' | 'température' | 'maladie' | 'irrigation'
  titre: string
  description: string
  sévérité: 'faible' | 'moyen' | 'élevé'
  parcelleId: string
}

// Données de démonstration simulées
const DEMO_PARCELS: DemoParcel[] = [
  {
    id: '1',
    nom: 'Parcelle Cacao Nord',
    superficie: 3.5,
    latitude: 5.3599,
    longitude: -4.0083,
    culture: 'Cacao',
    humidite: 65,
    temperature: 28,
    ph: 6.5,
    status: 'optimal',
  },
  {
    id: '2',
    nom: 'Parcelle Café Centre',
    superficie: 2.1,
    latitude: 5.3600,
    longitude: -4.0081,
    culture: 'Café',
    humidite: 42,
    temperature: 31,
    ph: 6.0,
    status: 'alerte',
  },
  {
    id: '3',
    nom: 'Parcelle Plantain Est',
    superficie: 1.8,
    latitude: 5.3598,
    longitude: -4.0085,
    culture: 'Plantain',
    humidite: 78,
    temperature: 26,
    ph: 7.2,
    status: 'optimal',
  },
]

const DEMO_ALERTS: DemoAlert[] = [
  {
    id: '1',
    type: 'irrigation',
    titre: 'Stress hydrique détecté',
    description: 'Humidité faible sur Parcelle Café Centre. Arrosage recommandé.',
    sévérité: 'moyen',
    parcelleId: '2',
  },
  {
    id: '2',
    type: 'maladie',
    titre: 'Feuille noire possible',
    description: 'Conditions favorables à la maladie. Surveillance recommandée.',
    sévérité: 'moyen',
    parcelleId: '1',
  },
]

const fadeInUp = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.6 },
}

const stagger = {
  animate: {
    transition: {
      staggerChildren: 0.1,
    },
  },
}

export default function VisitorDemoPage() {
  const { coordinates, error: geoError, loading: geoLoading, requestLocation } = useGeolocation()
  const [selectedParcel, setSelectedParcel] = useState<DemoParcel | null>(DEMO_PARCELS[0])
  const [showMap, setShowMap] = useState(false)
  const [demoStarted, setDemoStarted] = useState(false)

  useEffect(() => {
    setDemoStarted(true)
  }, [])

  const handleLocationRequest = () => {
    requestLocation()
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'optimal':
        return 'bg-green-100 text-green-700 border-green-300'
      case 'alerte':
        return 'bg-yellow-100 text-yellow-700 border-yellow-300'
      case 'critique':
        return 'bg-red-100 text-red-700 border-red-300'
      default:
        return 'bg-gray-100 text-gray-700'
    }
  }

  const getAlertIcon = (type: string) => {
    switch (type) {
      case 'irrigation':
        return <Droplets className="h-5 w-5" />
      case 'température':
        return <Thermometer className="h-5 w-5" />
      case 'maladie':
        return <AlertCircle className="h-5 w-5" />
      default:
        return <AlertCircle className="h-5 w-5" />
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      {/* Header */}
      <div className="border-b border-gray-200 bg-white/80 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Link href="/">
              <Button variant="ghost" size="sm">
                <ArrowLeft className="h-4 w-4" />
              </Button>
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Mode Découverte</h1>
              <p className="text-sm text-gray-500">Explorez les fonctionnalités d'AgroSmart</p>
            </div>
          </div>
          <Link href="/register">
            <Button className="bg-green-600 hover:bg-green-700">
              S'inscrire gratuitement
              <Send className="h-4 w-4 ml-2" />
            </Button>
          </Link>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto px-4 py-12">
        {/* Intro Card */}
        {!demoStarted ? null : (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="mb-12"
          >
            <Card className="border-2 border-green-200 bg-gradient-to-r from-green-50 to-emerald-50">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-green-700">
                  <Eye className="h-5 w-5" />
                  Démonstration Interactive
                </CardTitle>
                <CardDescription className="text-gray-600">
                  Découvrez comment AgroSmart vous aide à surveiller vos parcelles en temps réel avec géolocalisation, 
                  alertes intelligentes et analyses IA.
                </CardDescription>
              </CardHeader>
            </Card>
          </motion.div>
        )}

        {/* Geolocation Demo */}
        <motion.div variants={stagger} initial="initial" animate="animate" className="grid md:grid-cols-2 gap-6 mb-12">
          {/* Geolocation Card */}
          <motion.div variants={fadeInUp}>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <MapPin className="h-5 w-5 text-blue-600" />
                  Localisation de l'appareil
                </CardTitle>
                <CardDescription>Exemple d'intégration géolocalisation</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {coordinates ? (
                  <div className="space-y-2">
                    <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                      <p className="text-sm text-gray-600">Latitude</p>
                      <p className="text-lg font-mono font-semibold text-green-700">
                        {coordinates.latitude.toFixed(6)}
                      </p>
                    </div>
                    <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                      <p className="text-sm text-gray-600">Longitude</p>
                      <p className="text-lg font-mono font-semibold text-green-700">
                        {coordinates.longitude.toFixed(6)}
                      </p>
                    </div>
                    <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
                      <p className="text-sm text-gray-600">Précision</p>
                      <p className="text-lg font-mono font-semibold text-blue-700">
                        ±{Math.round(coordinates.accuracy)} mètres
                      </p>
                    </div>
                    <Badge variant="outline" className="w-full justify-center bg-green-50">
                      <CheckCircle2 className="h-4 w-4 mr-2 text-green-600" />
                      Position détectée
                    </Badge>
                  </div>
                ) : geoError ? (
                  <div className="space-y-3">
                    <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
                      <p className="font-semibold mb-1">Erreur de localisation</p>
                      <p>{geoError}</p>
                    </div>
                    <p className="text-sm text-gray-600">
                      Veuillez autoriser l'accès à votre position pour voir cette démonstration.
                    </p>
                  </div>
                ) : (
                  <p className="text-sm text-gray-600">
                    Cliquez sur le bouton ci-dessous pour autoriser l'accès à votre localisation et voir comment ça marche.
                  </p>
                )}
                <Button
                  onClick={handleLocationRequest}
                  disabled={geoLoading}
                  className="w-full"
                  variant={coordinates ? 'outline' : 'default'}
                >
                  {geoLoading ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Détection en cours...
                    </>
                  ) : (
                    <>
                      <Navigation className="h-4 w-4 mr-2" />
                      {coordinates ? 'Actualiser la position' : 'Détecter ma position'}
                    </>
                  )}
                </Button>
              </CardContent>
            </Card>
          </motion.div>

          {/* Info Card */}
          <motion.div variants={fadeInUp}>
            <Card className="hover:shadow-lg transition-shadow">
              <CardHeader>
                <CardTitle>Utilisation dans AgroSmart</CardTitle>
                <CardDescription>Comment nous utilisons la géolocalisation</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-3">
                  <div className="flex gap-3">
                    <div className="shrink-0 w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center">
                      <MapPin className="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-gray-900">Création de parcelles</h4>
                      <p className="text-sm text-gray-600">Position GPS automatique lors de la création</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <div className="shrink-0 w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                      <TrendingUp className="h-5 w-5 text-green-600" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-gray-900">Données météo locales</h4>
                      <p className="text-sm text-gray-600">Prévisions précises basées sur votre position</p>
                    </div>
                  </div>
                  <div className="flex gap-3">
                    <div className="shrink-0 w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center">
                      <AlertCircle className="h-5 w-5 text-orange-600" />
                    </div>
                    <div>
                      <h4 className="font-semibold text-gray-900">Alertes intelligentes</h4>
                      <p className="text-sm text-gray-600">Notifications adaptées à votre région agricole</p>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        </motion.div>

        {/* Parcels Overview */}
        <motion.div variants={fadeInUp}>
          <h2 className="text-3xl font-bold text-gray-900 mb-6">Vos Parcelles</h2>
          <div className="grid md:grid-cols-3 gap-4 mb-8">
            {DEMO_PARCELS.map((parcel) => (
              <Card
                key={parcel.id}
                className={`cursor-pointer transition-all ${
                  selectedParcel?.id === parcel.id
                    ? 'ring-2 ring-green-500 shadow-lg'
                    : 'hover:shadow-md'
                }`}
                onClick={() => setSelectedParcel(parcel)}
              >
                <CardContent className="p-4">
                  <div className="flex items-start justify-between mb-3">
                    <div>
                      <h3 className="font-semibold text-gray-900">{parcel.nom}</h3>
                      <p className="text-sm text-gray-500">{parcel.superficie} hectares</p>
                    </div>
                    <Badge className={getStatusColor(parcel.status)}>
                      {parcel.status === 'optimal' ? 'Optimal' : 
                       parcel.status === 'alerte' ? 'Alerte' : 'Critique'}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-4 text-sm">
                    <div className="flex items-center gap-1 text-blue-600">
                      <Droplets className="h-4 w-4" />
                      {parcel.humidite}%
                    </div>
                    <div className="flex items-center gap-1 text-orange-600">
                      <Thermometer className="h-4 w-4" />
                      {parcel.temperature}°C
                    </div>
                    <div className="flex items-center gap-1 text-green-600">
                      <Leaf className="h-4 w-4" />
                      {parcel.culture}
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </motion.div>

        {/* Selected Parcel Details */}
        {selectedParcel && (
          <motion.div variants={fadeInUp} className="grid md:grid-cols-2 gap-6 mb-12">
            {/* Details */}
            <Card>
              <CardHeader>
                <CardTitle>Données en temps réel</CardTitle>
                <CardDescription>Mesures actuelles de {selectedParcel.nom}</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-3 bg-blue-50 rounded-lg">
                    <p className="text-sm text-gray-600 mb-1">Humidité du sol</p>
                    <p className="text-2xl font-bold text-blue-600">{selectedParcel.humidite}%</p>
                    <p className="text-xs text-gray-500 mt-1">
                      {selectedParcel.humidite > 60 ? '✓ Optimal' : '⚠ Arrosage recommandé'}
                    </p>
                  </div>
                  <div className="p-3 bg-orange-50 rounded-lg">
                    <p className="text-sm text-gray-600 mb-1">Température</p>
                    <p className="text-2xl font-bold text-orange-600">{selectedParcel.temperature}°C</p>
                    <p className="text-xs text-gray-500 mt-1">Favorables</p>
                  </div>
                  <div className="p-3 bg-green-50 rounded-lg">
                    <p className="text-sm text-gray-600 mb-1">pH du sol</p>
                    <p className="text-2xl font-bold text-green-600">{selectedParcel.ph}</p>
                    <p className="text-xs text-gray-500 mt-1">
                      {selectedParcel.ph >= 6 && selectedParcel.ph <= 7.5 ? '✓ Optimal' : 'À vérifier'}
                    </p>
                  </div>
                  <div className="p-3 bg-purple-50 rounded-lg">
                    <p className="text-sm text-gray-600 mb-1">Superficie</p>
                    <p className="text-2xl font-bold text-purple-600">{selectedParcel.superficie}</p>
                    <p className="text-xs text-gray-500 mt-1">hectares</p>
                  </div>
                </div>

                <div className="p-3 bg-gray-50 rounded-lg border border-gray-200">
                  <p className="text-sm text-gray-600 mb-1">Coordonnées GPS</p>
                  <p className="font-mono text-xs text-gray-700">
                    {selectedParcel.latitude.toFixed(6)}, {selectedParcel.longitude.toFixed(6)}
                  </p>
                </div>
              </CardContent>
            </Card>

            {/* Recommendations */}
            <Card>
              <CardHeader>
                <CardTitle>Recommandations IA</CardTitle>
                <CardDescription>Actions recommandées pour {selectedParcel.culture}</CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                {selectedParcel.id === '2' && (
                  <>
                    <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg flex gap-3">
                      <AlertCircle className="h-5 w-5 text-yellow-600 shrink-0" />
                      <div>
                        <p className="font-semibold text-sm text-yellow-900">Arrosage urgent</p>
                        <p className="text-xs text-yellow-800 mt-1">
                          L'humidité est en dessous de 50%. Arrosez dès que possible.
                        </p>
                      </div>
                    </div>
                  </>
                )}
                <div className="p-3 bg-green-50 border border-green-200 rounded-lg flex gap-3">
                  <CheckCircle2 className="h-5 w-5 text-green-600 shrink-0" />
                  <div>
                    <p className="font-semibold text-sm text-green-900">Surveillance maladie</p>
                    <p className="text-xs text-green-800 mt-1">
                      Conditions météo favorables aux maladies. Inspectez les feuilles régulièrement.
                    </p>
                  </div>
                </div>
                <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg flex gap-3">
                  <CheckCircle2 className="h-5 w-5 text-blue-600 shrink-0" />
                  <div>
                    <p className="font-semibold text-sm text-blue-900">Fertilisation planifiée</p>
                    <p className="text-xs text-blue-800 mt-1">
                      Fertilisez dans 5-7 jours selon votre calendrier optimal.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {/* Alerts Section */}
        <motion.div variants={fadeInUp}>
          <h2 className="text-3xl font-bold text-gray-900 mb-6">Alertes & Notifications</h2>
          <div className="space-y-3">
            {DEMO_ALERTS.map((alert) => (
              <Card key={alert.id}>
                <CardContent className="p-4 flex items-start gap-4">
                  <div className="shrink-0 w-10 h-10 rounded-full bg-yellow-100 flex items-center justify-center">
                    {getAlertIcon(alert.type)}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-start justify-between gap-4">
                      <div>
                        <h3 className="font-semibold text-gray-900">{alert.titre}</h3>
                        <p className="text-sm text-gray-600 mt-1">{alert.description}</p>
                      </div>
                      <Badge variant="outline">{alert.type}</Badge>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </motion.div>

        {/* CTA Section */}
        <motion.div variants={fadeInUp} className="mt-16 text-center">
          <Card className="bg-gradient-to-r from-green-500 to-emerald-600 border-0 text-white">
            <CardContent className="p-12 space-y-6">
              <div>
                <h2 className="text-3xl font-bold mb-3">Prêt à démarrer ?</h2>
                <p className="text-green-50 max-w-2xl mx-auto">
                  Rejoignez plus de 5000 agriculteurs qui optimisent leur production avec AgroSmart.
                  Créez votre compte gratuitement en moins de 2 minutes.
                </p>
              </div>
              <div className="flex flex-col sm:flex-row gap-3 justify-center">
                <Link href="/register">
                  <Button size="lg" className="bg-white text-green-600 hover:bg-gray-50">
                    S'inscrire gratuitement
                    <Send className="h-4 w-4 ml-2" />
                  </Button>
                </Link>
                <Link href="/login">
                  <Button size="lg" variant="outline" className="text-white border-white hover:bg-white/20">
                    Se connecter
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </div>
  )
}

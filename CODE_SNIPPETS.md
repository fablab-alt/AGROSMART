# Snippets Clés du Mode Visiteur

Ce document contient les extraits de code clés du mode visiteur AgroSmart pour référence rapide.

---

## 🎯 Fichiers Clés Créés

### 1. Hook Géolocalisation - `useGeolocation.ts`

```typescript
'use client'

import { useState, useCallback } from 'react'

interface Coordinates {
  latitude: number
  longitude: number
  accuracy: number
  timestamp: number
}

interface UseGeolocationReturn {
  coordinates: Coordinates | null
  error: string | null
  loading: boolean
  requestLocation: () => void
  hasPermission: boolean | null
}

export function useGeolocation(): UseGeolocationReturn {
  const [coordinates, setCoordinates] = useState<Coordinates | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [hasPermission, setHasPermission] = useState<boolean | null>(null)

  const requestLocation = useCallback(() => {
    if (typeof window === 'undefined' || !navigator.geolocation) {
      setError('Géolocalisation non supportée par votre navigateur')
      return
    }

    setLoading(true)
    setError(null)

    navigator.geolocation.getCurrentPosition(
      (position) => {
        setCoordinates({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,
          timestamp: position.timestamp
        })
        setHasPermission(true)
        setLoading(false)
      },
      (err) => {
        if (err.code === 1) {
          setError('Vous avez refusé l\'accès à votre position')
          setHasPermission(false)
        } else if (err.code === 3) {
          setError('Délai d\'attente dépassé')
        } else {
          setError('Erreur lors de la détection de votre position')
        }
        setLoading(false)
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    )
  }, [])

  return {
    coordinates,
    error,
    loading,
    requestLocation,
    hasPermission
  }
}
```

---

### 2. Page Démo - `app/demo/page.tsx` (Extrait)

```typescript
'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { useGeolocation } from '@/hooks/useGeolocation'
import { MapPin, AlertCircle, Zap } from 'lucide-react'

export default function DemoPage() {
  const { coordinates, error, loading, requestLocation } = useGeolocation()
  const [selectedParcel, setSelectedParcel] = useState(0)

  const parcels = [
    {
      id: 1,
      name: 'Cacao Nord',
      area: '3.5 ha',
      humidity: 65,
      temperature: 28,
      ph: 6.2,
      status: 'optimal'
    },
    {
      id: 2,
      name: 'Café Centre',
      area: '2.1 ha',
      humidity: 42,
      temperature: 31,
      ph: 5.8,
      status: 'alert'
    },
    {
      id: 3,
      name: 'Plantain Est',
      area: '1.8 ha',
      humidity: 78,
      temperature: 25,
      ph: 6.5,
      status: 'optimal'
    }
  ]

  return (
    <div className="min-h-screen bg-white">
      {/* Géolocalisation Widget */}
      <motion.div className="bg-green-50 p-8 m-4 rounded-lg">
        <h2 className="text-2xl font-bold mb-4">Votre Position</h2>
        
        {!coordinates ? (
          <button
            onClick={requestLocation}
            disabled={loading}
            className="px-4 py-2 bg-green-600 text-white rounded"
          >
            {loading ? 'Détection...' : 'Détecter ma position'}
          </button>
        ) : (
          <div>
            <p>Latitude: {coordinates.latitude.toFixed(4)}°</p>
            <p>Longitude: {coordinates.longitude.toFixed(4)}°</p>
            <p>Précision: ±{Math.round(coordinates.accuracy)}m</p>
          </div>
        )}

        {error && (
          <p className="text-red-600 mt-2">
            <AlertCircle className="inline mr-2" />
            {error}
          </p>
        )}
      </motion.div>

      {/* Parcelles */}
      <div className="p-8">
        <h2 className="text-2xl font-bold mb-4">Vos Parcelles</h2>
        <div className="grid grid-cols-3 gap-4">
          {parcels.map((parcel) => (
            <div
              key={parcel.id}
              onClick={() => setSelectedParcel(parcel.id - 1)}
              className="p-4 border rounded cursor-pointer"
            >
              <h3 className="font-bold">{parcel.name}</h3>
              <p className="text-sm">{parcel.area}</p>
              <p className="text-sm">Humidité: {parcel.humidity}%</p>
            </div>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="p-8 bg-green-600 text-white text-center">
        <h2 className="text-2xl font-bold mb-4">Prêt à commencer?</h2>
        <button className="px-6 py-3 bg-white text-green-600 rounded font-bold">
          S'inscrire gratuitement
        </button>
      </div>
    </div>
  )
}
```

---

### 3. Routes Backend Démo - `backend/src/routes/demo.js`

```javascript
const express = require('express')
const router = express.Router()

// GET /api/demo/parcelles
router.get('/parcelles', (req, res) => {
  res.json({
    success: true,
    message: 'Parcelles de démonstration',
    data: [
      {
        id: 1,
        name: 'Cacao Nord',
        area: 3.5,
        culture: 'Cacao',
        location: { lat: 5.36, lng: 4.00 },
        sensors: {
          humidity: 65,
          temperature: 28,
          ph: 6.2
        },
        status: 'optimal'
      },
      {
        id: 2,
        name: 'Café Centre',
        area: 2.1,
        culture: 'Café',
        location: { lat: 5.35, lng: 4.02 },
        sensors: {
          humidity: 42,
          temperature: 31,
          ph: 5.8
        },
        status: 'alert',
        alertReason: 'Humidité faible'
      },
      {
        id: 3,
        name: 'Plantain Est',
        area: 1.8,
        culture: 'Plantain',
        location: { lat: 5.37, lng: 3.98 },
        sensors: {
          humidity: 78,
          temperature: 25,
          ph: 6.5
        },
        status: 'optimal'
      }
    ],
    count: 3,
    note: 'Ceci est une démonstration. Connectez-vous pour accéder à vos vraies données.'
  })
})

// GET /api/demo/alertes
router.get('/alertes', (req, res) => {
  res.json({
    success: true,
    message: 'Alertes de démonstration',
    data: [
      {
        id: 1,
        parcelName: 'Café Centre',
        type: 'irrigation',
        severity: 'high',
        message: 'Stress hydrique détecté',
        timestamp: new Date()
      },
      {
        id: 2,
        parcelName: 'Cacao Nord',
        type: 'disease',
        severity: 'medium',
        message: 'Conditions favorables à la maladie',
        timestamp: new Date()
      },
      {
        id: 3,
        parcelName: 'Plantain Est',
        type: 'temperature',
        severity: 'low',
        message: 'Température élevée',
        timestamp: new Date()
      }
    ],
    count: 3,
    note: 'Ceci est une démonstration.'
  })
})

// GET /api/demo/stats
router.get('/stats', (req, res) => {
  res.json({
    success: true,
    message: 'Statistiques de la plateforme',
    data: {
      totalFarmers: 5247,
      totalHectares: 51000,
      diseasePreventionRate: 94.3,
      waterSavings: 35,
      incomeIncrease: 28
    },
    note: 'Ceci est une démonstration.'
  })
})

module.exports = router
```

---

### 4. Enregistrement Routes - `backend/src/routes/index.js` (Extrait)

```javascript
// ... autres imports ...
const demoRoutes = require('./demo')

// ... autres routes ...

// ROUTES PUBLIQUES
// Routes accessibles sans authentification
router.use('/demo', demoRoutes)

// ROUTES AUTHENTIFIÉES
// Routes nécessitant un token JWT
router.use('/parcelles', authenticateToken, parcellesRoutes)
// ... autres routes authentifiées ...

module.exports = router
```

---

### 5. Navigation Frontend - `Navbar.tsx` (Extrait)

```typescript
<Link href="/demo">
  <Button variant="outline">
    <Eye className="w-4 h-4 mr-2" />
    Essayer
  </Button>
</Link>
```

---

### 6. CTA Amélioré - `CTASection.tsx` (Extrait)

```typescript
<div className="bg-gradient-to-r from-green-900 to-black rounded-2xl p-12">
  <div className="grid md:grid-cols-2 gap-12">
    <div>
      <h3 className="text-3xl font-bold text-white mb-6">
        Mode Découverte
      </h3>
      <div className="space-y-4 text-green-50">
        <p className="flex items-center gap-2">
          <MapPin className="w-5 h-5" />
          Position automatique de vos parcelles
        </p>
        <p className="flex items-center gap-2">
          <Zap className="w-5 h-5" />
          Alertes adaptées à votre région
        </p>
        <p className="flex items-center gap-2">
          <TrendingUp className="w-5 h-5" />
          Recommandations localisées
        </p>
      </div>
      <Link href="/demo" className="mt-6 inline-block">
        <Button>Voir une démonstration →</Button>
      </Link>
    </div>
  </div>
</div>
```

---

## 🔌 Points d'Intégration

### Frontend → Backend
```typescript
// App démo fetch les routes publiques
const response = await fetch('/api/demo/parcelles')
const data = await response.json()

// SANS authentification requise!
// CORS autorise cross-origin requests
```

### Navigation Flow
```
/ (landing) 
  ↓ [Essayer button]
/demo (page démo)
  ↓ [S'inscrire button]
/register (inscription)
```

---

## 🧪 Test Individual Routes

```bash
# Test parcelles
curl http://localhost:3600/api/demo/parcelles | jq

# Test alertes
curl http://localhost:3600/api/demo/alertes | jq

# Test stats
curl http://localhost:3600/api/demo/stats | jq

# Tous doivent retourner 200 SANS authentification
```

---

## 📊 Types TypeScript

```typescript
// Coordonnées géolocalisation
interface Coordinates {
  latitude: number
  longitude: number
  accuracy: number
  timestamp: number
}

// Parcelle démo
interface Parcel {
  id: number
  name: string
  area: number
  culture: string
  location: { lat: number; lng: number }
  sensors: {
    humidity: number
    temperature: number
    ph: number
  }
  status: 'optimal' | 'alert' | 'critical'
}

// Alerte démo
interface Alert {
  id: number
  parcelName: string
  type: 'irrigation' | 'disease' | 'temperature'
  severity: 'low' | 'medium' | 'high'
  message: string
  timestamp: Date
}
```

---

## 🚀 Déploiement

### Commandes Frontend
```bash
cd frontend
npm install
npm run build
npm run start
```

### Commandes Backend
```bash
cd backend
npm install
npm run build
npm run start
```

### Vérification Post-Déploiement
```bash
# Routes publiques accessibles
curl https://api.agrosmart.ci/api/demo/parcelles

# Page démo accessible
curl https://agrosmart.ci/demo
```

---

## ✨ Points Importants

1. **Pas d'authentification** requise pour `/api/demo/*`
2. **Données simulées** uniquement, jamais vraies données
3. **Géolocalisation** optionnelle et locale au navigateur
4. **CTA clairs** invitant à s'inscrire à chaque étape
5. **Réponses JSON** suivent le format d'autres routes

---

*Pour plus de détails, voir VISITOR_MODE_README.md et INTEGRATION_CHECKLIST.md*

# 🔧 Guide de Maintenance - Mode Visiteur

Ce document explique comment maintenir et améliorer le mode visiteur AgroSmart.

---

## 📋 Maintenance Courante

### Vérifications Mensuelles

```bash
# 1. Vérifier que les routes sont accessibles
curl https://api.agrosmart.ci/api/demo/parcelles
# Doit répondre: { success: true, data: [...] }

# 2. Vérifier que la page /demo charge
curl https://agrosmart.ci/demo | grep "demo"
# Doit retourner du HTML

# 3. Vérifier les stats d'utilisation
SELECT COUNT(*) FROM analytics WHERE page = '/demo' AND month = CURRENT_MONTH
```

### Mise à Jour des Données Démo

Les données démo sont codées en dur dans `backend/src/routes/demo.js`.

**Pour ajouter une parcelle démo:**

```javascript
// Dans backend/src/routes/demo.js
router.get('/parcelles', (req, res) => {
  const demoParcels = [
    // ... parcelles existantes ...
    {
      id: 4,
      name: 'Cacaoyère Ouest',
      area: 4.2,
      culture: 'Cacao',
      location: { lat: 5.34, lng: 4.05 },
      sensors: {
        humidity: 71,
        temperature: 27,
        ph: 6.1
      },
      status: 'optimal'
    }
  ]
})
```

**Pour mettre à jour les stats:**

```javascript
// Dans backend/src/routes/demo.js -> /stats endpoint
data: {
  totalFarmers: 5500,      // ← Mettez à jour
  totalHectares: 54000,    // ← Mettez à jour
  diseasePreventionRate: 95, // ← Mettez à jour
  waterSavings: 36,        // ← Mettez à jour
  incomeIncrease: 29       // ← Mettez à jour
}
```

---

## 🐛 Dépannage des Problèmes Courants

### Problème 1: Géolocalisation ne fonctionne pas

**Symptômes:**
- Bouton "Détecter ma position" ne répond pas
- Permission non demandée au navigateur

**Causes possibles:**
1. Pas HTTPS en production (géolocalisation requiert HTTPS)
2. Navigateur bloque la permission
3. Hook non importé correctement

**Solutions:**

```bash
# Vérifier HTTPS
curl -I https://agrosmart.ci
# Doit avoir certificat valide

# Vérifier import dans page
grep "useGeolocation" frontend/src/app/demo/page.tsx
# Doit afficher: import { useGeolocation } from '@/hooks/useGeolocation'

# Vérifier fichier hook existe
ls -la frontend/src/hooks/useGeolocation.ts
```

### Problème 2: Routes /api/demo/* retournent 404

**Causes possibles:**
1. Fichier demo.js manquant
2. Routes non enregistrées dans index.js
3. Backend pas redémarré

**Solutions:**

```bash
# Vérifier fichier existe
ls -la backend/src/routes/demo.js

# Vérifier enregistrement
grep "demoRoutes\|'/demo'" backend/src/routes/index.js

# Vérifier les deux lignes:
# const demoRoutes = require('./demo')
# router.use('/demo', demoRoutes)

# Relancer backend
cd backend && npm run dev
```

### Problème 3: Page /demo ne charge pas

**Causes possibles:**
1. Fichier page.tsx manquant
2. Imports brisés
3. Erreur TypeScript

**Solutions:**

```bash
# Vérifier fichier existe
ls -la frontend/src/app/demo/page.tsx

# Vérifier build
npm run build
# Si erreur, doit afficher le fichier problématique

# Consulter logs
npm run dev
# Regarder la console pour les erreurs
```

### Problème 4: CORS error sur route démo

**Symptôme:**
```
Access to XMLHttpRequest at 'https://api.agrosmart.ci/api/demo/parcelles' 
from origin 'https://agrosmart.ci' has been blocked by CORS policy
```

**Solution:**

```javascript
// Dans backend/src/server.js ou middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', 'https://agrosmart.ci')
  res.header('Access-Control-Allow-Methods', 'GET, OPTIONS')
  res.header('Access-Control-Allow-Headers', 'Content-Type')
  next()
})
```

---

## 📊 Monitoring & Analytics

### Métriques à Tracker

```javascript
// Dans frontend/src/app/demo/page.tsx
import { analytics } from '@/lib/analytics'

// 1. Page charge
useEffect(() => {
  analytics.track('demo_page_loaded', {
    timestamp: new Date(),
    userAgent: navigator.userAgent
  })
}, [])

// 2. Géolocalisation demandée
const handleGeolocationClick = () => {
  analytics.track('geolocation_requested')
  requestLocation()
}

// 3. Géolocalisation accordée
useEffect(() => {
  if (coordinates) {
    analytics.track('geolocation_success', {
      lat: coordinates.latitude,
      lng: coordinates.longitude
    })
  }
}, [coordinates])

// 4. Parcelle consultée
const handleParcelClick = (id) => {
  analytics.track('parcel_demo_viewed', {
    parcelId: id,
    parcelName: parcels[id].name
  })
}

// 5. CTA cliqué
const handleSignupClick = () => {
  analytics.track('signup_cta_clicked_from_demo')
  router.push('/register')
}
```

### Dashboard Recommandé

**Google Analytics 4 Events:**

```
Event                        | Property
------------------------------------------
demo_page_loaded            | timestamp, userAgent
geolocation_requested       | -
geolocation_success         | lat, lng, accuracy
parcel_demo_viewed          | parcelId, parcelName
alert_demo_viewed           | alertType, severity
recommendation_demo_viewed  | type
signup_cta_clicked_from_demo| -
conversion_visitor_to_user  | conversion
```

---

## 🔄 Mises à Jour de Contenu

### Mettre à Jour les Parcelles Démo

```javascript
// backend/src/routes/demo.js
const parcels = [
  {
    // Mise à jour des données réalistes
    // Basé sur les vraies parcelles de la plateforme
    humidity: 65,      // Mettre à jour si conditions changent
    temperature: 28,   // Mettre à jour si conditions changent
    ph: 6.2           // Mettre à jour si conditions changent
  }
]
```

**Fréquence:** Hebdomadaire (basé sur données réelles)

### Mettre à Jour les Alertes Type

```javascript
// backend/src/routes/demo.js
const alerts = [
  {
    severity: 'high',    // Changer si moins urgente
    message: '...'       // Mettre à jour message
  }
]
```

**Fréquence:** Hebdomadaire (basé sur alertes réelles)

### Mettre à Jour les Stats

```javascript
// backend/src/routes/demo.js
data: {
  totalFarmers: 5247,              // Update depuis DB
  totalHectares: 51000,            // Update depuis DB
  diseasePreventionRate: 94.3,     // Calculate depuis analytics
  waterSavings: 35,                // Calculate depuis savings data
  incomeIncrease: 28               // Calculate depuis income data
}
```

**Fréquence:** Mensuels (data audit)

---

## 🚀 Déploiement

### Déployer une Mise à Jour

```bash
# 1. Modifier fichiers
# Exemple: Changer données démo

# 2. Tester localement
cd backend && npm run dev
curl http://localhost:3600/api/demo/parcelles

# 3. Committer
git add backend/src/routes/demo.js
git commit -m "Update demo data with latest stats"

# 4. Push vers production
git push origin main

# 5. Déclencher deploy (selon votre CI/CD)
# Jenkins/GitHub Actions/etc doit auto-deployer
```

### Rollback si Problème

```bash
# Revert le dernier commit
git revert HEAD
git push origin main

# Ou revert une version spécifique
git log --oneline | grep "demo"
# git revert <commit-hash>
```

---

## 🆕 Ajouter une Nouvelle Route Démo

**Exemple:** Ajouter une route pour les images parcelles

```javascript
// backend/src/routes/demo.js

// Nouvelle route
router.get('/images', (req, res) => {
  res.json({
    success: true,
    message: 'Images de démonstration',
    data: [
      {
        parcelId: 1,
        type: 'satellite',
        url: 'https://images.agrosmart.ci/demo/parcel1.jpg',
        date: '2024-01-15'
      },
      // ... autres images ...
    ],
    note: 'Ceci est une démonstration.'
  })
})

// Exporter
module.exports = router
```

Puis mettre à jour la documentation:
1. Mettre à jour `CODE_SNIPPETS.md`
2. Mettre à jour `INTEGRATION_CHECKLIST.md`
3. Tester la nouvelle route

---

## 📱 Ajouter Page Démo Mobile (Flutter)

**Pour la prochaine itération:**

```dart
// mobile/lib/screens/demo_screen.dart

class DemoScreen extends StatefulWidget {
  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  // Similaire à /demo en Flutter
  // Utiliser geolocator package existant
  // Fetch /api/demo/parcelles
  // Afficher UI demo
}
```

---

## 🔐 Sécurité - Checklist Maintenance

- [ ] Routes démo JAMAIS retournent vraies données
- [ ] Pas d'authentification enregistrée dans logs
- [ ] Pas de JWT tokens exposés
- [ ] Géolocalisation jamais loggée
- [ ] CORS whitelist actualisé
- [ ] Rate limiting configuré
- [ ] HTTPS enforced en production

---

## 📈 Performance

### Optimisations Possibles

```javascript
// 1. Cacher les routes démo (Redis)
const redis = require('redis')
const client = redis.createClient()

router.get('/parcelles', async (req, res) => {
  const cached = await client.get('demo:parcelles')
  if (cached) return res.json(JSON.parse(cached))
  
  // Si pas en cache, générer et cacher 1 heure
  const data = generateDemoData()
  await client.setex('demo:parcelles', 3600, JSON.stringify(data))
  res.json(data)
})

// 2. Compresser réponses
const compression = require('compression')
app.use(compression())

// 3. Limiter requêtes
const rateLimit = require('express-rate-limit')
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // 100 requêtes par IP
})
app.use('/api/demo/', limiter)
```

---

## 🆘 Support & Questions

### Vérifier la Santé du Système

```bash
# Script de santé
#!/bin/bash

echo "1. Vérifier backend démo routes:"
curl -s http://localhost:3600/api/demo/stats | jq .success

echo "2. Vérifier frontend page:"
curl -s http://localhost:3603/demo | grep "demo" | wc -l

echo "3. Vérifier logs:"
tail -20 backend/logs/app.log | grep demo

echo "4. Vérifier BD connection:"
prisma db execute --stdin < <(echo "SELECT COUNT(*) as count;")
```

---

## 📞 Ressources

**Documentation Interne:**
- VISITOR_MODE_README.md - Guide utilisateur
- INTEGRATION_CHECKLIST.md - Checklist technique
- CODE_SNIPPETS.md - Extraits code
- SUMMARY_IMPLEMENTATION.md - Vue d'ensemble

**Fichiers à Modifier:**
- `backend/src/routes/demo.js` - Données démo
- `frontend/src/app/demo/page.tsx` - UI démo
- `frontend/src/hooks/useGeolocation.ts` - Géolocalisation

**Fichiers à NE PAS Modifier:**
- `backend/src/routes/index.js` (sauf si réorganisation)
- `frontend/src/components/landing/*` (sauf mises à jour)
- Fichiers authentification/données réelles

---

## ✅ Checklist de Maintenance Mensuelle

- [ ] Vérifier routes démo accessibles
- [ ] Vérifier page /demo charge
- [ ] Vérifier géolocalisation fonctionne
- [ ] Mettre à jour stats démo
- [ ] Vérifier analytiques fonctionnent
- [ ] Vérifier pas de fuites de données
- [ ] Vérifier HTTPS valide
- [ ] Consulter logs d'erreurs
- [ ] Tester sur mobile
- [ ] Documenter changements

---

## 🎯 Conclusion

**Mode Visiteur est facile à maintenir:**
- Code isolé et indépendant
- Données configurables
- Routes publiques claires
- Documentation complète
- Pas de dépendances complexes

**Pour toute question:** Consulter les documents ou vérifier les logs! 🚀

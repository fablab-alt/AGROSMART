'use client'

import React, { useState } from 'react'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import {
  ArrowRight,
  Wifi,
  Cloud,
  Bell,
  Camera,
  Brain,
  ShoppingCart,
  Users,
  GraduationCap,
  Calendar,
  Package,
  TrendingUp,
  Award,
  Smartphone,
  Globe,
  Droplets,
  Thermometer,
  Leaf,
  AlertCircle,
  CheckCircle2,
  Star,
  Battery,
  Signal,
  MapPin,
  Sun,
  CloudRain,
  Wind,
  BarChart3,
  BookOpen,
  MessageSquare,
  Eye,
  Lock,
  ChevronRight,
  Zap,
  Shield,
  Target,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts'

// ─── Mock data (mirrors backend /api/v1/demo/*) ───────────────────────────────

const PARCELLES = [
  {
    id: 'p1', nom: 'Parcelle Cacao Nord', superficie: 3.5,
    cultureActuelle: 'Cacao', typeSol: 'Argileux', statut: 'EN_CROISSANCE',
    sante: 'OPTIMAL', sante_globale: 92, humidite: 65, temperature: 28, ph: 6.5,
    npk: { n: 42, p: 18, k: 35 }, region: 'Abidjan',
    nb_stations: 2, nb_capteurs: 6, rendement_estime: '1.8 t/ha',
  },
  {
    id: 'p2', nom: 'Parcelle Café Centre', superficie: 2.1,
    cultureActuelle: 'Café', typeSol: 'Limoneux', statut: 'EN_CROISSANCE',
    sante: 'SURVEILLANCE', sante_globale: 68, humidite: 42, temperature: 31, ph: 6.0,
    npk: { n: 28, p: 12, k: 22 }, region: 'Abidjan',
    nb_stations: 1, nb_capteurs: 4, rendement_estime: '0.9 t/ha',
  },
  {
    id: 'p3', nom: 'Parcelle Plantain Est', superficie: 1.8,
    cultureActuelle: 'Plantain', typeSol: 'Sableux', statut: 'RECOLTE',
    sante: 'OPTIMAL', sante_globale: 88, humidite: 78, temperature: 26, ph: 7.2,
    npk: { n: 55, p: 24, k: 48 }, region: 'Yamoussoukro',
    nb_stations: 1, nb_capteurs: 3, rendement_estime: '12 t/ha',
  },
]

const CAPTEURS = [
  { id: 'c1', parcelleId: 'p1', nom: 'Capteur Sol Nord-A', type: 'HUMIDITE_SOL', statut: 'ACTIF', batterie: 87, signal: 95, valeur: 65, unite: '%' },
  { id: 'c2', parcelleId: 'p1', nom: 'Capteur Ambiant Nord-B', type: 'HUMIDITE_TEMPERATURE_AMBIANTE', statut: 'ACTIF', batterie: 92, signal: 88, valeur: 28.4, unite: '°C' },
  { id: 'c3', parcelleId: 'p1', nom: 'Capteur NPK Nord-C', type: 'NPK', statut: 'ACTIF', batterie: 74, signal: 82, valeur: null, unite: 'mg/kg' },
  { id: 'c4', parcelleId: 'p2', nom: 'Capteur Sol Centre-A', type: 'HUMIDITE_SOL', statut: 'ACTIF', batterie: 61, signal: 79, valeur: 42, unite: '%' },
  { id: 'c5', parcelleId: 'p2', nom: 'Capteur Ambiant Centre-B', type: 'HUMIDITE_TEMPERATURE_AMBIANTE', statut: 'MAINTENANCE', batterie: 38, signal: 55, valeur: 31.2, unite: '°C' },
  { id: 'c6', parcelleId: 'p3', nom: 'Capteur Sol Est-A', type: 'HUMIDITE_SOL', statut: 'ACTIF', batterie: 95, signal: 98, valeur: 78, unite: '%' },
]

const MESURES_CHART = Array.from({ length: 12 }, (_, i) => ({
  heure: `${(23 - i).toString().padStart(2, '0')}h`,
  humidite: Math.round(60 + Math.sin(i * 0.5) * 10),
  temperature: Math.round(27 + Math.cos(i * 0.4) * 3),
})).reverse()

const ALERTES = [
  { id: 'a1', niveau: 'IMPORTANT', titre: 'Stress hydrique détecté', message: 'Humidité du sol en dessous de 45% sur Parcelle Café Centre. Irrigation recommandée dans les 6h.', statut: 'NOUVELLE', parcelle_nom: 'Parcelle Café Centre', type: 'irrigation', createdAt: '2h' },
  { id: 'a2', niveau: 'IMPORTANT', titre: 'Risque feuille noire cacao', message: 'Conditions météo favorables à Phytophthora. Inspection recommandée.', statut: 'NOUVELLE', parcelle_nom: 'Parcelle Cacao Nord', type: 'maladie', createdAt: '4h' },
  { id: 'a3', niveau: 'INFO', titre: 'Température élevée', message: 'Température > 30°C sur Parcelle Café. Stress thermique possible.', statut: 'LUE', parcelle_nom: 'Parcelle Café Centre', type: 'temperature', createdAt: '1h' },
  { id: 'a4', niveau: 'INFO', titre: 'Carence en azote détectée', message: 'Taux d\'azote (N=28 mg/kg) en dessous de la norme. Fertilisation conseillée.', statut: 'NOUVELLE', parcelle_nom: 'Parcelle Café Centre', type: 'npk', createdAt: '8h' },
]

const METEO_PREVISIONS = [
  { jour: 'Auj.', max: 31, min: 23, icon: '⛅', pluie: 10 },
  { jour: 'Dem.', max: 29, min: 22, icon: '🌧', pluie: 65 },
  { jour: 'Mer', max: 27, min: 21, icon: '🌦', pluie: 40 },
  { jour: 'Jeu', max: 30, min: 23, icon: '☀️', pluie: 5 },
  { jour: 'Ven', max: 32, min: 24, icon: '☀️', pluie: 0 },
  { jour: 'Sam', max: 31, min: 23, icon: '⛅', pluie: 15 },
  { jour: 'Dim', max: 28, min: 22, icon: '🌧', pluie: 70 },
]

const RECOMMANDATIONS = [
  { id: 'r1', titre: 'Irrigation urgente — Parcelle Café', type: 'irrigation', priorite: 1, parcelle: 'Parcelle Café Centre', delai: '6h', economie: '45 000', description: 'Humidité sol à 42%, en dessous du seuil critique de 50%. Arrosez 25-30L/m².' },
  { id: 'r2', titre: 'Application NPK — Parcelle Café', type: 'fertilisation', priorite: 2, parcelle: 'Parcelle Café Centre', delai: '24h', economie: '120 000', description: 'Taux d\'azote insuffisant. Appliquer 150 kg/ha NPK 20-10-10.' },
  { id: 'r3', titre: 'Inspection phytosanitaire — Cacao', type: 'prevention', priorite: 2, parcelle: 'Parcelle Cacao Nord', delai: '48h', economie: '200 000', description: 'Conditions propices à la feuille noire. Inspectez et appliquez bouillie bordelaise.' },
  { id: 'r4', titre: 'Récolte Plantain — Optimal', type: 'recolte', priorite: 3, parcelle: 'Parcelle Plantain Est', delai: '72h', economie: '80 000', description: 'Maturité optimale atteinte. Programmez la récolte cette semaine.' },
]

const DIAGNOSTICS = [
  { culture: 'Cacao', maladie: 'Pourriture brune (Phytophthora palmivora)', confiance: 87.3, gravite: 'Modérée', symptomes: ['Taches brunes sur cabosses', 'Pourriture des racines', 'Flétrissement feuilles'], traitements: ['Bouillie bordelaise (10g/L)', 'Retirer parties infectées', 'Améliorer drainage'] },
  { culture: 'Café', maladie: 'Rouille orangée (Hemileia vastatrix)', confiance: 93.1, gravite: 'Élevée', symptomes: ['Poudre orangée sous feuilles', 'Jaunissement', 'Défoliation précoce'], traitements: ['Fongicide cuivre (3kg/ha)', 'Retirer feuilles atteintes', 'Améliorer ventilation'] },
]

const MARKETPLACE = [
  { id: 'mp1', nom: 'Semences Maïs Hybride SAMARU 2Y', categorie: 'Semences', prix: 12500, unite: 'kg', vendeur: 'Coopérative COOPAG', note: 4.7, nb_avis: 23, typeOffre: 'vente', stock: 500 },
  { id: 'mp2', nom: 'Engrais NPK 20-10-10 (50kg)', categorie: 'Engrais', prix: 18000, unite: 'sac', vendeur: 'AgriIntrants Abidjan', note: 4.5, nb_avis: 45, typeOffre: 'vente', stock: 200 },
  { id: 'mp3', nom: 'Tracteur John Deere 5E — Location', categorie: 'Équipement', prix: 35000, unite: 'jour', vendeur: 'MecaAgri CI', note: 4.9, nb_avis: 12, typeOffre: 'location', stock: 1 },
  { id: 'mp4', nom: 'Récolte Cacao grade 1 (100kg)', categorie: 'Récoltes', prix: 165000, unite: 'sac', vendeur: 'Kouassi Jean-Baptiste', note: 4.8, nb_avis: 8, typeOffre: 'vente', stock: 50 },
  { id: 'mp5', nom: 'Pulvérisateur dorsal 16L', categorie: 'Équipement', prix: 24500, unite: 'pièce', vendeur: 'AgriOutillage Yamoussoukro', note: 4.2, nb_avis: 18, typeOffre: 'vente', stock: 30 },
  { id: 'mp6', nom: 'Fongicide Ridomil Gold (1kg)', categorie: 'Pesticides', prix: 8500, unite: 'kg', vendeur: 'PhytoSolutions CI', note: 4.6, nb_avis: 31, typeOffre: 'vente', stock: 80 },
]

const ACHATS_GROUPES = [
  { id: 'ag1', titre: 'Achat groupé engrais NPK', categorie: 'Engrais', prixNormal: 18000, prixGroupe: 13500, reduction: 25, objectif: 100, actuel: 73, dateLimite: '10 jours', participants: 18 },
  { id: 'ag2', titre: 'Groupage semences riz IR64', categorie: 'Semences', prixNormal: 9000, prixGroupe: 6300, reduction: 30, objectif: 50, actuel: 32, dateLimite: '7 jours', participants: 12 },
]

const FORUM = [
  { id: 'fo1', titre: 'Comment gérer la feuille noire sur le cacao cette saison ?', auteur: 'Kouassi Koffi', categorie: 'Maladies', vues: 156, reponses: 8, resolu: false, age: '2 jours' },
  { id: 'fo2', titre: 'Meilleures périodes de plantation maïs en zone forêt', auteur: 'Traoré Aminata', categorie: 'Cultures', vues: 234, reponses: 15, resolu: true, age: '5 jours' },
  { id: 'fo3', titre: 'Retour d\'expérience : drip irrigation sur tomate', auteur: 'Yao Bernard', categorie: 'Irrigation', vues: 89, reponses: 4, resolu: false, age: '1 jour' },
  { id: 'fo4', titre: 'Capteur NPK : interprétation des valeurs', auteur: 'Diallo Ibrahima', categorie: 'IoT', vues: 198, reponses: 11, resolu: true, age: '3 jours' },
]

const FORMATIONS = [
  { id: 'f1', titre: 'Gestion de l\'irrigation au goutte-à-goutte', categorie: 'Irrigation', niveau: 'Débutant', duree: 45, vues: 1247, modules: 6, progression: 0 },
  { id: 'f2', titre: 'Détection précoce des maladies du cacao', categorie: 'Phytosanitaire', niveau: 'Intermédiaire', duree: 60, vues: 892, modules: 8, progression: 30 },
  { id: 'f3', titre: 'Fertilisation raisonnée avec le NPK', categorie: 'Fertilisation', niveau: 'Intermédiaire', duree: 35, vues: 534, modules: 5, progression: 0 },
  { id: 'f4', titre: 'Utilisation de l\'application AgroSmart', categorie: 'Numérique', niveau: 'Débutant', duree: 20, vues: 2108, modules: 4, progression: 100 },
]

const CALENDRIER = [
  { id: 'cal1', titre: 'Arrosage Parcelle Café', type: 'ARROSAGE', statut: 'PLANIFIEE', priorite: 'URGENTE', date: 'Aujourd\'hui 14h', parcelle: 'Parcelle Café Centre', cout: '5 000' },
  { id: 'cal2', titre: 'Fertilisation NPK — Cacao', type: 'FERTILISATION', statut: 'PLANIFIEE', priorite: 'HAUTE', date: 'Dans 2 jours', parcelle: 'Parcelle Cacao Nord', cout: '45 000' },
  { id: 'cal3', titre: 'Récolte Plantain', type: 'RECOLTE', statut: 'PLANIFIEE', priorite: 'HAUTE', date: 'Dans 4 jours', parcelle: 'Parcelle Plantain Est', cout: '15 000' },
  { id: 'cal4', titre: 'Inspection phytosanitaire', type: 'TRAITEMENT', statut: 'TERMINEE', priorite: 'MOYENNE', date: 'Hier', parcelle: 'Parcelle Cacao Nord', cout: '8 000' },
]

const STOCKS = [
  { nom: 'Engrais NPK 20-10-10', categorie: 'Engrais', quantite: 125, unite: 'kg', seuil: 50, statut: 'OK' },
  { nom: 'Semences Maïs Hybride', categorie: 'Semences', quantite: 8, unite: 'kg', seuil: 10, statut: 'BAS' },
  { nom: 'Bouillie bordelaise', categorie: 'Pesticides', quantite: 15, unite: 'kg', seuil: 5, statut: 'OK' },
  { nom: 'Cacao grade 1 en stock', categorie: 'Récoltes', quantite: 250, unite: 'kg', seuil: 100, statut: 'OK' },
  { nom: 'Herbicide glyphosate', categorie: 'Herbicides', quantite: 2, unite: 'L', seuil: 5, statut: 'CRITIQUE' },
]

const GAMIFICATION = {
  points: 1240, niveau: 5, niveau_nom: 'Agriculteur Confirmé', prochain: 'Expert', points_prochain: 1500,
  badges: [
    { nom: 'Premier Pas', desc: 'Créer votre première parcelle', icone: '🌱', obtenu: true },
    { nom: 'Observateur', desc: 'Consulter 10 alertes', icone: '👁️', obtenu: true },
    { nom: 'Agronome Digital', desc: 'Compléter 3 formations', icone: '🎓', obtenu: true },
    { nom: 'Commerçant', desc: 'Effectuer un achat', icone: '🛒', obtenu: false },
    { nom: 'Communautaire', desc: 'Répondre à 5 questions', icone: '💬', obtenu: false },
    { nom: 'Expert IA', desc: 'Utiliser le diagnostic 10×', icone: '🤖', obtenu: false },
  ],
}

const PERF_ROI = [
  { mois: 'Oct', revenu: 580000, cout: 210000 },
  { mois: 'Nov', revenu: 720000, cout: 245000 },
  { mois: 'Déc', revenu: 890000, cout: 260000 },
  { mois: 'Jan', revenu: 1050000, cout: 290000 },
  { mois: 'Fév', revenu: 960000, cout: 275000 },
  { mois: 'Mar', revenu: 1240000, cout: 310000 },
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

const fmt = (n: number) => n.toLocaleString('fr-FR')

function NiveauBadge({ niveau }: { niveau: string }) {
  const map: Record<string, string> = {
    IMPORTANT: 'bg-orange-100 text-orange-700 border-orange-300',
    INFO: 'bg-blue-100 text-blue-700 border-blue-300',
    CRITIQUE: 'bg-red-100 text-red-700 border-red-300',
  }
  return <Badge className={`${map[niveau] || map.INFO} border text-xs`}>{niveau}</Badge>
}

function StatusBadge({ statut }: { statut: string }) {
  const map: Record<string, string> = {
    OPTIMAL: 'bg-green-100 text-green-700',
    SURVEILLANCE: 'bg-yellow-100 text-yellow-700',
    CRITIQUE: 'bg-red-100 text-red-700',
    ACTIF: 'bg-green-100 text-green-700',
    MAINTENANCE: 'bg-yellow-100 text-yellow-700',
    PLANIFIEE: 'bg-blue-100 text-blue-700',
    TERMINEE: 'bg-gray-100 text-gray-600',
    OK: 'bg-green-100 text-green-700',
    BAS: 'bg-yellow-100 text-yellow-700',
  }
  return <Badge className={`${map[statut] || 'bg-gray-100 text-gray-600'} text-xs`}>{statut}</Badge>
}

function DemoBanner() {
  return (
    <div className="bg-amber-50 border border-amber-200 rounded-lg px-4 py-2 flex items-center gap-2 text-sm text-amber-800 mb-6">
      <Eye className="h-4 w-4 shrink-0" />
      <span>Mode démonstration — données simulées. <Link href="/register" className="font-semibold underline">Créez un compte</Link> pour accéder à vos vraies données.</span>
    </div>
  )
}

function RegisterCTA({ context }: { context: string }) {
  return (
    <div className="mt-6 p-4 bg-green-50 border border-green-200 rounded-xl flex flex-col sm:flex-row items-center gap-3">
      <Lock className="h-5 w-5 text-green-600 shrink-0" />
      <p className="text-sm text-green-800 flex-1">
        <strong>Cette fonctionnalité est disponible après inscription.</strong>{' '}
        {context}
      </p>
      <Link href="/register">
        <Button size="sm" className="bg-green-600 hover:bg-green-700 whitespace-nowrap">
          S'inscrire gratuitement <ArrowRight className="h-4 w-4 ml-1" />
        </Button>
      </Link>
    </div>
  )
}

// ─── Tab: Dashboard ──────────────────────────────────────────────────────────

function TabDashboard() {
  const stats = [
    { label: 'Agriculteurs inscrits', value: '5 247', icon: Users, color: 'text-blue-600', bg: 'bg-blue-50' },
    { label: 'Hectares connectés', value: '51 230', icon: MapPin, color: 'text-green-600', bg: 'bg-green-50' },
    { label: 'Capteurs IoT actifs', value: '14 580', icon: Wifi, color: 'text-purple-600', bg: 'bg-purple-50' },
    { label: 'Alertes traitées ce mois', value: '892', icon: Bell, color: 'text-orange-600', bg: 'bg-orange-50' },
  ]

  return (
    <div className="space-y-8">
      {/* Plateforme stats */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">La plateforme en chiffres</h3>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {stats.map((s) => (
            <Card key={s.label}>
              <CardContent className="p-4 flex items-center gap-3">
                <div className={`p-2 rounded-lg ${s.bg}`}>
                  <s.icon className={`h-5 w-5 ${s.color}`} />
                </div>
                <div>
                  <p className="text-xl font-bold text-gray-900">{s.value}</p>
                  <p className="text-xs text-gray-500">{s.label}</p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Parcelles overview */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Vos parcelles (exemple)</h3>
        <div className="grid md:grid-cols-3 gap-4">
          {PARCELLES.map((p) => (
            <Card key={p.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex justify-between items-start mb-3">
                  <div>
                    <h4 className="font-semibold text-gray-900 text-sm">{p.nom}</h4>
                    <p className="text-xs text-gray-500">{p.superficie} ha · {p.cultureActuelle}</p>
                  </div>
                  <StatusBadge statut={p.sante} />
                </div>
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="text-gray-500">Santé globale</span>
                    <span className="font-medium">{p.sante_globale}%</span>
                  </div>
                  <Progress value={p.sante_globale} className="h-1.5" />
                  <div className="flex gap-3 mt-2 text-xs text-gray-600">
                    <span className="flex items-center gap-1"><Droplets className="h-3 w-3 text-blue-500" />{p.humidite}%</span>
                    <span className="flex items-center gap-1"><Thermometer className="h-3 w-3 text-orange-500" />{p.temperature}°C</span>
                    <span className="flex items-center gap-1"><Leaf className="h-3 w-3 text-green-500" />pH {p.ph}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Quick stats row */}
      <div className="grid md:grid-cols-3 gap-4">
        <Card className="bg-gradient-to-br from-green-50 to-emerald-50 border-green-200">
          <CardContent className="p-4">
            <p className="text-sm text-gray-600">ROI estimé</p>
            <p className="text-3xl font-bold text-green-700">+210%</p>
            <p className="text-xs text-gray-500 mt-1">sur 6 mois avec AgroSmart</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-blue-50 to-sky-50 border-blue-200">
          <CardContent className="p-4">
            <p className="text-sm text-gray-600">Économies réalisées</p>
            <p className="text-3xl font-bold text-blue-700">545 000</p>
            <p className="text-xs text-gray-500 mt-1">FCFA d'économies (eau + engrais)</p>
          </CardContent>
        </Card>
        <Card className="bg-gradient-to-br from-purple-50 to-violet-50 border-purple-200">
          <CardContent className="p-4">
            <p className="text-sm text-gray-600">Rendement vs national</p>
            <p className="text-3xl font-bold text-purple-700">+29.5%</p>
            <p className="text-xs text-gray-500 mt-1">au-dessus de la moyenne nationale</p>
          </CardContent>
        </Card>
      </div>

      <RegisterCTA context="Connectez vos vraies parcelles, capteurs IoT et recevez des alertes personnalisées." />
    </div>
  )
}

// ─── Tab: IoT & Capteurs ──────────────────────────────────────────────────────

function TabIoT() {
  const [selectedCapteur, setSelectedCapteur] = useState(CAPTEURS[0])

  return (
    <div className="space-y-6">
      <div className="grid md:grid-cols-2 gap-6">
        <div>
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Capteurs IoT ({CAPTEURS.length})</h3>
          <div className="space-y-2">
            {CAPTEURS.map((c) => (
              <Card
                key={c.id}
                className={`cursor-pointer transition-all ${selectedCapteur.id === c.id ? 'ring-2 ring-green-500' : 'hover:shadow-sm'}`}
                onClick={() => setSelectedCapteur(c)}
              >
                <CardContent className="p-3 flex items-center gap-3">
                  <div className={`w-2 h-2 rounded-full ${c.statut === 'ACTIF' ? 'bg-green-500' : 'bg-yellow-500'}`} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 truncate">{c.nom}</p>
                    <p className="text-xs text-gray-500">{c.type.replace(/_/g, ' ')}</p>
                  </div>
                  <div className="flex gap-3 text-xs text-gray-500 shrink-0">
                    <span className="flex items-center gap-1"><Battery className="h-3 w-3" />{c.batterie}%</span>
                    <span className="flex items-center gap-1"><Signal className="h-3 w-3" />{c.signal}%</span>
                  </div>
                  <StatusBadge statut={c.statut} />
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        <div>
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Historique 12h — {selectedCapteur.nom}</h3>
          <Card>
            <CardContent className="p-4">
              <div className="grid grid-cols-2 gap-3 mb-4">
                <div className="p-3 bg-blue-50 rounded-lg text-center">
                  <p className="text-xs text-gray-500">Valeur actuelle</p>
                  <p className="text-2xl font-bold text-blue-700">{selectedCapteur.valeur ?? '—'}</p>
                  <p className="text-xs text-gray-500">{selectedCapteur.unite}</p>
                </div>
                <div className="p-3 bg-green-50 rounded-lg text-center">
                  <p className="text-xs text-gray-500">Batterie</p>
                  <p className="text-2xl font-bold text-green-700">{selectedCapteur.batterie}%</p>
                  <Progress value={selectedCapteur.batterie} className="h-1 mt-1" />
                </div>
              </div>
              <ResponsiveContainer width="100%" height={160}>
                <LineChart data={MESURES_CHART}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis dataKey="heure" tick={{ fontSize: 10 }} />
                  <YAxis tick={{ fontSize: 10 }} />
                  <Tooltip />
                  <Line type="monotone" dataKey="humidite" stroke="#3b82f6" strokeWidth={2} dot={false} name="Humidité %" />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </Card>

          <Card className="mt-3">
            <CardContent className="p-4">
              <h4 className="text-sm font-semibold text-gray-700 mb-3">NPK — Parcelle Cacao Nord</h4>
              <div className="grid grid-cols-3 gap-2">
                {[{ label: 'Azote (N)', val: 42, color: '#22c55e' }, { label: 'Phosphore (P)', val: 18, color: '#3b82f6' }, { label: 'Potassium (K)', val: 35, color: '#f59e0b' }].map((item) => (
                  <div key={item.label} className="text-center p-2 bg-gray-50 rounded-lg">
                    <p className="text-lg font-bold" style={{ color: item.color }}>{item.val}</p>
                    <p className="text-xs text-gray-500">mg/kg</p>
                    <p className="text-xs text-gray-400">{item.label}</p>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      <RegisterCTA context="Connectez vos capteurs IoT (humidité, température, NPK, UV) et recevez des données en temps réel toutes les 15 minutes." />
    </div>
  )
}

// ─── Tab: Météo ───────────────────────────────────────────────────────────────

function TabMeteo() {
  return (
    <div className="space-y-6">
      {/* Météo actuelle */}
      <Card className="bg-gradient-to-r from-sky-500 to-blue-600 text-white border-0">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sky-100 text-sm">Abidjan, Côte d'Ivoire</p>
              <div className="flex items-end gap-2 mt-1">
                <p className="text-6xl font-bold">28.5°</p>
                <p className="text-sky-200 mb-2">Partiellement nuageux ⛅</p>
              </div>
              <div className="flex gap-4 mt-3 text-sm text-sky-100">
                <span className="flex items-center gap-1"><Droplets className="h-4 w-4" />72% humidité</span>
                <span className="flex items-center gap-1"><Wind className="h-4 w-4" />12 km/h SW</span>
                <span className="flex items-center gap-1"><CloudRain className="h-4 w-4" />0mm</span>
              </div>
            </div>
            <div className="text-7xl">⛅</div>
          </div>
        </CardContent>
      </Card>

      {/* Alerte météo */}
      <Card className="border-orange-200 bg-orange-50">
        <CardContent className="p-4 flex gap-3">
          <AlertCircle className="h-5 w-5 text-orange-600 shrink-0 mt-0.5" />
          <div>
            <p className="font-semibold text-orange-900 text-sm">Averses demain</p>
            <p className="text-xs text-orange-700 mt-1">Risque de pluies intenses (&gt;20mm). Reportez les traitements phytosanitaires.</p>
          </div>
        </CardContent>
      </Card>

      {/* Prévisions 7 jours */}
      <div>
        <h3 className="text-sm font-semibold text-gray-700 mb-3">Prévisions 7 jours</h3>
        <div className="grid grid-cols-7 gap-2">
          {METEO_PREVISIONS.map((j) => (
            <Card key={j.jour} className="text-center">
              <CardContent className="p-2">
                <p className="text-xs text-gray-500 font-medium">{j.jour}</p>
                <p className="text-2xl my-1">{j.icon}</p>
                <p className="text-xs font-bold text-gray-900">{j.max}°</p>
                <p className="text-xs text-gray-400">{j.min}°</p>
                {j.pluie > 0 && (
                  <p className="text-xs text-blue-500 mt-1">{j.pluie}%</p>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Chart précipitations */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm">Précipitations prévues (mm)</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={METEO_PREVISIONS}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="jour" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="pluie" fill="#3b82f6" radius={[3, 3, 0, 0]} name="Précipitations %" />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <RegisterCTA context="Recevez la météo hyperlocale de vos parcelles avec alertes SMS en cas de sécheresse ou orages imminents." />
    </div>
  )
}

// ─── Tab: Alertes ─────────────────────────────────────────────────────────────

function TabAlertes() {
  const nonLues = ALERTES.filter(a => a.statut === 'NOUVELLE').length

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Badge className="bg-red-100 text-red-700">{nonLues} nouvelles</Badge>
        <p className="text-sm text-gray-500">{ALERTES.length} alertes au total</p>
      </div>

      <div className="space-y-3">
        {ALERTES.map((a) => (
          <Card key={a.id} className={a.statut === 'LUE' ? 'opacity-75' : ''}>
            <CardContent className="p-4 flex gap-4">
              <div className={`shrink-0 w-10 h-10 rounded-full flex items-center justify-center ${
                a.niveau === 'IMPORTANT' ? 'bg-orange-100' : 'bg-blue-100'
              }`}>
                <Bell className={`h-5 w-5 ${a.niveau === 'IMPORTANT' ? 'text-orange-600' : 'text-blue-600'}`} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2 flex-wrap">
                  <h4 className="font-semibold text-gray-900 text-sm">{a.titre}</h4>
                  <div className="flex gap-2">
                    <NiveauBadge niveau={a.niveau} />
                    {a.statut === 'LUE' && <Badge variant="outline" className="text-xs">Lue</Badge>}
                  </div>
                </div>
                <p className="text-xs text-gray-600 mt-1">{a.message}</p>
                <div className="flex items-center gap-3 mt-2 text-xs text-gray-400">
                  <span className="flex items-center gap-1"><MapPin className="h-3 w-3" />{a.parcelle_nom}</span>
                  <span>Il y a {a.createdAt}</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <RegisterCTA context="Recevez des alertes en temps réel par SMS et WhatsApp dès qu'un capteur dépasse les seuils critiques." />
    </div>
  )
}

// ─── Tab: Diagnostic IA ───────────────────────────────────────────────────────

function TabDiagnostic() {
  return (
    <div className="space-y-6">
      <Card className="bg-gradient-to-r from-violet-50 to-purple-50 border-violet-200">
        <CardContent className="p-4 flex gap-3">
          <Brain className="h-6 w-6 text-violet-600 shrink-0 mt-0.5" />
          <div>
            <p className="font-semibold text-violet-900">IA de diagnostic — 94% de précision</p>
            <p className="text-sm text-violet-700 mt-1">Photographiez une plante malade et notre IA détecte 50+ maladies en secondes. Les diagnostics ci-dessous sont des exemples réels.</p>
          </div>
        </CardContent>
      </Card>

      <div className="space-y-4">
        {DIAGNOSTICS.map((d, i) => (
          <Card key={i}>
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between gap-3 flex-wrap">
                <div>
                  <CardTitle className="text-base">{d.maladie}</CardTitle>
                  <CardDescription>Culture : {d.culture}</CardDescription>
                </div>
                <div className="flex gap-2 items-center">
                  <Badge className={`${d.gravite === 'Élevée' ? 'bg-red-100 text-red-700' : 'bg-yellow-100 text-yellow-700'}`}>
                    Gravité {d.gravite}
                  </Badge>
                  <Badge className="bg-violet-100 text-violet-700">{d.confiance}% confiance</Badge>
                </div>
              </div>
              <div className="mt-2">
                <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
                  <span>Score de confiance IA</span>
                  <span>{d.confiance}%</span>
                </div>
                <Progress value={d.confiance} className="h-2" />
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <p className="text-xs font-semibold text-gray-700 mb-2">Symptômes détectés</p>
                  <ul className="space-y-1">
                    {d.symptomes.map((s, j) => (
                      <li key={j} className="flex items-center gap-2 text-xs text-gray-600">
                        <div className="w-1.5 h-1.5 rounded-full bg-red-400 shrink-0" />
                        {s}
                      </li>
                    ))}
                  </ul>
                </div>
                <div>
                  <p className="text-xs font-semibold text-gray-700 mb-2">Traitements recommandés</p>
                  <ul className="space-y-1">
                    {d.traitements.map((t, j) => (
                      <li key={j} className="flex items-center gap-2 text-xs text-gray-600">
                        <CheckCircle2 className="h-3 w-3 text-green-500 shrink-0" />
                        {t}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <Card className="border-dashed border-2 border-gray-300">
        <CardContent className="p-8 text-center">
          <Camera className="h-10 w-10 text-gray-400 mx-auto mb-3" />
          <p className="font-semibold text-gray-700">Analysez vos propres plantes</p>
          <p className="text-sm text-gray-500 mt-1">Prenez une photo de vos cultures malades et l'IA établit un diagnostic en moins de 5 secondes.</p>
          <Link href="/register" className="mt-4 inline-block">
            <Button className="bg-violet-600 hover:bg-violet-700 mt-3">
              Essayer le diagnostic IA <ArrowRight className="h-4 w-4 ml-1" />
            </Button>
          </Link>
        </CardContent>
      </Card>
    </div>
  )
}

// ─── Tab: Recommandations ─────────────────────────────────────────────────────

function TabRecommandations() {
  const typeColors: Record<string, string> = {
    irrigation: 'bg-blue-50 border-blue-200 text-blue-700',
    fertilisation: 'bg-green-50 border-green-200 text-green-700',
    prevention: 'bg-orange-50 border-orange-200 text-orange-700',
    recolte: 'bg-purple-50 border-purple-200 text-purple-700',
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2 text-sm text-gray-600">
        <Brain className="h-4 w-4 text-violet-600" />
        <span>4 recommandations générées par l'IA pour les parcelles démo</span>
      </div>

      <div className="space-y-3">
        {RECOMMANDATIONS.map((r) => (
          <Card key={r.id} className={`border-l-4 ${r.priorite === 1 ? 'border-l-red-500' : r.priorite === 2 ? 'border-l-orange-400' : 'border-l-yellow-400'}`}>
            <CardContent className="p-4">
              <div className="flex items-start justify-between gap-3 flex-wrap mb-2">
                <h4 className="font-semibold text-gray-900 text-sm">{r.titre}</h4>
                <div className="flex gap-2 flex-wrap">
                  <Badge className={`${typeColors[r.type] || 'bg-gray-100 text-gray-600'} border text-xs`}>{r.type}</Badge>
                  <Badge variant="outline" className="text-xs">Dans {r.delai}</Badge>
                </div>
              </div>
              <p className="text-xs text-gray-600 mb-3">{r.description}</p>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4 text-xs text-gray-500">
                  <span className="flex items-center gap-1"><MapPin className="h-3 w-3" />{r.parcelle}</span>
                  <span className="flex items-center gap-1 text-green-700 font-medium">
                    <TrendingUp className="h-3 w-3" />Économie potentielle : {r.economie} FCFA
                  </span>
                </div>
                <Button size="sm" variant="outline" className="text-xs h-7" disabled>
                  <Lock className="h-3 w-3 mr-1" />Appliquer
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <RegisterCTA context="Recevez des recommandations IA personnalisées basées sur vos capteurs, la météo locale et les conditions de vos cultures." />
    </div>
  )
}

// ─── Tab: Marketplace ─────────────────────────────────────────────────────────

function TabMarketplace() {
  const [categorie, setCategorie] = useState('Tous')
  const categories = ['Tous', 'Semences', 'Engrais', 'Équipement', 'Récoltes', 'Pesticides']
  const filtered = categorie === 'Tous' ? MARKETPLACE : MARKETPLACE.filter(p => p.categorie === categorie)

  return (
    <div className="space-y-6">
      <div className="flex gap-2 flex-wrap">
        {categories.map((c) => (
          <button
            key={c}
            onClick={() => setCategorie(c)}
            className={`px-3 py-1 rounded-full text-sm font-medium transition-colors ${
              categorie === c ? 'bg-green-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {c}
          </button>
        ))}
      </div>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filtered.map((p) => (
          <Card key={p.id} className="hover:shadow-md transition-shadow">
            <CardContent className="p-4">
              <div className="w-full h-28 bg-gradient-to-br from-gray-100 to-gray-200 rounded-lg mb-3 flex items-center justify-center">
                <ShoppingCart className="h-8 w-8 text-gray-400" />
              </div>
              <Badge className="mb-2 text-xs bg-gray-100 text-gray-600">{p.categorie}</Badge>
              {p.typeOffre === 'location' && <Badge className="mb-2 ml-1 text-xs bg-purple-100 text-purple-700">Location</Badge>}
              <h4 className="font-semibold text-gray-900 text-sm leading-tight">{p.nom}</h4>
              <p className="text-xs text-gray-500 mt-1">{p.vendeur}</p>
              <div className="flex items-center gap-1 mt-1">
                {[...Array(5)].map((_, i) => (
                  <Star key={i} className={`h-3 w-3 ${i < Math.floor(p.note) ? 'text-yellow-400 fill-yellow-400' : 'text-gray-200'}`} />
                ))}
                <span className="text-xs text-gray-500 ml-1">{p.note} ({p.nb_avis})</span>
              </div>
              <div className="flex items-center justify-between mt-3">
                <div>
                  <p className="text-lg font-bold text-gray-900">{fmt(p.prix)}</p>
                  <p className="text-xs text-gray-500">FCFA/{p.unite}</p>
                </div>
                <Button size="sm" variant="outline" className="text-xs" disabled>
                  <Lock className="h-3 w-3 mr-1" />Acheter
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Achats groupés */}
      <div>
        <h3 className="text-base font-semibold text-gray-900 mb-3 flex items-center gap-2">
          <Users className="h-5 w-5 text-green-600" />
          Achats groupés — Économisez plus ensemble
        </h3>
        <div className="grid md:grid-cols-2 gap-4">
          {ACHATS_GROUPES.map((ag) => (
            <Card key={ag.id} className="border-green-200">
              <CardContent className="p-4">
                <div className="flex justify-between items-start mb-2">
                  <h4 className="font-semibold text-gray-900 text-sm">{ag.titre}</h4>
                  <Badge className="bg-green-100 text-green-700 text-xs">-{ag.reduction}%</Badge>
                </div>
                <div className="flex gap-4 text-xs text-gray-600 mb-3">
                  <span>{fmt(ag.prixNormal)} FCFA/unité normal</span>
                  <span className="font-bold text-green-700">{fmt(ag.prixGroupe)} FCFA groupé</span>
                </div>
                <div className="space-y-1">
                  <div className="flex justify-between text-xs text-gray-500">
                    <span>{ag.actuel}/{ag.objectif} unités</span>
                    <span>{ag.participants} participants · {ag.dateLimite} restants</span>
                  </div>
                  <Progress value={(ag.actuel / ag.objectif) * 100} className="h-2" />
                </div>
                <Button size="sm" className="w-full mt-3 bg-green-600 hover:bg-green-700 text-xs" disabled>
                  <Lock className="h-3 w-3 mr-1" />Rejoindre le groupage
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      <RegisterCTA context="Achetez des semences, engrais et équipements, vendez vos récoltes et louez du matériel agricole à prix réduit." />
    </div>
  )
}

// ─── Tab: Forum ───────────────────────────────────────────────────────────────

function TabForum() {
  const communaute = { membres: 5247, discussions: 1234, reponses: 8976 }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-3 gap-4">
        {[
          { label: 'Membres', val: fmt(communaute.membres), icon: Users },
          { label: 'Discussions', val: fmt(communaute.discussions), icon: MessageSquare },
          { label: 'Réponses', val: fmt(communaute.reponses), icon: CheckCircle2 },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className="p-3 text-center">
              <s.icon className="h-5 w-5 text-green-600 mx-auto mb-1" />
              <p className="text-lg font-bold text-gray-900">{s.val}</p>
              <p className="text-xs text-gray-500">{s.label}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="space-y-3">
        {FORUM.map((f) => (
          <Card key={f.id} className="hover:shadow-sm transition-shadow">
            <CardContent className="p-4 flex gap-4">
              <div className="shrink-0 w-10 h-10 rounded-full bg-gradient-to-br from-green-400 to-emerald-600 flex items-center justify-center text-white font-bold text-sm">
                {f.auteur.charAt(0)}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-start justify-between gap-2 flex-wrap">
                  <h4 className="font-medium text-gray-900 text-sm leading-tight">{f.titre}</h4>
                  {f.resolu && <Badge className="bg-green-100 text-green-700 text-xs shrink-0">Résolu</Badge>}
                </div>
                <p className="text-xs text-gray-500 mt-1">Par {f.auteur} · {f.age} · <Badge variant="outline" className="text-xs py-0">{f.categorie}</Badge></p>
                <div className="flex gap-4 mt-2 text-xs text-gray-400">
                  <span className="flex items-center gap-1"><Eye className="h-3 w-3" />{f.vues} vues</span>
                  <span className="flex items-center gap-1"><MessageSquare className="h-3 w-3" />{f.reponses} réponses</span>
                </div>
              </div>
              <ChevronRight className="h-4 w-4 text-gray-400 shrink-0 mt-1" />
            </CardContent>
          </Card>
        ))}
      </div>

      <RegisterCTA context="Posez vos questions, partagez vos expériences et échangez avec 5 000+ agriculteurs de Côte d'Ivoire." />
    </div>
  )
}

// ─── Tab: Formations ─────────────────────────────────────────────────────────

function TabFormations() {
  const niveauColor: Record<string, string> = {
    Débutant: 'bg-green-100 text-green-700',
    Intermédiaire: 'bg-blue-100 text-blue-700',
    Avancé: 'bg-purple-100 text-purple-700',
  }

  return (
    <div className="space-y-6">
      <div className="grid md:grid-cols-2 gap-4">
        {FORMATIONS.map((f) => (
          <Card key={f.id} className="hover:shadow-md transition-shadow">
            <CardContent className="p-4">
              <div className="w-full h-24 bg-gradient-to-br from-green-100 to-emerald-100 rounded-lg mb-3 flex items-center justify-center">
                <BookOpen className="h-8 w-8 text-green-600" />
              </div>
              <div className="flex gap-2 mb-2 flex-wrap">
                <Badge className={`${niveauColor[f.niveau] || 'bg-gray-100'} text-xs`}>{f.niveau}</Badge>
                <Badge variant="outline" className="text-xs">{f.categorie}</Badge>
              </div>
              <h4 className="font-semibold text-gray-900 text-sm leading-tight">{f.titre}</h4>
              <div className="flex gap-4 mt-2 text-xs text-gray-500">
                <span>{f.duree} min</span>
                <span>{f.modules} modules</span>
                <span>{fmt(f.vues)} vues</span>
              </div>
              {f.progression > 0 && (
                <div className="mt-3">
                  <div className="flex justify-between text-xs text-gray-500 mb-1">
                    <span>Progression</span>
                    <span>{f.progression}%</span>
                  </div>
                  <Progress value={f.progression} className="h-1.5" />
                </div>
              )}
              <Button size="sm" variant={f.progression === 100 ? 'outline' : 'default'} className="w-full mt-3 text-xs" disabled>
                <Lock className="h-3 w-3 mr-1" />
                {f.progression === 100 ? 'Revoir' : f.progression > 0 ? 'Continuer' : 'Commencer'}
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>

      <RegisterCTA context="Accédez à plus de 50 formations vidéo sur l'irrigation, les maladies des cultures, la fertilisation et l'utilisation des capteurs IoT." />
    </div>
  )
}

// ─── Tab: Calendrier ─────────────────────────────────────────────────────────

function TabCalendrier() {
  const typeIcons: Record<string, React.ReactNode> = {
    ARROSAGE: <Droplets className="h-4 w-4 text-blue-600" />,
    FERTILISATION: <Leaf className="h-4 w-4 text-green-600" />,
    RECOLTE: <Package className="h-4 w-4 text-purple-600" />,
    TRAITEMENT: <Shield className="h-4 w-4 text-orange-600" />,
  }
  const prioriteColor: Record<string, string> = {
    URGENTE: 'border-l-red-500',
    HAUTE: 'border-l-orange-400',
    MOYENNE: 'border-l-yellow-400',
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-4 gap-3 text-center">
        {[
          { label: 'Planifiées', val: 3, color: 'text-blue-600', bg: 'bg-blue-50' },
          { label: 'Urgentes', val: 1, color: 'text-red-600', bg: 'bg-red-50' },
          { label: 'Terminées', val: 1, color: 'text-gray-600', bg: 'bg-gray-50' },
          { label: 'Coût total', val: '73K', color: 'text-green-600', bg: 'bg-green-50' },
        ].map((s) => (
          <Card key={s.label}>
            <CardContent className={`p-3 ${s.bg} rounded-lg`}>
              <p className={`text-xl font-bold ${s.color}`}>{s.val}</p>
              <p className="text-xs text-gray-500">{s.label}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="space-y-3">
        {CALENDRIER.map((e) => (
          <Card key={e.id} className={`border-l-4 ${prioriteColor[e.priorite] || 'border-l-gray-300'}`}>
            <CardContent className="p-4 flex gap-4">
              <div className="shrink-0 w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center">
                {typeIcons[e.type] || <Calendar className="h-4 w-4 text-gray-500" />}
              </div>
              <div className="flex-1">
                <div className="flex items-start justify-between gap-2 flex-wrap">
                  <h4 className="font-semibold text-gray-900 text-sm">{e.titre}</h4>
                  <div className="flex gap-2">
                    <StatusBadge statut={e.statut} />
                    <Badge variant="outline" className="text-xs">{e.priorite}</Badge>
                  </div>
                </div>
                <div className="flex gap-4 mt-1 text-xs text-gray-500">
                  <span className="flex items-center gap-1"><Calendar className="h-3 w-3" />{e.date}</span>
                  <span className="flex items-center gap-1"><MapPin className="h-3 w-3" />{e.parcelle}</span>
                  <span className="text-green-700 font-medium">{e.cout} FCFA</span>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <RegisterCTA context="Planifiez arrosages, fertilisations, traitements et récoltes. Recevez des rappels automatiques sur votre téléphone." />
    </div>
  )
}

// ─── Tab: Stocks ─────────────────────────────────────────────────────────────

function TabStocks() {
  const alertes = STOCKS.filter(s => s.statut !== 'OK')
  const valeurTotale = STOCKS.reduce((sum, s) => sum + s.quantite * (s.statut === 'BAS' ? 2500 : s.statut === 'CRITIQUE' ? 4500 : 360), 0)

  const statutColor: Record<string, string> = {
    OK: 'bg-green-100 text-green-700',
    BAS: 'bg-yellow-100 text-yellow-700',
    CRITIQUE: 'bg-red-100 text-red-700',
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-3 text-center">
            <p className="text-2xl font-bold text-gray-900">{STOCKS.length}</p>
            <p className="text-xs text-gray-500">Articles en stock</p>
          </CardContent>
        </Card>
        <Card className={alertes.length > 0 ? 'border-orange-200 bg-orange-50' : ''}>
          <CardContent className="p-3 text-center">
            <p className="text-2xl font-bold text-orange-700">{alertes.length}</p>
            <p className="text-xs text-gray-500">Alertes stock</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-3 text-center">
            <p className="text-2xl font-bold text-gray-900">{fmt(valeurTotale)}</p>
            <p className="text-xs text-gray-500">Valeur totale FCFA</p>
          </CardContent>
        </Card>
      </div>

      {alertes.length > 0 && (
        <Card className="border-orange-200 bg-orange-50">
          <CardContent className="p-3 flex gap-2">
            <AlertCircle className="h-4 w-4 text-orange-600 shrink-0 mt-0.5" />
            <div className="text-xs text-orange-800">
              <strong>{alertes.length} articles en stock bas ou critique :</strong>{' '}
              {alertes.map(a => a.nom).join(', ')}
            </div>
          </CardContent>
        </Card>
      )}

      <div className="space-y-2">
        {STOCKS.map((s, i) => (
          <Card key={i}>
            <CardContent className="p-4 flex items-center gap-4">
              <div className="flex-1">
                <div className="flex items-center justify-between gap-2 flex-wrap">
                  <h4 className="font-medium text-gray-900 text-sm">{s.nom}</h4>
                  <Badge className={`${statutColor[s.statut]} text-xs`}>{s.statut}</Badge>
                </div>
                <p className="text-xs text-gray-500 mt-1">{s.categorie}</p>
                <div className="mt-2">
                  <div className="flex justify-between text-xs text-gray-500 mb-1">
                    <span>{s.quantite} {s.unite} en stock</span>
                    <span>Seuil : {s.seuil} {s.unite}</span>
                  </div>
                  <Progress
                    value={Math.min(100, (s.quantite / s.seuil) * 50)}
                    className={`h-1.5 ${s.statut === 'CRITIQUE' ? '[&>div]:bg-red-500' : s.statut === 'BAS' ? '[&>div]:bg-yellow-500' : ''}`}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <RegisterCTA context="Gérez l'inventaire de vos intrants et récoltes, et recevez des alertes automatiques quand le stock est trop bas." />
    </div>
  )
}

// ─── Tab: Performance & Gamification ─────────────────────────────────────────

function TabPerformance() {
  const COLORS_PIE = ['#22c55e', '#3b82f6', '#f59e0b']
  const economies = [
    { label: 'Eau', val: 85000, pct: 32 },
    { label: 'Engrais', val: 120000, pct: 24 },
    { label: 'Pertes évitées', val: 340000, pct: 38 },
  ]

  return (
    <div className="space-y-6">
      {/* ROI Card */}
      <Card className="bg-gradient-to-r from-green-500 to-emerald-600 text-white border-0">
        <CardContent className="p-6 flex items-center justify-between gap-4 flex-wrap">
          <div>
            <p className="text-green-100 text-sm">Retour sur investissement</p>
            <p className="text-5xl font-bold">+210%</p>
            <p className="text-green-100 text-sm mt-1">Bénéfice net : 2 625 000 FCFA sur 6 mois</p>
          </div>
          <div className="text-right">
            <p className="text-green-100 text-xs">Coût total</p>
            <p className="text-xl font-bold">1 250 000 FCFA</p>
            <p className="text-green-100 text-xs mt-2">Revenus</p>
            <p className="text-xl font-bold">3 875 000 FCFA</p>
          </div>
        </CardContent>
      </Card>

      {/* Évolution revenus/coûts */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm">Revenus vs Coûts (6 derniers mois)</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={PERF_ROI}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="mois" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 10 }} tickFormatter={(v) => `${(v / 1000).toFixed(0)}k`} />
              <Tooltip formatter={(v: number | undefined) => `${fmt(v ?? 0)} FCFA`} />
              <Bar dataKey="revenu" fill="#22c55e" name="Revenus" radius={[2, 2, 0, 0]} />
              <Bar dataKey="cout" fill="#f87171" name="Coûts" radius={[2, 2, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Économies */}
      <div className="grid md:grid-cols-2 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Répartition des économies</CardTitle>
          </CardHeader>
          <CardContent className="flex items-center gap-4">
            <ResponsiveContainer width={120} height={120}>
              <PieChart>
                <Pie data={economies} dataKey="val" cx="50%" cy="50%" outerRadius={55} innerRadius={30}>
                  {economies.map((_, i) => <Cell key={i} fill={COLORS_PIE[i]} />)}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div className="space-y-2">
              {economies.map((e, i) => (
                <div key={e.label} className="flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-full shrink-0" style={{ backgroundColor: COLORS_PIE[i] }} />
                  <div>
                    <p className="text-xs font-medium text-gray-700">{e.label} ({e.pct}%)</p>
                    <p className="text-xs text-gray-500">{fmt(e.val)} FCFA</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm">Rendements vs Optimal</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            {[
              { culture: 'Cacao', actuel: 520, optimal: 800, pct: 65 },
              { culture: 'Café', actuel: 380, optimal: 600, pct: 63 },
              { culture: 'Plantain', actuel: 11500, optimal: 15000, pct: 77 },
            ].map((r) => (
              <div key={r.culture}>
                <div className="flex justify-between text-xs text-gray-600 mb-1">
                  <span>{r.culture}</span>
                  <span className="font-medium">{r.pct}% de l'optimal</span>
                </div>
                <Progress value={r.pct} className="h-2" />
                <p className="text-xs text-gray-400 mt-0.5">{fmt(r.actuel)} kg/ha · optimal {fmt(r.optimal)} kg/ha</p>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>

      {/* Gamification */}
      <div>
        <h3 className="text-base font-semibold text-gray-900 mb-3 flex items-center gap-2">
          <Award className="h-5 w-5 text-yellow-500" />
          Gamification — {GAMIFICATION.niveau_nom}
        </h3>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-4 mb-4">
              <div className="w-14 h-14 rounded-full bg-gradient-to-br from-yellow-400 to-orange-500 flex items-center justify-center text-white font-bold text-xl">
                {GAMIFICATION.niveau}
              </div>
              <div className="flex-1">
                <p className="font-semibold text-gray-900">{GAMIFICATION.niveau_nom}</p>
                <div className="flex justify-between text-xs text-gray-500 mt-1 mb-1">
                  <span>{fmt(GAMIFICATION.points)} pts</span>
                  <span>Prochain : {GAMIFICATION.prochain} ({fmt(GAMIFICATION.points_prochain)} pts)</span>
                </div>
                <Progress value={(GAMIFICATION.points / GAMIFICATION.points_prochain) * 100} className="h-2" />
              </div>
            </div>
            <div className="grid grid-cols-3 sm:grid-cols-6 gap-2">
              {GAMIFICATION.badges.map((b) => (
                <div key={b.nom} className={`text-center p-2 rounded-lg ${b.obtenu ? 'bg-yellow-50 border border-yellow-200' : 'bg-gray-50 opacity-50 grayscale'}`}>
                  <p className="text-2xl">{b.icone}</p>
                  <p className="text-xs font-medium text-gray-700 mt-1 leading-tight">{b.nom}</p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <RegisterCTA context="Suivez votre ROI en temps réel, gagnez des points et débloquez des badges en adoptant les meilleures pratiques agricoles." />
    </div>
  )
}

// ─── Main Page ────────────────────────────────────────────────────────────────

const TABS = [
  { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
  { id: 'iot', label: 'IoT', icon: Wifi },
  { id: 'meteo', label: 'Météo', icon: Cloud },
  { id: 'alertes', label: 'Alertes', icon: Bell },
  { id: 'ia', label: 'IA', icon: Brain },
  { id: 'recommandations', label: 'Conseils', icon: Target },
  { id: 'marketplace', label: 'Marché', icon: ShoppingCart },
  { id: 'forum', label: 'Forum', icon: Users },
  { id: 'formations', label: 'Formations', icon: GraduationCap },
  { id: 'calendrier', label: 'Calendrier', icon: Calendar },
  { id: 'stocks', label: 'Stocks', icon: Package },
  { id: 'performance', label: 'ROI', icon: TrendingUp },
]

export default function VisitorDemoPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 to-emerald-50">
      {/* Header */}
      <div className="border-b border-gray-200 bg-white/90 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Link href="/" className="flex items-center gap-2">
              <div className="w-8 h-8 bg-green-600 rounded-lg flex items-center justify-center">
                <Leaf className="h-5 w-5 text-white" />
              </div>
              <span className="font-bold text-gray-900 hidden sm:block">AgroSmart</span>
            </Link>
            <div className="hidden sm:block">
              <Badge className="bg-amber-100 text-amber-700 border border-amber-300 text-xs">
                <Eye className="h-3 w-3 mr-1" />Mode Découverte
              </Badge>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Link href="/login">
              <Button variant="ghost" size="sm" className="text-gray-600 text-xs">Se connecter</Button>
            </Link>
            <Link href="/register">
              <Button size="sm" className="bg-green-600 hover:bg-green-700 text-xs">
                S'inscrire gratuitement <ArrowRight className="h-3 w-3 ml-1" />
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Hero */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="max-w-7xl mx-auto px-4 py-8"
      >
        <div className="text-center mb-8">
          <h1 className="text-3xl md:text-4xl font-bold text-gray-900 mb-3">
            Découvrez AgroSmart en action
          </h1>
          <p className="text-gray-600 max-w-2xl mx-auto text-sm md:text-base">
            Explorez toutes les fonctionnalités avec des données simulées réalistes.
            Parcelles IoT, météo, IA, marketplace, formations et bien plus.
          </p>
          <div className="flex flex-wrap justify-center gap-4 mt-4 text-xs text-gray-500">
            {[
              { icon: Wifi, text: 'IoT temps réel' },
              { icon: Brain, text: 'IA 94% précision' },
              { icon: Smartphone, text: 'Android & iOS' },
              { icon: Globe, text: 'Multilingue' },
              { icon: Zap, text: 'Alertes SMS/WhatsApp' },
            ].map((f) => (
              <span key={f.text} className="flex items-center gap-1">
                <f.icon className="h-3 w-3 text-green-600" />{f.text}
              </span>
            ))}
          </div>
        </div>

        <DemoBanner />

        {/* Tabs */}
        <Tabs defaultValue="dashboard">
          <div className="overflow-x-auto pb-1 mb-6">
            <TabsList className="inline-flex h-auto gap-1 bg-white border border-gray-200 p-1 rounded-xl shadow-sm min-w-max">
              {TABS.map((t) => (
                <TabsTrigger
                  key={t.id}
                  value={t.id}
                  className="flex items-center gap-1.5 px-3 py-2 text-xs font-medium rounded-lg data-[state=active]:bg-green-600 data-[state=active]:text-white"
                >
                  <t.icon className="h-3.5 w-3.5" />
                  <span className="hidden sm:inline">{t.label}</span>
                </TabsTrigger>
              ))}
            </TabsList>
          </div>

          <AnimatePresence mode="wait">
            <TabsContent value="dashboard"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabDashboard /></motion.div></TabsContent>
            <TabsContent value="iot"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabIoT /></motion.div></TabsContent>
            <TabsContent value="meteo"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabMeteo /></motion.div></TabsContent>
            <TabsContent value="alertes"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabAlertes /></motion.div></TabsContent>
            <TabsContent value="ia"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabDiagnostic /></motion.div></TabsContent>
            <TabsContent value="recommandations"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabRecommandations /></motion.div></TabsContent>
            <TabsContent value="marketplace"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabMarketplace /></motion.div></TabsContent>
            <TabsContent value="forum"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabForum /></motion.div></TabsContent>
            <TabsContent value="formations"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabFormations /></motion.div></TabsContent>
            <TabsContent value="calendrier"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabCalendrier /></motion.div></TabsContent>
            <TabsContent value="stocks"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabStocks /></motion.div></TabsContent>
            <TabsContent value="performance"><motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}><TabPerformance /></motion.div></TabsContent>
          </AnimatePresence>
        </Tabs>

        {/* Final CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mt-12"
        >
          <Card className="bg-gradient-to-r from-green-600 to-emerald-700 border-0 text-white overflow-hidden">
            <CardContent className="p-8 md:p-12">
              <div className="max-w-2xl mx-auto text-center">
                <h2 className="text-2xl md:text-3xl font-bold mb-3">
                  Prêt à transformer votre exploitation ?
                </h2>
                <p className="text-green-100 mb-6 text-sm md:text-base">
                  Rejoignez 5 247 agriculteurs qui augmentent leur rendement de 25% et économisent jusqu'à 545 000 FCFA par saison avec AgroSmart.
                </p>
                <div className="flex flex-col sm:flex-row gap-3 justify-center">
                  <Link href="/register">
                    <Button size="lg" className="bg-white text-green-700 hover:bg-gray-50 font-semibold w-full sm:w-auto">
                      Créer mon compte gratuit <ArrowRight className="h-4 w-4 ml-2" />
                    </Button>
                  </Link>
                  <Link href="/login">
                    <Button size="lg" variant="outline" className="border-white text-white hover:bg-white/10 w-full sm:w-auto">
                      J'ai déjà un compte
                    </Button>
                  </Link>
                </div>
                <p className="text-green-200 text-xs mt-4">
                  Gratuit · Pas de carte bancaire requise · Assistance en français
                </p>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </motion.div>
    </div>
  )
}

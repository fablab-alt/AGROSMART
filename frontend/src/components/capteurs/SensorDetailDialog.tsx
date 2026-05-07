'use client'

import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent } from '@/components/ui/card'
import {
  Thermometer, Droplets, Sun, Wind, Gauge, Activity,
  CheckCircle2, AlertTriangle, Info, Lightbulb, ShieldCheck, TrendingUp
} from 'lucide-react'

interface CapteurDetail {
  id: string
  nom: string
  type: string
  parcelleNom: string
  statut: string
  batterie: number
  signal: number
  derniereMesure: {
    valeur: number | string
    unite: string
    date: string
  } | null
  seuilMin: number
  seuilMax: number
}

interface Props {
  capteur: CapteurDetail | null
  open: boolean
  onClose: () => void
}

// Generate farmer-friendly interpretation and recommendations
function getSensorAnalysis(capteur: CapteurDetail) {
  if (!capteur.derniereMesure) {
    return {
      status: 'no_data',
      statusColor: 'text-gray-500',
      statusBg: 'bg-gray-50',
      statusIcon: Info,
      statusLabel: 'Aucune donnée',
      interpretation: 'Ce capteur n\'a pas encore transmis de mesure. Vérifiez qu\'il est correctement installé et connecté.',
      recommendations: [
        'Vérifiez que le capteur est bien alimenté (batterie ou panneau solaire)',
        'Assurez-vous que le capteur est à portée de la station relais',
        'Si le problème persiste, contactez le support technique'
      ],
      details: []
    }
  }

  const value = typeof capteur.derniereMesure.valeur === 'string'
    ? parseFloat(capteur.derniereMesure.valeur) || 0
    : capteur.derniereMesure.valeur
  const { seuilMin, seuilMax, type } = capteur
  const isAlert = value < seuilMin || value > seuilMax
  const isCritical = value < seuilMin * 0.7 || value > seuilMax * 1.3

  let interpretation = ''
  let recommendations: string[] = []
  let details: { label: string; value: string }[] = []

  switch (type?.toLowerCase()) {
    case 'humidite_temperature_ambiante':
    case 'humidite_temperature': {
      // Parse compound reading if needed
      const temp = value
      details = [
        { label: 'Température actuelle', value: `${value}${capteur.derniereMesure.unite}` },
        { label: 'Plage optimale', value: `${seuilMin} - ${seuilMax}${capteur.derniereMesure.unite}` },
      ]

      if (value > seuilMax) {
        interpretation = `La température est élevée (${value}${capteur.derniereMesure.unite}). Vos cultures peuvent souffrir de stress thermique.`
        recommendations = [
          '🌿 Augmentez l\'irrigation pour compenser l\'évaporation',
          '🛡️ Installez des filets d\'ombrage sur les cultures sensibles',
          '⏰ Évitez les travaux aux champs entre 12h et 15h',
          '💧 Privilégiez l\'arrosage tôt le matin ou en fin d\'après-midi'
        ]
      } else if (value < seuilMin) {
        interpretation = `La température est basse (${value}${capteur.derniereMesure.unite}). Certaines cultures tropicales peuvent être affectées.`
        recommendations = [
          '🌱 Protégez les jeunes plants avec un paillage',
          '⛺ Utilisez des voiles de protection la nuit si possible',
          '🔥 Évitez de planter ou repiquer pendant cette période froide',
          '📅 Attendez des températures plus clémentes pour les semis'
        ]
      } else {
        interpretation = `La température est dans la plage optimale (${value}${capteur.derniereMesure.unite}). Conditions favorables pour vos cultures.`
        recommendations = [
          '✅ Conditions idéales pour la croissance des plantes',
          '🌱 Bon moment pour les semis et le repiquage',
          '📊 Continuez à surveiller régulièrement'
        ]
      }
      break
    }

    case 'humidite_sol': {
      details = [
        { label: 'Humidité du sol', value: `${value}${capteur.derniereMesure.unite}` },
        { label: 'Plage optimale', value: `${seuilMin} - ${seuilMax}${capteur.derniereMesure.unite}` },
      ]

      if (value < seuilMin) {
        interpretation = `Le sol est trop sec (${value}%). Vos plantes risquent de manquer d\'eau.`
        recommendations = [
          '💧 Arrosez dès que possible, de préférence le matin',
          '🌾 Appliquez du paillage pour retenir l\'humidité',
          '🕐 Programmez l\'irrigation automatique si disponible',
          '🌿 Priorisez l\'arrosage des cultures les plus sensibles (légumes, jeunes plants)'
        ]
      } else if (value > seuilMax) {
        interpretation = `Le sol est trop humide (${value}%). Risque de pourriture des racines.`
        recommendations = [
          '⚠️ Réduisez ou stoppez l\'irrigation temporairement',
          '🚿 Vérifiez le drainage de vos parcelles',
          '👀 Surveillez les signes de maladie fongique (jaunissement, moisissures)',
          '🌱 Évitez de marcher sur les zones détrempées pour ne pas compacter le sol'
        ]
      } else {
        interpretation = `L\'humidité du sol est optimale (${value}%). Vos plantes disposent de suffisamment d\'eau.`
        recommendations = [
          '✅ Niveau d\'hydratation parfait pour la croissance',
          '📊 Maintenez ce niveau avec un arrosage régulier',
          '🌱 Conditions idéales pour l\'absorption des nutriments'
        ]
      }
      break
    }

    case 'uv': {
      details = [
        { label: 'Indice UV', value: `${value} ${capteur.derniereMesure.unite}` },
        { label: 'Plage optimale', value: `${seuilMin} - ${seuilMax}` },
      ]

      if (value > seuilMax) {
        interpretation = `L\'indice UV est très élevé (${value}). Risque de brûlure pour les plantes sensibles.`
        recommendations = [
          '☀️ Installez des filets d\'ombrage (30-50%) sur les cultures sensibles',
          '💧 Augmentez la fréquence d\'arrosage pour compenser la chaleur',
          '🌿 Les jeunes plants et les semis sont les plus vulnérables',
          '🧑‍🌾 Protégez-vous aussi ! Portez un chapeau et de la crème solaire'
        ]
      } else if (value < seuilMin) {
        interpretation = `L\'ensoleillement est faible (UV: ${value}). Certaines cultures peuvent manquer de lumière.`
        recommendations = [
          '🔍 Vérifiez que rien ne fait de l\'ombre sur vos cultures',
          '🌱 Les cultures fruitières ont besoin de plus de lumière',
          '📅 C\'est normal en saison des pluies, patience !',
          '✅ Les cultures d\'ombre (cacao, café) se portent bien'
        ]
      } else {
        interpretation = `L\'ensoleillement est bon (UV: ${value}). Conditions favorables à la photosynthèse.`
        recommendations = [
          '✅ Luminosité idéale pour la croissance',
          '🌱 Parfait pour la floraison et la fructification',
          '📊 Continuez la surveillance'
        ]
      }
      break
    }

    case 'npk': {
      const npkStr = String(capteur.derniereMesure.valeur)
      details = [
        { label: 'Niveau NPK', value: npkStr },
        { label: 'N = Azote', value: 'Croissance des feuilles' },
        { label: 'P = Phosphore', value: 'Développement des racines' },
        { label: 'K = Potassium', value: 'Qualité des fruits' },
      ]

      interpretation = `Analyse NPK du sol : ${npkStr}. Ces nutriments sont essentiels pour vos cultures.`
      recommendations = [
        '🧪 Comparez ces valeurs avec les besoins de votre culture',
        '🌿 Un manque d\'azote (N) se voit par des feuilles jaunissantes',
        '🌱 Un manque de phosphore (P) ralentit la croissance des racines',
        '🍎 Un manque de potassium (K) affecte la qualité des fruits',
        '🐄 Utilisez du compost ou du fumier pour enrichir naturellement le sol'
      ]
      break
    }

    case 'direction_vent': {
      details = [
        { label: 'Vitesse/Direction', value: `${value} ${capteur.derniereMesure.unite}` },
        { label: 'Plage normale', value: `${seuilMin} - ${seuilMax} ${capteur.derniereMesure.unite}` },
      ]

      if (value > seuilMax) {
        interpretation = `Le vent est fort (${value} ${capteur.derniereMesure.unite}). Risque de dégâts sur les cultures hautes.`
        recommendations = [
          '⚠️ Reportez les traitements phytosanitaires (le vent disperse les produits)',
          '🌳 Vérifiez les tuteurs et supports des plantes hautes',
          '🏗️ Sécurisez les bâches et équipements légers',
          '🌿 Les brise-vent végétaux protègent efficacement vos parcelles'
        ]
      } else {
        interpretation = `Le vent est modéré (${value} ${capteur.derniereMesure.unite}). Conditions normales.`
        recommendations = [
          '✅ Conditions favorables pour les traitements phytosanitaires',
          '🌱 Le vent léger favorise la pollinisation naturelle',
          '📊 Aucune action particulière requise'
        ]
      }
      break
    }

    case 'transpiration_plante': {
      details = [
        { label: 'Transpiration', value: `${value} ${capteur.derniereMesure.unite}` },
        { label: 'Plage optimale', value: `${seuilMin} - ${seuilMax} ${capteur.derniereMesure.unite}` },
      ]

      if (value > seuilMax) {
        interpretation = `La transpiration est élevée (${value} ${capteur.derniereMesure.unite}). Vos plantes perdent beaucoup d\'eau.`
        recommendations = [
          '💧 Augmentez l\'arrosage pour compenser la perte en eau',
          '🌿 Le paillage réduit l\'évaporation du sol',
          '☀️ Si possible, protégez les plantes du soleil direct',
          '🔍 Vérifiez que les plantes ne sont pas stressées'
        ]
      } else if (value < seuilMin) {
        interpretation = `La transpiration est basse (${value} ${capteur.derniereMesure.unite}). Les plantes ne transpirent pas assez.`
        recommendations = [
          '🔍 Vérifiez que les stomates des feuilles sont ouverts',
          '💧 Un excès d\'eau peut bloquer la transpiration',
          '🌡️ Les températures basses réduisent naturellement la transpiration',
          '📊 Surveillez l\'état général des plantes'
        ]
      } else {
        interpretation = `La transpiration est normale (${value} ${capteur.derniereMesure.unite}). Vos plantes fonctionnent bien.`
        recommendations = [
          '✅ Les plantes transpirent normalement',
          '🌱 Signe d\'une bonne santé végétale',
          '💧 L\'absorption d\'eau et de nutriments est optimale'
        ]
      }
      break
    }

    default: {
      details = [
        { label: 'Valeur mesurée', value: `${value} ${capteur.derniereMesure.unite}` },
        { label: 'Plage optimale', value: `${seuilMin} - ${seuilMax}` },
      ]
      interpretation = `Mesure actuelle : ${value} ${capteur.derniereMesure.unite}.`
      recommendations = ['📊 Continuez la surveillance régulière']
    }
  }

  return {
    status: isCritical ? 'critical' : isAlert ? 'warning' : 'ok',
    statusColor: isCritical ? 'text-red-600' : isAlert ? 'text-orange-600' : 'text-green-600',
    statusBg: isCritical ? 'bg-red-50 border-red-200' : isAlert ? 'bg-orange-50 border-orange-200' : 'bg-green-50 border-green-200',
    statusIcon: isCritical ? AlertTriangle : isAlert ? AlertTriangle : CheckCircle2,
    statusLabel: isCritical ? 'Critique - Action requise' : isAlert ? 'Attention - À surveiller' : 'Tout est normal',
    interpretation,
    recommendations,
    details
  }
}

function getTypeIcon(type: string) {
  switch (type?.toLowerCase()) {
    case 'humidite_temperature_ambiante': return <Thermometer className="h-6 w-6" />
    case 'humidite_sol': return <Droplets className="h-6 w-6" />
    case 'uv': return <Sun className="h-6 w-6" />
    case 'npk': return <Gauge className="h-6 w-6" />
    case 'direction_vent': return <Wind className="h-6 w-6" />
    case 'transpiration_plante': return <Activity className="h-6 w-6" />
    default: return <Activity className="h-6 w-6" />
  }
}

function getTypeLabel(type: string) {
  switch (type?.toLowerCase()) {
    case 'humidite_temperature_ambiante': return 'Humidité & Température Ambiante'
    case 'humidite_sol': return 'Humidité du Sol'
    case 'uv': return 'Indice UV / Ensoleillement'
    case 'npk': return 'NPK - Nutriments du Sol'
    case 'direction_vent': return 'Vent'
    case 'transpiration_plante': return 'Transpiration des Plantes'
    default: return type
  }
}

export default function SensorDetailDialog({ capteur, open, onClose }: Props) {
  if (!capteur) return null

  const analysis = getSensorAnalysis(capteur)
  const StatusIcon = analysis.statusIcon

  return (
    <Dialog open={open} onOpenChange={onClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-3">
            <div className="p-2 bg-primary/10 rounded-lg text-primary">
              {getTypeIcon(capteur.type)}
            </div>
            <div>
              <div className="text-lg">{capteur.nom}</div>
              <div className="text-sm font-normal text-gray-500">
                {getTypeLabel(capteur.type)} · {capteur.parcelleNom}
              </div>
            </div>
          </DialogTitle>
        </DialogHeader>

        <div className="space-y-4 mt-2">
          {/* Status Banner */}
          <div className={`p-4 rounded-lg border ${analysis.statusBg}`}>
            <div className="flex items-center gap-3">
              <StatusIcon className={`h-6 w-6 ${analysis.statusColor}`} />
              <div>
                <p className={`font-semibold ${analysis.statusColor}`}>{analysis.statusLabel}</p>
                <p className="text-sm text-gray-700 mt-1">{analysis.interpretation}</p>
              </div>
            </div>
          </div>

          {/* Measurement Details */}
          {analysis.details.length > 0 && (
            <Card>
              <CardContent className="p-4">
                <h3 className="font-semibold text-gray-900 flex items-center gap-2 mb-3">
                  <TrendingUp className="h-4 w-4 text-blue-600" />
                  Détails de la mesure
                </h3>
                <div className="grid grid-cols-2 gap-3">
                  {analysis.details.map((detail, i) => (
                    <div key={i} className="bg-gray-50 rounded-lg p-3">
                      <p className="text-xs text-gray-500">{detail.label}</p>
                      <p className="text-sm font-semibold text-gray-900">{detail.value}</p>
                    </div>
                  ))}
                </div>
                {capteur.derniereMesure?.date && (
                  <p className="text-xs text-gray-400 mt-3">
                    Dernière mise à jour : {new Date(capteur.derniereMesure.date).toLocaleString('fr-FR')}
                  </p>
                )}
              </CardContent>
            </Card>
          )}

          {/* Recommendations */}
          <Card>
            <CardContent className="p-4">
              <h3 className="font-semibold text-gray-900 flex items-center gap-2 mb-3">
                <Lightbulb className="h-4 w-4 text-yellow-600" />
                Conseils & Recommandations
              </h3>
              <div className="space-y-2">
                {analysis.recommendations.map((rec, i) => (
                  <div key={i} className="flex items-start gap-2 p-2 rounded-lg hover:bg-gray-50">
                    <span className="text-sm text-gray-700">{rec}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Sensor Health */}
          <Card>
            <CardContent className="p-4">
              <h3 className="font-semibold text-gray-900 flex items-center gap-2 mb-3">
                <ShieldCheck className="h-4 w-4 text-green-600" />
                État du capteur
              </h3>
              <div className="grid grid-cols-3 gap-3">
                <div className="text-center p-2 bg-gray-50 rounded-lg">
                  <p className="text-xs text-gray-500">Statut</p>
                  <Badge className={
                    capteur.statut?.toLowerCase() === 'actif' ? 'bg-green-100 text-green-800' :
                    capteur.statut?.toLowerCase() === 'erreur' ? 'bg-red-100 text-red-800' :
                    'bg-gray-100 text-gray-800'
                  }>
                    {capteur.statut}
                  </Badge>
                </div>
                <div className="text-center p-2 bg-gray-50 rounded-lg">
                  <p className="text-xs text-gray-500">Batterie</p>
                  <p className={`text-lg font-bold ${
                    capteur.batterie > 50 ? 'text-green-600' :
                    capteur.batterie > 20 ? 'text-orange-500' : 'text-red-500'
                  }`}>
                    {capteur.batterie}%
                  </p>
                </div>
                <div className="text-center p-2 bg-gray-50 rounded-lg">
                  <p className="text-xs text-gray-500">Signal</p>
                  <p className={`text-lg font-bold ${
                    capteur.signal > 70 ? 'text-green-600' :
                    capteur.signal > 40 ? 'text-orange-500' : 'text-red-500'
                  }`}>
                    {capteur.signal}%
                  </p>
                </div>
              </div>
              {capteur.batterie < 20 && (
                <div className="mt-3 p-2 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
                  ⚠️ Batterie faible ! Rechargez ou remplacez la batterie du capteur bientôt.
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </DialogContent>
    </Dialog>
  )
}

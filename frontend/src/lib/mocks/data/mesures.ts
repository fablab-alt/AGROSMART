import type { Mesure } from '@/lib/store'
import { mockCapteurs } from './capteurs'
import { hoursAgo, sineSeries, range } from '../helpers'

// Génère 7 jours de mesures (1 mesure / 4h = 42 points par capteur)
const POINTS    = 42
const HOURS_STEP = 4

interface CapteurProfile {
  base: number
  amplitude: number
  unite: string
  noise: number
}

// Profils alignés sur les 6 types Prisma (en minuscules, convention frontend)
const PROFILES: Record<string, CapteurProfile> = {
  humidite_sol:                  { base: 60,   amplitude: 12,  unite: '%',        noise: 0.15 },
  humidite_temperature_ambiante: { base: 28,   amplitude: 5,   unite: '°C',       noise: 0.10 },
  uv:                            { base: 6,    amplitude: 4,   unite: 'UV index', noise: 0.20 },
  npk:                           { base: 180,  amplitude: 30,  unite: 'mg/kg',    noise: 0.20 },
  direction_vent:                { base: 180,  amplitude: 90,  unite: '°',        noise: 0.30 },
  transpiration_plante:          { base: 2.5,  amplitude: 1.5, unite: 'mm/h',     noise: 0.25 },
}

function generateForCapteur(c: typeof mockCapteurs[number]): Mesure[] {
  const normalizedType = c.type?.toLowerCase() || ''
  const profile = PROFILES[normalizedType]
  if (!profile) return []

  const series = sineSeries(POINTS, profile.base, profile.amplitude, profile.noise)
  return range(POINTS).map((i) => {
    const ts = hoursAgo((POINTS - 1 - i) * HOURS_STEP)
    return {
      id:           `${c.id}-m-${i}`,
      capteur_id:   c.id,
      capteur_type: normalizedType,
      valeur:       series[i],
      unite:        profile.unite,
      mesure_at:    ts,
      timestamp:    ts,
      createdAt:    ts,
      parcelle_id:  (c as { parcelle_id?: string }).parcelle_id,
      parcelle_nom: c.parcelle_nom,
      station_nom:  c.station_nom,
    }
  })
}

export const mockMesures: Mesure[] = mockCapteurs.flatMap(generateForCapteur)

export function getMesuresByCapteur(capteurId: string) {
  return mockMesures.filter((m) => m.capteur_id === capteurId)
}

export function getLatestMesures(limit = 50) {
  return [...mockMesures]
    .sort((a, b) => b.mesure_at.localeCompare(a.mesure_at))
    .slice(0, limit)
}

// Mesures groupées pour graphiques dashboard (humidité sol / température ambiante 7j)
export function getDashboardMesures() {
  const byType = (type: string) =>
    mockMesures.filter((m) => m.capteur_type === type).slice(-30)
  return {
    humidite:    byType('humidite_sol'),
    temperature: byType('humidite_temperature_ambiante'),
    npk:         byType('npk'),
  }
}

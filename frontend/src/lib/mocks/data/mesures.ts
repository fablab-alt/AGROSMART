import type { Mesure } from '@/lib/store'
import { mockCapteurs } from './capteurs'
import { hoursAgo, sineSeries, range } from '../helpers'

// Génère 7 jours de mesures (1 mesure / 4h = 42 points par capteur)
const POINTS = 42
const HOURS_STEP = 4

interface CapteurProfile {
  base: number
  amplitude: number
  unite: string
  noise: number
}

const PROFILES: Record<string, CapteurProfile> = {
  humidite: { base: 60, amplitude: 12, unite: '%', noise: 0.15 },
  temperature: { base: 28, amplitude: 5, unite: '°C', noise: 0.1 },
  ph: { base: 6.5, amplitude: 0.5, unite: 'pH', noise: 0.08 },
  npk: { base: 180, amplitude: 30, unite: 'mg/kg', noise: 0.2 },
  meteo: { base: 1013, amplitude: 8, unite: 'hPa', noise: 0.05 },
  camera: { base: 0, amplitude: 0, unite: '-', noise: 0 },
}

function generateForCapteur(c: typeof mockCapteurs[number]): Mesure[] {
  const profile = PROFILES[c.type] ?? PROFILES.humidite
  if (c.type === 'camera') return []
  const series = sineSeries(POINTS, profile.base, profile.amplitude, profile.noise)
  return range(POINTS).map((i) => {
    const ts = hoursAgo((POINTS - 1 - i) * HOURS_STEP)
    return {
      id: `${c.id}-m-${i}`,
      capteur_id: c.id,
      capteur_type: c.type,
      valeur: series[i],
      unite: profile.unite,
      mesure_at: ts,
      timestamp: ts,        // alias used by mesures page
      createdAt: ts,        // alias used by mesures page
      parcelle_id: (c as { parcelle_id?: string }).parcelle_id,
      parcelle_nom: c.parcelle_nom,
      station_nom: c.station_nom,
    }
  })
}

export const mockMesures: Mesure[] = mockCapteurs.flatMap(generateForCapteur)

export function getMesuresByCapteur(capteurId: string) {
  return mockMesures.filter((m) => m.capteur_id === capteurId)
}

export function getLatestMesures(limit = 50) {
  return [...mockMesures].sort((a, b) => b.mesure_at.localeCompare(a.mesure_at)).slice(0, limit)
}

// Mesures groupées pour graphiques dashboard (humidité/température/pH 7j)
export function getDashboardMesures() {
  const byType = (type: string) =>
    mockMesures.filter((m) => m.capteur_type === type).slice(-30)
  return {
    humidite: byType('humidite'),
    temperature: byType('temperature'),
    ph: byType('ph'),
  }
}

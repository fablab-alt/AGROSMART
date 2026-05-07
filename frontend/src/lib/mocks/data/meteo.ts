import { daysAhead, range } from '../helpers'

const CONDITIONS = ['ensoleille', 'partiellement_nuageux', 'nuageux', 'pluie_legere', 'orage']
const ICONS: Record<string, string> = {
  ensoleille: '☀️',
  partiellement_nuageux: '⛅',
  nuageux: '☁️',
  pluie_legere: '🌦️',
  orage: '⛈️',
}

export const mockMeteoActuelle = {
  temperature: 28.5,
  ressentie: 31.2,
  humidite: 72,
  pression: 1013,
  vent_vitesse: 12,
  vent_direction: 'SO',
  uv_index: 7,
  visibilite: 10,
  condition: 'partiellement_nuageux',
  icone: ICONS.partiellement_nuageux,
  description: 'Partiellement nuageux',
  lever_soleil: '06:12',
  coucher_soleil: '18:34',
  ville: 'Abidjan',
  region: 'Lagunes',
  observe_at: new Date().toISOString(),
}

export const mockMeteoPrevisions = range(7).map((i) => {
  const cond = CONDITIONS[i % CONDITIONS.length]
  return {
    date: daysAhead(i),
    temperature_min: Math.round(22 + Math.random() * 3),
    temperature_max: Math.round(29 + Math.random() * 5),
    humidite_moy: Math.round(65 + Math.random() * 20),
    precipitation_mm: cond === 'pluie_legere' ? 8 + Math.random() * 5 : cond === 'orage' ? 25 + Math.random() * 15 : 0,
    vent_vitesse: Math.round(8 + Math.random() * 12),
    condition: cond,
    icone: ICONS[cond],
    description: cond.replace('_', ' '),
  }
})

export const mockMeteoHistorique = range(30).map((i) => ({
  date: daysAhead(-30 + i),
  temperature_moy: Math.round(26 + Math.sin(i / 5) * 4),
  precipitation_mm: Math.random() < 0.3 ? Math.round(Math.random() * 20) : 0,
  humidite_moy: Math.round(65 + Math.random() * 20),
}))

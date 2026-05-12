import type { Capteur } from '@/lib/store'
import { mockParcelles } from './parcelles'
import { hoursAgo } from '../helpers'

interface ExtendedCapteur extends Capteur {
  parcelle_id?: string
  batterie?: number
  signal?: number
  derniere_mesure?: string
  derniere_valeur?: number
  seuil_min?: number
  seuil_max?: number
}

// Types utilisés : minuscules = convention frontend (correspond aux enums Prisma en minuscules)
// API réelle retourne MAJUSCULES (ex: HUMIDITE_SOL) → normalisé en minuscules dans la page

const baseCapteurs: ExtendedCapteur[] = [
  // Parcelle 001 — Cacao Bingerville
  { id: 'cap-001', station_id: 'st-001', code: 'HUM-SOL-01',  type: 'humidite_sol',                   modele: 'SoilWatch X1',  fabricant: 'AgriTech',  unite_mesure: '%',        status: 'ACTIF',       station_nom: 'Station Sud',       parcelle_nom: 'Parcelle Bingerville Nord',    parcelle_id: 'parc-001', batterie: 87, signal: 92, derniere_mesure: hoursAgo(0.5),  derniere_valeur: 64,   seuil_min: 40,  seuil_max: 80  },
  { id: 'cap-002', station_id: 'st-001', code: 'HTA-AMB-01',  type: 'humidite_temperature_ambiante',  modele: 'ThermoSense',   fabricant: 'AgriTech',  unite_mesure: '°C / %',   status: 'ACTIF',       station_nom: 'Station Sud',       parcelle_nom: 'Parcelle Bingerville Nord',    parcelle_id: 'parc-001', batterie: 91, signal: 95, derniere_mesure: hoursAgo(0.5),  derniere_valeur: 27.4, seuil_min: 18,  seuil_max: 35  },
  { id: 'cap-003', station_id: 'st-002', code: 'NPK-01',      type: 'npk',                            modele: 'NPK-Pro',       fabricant: 'SoilLab',   unite_mesure: 'mg/kg',    status: 'ACTIF',       station_nom: 'Station Nord',      parcelle_nom: 'Parcelle Bingerville Nord',    parcelle_id: 'parc-001', batterie: 73, signal: 80, derniere_mesure: hoursAgo(2),    derniere_valeur: 145,  seuil_min: 100, seuil_max: 250 },

  // Parcelle 002 — Maïs Korhogo
  { id: 'cap-004', station_id: 'st-003', code: 'HUM-SOL-02',  type: 'humidite_sol',                   modele: 'SoilWatch X1',  fabricant: 'AgriTech',  unite_mesure: '%',        status: 'ACTIF',       station_nom: 'Station Centre',    parcelle_nom: 'Champ de Maïs - Korhogo',     parcelle_id: 'parc-002', batterie: 65, signal: 70, derniere_mesure: hoursAgo(1),    derniere_valeur: 35,   seuil_min: 40,  seuil_max: 75  },
  { id: 'cap-005', station_id: 'st-003', code: 'HTA-AMB-02',  type: 'humidite_temperature_ambiante',  modele: 'ThermoSense',   fabricant: 'AgriTech',  unite_mesure: '°C / %',   status: 'ACTIF',       station_nom: 'Station Centre',    parcelle_nom: 'Champ de Maïs - Korhogo',     parcelle_id: 'parc-002', batterie: 68, signal: 72, derniere_mesure: hoursAgo(1),    derniere_valeur: 33.2, seuil_min: 18,  seuil_max: 35  },
  { id: 'cap-006', station_id: 'st-004', code: 'UV-01',       type: 'uv',                             modele: 'UVSense Pro',   fabricant: 'SolarTech', unite_mesure: 'UV index', status: 'ACTIF',       station_nom: 'Station Est',       parcelle_nom: 'Champ de Maïs - Korhogo',     parcelle_id: 'parc-002', batterie: 80, signal: 88, derniere_mesure: hoursAgo(3),    derniere_valeur: 7,    seuil_min: 0,   seuil_max: 11  },
  { id: 'cap-007', station_id: 'st-005', code: 'VENT-01',     type: 'direction_vent',                 modele: 'WindSensor A2', fabricant: 'MeteoCI',   unite_mesure: '° / km/h', status: 'MAINTENANCE', station_nom: 'Station Ouest',     parcelle_nom: 'Champ de Maïs - Korhogo',     parcelle_id: 'parc-002', batterie: 42, signal: 0,  derniere_mesure: hoursAgo(48) },

  // Parcelle 003 — Bananeraie Daloa (CRITIQUE)
  { id: 'cap-008', station_id: 'st-006', code: 'HUM-SOL-03',  type: 'humidite_sol',                   modele: 'SoilWatch X1',  fabricant: 'AgriTech',  unite_mesure: '%',        status: 'ACTIF',       station_nom: 'Station Bananiers', parcelle_nom: 'Bananeraie Daloa',             parcelle_id: 'parc-003', batterie: 22, signal: 65, derniere_mesure: hoursAgo(0.25), derniere_valeur: 28,   seuil_min: 50,  seuil_max: 85  },
  { id: 'cap-009', station_id: 'st-006', code: 'HTA-AMB-03',  type: 'humidite_temperature_ambiante',  modele: 'ThermoSense',   fabricant: 'AgriTech',  unite_mesure: '°C / %',   status: 'ACTIF',       station_nom: 'Station Bananiers', parcelle_nom: 'Bananeraie Daloa',             parcelle_id: 'parc-003', batterie: 23, signal: 68, derniere_mesure: hoursAgo(0.25), derniere_valeur: 36.1, seuil_min: 18,  seuil_max: 33  },

  // Parcelle 004 — Hévéa San-Pédro
  { id: 'cap-010', station_id: 'st-007', code: 'HUM-SOL-04',  type: 'humidite_sol',                   modele: 'SoilWatch X1',  fabricant: 'AgriTech',  unite_mesure: '%',        status: 'ACTIF',       station_nom: 'Station A',         parcelle_nom: 'Hévéa San-Pédro',             parcelle_id: 'parc-004', batterie: 95, signal: 98, derniere_mesure: hoursAgo(0.1),  derniere_valeur: 72,   seuil_min: 45,  seuil_max: 85  },
  { id: 'cap-011', station_id: 'st-008', code: 'NPK-02',      type: 'npk',                            modele: 'NPK-Pro',       fabricant: 'SoilLab',   unite_mesure: 'mg/kg',    status: 'ACTIF',       station_nom: 'Station B',         parcelle_nom: 'Hévéa San-Pédro',             parcelle_id: 'parc-004', batterie: 88, signal: 91, derniere_mesure: hoursAgo(4),    derniere_valeur: 210,  seuil_min: 150, seuil_max: 300 },

  // Parcelle 005 — Maraîchage Yamoussoukro
  { id: 'cap-012', station_id: 'st-009', code: 'TRANSP-01',   type: 'transpiration_plante',           modele: 'LeafSense T1',  fabricant: 'BioSens',   unite_mesure: 'mm/h',     status: 'ACTIF',       station_nom: 'Station Centrale',  parcelle_nom: 'Maraîchage Yamoussoukro',     parcelle_id: 'parc-005', batterie: 76, signal: 85, derniere_mesure: hoursAgo(0.75), derniere_valeur: 1.8,  seuil_min: 0.5, seuil_max: 5   },
]

export const mockCapteurs = baseCapteurs

export const mockStations = mockParcelles.flatMap((p) => {
  const stations = mockCapteurs
    .filter((c) => c.parcelle_id === p.id)
    .map((c) => ({ id: c.station_id, nom: c.station_nom ?? 'Station', parcelle_id: p.id, parcelle_nom: p.nom, status: 'ACTIVE' }))
  return Array.from(new Map(stations.map((s) => [s.id, s])).values())
})

export function getCapteurById(id: string) {
  return mockCapteurs.find((c) => c.id === id) ?? null
}

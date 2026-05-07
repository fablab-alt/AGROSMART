import type { Parcelle } from '@/lib/store'
import { daysAgo } from '../helpers'

// 5 parcelles de démo avec des situations variées (santé, type sol, cultures)
export const mockParcelles: (Parcelle & {
  culture_actuelle?: string
  sante?: 'OPTIMAL' | 'SURVEILLANCE' | 'CRITIQUE'
  region?: string
  rendement_moyen?: number
})[] = [
  {
    id: 'parc-001',
    nom: 'Parcelle Bingerville Nord',
    latitude: 5.355,
    longitude: -3.879,
    superficie_hectares: 2.5,
    type_sol: 'Argilo-limoneux',
    description: 'Parcelle principale de cacao en pleine production.',
    status: 'EN_CROISSANCE',
    created_at: daysAgo(420),
    nb_stations: 2,
    nb_plantations: 1,
    culture_actuelle: 'Cacao',
    sante: 'OPTIMAL',
    region: 'Lagunes',
    rendement_moyen: 1.2,
  },
  {
    id: 'parc-002',
    nom: 'Champ de Maïs - Korhogo',
    latitude: 9.458,
    longitude: -5.629,
    superficie_hectares: 4.0,
    type_sol: 'Sablonneux',
    description: 'Rotation maïs/arachide. Sol récemment amendé.',
    status: 'ENSEMENCEE',
    created_at: daysAgo(280),
    nb_stations: 3,
    nb_plantations: 2,
    culture_actuelle: 'Maïs',
    sante: 'SURVEILLANCE',
    region: 'Savanes',
    rendement_moyen: 2.8,
  },
  {
    id: 'parc-003',
    nom: 'Bananeraie Daloa',
    latitude: 6.872,
    longitude: -6.451,
    superficie_hectares: 1.8,
    type_sol: 'Limoneux',
    description: 'Bananiers plantain — irrigation goutte à goutte.',
    status: 'EN_CROISSANCE',
    created_at: daysAgo(620),
    nb_stations: 2,
    nb_plantations: 1,
    culture_actuelle: 'Banane plantain',
    sante: 'CRITIQUE',
    region: 'Haut-Sassandra',
    rendement_moyen: 8.5,
  },
  {
    id: 'parc-004',
    nom: 'Hévéa San-Pédro',
    latitude: 4.748,
    longitude: -6.638,
    superficie_hectares: 6.2,
    type_sol: 'Argileux',
    description: 'Plantation d’hévéa en exploitation depuis 2018.',
    status: 'ACTIVE',
    created_at: daysAgo(2200),
    nb_stations: 4,
    nb_plantations: 1,
    culture_actuelle: 'Hévéa',
    sante: 'OPTIMAL',
    region: 'San-Pédro',
    rendement_moyen: 1.6,
  },
  {
    id: 'parc-005',
    nom: 'Maraîchage Yamoussoukro',
    latitude: 6.827,
    longitude: -5.289,
    superficie_hectares: 0.8,
    type_sol: 'Limoneux',
    description: 'Tomates, piments, gombos — production maraîchère.',
    status: 'PREPAREE',
    created_at: daysAgo(60),
    nb_stations: 1,
    nb_plantations: 3,
    culture_actuelle: 'Tomate',
    sante: 'OPTIMAL',
    region: 'Lacs',
    rendement_moyen: 25,
  },
]

export function getParcelleById(id: string) {
  return mockParcelles.find((p) => p.id === id) ?? null
}

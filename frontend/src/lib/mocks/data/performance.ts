import { daysAgo } from '../helpers'

export interface MockROI {
  parcelle_id: string
  parcelle_nom: string
  culture: string
  superficie_ha: number
  cout_total: number
  revenu_total: number
  roi_pct: number
  benefice_net: number
  periode: string
}

export interface MockRendement {
  parcelle_id: string
  parcelle_nom: string
  culture: string
  annee: number
  saison: string
  rendement_kg_ha: number
  superficie_ha: number
  production_totale_kg: number
  objectif_kg_ha: number
  taux_realisation_pct: number
}

export interface MockComparaisonSaisonniere {
  culture: string
  saison_actuelle: { label: string; valeur: number; cout: number }
  saison_precedente: { label: string; valeur: number; cout: number }
  evolution_pct: number
}

export const mockROI: MockROI[] = [
  {
    parcelle_id: 'parc-001',
    parcelle_nom: 'Parcelle Bingerville Nord',
    culture: 'Cacao',
    superficie_ha: 2.5,
    cout_total: 1_250_000,
    revenu_total: 2_750_000,
    roi_pct: 120,
    benefice_net: 1_500_000,
    periode: '2024-2025',
  },
  {
    parcelle_id: 'parc-002',
    parcelle_nom: 'Champ de Maïs - Korhogo',
    culture: 'Maïs',
    superficie_ha: 1.8,
    cout_total: 540_000,
    revenu_total: 900_000,
    roi_pct: 67,
    benefice_net: 360_000,
    periode: '2024-2025',
  },
  {
    parcelle_id: 'parc-003',
    parcelle_nom: 'Bananeraie Daloa',
    culture: 'Banane',
    superficie_ha: 1.0,
    cout_total: 820_000,
    revenu_total: 1_050_000,
    roi_pct: 28,
    benefice_net: 230_000,
    periode: '2024-2025',
  },
  {
    parcelle_id: 'parc-004',
    parcelle_nom: 'Hévéa San-Pédro',
    culture: 'Hévéa',
    superficie_ha: 5.0,
    cout_total: 950_000,
    revenu_total: 2_400_000,
    roi_pct: 152,
    benefice_net: 1_450_000,
    periode: '2024-2025',
  },
  {
    parcelle_id: 'parc-005',
    parcelle_nom: 'Maraîchage Yamoussoukro',
    culture: 'Tomate',
    superficie_ha: 0.5,
    cout_total: 380_000,
    revenu_total: 720_000,
    roi_pct: 89,
    benefice_net: 340_000,
    periode: '2024-2025',
  },
]

export const mockRendements: MockRendement[] = [
  { parcelle_id: 'parc-001', parcelle_nom: 'Parcelle Bingerville Nord', culture: 'Cacao', annee: 2025, saison: 'Principal', rendement_kg_ha: 1200, superficie_ha: 2.5, production_totale_kg: 3000, objectif_kg_ha: 1100, taux_realisation_pct: 109 },
  { parcelle_id: 'parc-001', parcelle_nom: 'Parcelle Bingerville Nord', culture: 'Cacao', annee: 2024, saison: 'Principal', rendement_kg_ha: 980, superficie_ha: 2.5, production_totale_kg: 2450, objectif_kg_ha: 1100, taux_realisation_pct: 89 },
  { parcelle_id: 'parc-002', parcelle_nom: 'Champ de Maïs - Korhogo', culture: 'Maïs', annee: 2025, saison: 'Saison A', rendement_kg_ha: 3200, superficie_ha: 1.8, production_totale_kg: 5760, objectif_kg_ha: 3500, taux_realisation_pct: 91 },
  { parcelle_id: 'parc-002', parcelle_nom: 'Champ de Maïs - Korhogo', culture: 'Maïs', annee: 2024, saison: 'Saison A', rendement_kg_ha: 2800, superficie_ha: 1.8, production_totale_kg: 5040, objectif_kg_ha: 3000, taux_realisation_pct: 93 },
  { parcelle_id: 'parc-003', parcelle_nom: 'Bananeraie Daloa', culture: 'Banane', annee: 2025, saison: 'Continue', rendement_kg_ha: 18000, superficie_ha: 1.0, production_totale_kg: 18000, objectif_kg_ha: 20000, taux_realisation_pct: 90 },
  { parcelle_id: 'parc-004', parcelle_nom: 'Hévéa San-Pédro', culture: 'Hévéa (latex)', annee: 2025, saison: 'Saignage', rendement_kg_ha: 1800, superficie_ha: 5.0, production_totale_kg: 9000, objectif_kg_ha: 1700, taux_realisation_pct: 106 },
  { parcelle_id: 'parc-005', parcelle_nom: 'Maraîchage Yamoussoukro', culture: 'Tomate', annee: 2025, saison: 'Saison sèche', rendement_kg_ha: 28000, superficie_ha: 0.5, production_totale_kg: 14000, objectif_kg_ha: 25000, taux_realisation_pct: 112 },
]

export const mockComparaisonSaisonniere: MockComparaisonSaisonniere[] = [
  { culture: 'Cacao', saison_actuelle: { label: '2024-2025', valeur: 3000, cout: 1_250_000 }, saison_precedente: { label: '2023-2024', valeur: 2450, cout: 1_100_000 }, evolution_pct: 22.4 },
  { culture: 'Maïs', saison_actuelle: { label: 'Saison A 2025', valeur: 5760, cout: 540_000 }, saison_precedente: { label: 'Saison A 2024', valeur: 5040, cout: 490_000 }, evolution_pct: 14.3 },
  { culture: 'Banane', saison_actuelle: { label: '2025', valeur: 18000, cout: 820_000 }, saison_precedente: { label: '2024', valeur: 15000, cout: 780_000 }, evolution_pct: 20.0 },
  { culture: 'Hévéa', saison_actuelle: { label: '2025', valeur: 9000, cout: 950_000 }, saison_precedente: { label: '2024', valeur: 8200, cout: 900_000 }, evolution_pct: 9.8 },
]

// Évolution mensuelle des revenus (12 mois)
export const mockRevenusParMois = [
  { mois: 'Juin 24', revenu: 850_000, cout: 420_000 },
  { mois: 'Juil 24', revenu: 720_000, cout: 380_000 },
  { mois: 'Août 24', revenu: 910_000, cout: 450_000 },
  { mois: 'Sep 24', revenu: 1_050_000, cout: 490_000 },
  { mois: 'Oct 24', revenu: 1_320_000, cout: 510_000 },
  { mois: 'Nov 24', revenu: 1_180_000, cout: 480_000 },
  { mois: 'Déc 24', revenu: 980_000, cout: 430_000 },
  { mois: 'Jan 25', revenu: 750_000, cout: 360_000 },
  { mois: 'Fév 25', revenu: 820_000, cout: 390_000 },
  { mois: 'Mar 25', revenu: 1_100_000, cout: 460_000 },
  { mois: 'Avr 25', revenu: 1_250_000, cout: 500_000 },
  { mois: 'Mai 25', revenu: 1_450_000, cout: 520_000 },
]

export const mockPerformanceStats = {
  roi_moyen_pct: Math.round(mockROI.reduce((s, r) => s + r.roi_pct, 0) / mockROI.length),
  benefice_total: mockROI.reduce((s, r) => s + r.benefice_net, 0),
  revenu_total: mockROI.reduce((s, r) => s + r.revenu_total, 0),
  cout_total: mockROI.reduce((s, r) => s + r.cout_total, 0),
  meilleure_culture: 'Hévéa',
  date_calcul: daysAgo(0),
}

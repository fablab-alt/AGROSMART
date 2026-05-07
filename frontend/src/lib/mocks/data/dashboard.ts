import { mockParcelles } from './parcelles'
import { mockCapteurs } from './capteurs'
import { mockAlertes, getUnreadAlertesCount } from './alertes'
import { mockUnreadMessagesCount } from './messages'
import { mockUserGamification } from './communaute'
import { mockStockStats } from './stocks'
import { mockCalendrierStats, mockProchainesActivites } from './calendrier'
import { mockROI, mockRevenusParMois, mockPerformanceStats } from './performance'

const nbParcelles = mockParcelles.length
const superficieTotal = mockParcelles.reduce((s, p) => s + (p.superficie_hectares ?? 0), 0)
const alertesActives = getUnreadAlertesCount()
const capteurActifs = mockCapteurs.filter((c) => c.status === 'ACTIF').length

// ── Shape attendue par /dashboard/stats (dashboard/page.tsx) ─────────────────
// Le composant lit : d.parcelles.count, d.alertes, d.capteurs.total, d.superficie, etc.
export const mockDashboardStats = {
  // Objets imbriqués — correspondance exacte avec ce que le composant lit
  parcelles: {
    count: nbParcelles,
    total: nbParcelles,
    superficie_totale: superficieTotal,
    optimal: mockParcelles.filter((p) => p.sante === 'OPTIMAL').length,
    surveillance: mockParcelles.filter((p) => p.sante === 'SURVEILLANCE').length,
    critique: mockParcelles.filter((p) => p.sante === 'CRITIQUE').length,
  },
  capteurs: {
    total: mockCapteurs.length,
    actifs: capteurActifs,
    maintenance: mockCapteurs.filter((c) => c.status === 'MAINTENANCE').length,
  },
  // Champ plat attendu par "alertesActives: d.alertes"
  alertes: alertesActives,
  alertes_critiques: mockAlertes.filter((a) => a.niveau === 'critique' && !a.lu_at).length,
  messages_non_lus: mockUnreadMessagesCount,

  // Activités
  activites_a_faire: mockCalendrierStats.total_a_faire,
  activites_en_cours: mockCalendrierStats.en_cours,
  prochaines_activites: mockProchainesActivites,

  // Stocks
  stocks_alertes: mockStockStats.alertes_seuil,
  stocks_valeur_totale: mockStockStats.valeur_totale,

  // Performance
  roi_moyen: mockPerformanceStats.roi_moyen_pct,
  revenu_total: mockPerformanceStats.revenu_total,
  benefice_net: mockPerformanceStats.benefice_total,

  // Gamification
  gamification: mockUserGamification,

  // Météo résumé
  meteo_resume: {
    temperature: 28,
    description: 'Partiellement nuageux',
    humidite: 75,
    icone: 'cloud-sun',
  },
}

// ── Shape attendue par /analytics/stats (performance/page.tsx) ───────────────
// Le composant lit :
//   data.roi.{coutTotal, revenuTotal, roiPourcentage, variation}
//   data.rendements_cultures[].{culture, rendement_actuel, rendement_objectif}
//   data.production_mensuelle[].{mois, production, objectif, saisonPrecedente}
//   data.comparaison_saisons[].{metric, saisonActuelle, saisonPrecedente, variation}
export const mockAnalyticsStats = {
  roi: {
    coutTotal: mockPerformanceStats.cout_total,
    revenuTotal: mockPerformanceStats.revenu_total,
    beneficeNet: mockPerformanceStats.benefice_total,
    roiPourcentage: mockPerformanceStats.roi_moyen_pct,
    variation: 14,  // +14% vs saison précédente
  },
  rendements_cultures: mockROI.map((r) => ({
    culture: r.culture,
    rendement_actuel: r.superficie_ha > 0 ? Math.round(r.revenu_total / r.superficie_ha / 1000) : 1.2,
    rendement_objectif: r.superficie_ha > 0 ? Math.round(r.revenu_total / r.superficie_ha / 900) : 1.4,
    superficie: r.superficie_ha,
    revenus: r.revenu_total,
  })),
  evolution_mensuelle: mockRevenusParMois,
  // production_mensuelle : lu par performance/page.tsx (ProductionTrend[])
  production_mensuelle: mockRevenusParMois.map((m) => ({
    mois: m.mois,
    production: Math.round(m.revenu / 1200),    // kg approximatif
    objectif: Math.round(m.revenu / 1100),
    saisonPrecedente: Math.round(m.revenu / 1350),
  })),
  // comparaison_saisons : lu par performance/page.tsx (SeasonComparison[])
  comparaison_saisons: [
    { metric: 'Rendement (t/ha)', saisonActuelle: 1.20, saisonPrecedente: 0.98, variation: 22.4 },
    { metric: 'Revenus (MXOF)',   saisonActuelle: 7.82, saisonPrecedente: 6.85, variation: 14.2 },
    { metric: 'Coûts (MXOF)',     saisonActuelle: 3.94, saisonPrecedente: 3.67, variation:  7.4 },
    { metric: 'ROI (%)',          saisonActuelle: mockPerformanceStats.roi_moyen_pct, saisonPrecedente: Math.round(mockPerformanceStats.roi_moyen_pct * 0.86), variation: 16.3 },
  ],
}

// ── Shape attendue par /dashboard/cultures ───────────────────────────────────
export const mockDashboardCultures = mockROI.map((r) => ({
  culture: r.culture,
  superficie: r.superficie_ha,
  revenu: r.revenu_total,
  roi: r.roi_pct,
  color: ['#16a34a', '#f59e0b', '#3b82f6', '#8b5cf6', '#ef4444'][mockROI.indexOf(r) % 5],
}))

// ── KPI cards ────────────────────────────────────────────────────────────────
export const mockKPICards = [
  { id: 'kpi-parcelles', titre: 'Parcelles actives', valeur: nbParcelles, unite: '', evolution_pct: 0, couleur: 'green', icone: 'map' },
  { id: 'kpi-rendement', titre: 'Rendement moyen', valeur: 1.2, unite: 't/ha', evolution_pct: 22, couleur: 'emerald', icone: 'trending-up' },
  { id: 'kpi-roi', titre: 'ROI moyen', valeur: mockPerformanceStats.roi_moyen_pct, unite: '%', evolution_pct: 12, couleur: 'blue', icone: 'bar-chart' },
  { id: 'kpi-alertes', titre: 'Alertes actives', valeur: alertesActives, unite: '', evolution_pct: -15, couleur: 'amber', icone: 'bell' },
]

export const mockRevenusEvolution = mockRevenusParMois

export const mockRepartitionCultures = mockROI.map((r) => ({
  culture: r.culture,
  superficie: r.superficie_ha,
  revenu: r.revenu_total,
  roi: r.roi_pct,
}))

import { daysAhead } from '../helpers'

export interface MockActivite {
  id: string
  titre: string
  description?: string
  type: 'SEMIS' | 'IRRIGATION' | 'FERTILISATION' | 'TRAITEMENT' | 'RECOLTE' | 'TAILLE' | 'AUTRE'
  date_prevue: string
  duree_estimee_h?: number
  statut: 'A_FAIRE' | 'EN_COURS' | 'TERMINEE' | 'ANNULEE'
  parcelle_id?: string
  parcelle_nom?: string
  priorite: 1 | 2 | 3
}

export const mockActivites: MockActivite[] = [
  { id: 'act-001', titre: 'Irrigation Bananeraie Daloa', type: 'IRRIGATION', date_prevue: daysAhead(0), duree_estimee_h: 4, statut: 'EN_COURS', parcelle_id: 'parc-003', parcelle_nom: 'Bananeraie Daloa', priorite: 1 },
  { id: 'act-002', titre: 'Apport NPK cacao', description: '250 kg/ha de NPK 12-24-12', type: 'FERTILISATION', date_prevue: daysAhead(2), duree_estimee_h: 6, statut: 'A_FAIRE', parcelle_id: 'parc-001', parcelle_nom: 'Parcelle Bingerville Nord', priorite: 2 },
  { id: 'act-003', titre: 'Traitement préventif maïs', type: 'TRAITEMENT', date_prevue: daysAhead(3), duree_estimee_h: 3, statut: 'A_FAIRE', parcelle_id: 'parc-002', parcelle_nom: 'Champ de Maïs - Korhogo', priorite: 2 },
  { id: 'act-004', titre: 'Semis tomate Yamoussoukro', type: 'SEMIS', date_prevue: daysAhead(5), duree_estimee_h: 8, statut: 'A_FAIRE', parcelle_id: 'parc-005', parcelle_nom: 'Maraîchage Yamoussoukro', priorite: 2 },
  { id: 'act-005', titre: 'Saignage hévéa rotation A', type: 'RECOLTE', date_prevue: daysAhead(7), duree_estimee_h: 5, statut: 'A_FAIRE', parcelle_id: 'parc-004', parcelle_nom: 'Hévéa San-Pédro', priorite: 3 },
  { id: 'act-006', titre: 'Désherbage manuel cacao', type: 'AUTRE', date_prevue: daysAhead(10), duree_estimee_h: 12, statut: 'A_FAIRE', parcelle_id: 'parc-001', parcelle_nom: 'Parcelle Bingerville Nord', priorite: 3 },
  { id: 'act-007', titre: 'Taille hévéas zone B', type: 'TAILLE', date_prevue: daysAhead(14), duree_estimee_h: 8, statut: 'A_FAIRE', parcelle_id: 'parc-004', parcelle_nom: 'Hévéa San-Pédro', priorite: 3 },
  { id: 'act-008', titre: 'Récolte cacao mensuelle', type: 'RECOLTE', date_prevue: daysAhead(20), duree_estimee_h: 16, statut: 'A_FAIRE', parcelle_id: 'parc-001', parcelle_nom: 'Parcelle Bingerville Nord', priorite: 2 },
  { id: 'act-009', titre: 'Récolte tomates lot 1', type: 'RECOLTE', date_prevue: daysAhead(28), duree_estimee_h: 6, statut: 'A_FAIRE', parcelle_id: 'parc-005', parcelle_nom: 'Maraîchage Yamoussoukro', priorite: 2 },
  { id: 'act-010', titre: 'Inventaire stocks mensuel', type: 'AUTRE', date_prevue: daysAhead(30), duree_estimee_h: 4, statut: 'A_FAIRE', priorite: 3 },
  { id: 'act-011', titre: 'Récolte maïs', type: 'RECOLTE', date_prevue: daysAhead(45), duree_estimee_h: 24, statut: 'A_FAIRE', parcelle_id: 'parc-002', parcelle_nom: 'Champ de Maïs - Korhogo', priorite: 1 },
  // Activités passées
  { id: 'act-012', titre: 'Irrigation cacao', type: 'IRRIGATION', date_prevue: daysAhead(-3), duree_estimee_h: 3, statut: 'TERMINEE', parcelle_id: 'parc-001', parcelle_nom: 'Parcelle Bingerville Nord', priorite: 2 },
  { id: 'act-013', titre: 'Application NPK maïs', type: 'FERTILISATION', date_prevue: daysAhead(-10), duree_estimee_h: 5, statut: 'TERMINEE', parcelle_id: 'parc-002', parcelle_nom: 'Champ de Maïs - Korhogo', priorite: 2 },
  { id: 'act-014', titre: 'Diagnostic mosaïque maïs', type: 'TRAITEMENT', date_prevue: daysAhead(-15), duree_estimee_h: 2, statut: 'TERMINEE', parcelle_id: 'parc-002', parcelle_nom: 'Champ de Maïs - Korhogo', priorite: 1 },
  { id: 'act-015', titre: 'Traitement fongicide bananiers', type: 'TRAITEMENT', date_prevue: daysAhead(-22), duree_estimee_h: 4, statut: 'TERMINEE', parcelle_id: 'parc-003', parcelle_nom: 'Bananeraie Daloa', priorite: 2 },
]

export const mockProchainesActivites = mockActivites
  .filter((a) => a.statut === 'A_FAIRE' || a.statut === 'EN_COURS')
  .sort((a, b) => a.date_prevue.localeCompare(b.date_prevue))
  .slice(0, 5)

export const mockCalendrierStats = {
  total_a_faire: mockActivites.filter((a) => a.statut === 'A_FAIRE').length,
  en_cours: mockActivites.filter((a) => a.statut === 'EN_COURS').length,
  terminees: mockActivites.filter((a) => a.statut === 'TERMINEE').length,
  en_retard: 0,
}

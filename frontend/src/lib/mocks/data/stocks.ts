import { daysAgo, daysAhead } from '../helpers'

export interface MockStock {
  id: string
  nom: string
  categorie: 'SEMENCES' | 'ENGRAIS' | 'PESTICIDES' | 'HERBICIDES' | 'OUTILS' | 'RECOLTES' | 'AUTRES'
  quantite: number
  unite: string
  seuil_alerte: number
  date_expiration?: string
  emplacement: string
  prix_unitaire?: number
  devise?: string
  derniere_mouvement_at: string
}

export const mockStocks: MockStock[] = [
  { id: 'stk-001', nom: 'NPK 15-15-15', categorie: 'ENGRAIS', quantite: 8, unite: 'sac 50kg', seuil_alerte: 10, date_expiration: daysAhead(540), emplacement: 'Hangar A', prix_unitaire: 22000, devise: 'XOF', derniere_mouvement_at: daysAgo(2) },
  { id: 'stk-002', nom: 'NPK 12-24-12', categorie: 'ENGRAIS', quantite: 25, unite: 'sac 50kg', seuil_alerte: 10, date_expiration: daysAhead(620), emplacement: 'Hangar A', prix_unitaire: 24500, devise: 'XOF', derniere_mouvement_at: daysAgo(7) },
  { id: 'stk-003', nom: 'Urée 46%', categorie: 'ENGRAIS', quantite: 15, unite: 'sac 50kg', seuil_alerte: 8, emplacement: 'Hangar A', prix_unitaire: 19500, devise: 'XOF', derniere_mouvement_at: daysAgo(12) },
  { id: 'stk-004', nom: 'Semences Maïs IRAT 81', categorie: 'SEMENCES', quantite: 80, unite: 'kg', seuil_alerte: 50, date_expiration: daysAhead(180), emplacement: 'Magasin', prix_unitaire: 4500, devise: 'XOF', derniere_mouvement_at: daysAgo(15) },
  { id: 'stk-005', nom: 'Semences Tomate Mongal', categorie: 'SEMENCES', quantite: 5, unite: 'sachet 10g', seuil_alerte: 10, date_expiration: daysAhead(90), emplacement: 'Magasin', prix_unitaire: 12000, devise: 'XOF', derniere_mouvement_at: daysAgo(30) },
  { id: 'stk-006', nom: 'Bacillus thuringiensis', categorie: 'PESTICIDES', quantite: 12, unite: 'litre', seuil_alerte: 5, date_expiration: daysAhead(420), emplacement: 'Local sécurisé', prix_unitaire: 8500, devise: 'XOF', derniere_mouvement_at: daysAgo(20) },
  { id: 'stk-007', nom: 'Mancozèbe 80%', categorie: 'PESTICIDES', quantite: 4, unite: 'kg', seuil_alerte: 5, date_expiration: daysAhead(210), emplacement: 'Local sécurisé', prix_unitaire: 14000, devise: 'XOF', derniere_mouvement_at: daysAgo(45) },
  { id: 'stk-008', nom: 'Glyphosate 36%', categorie: 'HERBICIDES', quantite: 18, unite: 'litre', seuil_alerte: 8, date_expiration: daysAhead(380), emplacement: 'Local sécurisé', prix_unitaire: 7500, devise: 'XOF', derniere_mouvement_at: daysAgo(8) },
  { id: 'stk-009', nom: 'Pulvérisateurs 16L', categorie: 'OUTILS', quantite: 6, unite: 'unité', seuil_alerte: 3, emplacement: 'Atelier', prix_unitaire: 35000, devise: 'XOF', derniere_mouvement_at: daysAgo(60) },
  { id: 'stk-010', nom: 'Houes', categorie: 'OUTILS', quantite: 22, unite: 'unité', seuil_alerte: 10, emplacement: 'Atelier', prix_unitaire: 4500, devise: 'XOF', derniere_mouvement_at: daysAgo(40) },
  { id: 'stk-011', nom: 'Sécateurs', categorie: 'OUTILS', quantite: 8, unite: 'unité', seuil_alerte: 4, emplacement: 'Atelier', prix_unitaire: 18500, devise: 'XOF', derniere_mouvement_at: daysAgo(90) },
  { id: 'stk-012', nom: 'Cacao fermenté (récolte)', categorie: 'RECOLTES', quantite: 850, unite: 'kg', seuil_alerte: 100, emplacement: 'Hangar de séchage', prix_unitaire: 1100, devise: 'XOF', derniere_mouvement_at: daysAgo(3) },
  { id: 'stk-013', nom: 'Maïs grain sec', categorie: 'RECOLTES', quantite: 1200, unite: 'kg', seuil_alerte: 200, emplacement: 'Silo', prix_unitaire: 250, devise: 'XOF', derniere_mouvement_at: daysAgo(10) },
  { id: 'stk-014', nom: 'Bâches 6×4m', categorie: 'AUTRES', quantite: 8, unite: 'unité', seuil_alerte: 4, emplacement: 'Hangar B', prix_unitaire: 12500, devise: 'XOF', derniere_mouvement_at: daysAgo(25) },
  { id: 'stk-015', nom: 'Sacs jute 50kg', categorie: 'AUTRES', quantite: 320, unite: 'unité', seuil_alerte: 100, emplacement: 'Hangar B', prix_unitaire: 850, devise: 'XOF', derniere_mouvement_at: daysAgo(5) },
]

export const mockStockMouvements = [
  { id: 'mvt-001', stock_id: 'stk-001', type: 'SORTIE', quantite: 4, motif: 'Application NPK parc-001', created_at: daysAgo(2) },
  { id: 'mvt-002', stock_id: 'stk-004', type: 'SORTIE', quantite: 20, motif: 'Semis maïs Korhogo', created_at: daysAgo(15) },
  { id: 'mvt-003', stock_id: 'stk-006', type: 'ENTREE', quantite: 6, motif: 'Achat coopérative', created_at: daysAgo(20) },
  { id: 'mvt-004', stock_id: 'stk-012', type: 'ENTREE', quantite: 220, motif: 'Récolte cacao', created_at: daysAgo(3) },
  { id: 'mvt-005', stock_id: 'stk-002', type: 'AJUSTEMENT', quantite: 1, motif: 'Inventaire mensuel', created_at: daysAgo(7) },
]

export const mockStockStats = {
  total_articles: mockStocks.length,
  valeur_totale: mockStocks.reduce((sum, s) => sum + (s.prix_unitaire ?? 0) * s.quantite, 0),
  alertes_seuil: mockStocks.filter((s) => s.quantite <= s.seuil_alerte).length,
  expiration_proche: mockStocks.filter((s) => {
    if (!s.date_expiration) return false
    const days = Math.floor((new Date(s.date_expiration).getTime() - Date.now()) / 86400000)
    return days < 90
  }).length,
}

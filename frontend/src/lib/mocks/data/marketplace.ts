import type { Produit } from '@/lib/store'
import { daysAgo } from '../helpers'

const VENDORS = [
  { id: 'v-001', nom: 'Coopérative Bingerville', telephone: '+225 07 11 22 33 44' },
  { id: 'v-002', nom: 'AgriSemences CI', telephone: '+225 05 22 33 44 55' },
  { id: 'v-003', nom: 'Ferme Yao Kouassi', telephone: '+225 01 33 44 55 66' },
  { id: 'v-004', nom: 'IvoireEngrais SA', telephone: '+225 07 44 55 66 77' },
  { id: 'v-005', nom: 'Daloa Fruits & Légumes', telephone: '+225 05 55 66 77 88' },
]

export const mockProduits: Produit[] = [
  // SEMENCES
  { id: 'prod-001', vendeur_id: 'v-002', nom: 'Semences Maïs IRAT 81', description: 'Variété adaptée à la zone savanicole, cycle 110 jours.', categorie: 'SEMENCES', prix: 4500, devise: 'XOF', unite: 'kg', quantite_disponible: 250, est_actif: true, vendeur_nom: 'AgriSemences CI', vendeur_telephone: VENDORS[1].telephone, images: [] },
  { id: 'prod-002', vendeur_id: 'v-002', nom: 'Semences Riz NERICA-1', description: 'Riz pluvial à haut rendement, cycle court.', categorie: 'SEMENCES', prix: 5200, devise: 'XOF', unite: 'kg', quantite_disponible: 180, est_actif: true, vendeur_nom: 'AgriSemences CI', vendeur_telephone: VENDORS[1].telephone, images: [] },
  { id: 'prod-003', vendeur_id: 'v-002', nom: 'Plants Cacao Mercedes', description: 'Plants greffés de cacao Mercedes, vigueur élevée.', categorie: 'SEMENCES', prix: 800, devise: 'XOF', unite: 'plant', quantite_disponible: 1500, est_actif: true, vendeur_nom: 'AgriSemences CI', vendeur_telephone: VENDORS[1].telephone, images: [] },
  { id: 'prod-004', vendeur_id: 'v-002', nom: 'Semences Tomate Mongal', description: 'Tomate hybride résistante aux maladies.', categorie: 'SEMENCES', prix: 12000, devise: 'XOF', unite: 'sachet 10g', quantite_disponible: 50, est_actif: true, vendeur_nom: 'AgriSemences CI', vendeur_telephone: VENDORS[1].telephone, images: [] },

  // ENGRAIS
  { id: 'prod-005', vendeur_id: 'v-004', nom: 'NPK 15-15-15', description: 'Engrais composé universel — sac de 50 kg.', categorie: 'ENGRAIS', prix: 22000, devise: 'XOF', unite: 'sac 50kg', quantite_disponible: 80, est_actif: true, vendeur_nom: 'IvoireEngrais SA', vendeur_telephone: VENDORS[3].telephone, images: [] },
  { id: 'prod-006', vendeur_id: 'v-004', nom: 'NPK 12-24-12 cacao', description: 'Spécifique cacao, riche en phosphore.', categorie: 'ENGRAIS', prix: 24500, devise: 'XOF', unite: 'sac 50kg', quantite_disponible: 60, est_actif: true, vendeur_nom: 'IvoireEngrais SA', vendeur_telephone: VENDORS[3].telephone, images: [] },
  { id: 'prod-007', vendeur_id: 'v-004', nom: 'Urée 46%', description: 'Engrais azoté pur — sac de 50 kg.', categorie: 'ENGRAIS', prix: 19500, devise: 'XOF', unite: 'sac 50kg', quantite_disponible: 120, est_actif: true, vendeur_nom: 'IvoireEngrais SA', vendeur_telephone: VENDORS[3].telephone, images: [] },
  { id: 'prod-008', vendeur_id: 'v-004', nom: 'Compost organique', description: 'Compost végétal certifié — sac de 25 kg.', categorie: 'ENGRAIS', prix: 6500, devise: 'XOF', unite: 'sac 25kg', quantite_disponible: 200, est_actif: true, vendeur_nom: 'IvoireEngrais SA', vendeur_telephone: VENDORS[3].telephone, images: [] },

  // PESTICIDES
  { id: 'prod-009', vendeur_id: 'v-001', nom: 'Bacillus thuringiensis', description: 'Insecticide biologique anti-chenilles.', categorie: 'PESTICIDES', prix: 8500, devise: 'XOF', unite: 'litre', quantite_disponible: 30, est_actif: true, vendeur_nom: 'Coopérative Bingerville', vendeur_telephone: VENDORS[0].telephone, images: [] },
  { id: 'prod-010', vendeur_id: 'v-001', nom: 'Mancozèbe 80%', description: 'Fongicide à large spectre.', categorie: 'PESTICIDES', prix: 14000, devise: 'XOF', unite: 'kg', quantite_disponible: 25, est_actif: true, vendeur_nom: 'Coopérative Bingerville', vendeur_telephone: VENDORS[0].telephone, images: [] },

  // OUTILS
  { id: 'prod-011', vendeur_id: 'v-001', nom: 'Pulvérisateur 16L', description: 'Pulvérisateur à dos manuel, marque Solo.', categorie: 'OUTILS', prix: 35000, devise: 'XOF', unite: 'unité', quantite_disponible: 12, est_actif: true, vendeur_nom: 'Coopérative Bingerville', vendeur_telephone: VENDORS[0].telephone, images: [] },
  { id: 'prod-012', vendeur_id: 'v-001', nom: 'Houe forgée', description: 'Houe locale forgée à la main.', categorie: 'OUTILS', prix: 4500, devise: 'XOF', unite: 'unité', quantite_disponible: 50, est_actif: true, vendeur_nom: 'Coopérative Bingerville', vendeur_telephone: VENDORS[0].telephone, images: [] },
  { id: 'prod-013', vendeur_id: 'v-001', nom: 'Sécateur professionnel', description: 'Sécateur Felco F-2 pour taille de précision.', categorie: 'OUTILS', prix: 18500, devise: 'XOF', unite: 'unité', quantite_disponible: 18, est_actif: true, vendeur_nom: 'Coopérative Bingerville', vendeur_telephone: VENDORS[0].telephone, images: [] },

  // RECOLTES
  { id: 'prod-014', vendeur_id: 'v-003', nom: 'Cacao fermenté', description: 'Cacao certifié UTZ, taux fermentation 85%.', categorie: 'RECOLTES', prix: 1100, devise: 'XOF', unite: 'kg', quantite_disponible: 800, est_actif: true, vendeur_nom: 'Ferme Yao Kouassi', vendeur_telephone: VENDORS[2].telephone, images: [] },
  { id: 'prod-015', vendeur_id: 'v-005', nom: 'Bananes plantain', description: 'Régime de bananes plantain, calibre moyen.', categorie: 'RECOLTES', prix: 3500, devise: 'XOF', unite: 'régime', quantite_disponible: 120, est_actif: true, vendeur_nom: 'Daloa Fruits & Légumes', vendeur_telephone: VENDORS[4].telephone, images: [] },
  { id: 'prod-016', vendeur_id: 'v-005', nom: 'Tomates fraîches', description: 'Tomates calibre 1, récoltées le matin.', categorie: 'RECOLTES', prix: 700, devise: 'XOF', unite: 'kg', quantite_disponible: 250, est_actif: true, vendeur_nom: 'Daloa Fruits & Légumes', vendeur_telephone: VENDORS[4].telephone, images: [] },
  { id: 'prod-017', vendeur_id: 'v-003', nom: 'Maïs grain sec', description: 'Maïs séché 14% humidité.', categorie: 'RECOLTES', prix: 250, devise: 'XOF', unite: 'kg', quantite_disponible: 1200, est_actif: true, vendeur_nom: 'Ferme Yao Kouassi', vendeur_telephone: VENDORS[2].telephone, images: [] },
  { id: 'prod-018', vendeur_id: 'v-003', nom: 'Manioc frais', description: 'Tubercules de manioc fraîchement déterrés.', categorie: 'RECOLTES', prix: 180, devise: 'XOF', unite: 'kg', quantite_disponible: 600, est_actif: true, vendeur_nom: 'Ferme Yao Kouassi', vendeur_telephone: VENDORS[2].telephone, images: [] },

  // AUTRES
  { id: 'prod-019', vendeur_id: 'v-001', nom: 'Bâche de séchage 6×4m', description: 'Bâche tissée pour séchage du cacao.', categorie: 'AUTRES', prix: 12500, devise: 'XOF', unite: 'unité', quantite_disponible: 20, est_actif: true, vendeur_nom: 'Coopérative Bingerville', vendeur_telephone: VENDORS[0].telephone, images: [] },
  { id: 'prod-020', vendeur_id: 'v-002', nom: 'Sac de jute 50 kg', description: 'Sac de jute neuf pour stockage.', categorie: 'AUTRES', prix: 850, devise: 'XOF', unite: 'unité', quantite_disponible: 500, est_actif: true, vendeur_nom: 'AgriSemences CI', vendeur_telephone: VENDORS[1].telephone, images: [] },
]

export const mockCommandes = [
  { id: 'cmd-001', produit_id: 'prod-005', produit_nom: 'NPK 15-15-15', quantite: 4, prix_total: 88000, devise: 'XOF', status: 'EN_COURS', vendeur_nom: 'IvoireEngrais SA', created_at: daysAgo(2) },
  { id: 'cmd-002', produit_id: 'prod-001', produit_nom: 'Semences Maïs IRAT 81', quantite: 50, prix_total: 225000, devise: 'XOF', status: 'LIVREE', vendeur_nom: 'AgriSemences CI', created_at: daysAgo(15) },
  { id: 'cmd-003', produit_id: 'prod-009', produit_nom: 'Bacillus thuringiensis', quantite: 5, prix_total: 42500, devise: 'XOF', status: 'CONFIRMEE', vendeur_nom: 'Coopérative Bingerville', created_at: daysAgo(5) },
]

export const mockFavoris = [
  { id: 'fav-001', produit_id: 'prod-006', produit_nom: 'NPK 12-24-12 cacao', prix: 24500, devise: 'XOF', vendeur_nom: 'IvoireEngrais SA', added_at: daysAgo(10) },
  { id: 'fav-002', produit_id: 'prod-013', produit_nom: 'Sécateur professionnel', prix: 18500, devise: 'XOF', vendeur_nom: 'Coopérative Bingerville', added_at: daysAgo(3) },
]

export const mockVendeurStats = {
  total_produits: 0,
  total_commandes: 0,
  total_revenus: 0,
  produits_actifs: 0,
  commandes_en_cours: 0,
}

export function getProduitById(id: string) {
  return mockProduits.find((p) => p.id === id) ?? null
}

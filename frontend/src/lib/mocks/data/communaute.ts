import { hoursAgo, daysAgo } from '../helpers'

export interface MockPost {
  id: string
  auteur_id: string
  auteur_nom: string
  auteur_avatar?: string
  auteur_role?: string
  auteur_badge?: string
  titre: string
  contenu: string
  categorie: string
  nb_reponses: number
  nb_likes: number
  vues: number
  created_at: string
  tags: string[]
}

export const mockPosts: MockPost[] = [
  { id: 'post-001', auteur_id: 'u-001', auteur_nom: 'Kouassi Yao', auteur_role: 'producteur', auteur_badge: 'Expert Cacao', titre: 'Quelle variété de cacao pour la zone de Daloa ?', contenu: 'Bonjour à tous, je prépare 3 ha de plantation à Daloa. Quelqu\'un a-t-il retour d\'expérience sur les variétés Mercedes vs hybrides locaux ?', categorie: 'Cacao', nb_reponses: 12, nb_likes: 28, vues: 245, created_at: hoursAgo(6), tags: ['cacao', 'variétés', 'plantation'] },
  { id: 'post-002', auteur_id: 'u-002', auteur_nom: 'Aminata Touré', auteur_role: 'agronome', auteur_badge: 'Conseillère certifiée', titre: 'Conseil : reconnaître la mosaïque africaine sur maïs', contenu: 'Avec les pluies, les attaques de mosaïque s\'intensifient. Voici les symptômes à surveiller et les premiers gestes à adopter.', categorie: 'Maladies', nb_reponses: 8, nb_likes: 45, vues: 320, created_at: daysAgo(1), tags: ['maïs', 'maladie', 'diagnostic'] },
  { id: 'post-003', auteur_id: 'u-003', auteur_nom: 'Moussa Diabaté', auteur_role: 'producteur', titre: 'Stock NPK épuisé à Korhogo, quelqu\'un a une piste ?', contenu: 'Tous les revendeurs sont en rupture. Je cherche du NPK 15-15-15 d\'urgence pour 2 ha de maïs.', categorie: 'Marketplace', nb_reponses: 15, nb_likes: 12, vues: 180, created_at: daysAgo(2), tags: ['NPK', 'rupture', 'achat'] },
  { id: 'post-004', auteur_id: 'u-004', auteur_nom: 'Fatima Koné', auteur_role: 'productrice', auteur_badge: 'Top vendeuse', titre: 'Retour d\'expérience : irrigation goutte à goutte sur tomate', contenu: 'Après 6 mois sur 0.5ha, voici les chiffres : économie d\'eau 40%, rendement +25%. Je partage le calcul ROI.', categorie: 'Irrigation', nb_reponses: 23, nb_likes: 87, vues: 612, created_at: daysAgo(3), tags: ['irrigation', 'tomate', 'ROI'] },
  { id: 'post-005', auteur_id: 'u-005', auteur_nom: 'Bassirou Sangaré', auteur_role: 'producteur', titre: 'Saignage hévéa : quel rythme adopter ?', contenu: 'Je passe de S/2 d3 à S/2 d4. Quelqu\'un a comparé les deux rotations sur 1 an ?', categorie: 'Hévéa', nb_reponses: 5, nb_likes: 8, vues: 95, created_at: daysAgo(4), tags: ['hévéa', 'saignage'] },
  { id: 'post-006', auteur_id: 'u-001', auteur_nom: 'Kouassi Yao', auteur_role: 'producteur', auteur_badge: 'Expert Cacao', titre: 'AgroSmart sauvé ma récolte de cacao !', contenu: 'L\'alerte stress hydrique m\'a permis d\'irriguer à temps. Les capteurs valent leur prix.', categorie: 'Témoignages', nb_reponses: 18, nb_likes: 102, vues: 890, created_at: daysAgo(7), tags: ['témoignage', 'cacao', 'capteurs'] },
  { id: 'post-007', auteur_id: 'u-006', auteur_nom: 'Aïssata Bamba', auteur_role: 'productrice', titre: 'Lutte bio contre la cercosporiose ?', contenu: 'Je veux éviter le mancozèbe sur mes bananiers. Des alternatives bio à recommander ?', categorie: 'Bio', nb_reponses: 11, nb_likes: 34, vues: 230, created_at: daysAgo(8), tags: ['bananier', 'bio', 'maladie'] },
  { id: 'post-008', auteur_id: 'u-002', auteur_nom: 'Aminata Touré', auteur_role: 'agronome', auteur_badge: 'Conseillère certifiée', titre: 'Webinaire gratuit : préparer la saison sèche', contenu: 'Rendez-vous samedi 18h pour un live sur la gestion de l\'eau en saison sèche.', categorie: 'Annonces', nb_reponses: 4, nb_likes: 67, vues: 410, created_at: daysAgo(10), tags: ['webinaire', 'saison sèche'] },
  { id: 'post-009', auteur_id: 'u-007', auteur_nom: 'Issa Diallo', auteur_role: 'producteur', titre: 'Commande NPK groupée — qui veut participer ?', contenu: 'Pour avoir un meilleur prix, je propose une commande groupée à la coopérative. Min. 100 sacs.', categorie: 'Coopération', nb_reponses: 16, nb_likes: 41, vues: 295, created_at: daysAgo(12), tags: ['coopération', 'achat groupé'] },
  { id: 'post-010', auteur_id: 'u-008', auteur_nom: 'Mariam Cissé', auteur_role: 'productrice', titre: 'Tomate Mongal vs F1 Cobra : votre avis ?', contenu: 'J\'hésite entre les deux pour ma prochaine saison. Quelles différences réelles en pratique ?', categorie: 'Maraîchage', nb_reponses: 9, nb_likes: 19, vues: 145, created_at: daysAgo(15), tags: ['tomate', 'variétés'] },
]

export const mockLeaderboard = [
  { rank: 1, user_id: 'u-001', nom: 'Kouassi Yao', points: 2450, niveau: 5, badges: ['Expert Cacao', 'Pionnier'], parcelles: 4 },
  { rank: 2, user_id: 'u-004', nom: 'Fatima Koné', points: 2100, niveau: 5, badges: ['Top vendeuse', 'Optimisatrice'], parcelles: 3 },
  { rank: 3, user_id: 'u-002', nom: 'Aminata Touré', points: 1820, niveau: 4, badges: ['Conseillère certifiée'], parcelles: 0 },
  { rank: 4, user_id: 'u-007', nom: 'Issa Diallo', points: 1650, niveau: 4, badges: ['Coopératif'], parcelles: 5 },
  { rank: 5, user_id: 'u-006', nom: 'Aïssata Bamba', points: 1320, niveau: 3, badges: ['Bio'], parcelles: 2 },
]

export const mockUserGamification = {
  points: 850,
  niveau: 2,
  niveau_nom: 'Apprenti Smart',
  progression_niveau: 65,
  badges: ['Premier capteur', 'Première récolte mockée'],
  realisations: 4,
  rang: 14,
}

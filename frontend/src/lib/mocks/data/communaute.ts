import { hoursAgo, daysAgo } from '../helpers'

export interface MockReponse {
  id: string
  post_id: string
  contenu: string
  auteur_id: string
  auteur_nom: string
  auteur_prenom?: string
  estSolution: boolean
  upvotes: number
  createdAt: string
}

export interface MockPost {
  id: string
  auteur_id: string
  auteur_nom: string
  auteur_prenom?: string
  auteur_avatar?: string
  auteur_role?: string
  auteur_badge?: string
  auteur_niveau?: number
  auteur_badges?: string[]
  titre: string
  contenu: string
  categorie: string
  nb_reponses: number       // legacy alias
  reponses_count: number    // utilisé par la page liste
  nb_likes: number          // legacy alias
  likes: number             // utilisé par la page liste
  vues: number
  resolu: boolean
  created_at: string
  updated_at: string
  tags: string[]
}

const baseAuteurs: Record<string, { nom: string; prenoms: string; niveau: number; badges: string[] }> = {
  'u-001': { nom: 'Yao', prenoms: 'Kouassi', niveau: 5, badges: ['Expert Cacao', 'Pionnier'] },
  'u-002': { nom: 'Touré', prenoms: 'Aminata', niveau: 4, badges: ['Conseillère certifiée'] },
  'u-003': { nom: 'Diabaté', prenoms: 'Moussa', niveau: 2, badges: [] },
  'u-004': { nom: 'Koné', prenoms: 'Fatima', niveau: 5, badges: ['Top vendeuse', 'Optimisatrice'] },
  'u-005': { nom: 'Sangaré', prenoms: 'Bassirou', niveau: 3, badges: [] },
  'u-006': { nom: 'Bamba', prenoms: 'Aïssata', niveau: 3, badges: ['Bio'] },
  'u-007': { nom: 'Diallo', prenoms: 'Issa', niveau: 4, badges: ['Coopératif'] },
  'u-008': { nom: 'Cissé', prenoms: 'Mariam', niveau: 2, badges: [] },
  'visitor-demo': { nom: 'Démo', prenoms: 'Visiteur', niveau: 1, badges: [] },
}

function buildPost(
  id: string, auteurId: string, role: string, titre: string, contenu: string,
  categorie: string, reponses: number, likes: number, vues: number,
  created: string, tags: string[], resolu = false, badge?: string,
): MockPost {
  const a = baseAuteurs[auteurId]
  return {
    id,
    auteur_id: auteurId,
    auteur_nom: `${a.prenoms} ${a.nom}`,
    auteur_prenom: a.prenoms,
    auteur_role: role,
    auteur_badge: badge,
    auteur_niveau: a.niveau,
    auteur_badges: a.badges,
    titre,
    contenu,
    categorie,
    nb_reponses: reponses,
    reponses_count: reponses,
    nb_likes: likes,
    likes,
    vues,
    resolu,
    created_at: created,
    updated_at: created,
    tags,
  }
}

export const mockPosts: MockPost[] = [
  buildPost('post-001', 'u-001', 'producteur', 'Quelle variété de cacao pour la zone de Daloa ?',
    'Bonjour à tous, je prépare 3 ha de plantation à Daloa. Quelqu\'un a-t-il retour d\'expérience sur les variétés Mercedes vs hybrides locaux ?\n\nMa parcelle est en bas-fonds avec un sol argileux, drainage moyen. J\'hésite entre :\n• Mercedes (cycle plus long, mais rendement)\n• Hybrides locaux (résistance maladies)\n\nMerci d\'avance pour vos retours.',
    'Cacao', 12, 28, 245, hoursAgo(6), ['cacao', 'variétés', 'plantation'], false, 'Expert Cacao'),
  buildPost('post-002', 'u-002', 'agronome', 'Conseil : reconnaître la mosaïque africaine sur maïs',
    'Avec les pluies, les attaques de mosaïque s\'intensifient. Voici les symptômes à surveiller :\n\n1. Taches jaunes en mosaïque sur les feuilles\n2. Décoloration progressive\n3. Nanisme des plants\n\nPremiers gestes : isoler les plants atteints, traiter au bouillie bordelaise.',
    'Maladies', 8, 45, 320, daysAgo(1), ['maïs', 'maladie', 'diagnostic'], true, 'Conseillère certifiée'),
  buildPost('post-003', 'u-003', 'producteur', 'Stock NPK épuisé à Korhogo, quelqu\'un a une piste ?',
    'Tous les revendeurs sont en rupture. Je cherche du NPK 15-15-15 d\'urgence pour 2 ha de maïs. Si quelqu\'un a un contact à Korhogo ou Bouaké, je suis preneur.',
    'Marketplace', 15, 12, 180, daysAgo(2), ['NPK', 'rupture', 'achat']),
  buildPost('post-004', 'u-004', 'productrice', 'Retour d\'expérience : irrigation goutte à goutte sur tomate',
    'Après 6 mois sur 0.5ha, voici les chiffres :\n\n• Économie d\'eau : 40%\n• Rendement : +25%\n• ROI sur 18 mois\n\nJe partage le détail des coûts et l\'installation en MP si ça intéresse.',
    'Irrigation', 23, 87, 612, daysAgo(3), ['irrigation', 'tomate', 'ROI'], true, 'Top vendeuse'),
  buildPost('post-005', 'u-005', 'producteur', 'Saignage hévéa : quel rythme adopter ?',
    'Je passe de S/2 d3 à S/2 d4. Quelqu\'un a comparé les deux rotations sur 1 an ? Le panneau s\'use moins vite mais est-ce que la production tient ?',
    'Hévéa', 5, 8, 95, daysAgo(4), ['hévéa', 'saignage']),
  buildPost('post-006', 'u-001', 'producteur', 'AgroSmart a sauvé ma récolte de cacao !',
    'L\'alerte stress hydrique m\'a permis d\'irriguer à temps. Les capteurs valent leur prix. Récolte 2025 : +18% vs 2024.',
    'Témoignages', 18, 102, 890, daysAgo(7), ['témoignage', 'cacao', 'capteurs'], false, 'Expert Cacao'),
  buildPost('post-007', 'u-006', 'productrice', 'Lutte bio contre la cercosporiose ?',
    'Je veux éviter le mancozèbe sur mes bananiers. Des alternatives bio à recommander ? J\'ai entendu parler de la décoction d\'ail mais je doute de l\'efficacité sur 0.8 ha.',
    'Bio', 11, 34, 230, daysAgo(8), ['bananier', 'bio', 'maladie']),
  buildPost('post-008', 'u-002', 'agronome', 'Webinaire gratuit : préparer la saison sèche',
    'Rendez-vous samedi 18h pour un live sur la gestion de l\'eau en saison sèche. Inscription via le bouton ci-dessous, places limitées à 200.',
    'Annonces', 4, 67, 410, daysAgo(10), ['webinaire', 'saison sèche'], false, 'Conseillère certifiée'),
  buildPost('post-009', 'u-007', 'producteur', 'Commande NPK groupée — qui veut participer ?',
    'Pour avoir un meilleur prix, je propose une commande groupée à la coopérative. Min. 100 sacs. Tarif négocié à 19 500 XOF/sac (vs 22 000 au détail).',
    'Coopération', 16, 41, 295, daysAgo(12), ['coopération', 'achat groupé']),
  buildPost('post-010', 'u-008', 'productrice', 'Tomate Mongal vs F1 Cobra : votre avis ?',
    'J\'hésite entre les deux pour ma prochaine saison. Quelles différences réelles en pratique ? Surtout sur résistance aux nématodes.',
    'Maraîchage', 9, 19, 145, daysAgo(15), ['tomate', 'variétés']),
]

// ── Réponses par post (forum complet) ─────────────────────────────────────────
export const mockReponses: Record<string, MockReponse[]> = {
  'post-001': [
    { id: 'rep-001-1', post_id: 'post-001', contenu: 'Salut ! Sur Daloa, j\'ai planté Mercedes en 2022 sur sol similaire. Bon rendement (1.4 t/ha en 3e année) mais sensible à la pourriture brune si humide. Tu auras besoin de drainage.',
      auteur_id: 'u-004', auteur_nom: 'Fatima Koné', auteur_prenom: 'Fatima', estSolution: false, upvotes: 14, createdAt: hoursAgo(5) },
    { id: 'rep-001-2', post_id: 'post-001', contenu: 'Mercedes greffé sur porte-greffe résistant = top combo pour Daloa. Compte 18-24 mois avant les premières cabosses. Hybrides locaux moins productifs mais plus rustiques.',
      auteur_id: 'u-002', auteur_nom: 'Aminata Touré', auteur_prenom: 'Aminata', estSolution: true, upvotes: 32, createdAt: hoursAgo(4) },
    { id: 'rep-001-3', post_id: 'post-001', contenu: 'Je confirme pour Mercedes greffé. Mon voisin à Issia a fait pareil en 2020, il dépasse 1.6 t/ha aujourd\'hui.',
      auteur_id: 'u-007', auteur_nom: 'Issa Diallo', auteur_prenom: 'Issa', estSolution: false, upvotes: 8, createdAt: hoursAgo(3) },
  ],
  'post-002': [
    { id: 'rep-002-1', post_id: 'post-002', contenu: 'Merci pour le post Aminata. Tu as une photo des feuilles atteintes ? Je veux comparer avec ce que je vois sur ma parcelle.',
      auteur_id: 'u-003', auteur_nom: 'Moussa Diabaté', auteur_prenom: 'Moussa', estSolution: false, upvotes: 5, createdAt: hoursAgo(20) },
    { id: 'rep-002-2', post_id: 'post-002', contenu: 'Dans la rubrique fiches pratiques d\'AgroSmart il y a un guide visuel détaillé avec photos. Très utile pour différencier de la carence en azote.',
      auteur_id: 'u-001', auteur_nom: 'Kouassi Yao', auteur_prenom: 'Kouassi', estSolution: true, upvotes: 18, createdAt: hoursAgo(18) },
  ],
  'post-003': [
    { id: 'rep-003-1', post_id: 'post-003', contenu: 'IvoireEngrais SA a livré chez moi à Bouaké hier. Tente leur magasin avenue Houphouët, ils dépannent souvent.',
      auteur_id: 'u-001', auteur_nom: 'Kouassi Yao', auteur_prenom: 'Kouassi', estSolution: false, upvotes: 11, createdAt: daysAgo(1) },
    { id: 'rep-003-2', post_id: 'post-003', contenu: 'Sur la marketplace AgroSmart il en reste 80 sacs chez IvoireEngrais. Lien direct dans la catégorie ENGRAIS.',
      auteur_id: 'u-007', auteur_nom: 'Issa Diallo', auteur_prenom: 'Issa', estSolution: false, upvotes: 9, createdAt: daysAgo(1) },
  ],
  'post-004': [
    { id: 'rep-004-1', post_id: 'post-004', contenu: 'Top retour. Tu peux partager le coût d\'installation par hectare ? Je voudrais simuler pour 2 ha.',
      auteur_id: 'u-008', auteur_nom: 'Mariam Cissé', auteur_prenom: 'Mariam', estSolution: false, upvotes: 6, createdAt: daysAgo(2) },
    { id: 'rep-004-2', post_id: 'post-004', contenu: 'Pour 0.5 ha j\'étais à 380 000 XOF tout compris (kit Netafim + filtration + pose). Amorti en 14 mois grâce aux gains.',
      auteur_id: 'u-004', auteur_nom: 'Fatima Koné', auteur_prenom: 'Fatima', estSolution: true, upvotes: 24, createdAt: daysAgo(2) },
  ],
  'post-006': [
    { id: 'rep-006-1', post_id: 'post-006', contenu: 'Félicitations Kouassi ! Tu as combien de capteurs au final ?',
      auteur_id: 'u-005', auteur_nom: 'Bassirou Sangaré', auteur_prenom: 'Bassirou', estSolution: false, upvotes: 3, createdAt: daysAgo(6) },
    { id: 'rep-006-2', post_id: 'post-006', contenu: '3 stations × 4 capteurs (humidité sol, température ambiante, NPK, UV). Total ~ 350 000 XOF, déjà rentabilisé.',
      auteur_id: 'u-001', auteur_nom: 'Kouassi Yao', auteur_prenom: 'Kouassi', estSolution: false, upvotes: 15, createdAt: daysAgo(6) },
  ],
}

export function getPostDetailMock(id: string) {
  const post = mockPosts.find((p) => p.id === id)
  if (!post) return null
  return {
    ...post,
    auteur: { nom: post.auteur_nom.split(' ').slice(-1)[0], prenoms: post.auteur_prenom },
    reponses: mockReponses[id] ?? [],
    createdAt: post.created_at,  // alias attendu par la page detail
  }
}

export const mockLeaderboard = [
  { rank: 1, id: 'u-001', user_id: 'u-001', nom: 'Kouassi Yao', score: 2450, points: 2450, niveau: 5, badges: ['Expert Cacao', 'Pionnier'], parcelles: 4 },
  { rank: 2, id: 'u-004', user_id: 'u-004', nom: 'Fatima Koné', score: 2100, points: 2100, niveau: 5, badges: ['Top vendeuse', 'Optimisatrice'], parcelles: 3 },
  { rank: 3, id: 'u-002', user_id: 'u-002', nom: 'Aminata Touré', score: 1820, points: 1820, niveau: 4, badges: ['Conseillère certifiée'], parcelles: 0 },
  { rank: 4, id: 'u-007', user_id: 'u-007', nom: 'Issa Diallo', score: 1650, points: 1650, niveau: 4, badges: ['Coopératif'], parcelles: 5 },
  { rank: 5, id: 'u-006', user_id: 'u-006', nom: 'Aïssata Bamba', score: 1320, points: 1320, niveau: 3, badges: ['Bio'], parcelles: 2 },
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

export interface MockFiche {
  id: string
  titre: string
  description: string
  categorie: string
  contenu: string
  duree_lecture_min: number
  difficulte: 'debutant' | 'intermediaire' | 'avance'
  tags: string[]
  vues: number
  publie_le: string
}

export const mockFichesPratiques: MockFiche[] = [
  { id: 'fp-001', titre: 'Préparer un sol avant semis', description: 'Étapes essentielles pour un labour réussi.', categorie: 'Sols', contenu: 'Le labour doit être effectué 2 à 3 semaines avant le semis. Profondeur recommandée : 20-25 cm. Apporter du compost (2-3 tonnes/ha) lors du dernier passage.', duree_lecture_min: 5, difficulte: 'debutant', tags: ['sol', 'labour', 'semis'], vues: 1240, publie_le: '2025-01-15' },
  { id: 'fp-002', titre: 'Calendrier de fertilisation du cacao', description: 'Quand et comment fertiliser efficacement.', categorie: 'Cacao', contenu: 'Apport principal en début de saison des pluies (mars-avril) avec NPK 12-24-12. Second apport en septembre. Doses : 250-300 kg/ha.', duree_lecture_min: 7, difficulte: 'intermediaire', tags: ['cacao', 'fertilisation', 'NPK'], vues: 890, publie_le: '2025-02-08' },
  { id: 'fp-003', titre: 'Lutte biologique contre la pyrale', description: 'Méthodes naturelles efficaces.', categorie: 'Maïs', contenu: 'Utiliser Bacillus thuringiensis (Bt) à raison de 1 L/ha. Traiter au coucher du soleil. Répéter tous les 7 jours en cas de forte pression.', duree_lecture_min: 6, difficulte: 'intermediaire', tags: ['maïs', 'pyrale', 'biologique'], vues: 654, publie_le: '2025-03-12' },
  { id: 'fp-004', titre: 'Irrigation goutte à goutte : installation', description: 'Guide pas à pas pour installer un système économique.', categorie: 'Irrigation', contenu: 'Matériel requis : tuyaux PE 16mm, goutteurs autorégulants 2L/h, filtre, vanne. Espacement goutteurs : 30-40 cm. Pression : 1.0-1.5 bar.', duree_lecture_min: 12, difficulte: 'avance', tags: ['irrigation', 'goutte-à-goutte', 'installation'], vues: 1520, publie_le: '2025-01-28' },
  { id: 'fp-005', titre: 'Reconnaître la cercosporiose du bananier', description: 'Symptômes, prévention et traitement.', categorie: 'Bananier', contenu: 'Taches brunes sur les feuilles évoluant en plages nécrotiques. Prévention : drainage, espacement adéquat. Traitement : fongicide à base de mancozèbe.', duree_lecture_min: 8, difficulte: 'intermediaire', tags: ['bananier', 'maladie', 'fongicide'], vues: 740, publie_le: '2025-02-22' },
  { id: 'fp-006', titre: 'Conserver ses semences pour la prochaine saison', description: 'Techniques traditionnelles et modernes.', categorie: 'Semences', contenu: 'Sécher les semences à 13% d\'humidité. Stocker dans des contenants hermétiques au frais (15-18°C). Ajouter de la cendre ou du sel comme répulsif.', duree_lecture_min: 5, difficulte: 'debutant', tags: ['semences', 'conservation', 'stockage'], vues: 1100, publie_le: '2025-03-05' },
  { id: 'fp-007', titre: 'Créer un compost à la ferme', description: 'Recette et entretien d\'un tas de compost.', categorie: 'Bio', contenu: 'Alterner couches vertes (déchets végétaux frais) et brunes (paille, feuilles sèches). Arroser modérément. Retourner toutes les 3 semaines. Compost prêt en 3-4 mois.', duree_lecture_min: 6, difficulte: 'debutant', tags: ['compost', 'organique', 'bio'], vues: 1850, publie_le: '2025-01-20' },
  { id: 'fp-008', titre: 'Le saignage de l\'hévéa : techniques avancées', description: 'Optimiser le rendement de latex.', categorie: 'Hévéa', contenu: 'Saignée en 1/2 spirale descendante (S/2 d3). Utiliser un stimulant (Ethrel 2.5%) toutes les 4-6 saignées. Repos pendant la défoliation.', duree_lecture_min: 10, difficulte: 'avance', tags: ['hévéa', 'saignage', 'latex'], vues: 420, publie_le: '2025-02-15' },
  { id: 'fp-009', titre: 'Calculer ses besoins en eau', description: 'Méthode simple basée sur l\'ETP.', categorie: 'Irrigation', contenu: 'Besoin en eau (mm/jour) = ETP × Kc culture. Cacao : Kc = 0.7-1.0 selon stade. Banane : Kc = 1.0-1.2. Tomate : Kc = 0.6-1.15.', duree_lecture_min: 9, difficulte: 'avance', tags: ['eau', 'irrigation', 'calcul'], vues: 580, publie_le: '2025-03-18' },
  { id: 'fp-010', titre: 'Gestion intégrée des nuisibles', description: 'Approche durable contre les ravageurs.', categorie: 'Protection', contenu: '1. Surveillance régulière. 2. Seuils d\'intervention. 3. Méthodes biologiques en priorité. 4. Chimique en dernier recours et ciblé.', duree_lecture_min: 7, difficulte: 'intermediaire', tags: ['nuisibles', 'IPM', 'durable'], vues: 690, publie_le: '2025-02-28' },
]

export const mockFichesCategories = Array.from(new Set(mockFichesPratiques.map((f) => f.categorie)))

import type { Formation } from '@/lib/store'

export const mockFormations: Formation[] = [
  { id: 'form-001', titre: 'Initiation à l\'agriculture intelligente', description: 'Découvrez les bases de l\'agriculture connectée et l\'usage des capteurs IoT.', categorie: 'Bases', type: 'video', url: 'https://www.youtube.com/embed/dQw4w9WgXcQ', duree_minutes: 12, langue: 'fr', progression: 100, complete: true },
  { id: 'form-002', titre: 'Calendrier cultural du cacao', description: 'Toutes les étapes mois par mois : taille, traitement, récolte.', categorie: 'Cacao', type: 'pdf', url: '#', duree_minutes: 20, langue: 'fr', progression: 60, complete: false },
  { id: 'form-003', titre: 'Lutte intégrée contre la pyrale du maïs', description: 'Méthodes biologiques et chimiques pour protéger vos cultures.', categorie: 'Maïs', type: 'article', url: '#', duree_minutes: 8, langue: 'fr', progression: 40, complete: false },
  { id: 'form-004', titre: 'Optimiser l\'irrigation goutte à goutte', description: 'Calcul des besoins en eau et programmation efficace.', categorie: 'Irrigation', type: 'video', url: 'https://www.youtube.com/embed/dQw4w9WgXcQ', duree_minutes: 18, langue: 'fr', progression: 0, complete: false },
  { id: 'form-005', titre: 'Fertilisation raisonnée du sol', description: 'Lire une analyse de sol et adapter les apports d\'engrais.', categorie: 'Sols', type: 'pdf', url: '#', duree_minutes: 25, langue: 'fr', progression: 0, complete: false },
  { id: 'form-006', titre: 'Maladies courantes du bananier plantain', description: 'Reconnaître la cercosporiose, la maladie de Panama et la mosaïque.', categorie: 'Bananier', type: 'article', url: '#', duree_minutes: 10, langue: 'fr', progression: 100, complete: true },
  { id: 'form-007', titre: 'Saignage de l\'hévéa : techniques modernes', description: 'Méthodes pour optimiser le rendement de latex.', categorie: 'Hévéa', type: 'video', url: 'https://www.youtube.com/embed/dQw4w9WgXcQ', duree_minutes: 22, langue: 'fr', progression: 0, complete: false },
  { id: 'form-008', titre: 'Maraîchage en saison sèche', description: 'Cultiver tomates, piments et gombos en période sèche.', categorie: 'Maraîchage', type: 'video', url: 'https://www.youtube.com/embed/dQw4w9WgXcQ', duree_minutes: 15, langue: 'fr', progression: 25, complete: false },
  { id: 'form-009', titre: 'Compostage et matières organiques', description: 'Fabriquer son compost à la ferme.', categorie: 'Bio', type: 'article', url: '#', duree_minutes: 6, langue: 'fr', progression: 0, complete: false },
  { id: 'form-010', titre: 'Comprendre l\'analyse de sol NPK', description: 'Lecture et interprétation des analyses agronomiques.', categorie: 'Sols', type: 'pdf', url: '#', duree_minutes: 14, langue: 'fr', progression: 0, complete: false },
  { id: 'form-011', titre: 'Marketing agricole : vendre mieux', description: 'Stratégies pour valoriser vos récoltes via la marketplace.', categorie: 'Commerce', type: 'video', url: 'https://www.youtube.com/embed/dQw4w9WgXcQ', duree_minutes: 16, langue: 'fr', progression: 0, complete: false },
  { id: 'form-012', titre: 'Gestion d\'une coopérative agricole', description: 'Bonnes pratiques de gouvernance et financement.', categorie: 'Coopératives', type: 'pdf', url: '#', duree_minutes: 30, langue: 'fr', progression: 0, complete: false },
]

export function getFormationById(id: string) {
  return mockFormations.find((f) => f.id === id) ?? null
}

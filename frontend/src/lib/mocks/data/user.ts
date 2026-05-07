import type { User } from '@/lib/store'

// Utilisateur visiteur injecté en mode démo
export const VISITOR_USER: User = {
  id: 'visitor-demo',
  nom: 'Visiteur',
  prenom: 'Démo',
  telephone: '+225 00 00 00 00',
  role: 'producteur',
  status: 'ACTIF',
  langue_preferee: 'fr',
}

export const VISITOR_TOKEN = 'visitor-demo-token'

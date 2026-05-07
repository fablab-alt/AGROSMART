import { hoursAgo, daysAgo } from '../helpers'

export interface MockMessage {
  id: string
  conversation_id: string
  expediteur_id: string
  expediteur_nom: string
  destinataire_id: string
  contenu: string
  lu: boolean
  created_at: string
}

export interface MockConversation {
  id: string
  participant_id: string
  participant_nom: string
  participant_role?: string
  participant_avatar?: string
  dernier_message?: string
  dernier_message_at?: string
  non_lus: number
}

export const mockConversations: MockConversation[] = [
  {
    id: 'conv-001',
    participant_id: 'v-004',
    participant_nom: 'IvoireEngrais SA',
    participant_role: 'fournisseur',
    dernier_message: 'Votre commande de NPK est prête à être livrée demain matin.',
    dernier_message_at: hoursAgo(2),
    non_lus: 1,
  },
  {
    id: 'conv-002',
    participant_id: 'u-002',
    participant_nom: 'Aminata Touré',
    participant_role: 'agronome',
    dernier_message: 'Je passe demain inspecter la parcelle de cacao.',
    dernier_message_at: hoursAgo(5),
    non_lus: 0,
  },
  {
    id: 'conv-003',
    participant_id: 'v-002',
    participant_nom: 'AgriSemences CI',
    participant_role: 'fournisseur',
    dernier_message: 'Les plants de cacao Mercedes sont disponibles sous 7j.',
    dernier_message_at: daysAgo(2),
    non_lus: 0,
  },
  {
    id: 'conv-004',
    participant_id: 'u-001',
    participant_nom: 'Kouassi Yao',
    participant_role: 'producteur',
    dernier_message: 'Merci pour ton retour sur les hybrides !',
    dernier_message_at: daysAgo(4),
    non_lus: 0,
  },
]

export const mockMessages: Record<string, MockMessage[]> = {
  'conv-001': [
    { id: 'msg-001', conversation_id: 'conv-001', expediteur_id: 'visitor-demo', expediteur_nom: 'Visiteur Démo', destinataire_id: 'v-004', contenu: 'Bonjour, je voudrais commander 4 sacs de NPK 15-15-15.', lu: true, created_at: daysAgo(2) },
    { id: 'msg-002', conversation_id: 'conv-001', expediteur_id: 'v-004', expediteur_nom: 'IvoireEngrais SA', destinataire_id: 'visitor-demo', contenu: 'Bonjour, c\'est noté. Total 88 000 XOF, livraison sous 48h. Confirmez-vous ?', lu: true, created_at: daysAgo(2) },
    { id: 'msg-003', conversation_id: 'conv-001', expediteur_id: 'visitor-demo', expediteur_nom: 'Visiteur Démo', destinataire_id: 'v-004', contenu: 'Confirmé, livraison à Bingerville.', lu: true, created_at: daysAgo(1) },
    { id: 'msg-004', conversation_id: 'conv-001', expediteur_id: 'v-004', expediteur_nom: 'IvoireEngrais SA', destinataire_id: 'visitor-demo', contenu: 'Votre commande de NPK est prête à être livrée demain matin.', lu: false, created_at: hoursAgo(2) },
  ],
  'conv-002': [
    { id: 'msg-101', conversation_id: 'conv-002', expediteur_id: 'u-002', expediteur_nom: 'Aminata Touré', destinataire_id: 'visitor-demo', contenu: 'Bonjour, je suis disponible pour visiter votre parcelle.', lu: true, created_at: daysAgo(1) },
    { id: 'msg-102', conversation_id: 'conv-002', expediteur_id: 'visitor-demo', expediteur_nom: 'Visiteur Démo', destinataire_id: 'u-002', contenu: 'Avec plaisir. Demain 10h vous convient ?', lu: true, created_at: hoursAgo(20) },
    { id: 'msg-103', conversation_id: 'conv-002', expediteur_id: 'u-002', expediteur_nom: 'Aminata Touré', destinataire_id: 'visitor-demo', contenu: 'Je passe demain inspecter la parcelle de cacao.', lu: true, created_at: hoursAgo(5) },
  ],
  'conv-003': [
    { id: 'msg-201', conversation_id: 'conv-003', expediteur_id: 'visitor-demo', expediteur_nom: 'Visiteur Démo', destinataire_id: 'v-002', contenu: 'Avez-vous des plants de cacao Mercedes ?', lu: true, created_at: daysAgo(3) },
    { id: 'msg-202', conversation_id: 'conv-003', expediteur_id: 'v-002', expediteur_nom: 'AgriSemences CI', destinataire_id: 'visitor-demo', contenu: 'Les plants de cacao Mercedes sont disponibles sous 7j.', lu: true, created_at: daysAgo(2) },
  ],
  'conv-004': [
    { id: 'msg-301', conversation_id: 'conv-004', expediteur_id: 'u-001', expediteur_nom: 'Kouassi Yao', destinataire_id: 'visitor-demo', contenu: 'Salut, tu utilises quels hybrides actuellement ?', lu: true, created_at: daysAgo(5) },
    { id: 'msg-302', conversation_id: 'conv-004', expediteur_id: 'visitor-demo', expediteur_nom: 'Visiteur Démo', destinataire_id: 'u-001', contenu: 'Mercedes principalement, et un peu de Forastero.', lu: true, created_at: daysAgo(4) },
    { id: 'msg-303', conversation_id: 'conv-004', expediteur_id: 'u-001', expediteur_nom: 'Kouassi Yao', destinataire_id: 'visitor-demo', contenu: 'Merci pour ton retour sur les hybrides !', lu: true, created_at: daysAgo(4) },
  ],
}

export const mockUnreadMessagesCount = mockConversations.reduce((sum, c) => sum + c.non_lus, 0)

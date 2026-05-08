/**
 * Données mockées pour le système d'amitié (mode visiteur).
 * Le visiteur a déjà des amis (pour démontrer la feature),
 * des demandes en attente, et reçoit aussi des suggestions.
 */
import { hoursAgo, daysAgo } from '../helpers'

export interface MockFriend {
  friendshipId: string
  id: string
  nom: string
  prenoms: string
  telephone: string
  role: string
  niveau: number
  points: number
  amisDepuis: string
  region?: { nom: string }
}

export interface MockFriendRequest {
  id: string
  from?: { id: string; nom: string; prenoms: string; role: string; niveau: number }
  to?: { id: string; nom: string; prenoms: string; role: string; niveau: number }
  sentAt: string
}

// Amis confirmés du visiteur
export const mockFriends: MockFriend[] = [
  {
    friendshipId: 'fs-001',
    id: 'u-001',
    nom: 'Yao',
    prenoms: 'Kouassi',
    telephone: '+225 07 11 22 33 44',
    role: 'producteur',
    niveau: 5,
    points: 2450,
    amisDepuis: daysAgo(45),
    region: { nom: 'Lagunes' },
  },
  {
    friendshipId: 'fs-002',
    id: 'u-002',
    nom: 'Touré',
    prenoms: 'Aminata',
    telephone: '+225 07 22 33 44 55',
    role: 'agronome',
    niveau: 4,
    points: 1820,
    amisDepuis: daysAgo(30),
    region: { nom: 'Vallée du Bandama' },
  },
  {
    friendshipId: 'fs-003',
    id: 'u-007',
    nom: 'Diallo',
    prenoms: 'Issa',
    telephone: '+225 07 33 44 55 66',
    role: 'producteur',
    niveau: 4,
    points: 1650,
    amisDepuis: daysAgo(15),
    region: { nom: 'Savanes' },
  },
  {
    friendshipId: 'fs-004',
    id: 'u-004',
    nom: 'Koné',
    prenoms: 'Fatima',
    telephone: '+225 05 44 55 66 77',
    role: 'productrice',
    niveau: 5,
    points: 2100,
    amisDepuis: daysAgo(8),
    region: { nom: 'Lacs' },
  },
]

// Demandes reçues (en attente d'acceptation par le visiteur)
export const mockReceivedRequests: MockFriendRequest[] = [
  {
    id: 'fs-req-001',
    from: { id: 'u-005', nom: 'Sangaré', prenoms: 'Bassirou', role: 'producteur', niveau: 3 },
    sentAt: hoursAgo(8),
  },
  {
    id: 'fs-req-002',
    from: { id: 'u-006', nom: 'Bamba', prenoms: 'Aïssata', role: 'productrice', niveau: 3 },
    sentAt: daysAgo(2),
  },
]

// Demandes envoyées (par le visiteur, en attente de réponse)
export const mockSentRequests: MockFriendRequest[] = [
  {
    id: 'fs-req-003',
    to: { id: 'u-008', nom: 'Cissé', prenoms: 'Mariam', role: 'productrice', niveau: 2 },
    sentAt: daysAgo(1),
  },
]

// Suggestions (utilisateurs à proximité, pas encore en relation)
export const mockSuggestions = [
  { id: 'u-009', nom: 'Konan', prenoms: 'Ahoua', telephone: '+225 07 99 88 77 66', role: 'producteur', niveau: 2, points: 540, region: { nom: 'Lagunes' } },
  { id: 'u-010', nom: 'Ouattara', prenoms: 'Mamadou', telephone: '+225 05 88 77 66 55', role: 'producteur', niveau: 3, points: 980, region: { nom: 'Lagunes' } },
  { id: 'u-011', nom: 'N\'Guessan', prenoms: 'Yvette', telephone: '+225 01 77 66 55 44', role: 'agronome', niveau: 4, points: 1480, region: { nom: 'Lagunes' } },
]

export function getFriendshipStatusFor(otherId: string): {
  status: 'NONE' | 'PENDING_SENT' | 'PENDING_RECEIVED' | 'ACCEPTED' | 'REJECTED' | 'BLOCKED' | 'SELF'
  friendshipId?: string
  since?: string
} {
  if (otherId === 'visitor-demo') return { status: 'SELF' }
  const friend = mockFriends.find((f) => f.id === otherId)
  if (friend) return { status: 'ACCEPTED', friendshipId: friend.friendshipId, since: friend.amisDepuis }
  const sent = mockSentRequests.find((r) => r.to?.id === otherId)
  if (sent) return { status: 'PENDING_SENT', friendshipId: sent.id }
  const received = mockReceivedRequests.find((r) => r.from?.id === otherId)
  if (received) return { status: 'PENDING_RECEIVED', friendshipId: received.id }
  return { status: 'NONE' }
}

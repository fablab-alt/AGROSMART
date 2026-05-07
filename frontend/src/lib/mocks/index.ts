/**
 * Mock dispatcher pour le mode visiteur AgroSmart CI.
 * Intercepte toutes les requêtes axios et retourne des données mockées
 * sans jamais contacter le serveur réel.
 */

import type { InternalAxiosRequestConfig, AxiosResponse } from 'axios'
import toast from 'react-hot-toast'
import { daysAgo } from './helpers'

// ── Imports données mockées ───────────────────────────────────────────────────
import { mockParcelles, getParcelleById } from './data/parcelles'
import { mockCapteurs, mockStations, getCapteurById } from './data/capteurs'
import { getMesuresByCapteur, getLatestMesures, getDashboardMesures, mockMesures } from './data/mesures'
import { mockAlertes, getUnreadAlertesCount } from './data/alertes'
import { mockRecommandations } from './data/recommandations'
import { mockMeteoActuelle, mockMeteoPrevisions, mockMeteoHistorique } from './data/meteo'
import { mockProduits, mockCommandes, mockFavoris, mockVendeurStats, getProduitById } from './data/marketplace'
import { mockFormations, getFormationById } from './data/formations'
import { mockStocks, mockStockMouvements, mockStockStats } from './data/stocks'
import { mockActivites, mockProchainesActivites, mockCalendrierStats } from './data/calendrier'
import { mockFichesPratiques, mockFichesCategories } from './data/fichesPratiques'
import { mockPosts, mockLeaderboard, mockUserGamification } from './data/communaute'
import { mockConversations, mockMessages, mockUnreadMessagesCount } from './data/messages'
import { mockROI, mockRendements, mockComparaisonSaisonniere, mockRevenusParMois, mockPerformanceStats } from './data/performance'
import { mockDashboardStats, mockAnalyticsStats, mockDashboardCultures, mockKPICards, mockRepartitionCultures } from './data/dashboard'
import { VISITOR_USER } from './data/user'

// ── Helpers ───────────────────────────────────────────────────────────────────
const delay = (ms: number) => new Promise((r) => setTimeout(r, ms))
const randomLatency = () => 80 + Math.random() * 200

function extractIdFromUrl(url: string | undefined): string {
  if (!url) return ''
  return url.split('?')[0].split('/').pop() ?? ''
}

function extractParam(url: string | undefined, key: string): string | null {
  if (!url) return null
  try {
    const u = new URL(url, 'http://localhost')
    return u.searchParams.get(key)
  } catch {
    return null
  }
}

function paginateItems<T>(items: T[], config: InternalAxiosRequestConfig) {
  const page = parseInt(extractParam(config.url, 'page') ?? '1', 10)
  const limit = parseInt(extractParam(config.url, 'limit') ?? '20', 10)
  const start = (page - 1) * limit
  return { items: items.slice(start, start + limit), total: items.length, page, limit }
}

function ok(data: unknown, extra?: Record<string, unknown>): Record<string, unknown> {
  return { success: true, data, message: 'OK', ...extra }
}

function okList<T>(items: T[], total: number, page: number, limit: number): Record<string, unknown> {
  return {
    success: true,
    data: items,
    pagination: { page, limit, total, pages: Math.ceil(total / limit) },
  }
}

// ── Mutation handler ──────────────────────────────────────────────────────────
function handleMutation(method: string, body?: unknown): Record<string, unknown> {
  if (typeof window !== 'undefined') {
    setTimeout(() => {
      toast('Mode démo — Créez un compte pour effectuer cette action.', {
        icon: '🎭',
        duration: 3000,
        style: { background: '#fef3c7', color: '#92400e' },
      })
    }, 0)
  }
  if (method === 'DELETE') return ok(null)
  const id = 'mock-' + Date.now()
  if (body && typeof body === 'object') return ok({ id, ...(body as object) })
  return ok({ id })
}

// ── Weather mock shapes (matching what meteo/page.tsx and dashboard expect) ───
const weatherCurrent = {
  weather_code: 2,          // WMO: partly cloudy
  temperature: 28.5,
  temperature_max: 32,
  temperature_min: 23,
  humidity: 72,
  wind_speed: 12,
  wind_direction: 225,
  uv_index: 7,
  precipitation: 0,
  feels_like: 31,
  location: 'Abidjan, CI',
  observed_at: new Date().toISOString(),
}

const weatherForecast = {
  daily: Array.from({ length: 7 }, (_, i) => ({
    date: new Date(Date.now() + i * 86400000).toISOString().split('T')[0],
    weather_code: [0, 2, 3, 61, 2, 0, 1][i],
    temp_min: Math.round(22 + Math.random() * 3),
    temp_max: Math.round(29 + Math.random() * 5),
    precipitation_probability: [5, 10, 30, 80, 20, 5, 10][i],
    precipitation_sum: [0, 0, 2, 15, 1, 0, 0][i],
    wind_speed_max: Math.round(10 + Math.random() * 8),
  })),
}

// ── Route table ──────────────────────────────────────────────────────────────
type RouteHandler = (config: InternalAxiosRequestConfig) => unknown

const ROUTES: Array<{ p: RegExp; m: string; h: RouteHandler }> = [
  // ── AUTH / USER ──────────────────────────────────────────────────────────
  { p: /\/auth\/login/, m: 'POST', h: () => ({ user: VISITOR_USER, accessToken: 'visitor-demo-token', refreshToken: 'visitor-refresh-token' }) },
  { p: /\/auth\/me|\/users\/profile|\/users\/me/, m: 'GET', h: () => VISITOR_USER },
  { p: /\/auth\/me|\/users\/profile|\/users\/me/, m: 'PUT', h: () => VISITOR_USER },
  { p: /\/auth\/change-password/, m: 'POST', h: () => handleMutation('POST') },
  { p: /\/users\/settings/, m: 'GET', h: () => ({
    notifications_email: true,
    notifications_sms: false,
    notifications_push: true,
    langue: 'fr',
    theme: 'light',
    two_factor_enabled: false,
  })},
  { p: /\/users\/settings/, m: 'PATCH', h: (c) => handleMutation('PATCH', c.data) },
  { p: /\/users\/profile/, m: 'PUT', h: () => VISITOR_USER },
  { p: /\/users\b/, m: 'GET', h: (c) => {
    const q = extractParam(c.url, 'search') ?? ''
    const users = [
      { id: 'u-001', nom: 'Yao', prenoms: 'Kouassi', telephone: '+225 07 11 22 33', role: 'producteur' },
      { id: 'u-002', nom: 'Touré', prenoms: 'Aminata', telephone: '+225 07 22 33 44', role: 'agronome' },
      { id: 'u-003', nom: 'Diabaté', prenoms: 'Moussa', telephone: '+225 07 33 44 55', role: 'producteur' },
    ]
    const filtered = q ? users.filter(u => `${u.prenoms} ${u.nom}`.toLowerCase().includes(q.toLowerCase())) : users
    return okList(filtered, filtered.length, 1, 20)
  }},

  // ── DASHBOARD ────────────────────────────────────────────────────────────
  { p: /\/dashboard\/stats/, m: 'GET', h: () => mockDashboardStats },
  { p: /\/dashboard\/kpi/, m: 'GET', h: () => mockKPICards },
  { p: /\/dashboard\/cultures/, m: 'GET', h: () => mockDashboardCultures },
  { p: /\/dashboard\/roi/, m: 'GET', h: () => ({ roi: mockROI, stats: mockPerformanceStats }) },
  { p: /\/dashboard\/parcelle\//, m: 'GET', h: (c) => {
    const id = c.url?.split('/').filter(Boolean).pop()
    return getParcelleById(id ?? '') ?? mockParcelles[0]
  }},

  // ── WEATHER (meteo page + dashboard) ────────────────────────────────────
  { p: /\/weather\/current/, m: 'GET', h: () => weatherCurrent },
  { p: /\/weather\/forecast/, m: 'GET', h: () => weatherForecast },
  // Legacy /meteo/* routes
  { p: /\/meteo\/current|\/meteo\/actuelle/, m: 'GET', h: () => ({ current: mockMeteoActuelle, forecast: mockMeteoPrevisions }) },
  { p: /\/meteo\/forecast|\/meteo\/previsions/, m: 'GET', h: () => mockMeteoPrevisions },
  { p: /\/meteo\/historique/, m: 'GET', h: () => mockMeteoHistorique },
  { p: /\/meteo$/, m: 'GET', h: () => ({ current: weatherCurrent, forecast: weatherForecast, historique: mockMeteoHistorique }) },

  // ── PARCELLES ────────────────────────────────────────────────────────────
  { p: /\/parcelles$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockParcelles, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/parcelles\/[^/]+\/stations/, m: 'GET', h: (c) => {
    const parts = c.url?.split('/')
    const id = parts?.[parts.indexOf('parcelles') + 1]
    return mockStations.filter((s) => s.parcelle_id === id)
  }},
  { p: /\/parcelles\/[^/]+\/mesures/, m: 'GET', h: (c) => {
    const parts = c.url?.split('/')
    const id = parts?.[parts.indexOf('parcelles') + 1]
    const capteurIds = mockCapteurs.filter((cap) => cap.parcelle_id === id).map((cap) => cap.id)
    return capteurIds.flatMap((cid) => getMesuresByCapteur(cid).slice(0, 48))
  }},
  { p: /\/parcelles\/[^/]+$/, m: 'GET', h: (c) => getParcelleById(extractIdFromUrl(c.url)) ?? mockParcelles[0] },
  { p: /\/parcelles$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/parcelles\/[^/]+$/, m: 'PUT', h: (c) => handleMutation('PUT', c.data) },
  { p: /\/parcelles\/[^/]+$/, m: 'DELETE', h: () => handleMutation('DELETE') },

  // ── CULTURES ─────────────────────────────────────────────────────────────
  { p: /\/cultures/, m: 'GET', h: () => [
    { id: 'cult-001', nom: 'Cacao', categorie: 'CULTURES_INDUSTRIELLES' },
    { id: 'cult-002', nom: 'Maïs', categorie: 'CEREALES' },
    { id: 'cult-003', nom: 'Banane', categorie: 'FRUITS' },
    { id: 'cult-004', nom: 'Hévéa', categorie: 'CULTURES_INDUSTRIELLES' },
    { id: 'cult-005', nom: 'Tomate', categorie: 'LEGUMES' },
    { id: 'cult-006', nom: 'Manioc', categorie: 'TUBERCULES' },
    { id: 'cult-007', nom: 'Igname', categorie: 'TUBERCULES' },
    { id: 'cult-008', nom: 'Arachide', categorie: 'LEGUMINEUSES' },
  ]},

  // ── CAPTEURS ─────────────────────────────────────────────────────────────
  { p: /\/capteurs\/stations/, m: 'GET', h: () => mockStations },
  { p: /\/capteurs$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockCapteurs, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/capteurs\/[^/]+$/, m: 'GET', h: (c) => getCapteurById(extractIdFromUrl(c.url)) ?? mockCapteurs[0] },
  { p: /\/capteurs$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/capteurs\/stations$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/capteurs\/[^/]+\/toggle/, m: 'PATCH', h: () => ok(null) },
  { p: /\/capteurs\/[^/]+$/, m: 'PUT', h: (c) => handleMutation('PUT', c.data) },
  { p: /\/capteurs\/[^/]+$/, m: 'DELETE', h: () => handleMutation('DELETE') },

  // ── MESURES ──────────────────────────────────────────────────────────────
  { p: /\/mesures\/recent/, m: 'GET', h: () => getLatestMesures(200) },
  { p: /\/mesures\/latest/, m: 'GET', h: () => getLatestMesures(50) },
  { p: /\/mesures/, m: 'GET', h: (c) => {
    const capteurId = extractParam(c.url, 'capteur_id')
    const parcelleId = extractParam(c.url, 'parcelle_id')
    const limit = parseInt(extractParam(c.url, 'limit') ?? '500', 10)
    let items = capteurId
      ? getMesuresByCapteur(capteurId)
      : parcelleId
        ? mockMesures.filter((m) => (m as { parcelle_id?: string }).parcelle_id === parcelleId)
        : getLatestMesures(limit)
    // Trim to limit
    items = items.slice(0, limit)
    const { page } = paginateItems(items, c)
    return okList(items, items.length, page, limit)
  }},
  { p: /\/mesures$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },

  // ── ALERTES ──────────────────────────────────────────────────────────────
  { p: /\/alertes\/unread\/count/, m: 'GET', h: () => ({ count: getUnreadAlertesCount() }) },
  { p: /\/alertes$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockAlertes, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/alertes\/[^/]+$/, m: 'GET', h: (c) => mockAlertes.find((a) => a.id === extractIdFromUrl(c.url)) ?? mockAlertes[0] },
  { p: /\/alertes\/[^/]+\/read/, m: 'PUT', h: () => ok(null) },
  { p: /\/alertes\/[^/]+\/process/, m: 'PUT', h: () => ok(null) },

  // ── RECOMMANDATIONS ──────────────────────────────────────────────────────
  { p: /\/recommandations$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockRecommandations, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/recommandations\/[^/]+$/, m: 'GET', h: (c) => mockRecommandations.find((r) => r.id === extractIdFromUrl(c.url)) ?? mockRecommandations[0] },
  { p: /\/recommandations\/[^/]+\/apply/, m: 'POST', h: () => ok(null) },
  { p: /\/recommandations\/[^/]+\/rate/, m: 'POST', h: () => ok(null) },

  // ── MARKETPLACE ──────────────────────────────────────────────────────────
  { p: /\/marketplace\/produits\/mes-produits/, m: 'GET', h: () => [] },
  { p: /\/marketplace\/stats\/vendeur/, m: 'GET', h: () => mockVendeurStats },
  { p: /\/marketplace\/produits\/[^/]+$/, m: 'GET', h: (c) => getProduitById(extractIdFromUrl(c.url)) ?? mockProduits[0] },
  { p: /\/marketplace\/produits$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockProduits, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/marketplace\/commandes\/[^/]+\/status/, m: 'PUT', h: () => ok(null) },
  { p: /\/marketplace\/commandes\/[^/]+\/cancel/, m: 'PUT', h: () => ok(null) },
  { p: /\/marketplace\/commandes\/[^/]+$/, m: 'GET', h: (c) => mockCommandes.find((cmd) => cmd.id === extractIdFromUrl(c.url)) ?? mockCommandes[0] },
  { p: /\/marketplace\/commandes$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockCommandes, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/marketplace\/produits$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/marketplace\/produits\/[^/]+$/, m: 'PUT', h: (c) => handleMutation('PUT', c.data) },
  { p: /\/marketplace\/produits\/[^/]+$/, m: 'DELETE', h: () => handleMutation('DELETE') },
  { p: /\/marketplace\/commandes$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },

  // ── FAVORIS ──────────────────────────────────────────────────────────────
  { p: /\/favorites\/count/, m: 'GET', h: () => ({ count: mockFavoris.length }) },
  { p: /\/favorites\/check\//, m: 'GET', h: (c) => {
    const id = extractIdFromUrl(c.url)
    return { isFavorite: mockFavoris.some((f) => f.produit_id === id) }
  }},
  { p: /\/favorites$/, m: 'GET', h: () => mockFavoris },
  { p: /\/favorites\/toggle/, m: 'POST', h: () => ok(null) },
  { p: /\/favorites$/, m: 'POST', h: () => ok(null) },
  { p: /\/favorites\/[^/]+$/, m: 'DELETE', h: () => ok(null) },

  // ── FORMATIONS ───────────────────────────────────────────────────────────
  { p: /\/formations\/[^/]+$/, m: 'GET', h: (c) => getFormationById(extractIdFromUrl(c.url)) ?? mockFormations[0] },
  { p: /\/formations$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockFormations, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/formations\/[^/]+\/progress/, m: 'POST', h: () => ok(null) },
  { p: /\/formations\/[^/]+\/complete/, m: 'POST', h: () => ok(null) },

  // ── STOCKS ───────────────────────────────────────────────────────────────
  { p: /\/stocks\/statistiques/, m: 'GET', h: () => mockStockStats },
  { p: /\/stocks\/[^/]+\/mouvements/, m: 'GET', h: (c) => {
    const id = c.url?.split('/').slice(-2, -1)[0]
    return mockStockMouvements.filter((m) => m.stock_id === id)
  }},
  { p: /\/stocks\/[^/]+$/, m: 'GET', h: (c) => mockStocks.find((s) => s.id === extractIdFromUrl(c.url)) ?? mockStocks[0] },
  { p: /\/stocks$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockStocks, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/stocks$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/stocks\/[^/]+$/, m: 'PUT', h: (c) => handleMutation('PUT', c.data) },
  { p: /\/stocks\/[^/]+$/, m: 'DELETE', h: () => handleMutation('DELETE') },
  { p: /\/stocks\/[^/]+\/mouvement/, m: 'POST', h: (c) => handleMutation('POST', c.data) },

  // ── CALENDRIER ───────────────────────────────────────────────────────────
  { p: /\/calendrier\/statistiques/, m: 'GET', h: () => mockCalendrierStats },
  { p: /\/calendrier\/prochaines/, m: 'GET', h: () => mockProchainesActivites },
  { p: /\/calendrier\/[^/]+$/, m: 'GET', h: (c) => mockActivites.find((a) => a.id === extractIdFromUrl(c.url)) ?? mockActivites[0] },
  { p: /\/calendrier$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockActivites, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/calendrier$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/calendrier\/[^/]+$/, m: 'PUT', h: (c) => handleMutation('PUT', c.data) },
  { p: /\/calendrier\/[^/]+$/, m: 'DELETE', h: () => handleMutation('DELETE') },
  { p: /\/calendrier\/[^/]+\/terminer/, m: 'PATCH', h: () => ok(null) },

  // ── FICHES PRATIQUES ─────────────────────────────────────────────────────
  { p: /\/fiches-pratiques\/categories/, m: 'GET', h: () => mockFichesCategories },
  { p: /\/fiches-pratiques\/search/, m: 'GET', h: (c) => {
    const q = extractParam(c.url, 'q')?.toLowerCase() ?? ''
    return mockFichesPratiques.filter(
      (f) => f.titre.toLowerCase().includes(q) || f.tags.some((t) => t.includes(q))
    )
  }},
  { p: /\/fiches-pratiques\/[^/]+$/, m: 'GET', h: (c) => mockFichesPratiques.find((f) => f.id === extractIdFromUrl(c.url)) ?? mockFichesPratiques[0] },
  { p: /\/fiches-pratiques$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockFichesPratiques, c)
    return okList(items, total, page, limit)
  }},

  // ── MESSAGES ─────────────────────────────────────────────────────────────
  // GET /messages/conversations — list all conversations
  { p: /\/messages\/conversations$/, m: 'GET', h: () => mockConversations },
  // GET /messages/conversations/{id} — messages in a conversation
  { p: /\/messages\/conversations\/[^/]+$/, m: 'GET', h: (c) => {
    const convId = extractIdFromUrl(c.url)
    return mockMessages[convId] ?? []
  }},
  // Legacy singular /messages/conversation/{userId}
  { p: /\/messages\/conversation\/[^/]+$/, m: 'GET', h: (c) => {
    const userId = extractIdFromUrl(c.url)
    const conv = mockConversations.find((cv) => cv.participant_id === userId)
    if (!conv) return []
    return mockMessages[conv.id] ?? []
  }},
  // Contacts search
  { p: /\/messages\/contacts\/search/, m: 'GET', h: (c) => {
    const q = extractParam(c.url, 'q')?.toLowerCase() ?? ''
    const contacts = [
      { id: 'u-001', nom: 'Yao', prenoms: 'Kouassi', telephone: '+225 07 11 22 33', role: 'producteur' },
      { id: 'u-002', nom: 'Touré', prenoms: 'Aminata', telephone: '+225 07 22 33 44', role: 'agronome' },
    ]
    return contacts.filter(u => !q || `${u.prenoms} ${u.nom}`.toLowerCase().includes(q))
  }},
  { p: /\/messages\/unread/, m: 'GET', h: () => ({ count: mockUnreadMessagesCount }) },
  { p: /\/messages\/[^/]+\/read/, m: 'PUT', h: () => ok(null) },
  { p: /\/messages$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },

  // ── COMMUNAUTÉ ───────────────────────────────────────────────────────────
  { p: /\/communaute\/stats/, m: 'GET', h: () => ({
    membresActifs: 1420,
    postsAujourd_hui: 7,
    postsPublies: mockPosts.length,
    reponsesAujourd_hui: 23,
    topContributeurs: mockLeaderboard.slice(0, 3).map((u) => ({ nom: u.nom, points: u.points })),
  })},
  { p: /\/communaute\/leaderboard/, m: 'GET', h: () => mockLeaderboard },
  { p: /\/communaute\/gamification/, m: 'GET', h: () => mockUserGamification },
  // /communaute/posts — plain array (page does .map() directly on data.data)
  { p: /\/communaute\/posts$/, m: 'GET', h: () => mockPosts },
  { p: /\/communaute\/[^/]+$/, m: 'GET', h: (c) => mockPosts.find((p) => p.id === extractIdFromUrl(c.url)) ?? mockPosts[0] },
  { p: /\/communaute$/, m: 'GET', h: (c) => {
    const { items, total, page, limit } = paginateItems(mockPosts, c)
    return okList(items, total, page, limit)
  }},
  { p: /\/communaute$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/communaute\/[^/]+\/reponse/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/communaute\/[^/]+\/like/, m: 'POST', h: () => ok(null) },

  // ── ANALYTICS / PERFORMANCE ──────────────────────────────────────────────
  // /analytics/stats — for performance/page.tsx
  { p: /\/analytics\/stats/, m: 'GET', h: () => mockAnalyticsStats },
  { p: /\/analytics\/seasonal-comparison/, m: 'GET', h: () => mockComparaisonSaisonniere },
  { p: /\/analytics\/export/, m: 'GET', h: () => ({ message: 'Export non disponible en mode démo' }) },
  { p: /\/performance\/roi/, m: 'GET', h: () => ({ roi: mockROI, stats: mockPerformanceStats }) },
  { p: /\/performance\/rendements/, m: 'GET', h: () => mockRendements },
  { p: /\/performance\/revenus/, m: 'GET', h: () => mockRevenusParMois },
  { p: /\/performance\/cultures/, m: 'GET', h: () => mockRepartitionCultures },

  // ── ÉQUIPEMENTS ──────────────────────────────────────────────────────────
  { p: /\/equipment\/rentals\/my-rentals/, m: 'GET', h: () => [] },
  { p: /\/equipment\/rentals\/requests/, m: 'GET', h: () => [] },
  { p: /\/equipment$/, m: 'GET', h: () => okList([], 0, 1, 20) },
  { p: /\/equipment$/, m: 'POST', h: (c) => handleMutation('POST', c.data) },
  { p: /\/equipment\/[^/]+\/rent/, m: 'POST', h: (c) => handleMutation('POST', c.data) },

  // ── DIAGNOSTICS ──────────────────────────────────────────────────────────
  { p: /\/diagnostics\/history/, m: 'GET', h: () => [
    { id: 'diag-001', culture: 'Cacao', maladie: 'Pourriture brune', severite: 'MODEREE', date: daysAgo(5), parcelle_nom: 'Parcelle Bingerville Nord', traitement: 'Fongicide cuivre appliqué', statut: 'TRAITE' },
    { id: 'diag-002', culture: 'Maïs', maladie: 'Bruche du maïs', severite: 'FAIBLE', date: daysAgo(12), parcelle_nom: 'Champ de Maïs - Korhogo', traitement: 'Insecticide biologique', statut: 'EN_COURS' },
  ]},
  { p: /\/diagnostics$/, m: 'GET', h: () => okList([], 0, 1, 20) },
  { p: /\/diagnostic\/analyser|\/diagnostics$/, m: 'POST', h: () => ok({ id: 'mock-diag-' + Date.now(), status: 'EN_COURS', maladie_detectee: null, confiance: 0, message: 'Analyse en cours (mode démo)' }) },

  // ── AI / CHATBOT ─────────────────────────────────────────────────────────
  { p: /\/chatbot|\/ai/, m: 'POST', h: () => ok({ reponse: 'Je suis en mode démo. Créez un compte pour accéder à l\'assistant IA complet.', suggestions: ['Créer une parcelle', 'Voir mes alertes', 'Explorer la marketplace'] }) },

  // ── PAYMENTS ─────────────────────────────────────────────────────────────
  { p: /\/payments/, m: 'POST', h: () => handleMutation('POST') },
  { p: /\/payments/, m: 'GET', h: () => okList([], 0, 1, 20) },
]

// ── Route matching ─────────────────────────────────────────────────────────
function findHandler(url: string, method: string): RouteHandler | null {
  const pathname = url.split('?')[0]
  const m = method.toUpperCase()
  for (const { p, m: hm, h } of ROUTES) {
    if (hm === m && p.test(pathname)) return h
  }
  return null
}

// ── Main dispatcher ────────────────────────────────────────────────────────
export async function mockDispatch(config: InternalAxiosRequestConfig): Promise<AxiosResponse> {
  await delay(randomLatency())

  const url = config.url ?? ''
  const method = config.method?.toUpperCase() ?? 'GET'
  const handler = findHandler(url, method)

  let responseData: unknown
  if (handler) {
    const result = handler(config)
    // If handler already returned a wrapped ok() / okList() object, use as-is
    if (result && typeof result === 'object' && 'success' in (result as object)) {
      responseData = result
    } else {
      responseData = ok(result)
    }
  } else {
    console.warn(`[MockDispatch] No handler for ${method} ${url}`)
    responseData = ok(null)
  }

  return {
    data: responseData,
    status: 200,
    statusText: 'OK',
    headers: { 'content-type': 'application/json' },
    config,
  } as AxiosResponse
}

export { VISITOR_USER }

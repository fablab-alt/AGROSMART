import { create } from 'zustand'
import { persist } from 'zustand/middleware'
import { clearDiscoveryMode } from '@/lib/discoveryMode'

// Types
export interface User {
  id: string
  nom: string
  prenom?: string  // Backend uses prenom
  prenoms?: string // Frontend alias for prenom
  telephone: string
  email?: string
  role: 'PRODUCTEUR' | 'CONSEILLER' | 'ADMIN' | 'PARTENAIRE' | 'AGRONOME' | 'FOURNISSEUR' | 'ACHETEUR'
  status: string
  region_id?: string
  cooperative_id?: string
  langue_preferee?: string
  notifications_sms?: boolean
  notifications_whatsapp?: boolean
  notifications_push?: boolean
}

export interface Parcelle {
  id: string
  nom: string
  latitude?: number
  longitude?: number
  superficie_hectares?: number
  type_sol?: string
  description?: string
  status: string
  created_at: string
  nb_stations?: number
  nb_plantations?: number
}

export interface Capteur {
  id: string
  station_id: string
  code: string
  type: 'humidite' | 'temperature' | 'ph' | 'npk' | 'meteo' | 'camera'
  modele?: string
  fabricant?: string
  unite_mesure?: string
  status: string
  station_nom?: string
  parcelle_nom?: string
}

export interface Mesure {
  id: string
  capteur_id: string
  capteur_type: string
  valeur: number
  unite?: string
  mesure_at: string
  parcelle_id?: string
  parcelle_nom?: string
  station_nom?: string
}

export interface Alerte {
  id: string
  niveau: 'info' | 'important' | 'critique'
  titre: string
  message: string
  categorie: string
  status: string
  created_at: string
  parcelle_id?: string
  parcelle_nom?: string
  lu_at?: string | null
}

export interface Recommandation {
  id: string
  type: string
  titre: string
  description: string
  action?: string
  priorite: number
  appliquee: boolean
  parcelle_id?: string
  created_at: string
}

export interface Produit {
  id: string
  vendeur_id: string
  nom: string
  description?: string
  categorie: string
  prix: number
  devise: string
  unite: string
  quantite_disponible: number
  images?: string[]
  est_actif: boolean
  vendeur_nom?: string
  vendeur_telephone?: string
}

export interface Formation {
  id: string
  titre: string
  description?: string
  categorie: string
  type: 'video' | 'pdf' | 'article'
  url?: string
  duree_minutes?: number
  langue: string
  progression?: number
  complete?: boolean
}

// Auth Store
interface AuthState {
  user: User | null
  token: string | null
  refreshToken: string | null
  isAuthenticated: boolean
  isLoading: boolean
  setUser: (user: User | null) => void
  setToken: (token: string | null) => void
  login: (user: User, token: string, refreshToken?: string) => void
  logout: () => void
  setLoading: (loading: boolean) => void
  updateTokens: (token: string, refreshToken?: string) => void
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      token: null,
      refreshToken: null,
      isAuthenticated: false,
      isLoading: true,
      setUser: (user) => set({ user, isAuthenticated: !!user }),
      setToken: (token) => set({ token }),
      login: (user, token, refreshToken) => {
        clearDiscoveryMode()
        set({ user, token, refreshToken: refreshToken || null, isAuthenticated: true, isLoading: false })
      },
      logout: () => {
        clearDiscoveryMode()
        if (typeof window !== 'undefined') {
          localStorage.removeItem('auth-storage')
        }
        set({ user: null, token: null, refreshToken: null, isAuthenticated: false, isLoading: false })
      },
      updateTokens: (token, refreshToken) => {
        set({ token, ...(refreshToken ? { refreshToken } : {}) })
      },
      setLoading: (isLoading) => set({ isLoading }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ user: state.user, token: state.token, refreshToken: state.refreshToken, isAuthenticated: state.isAuthenticated }),
      onRehydrateStorage: () => (state) => {
        // Après la réhydratation, mettre isLoading à false et vérifier isAuthenticated
        if (state) {
          state.isLoading = false
          state.isAuthenticated = !!(state.token && state.user)
        }
      },
    }
  )
)

// Parcelles Store
interface ParcellesState {
  parcelles: Parcelle[]
  selectedParcelle: Parcelle | null
  isLoading: boolean
  setParcelles: (parcelles: Parcelle[]) => void
  setSelectedParcelle: (parcelle: Parcelle | null) => void
  addParcelle: (parcelle: Parcelle) => void
  updateParcelle: (id: string, data: Partial<Parcelle>) => void
  removeParcelle: (id: string) => void
  setLoading: (loading: boolean) => void
}

export const useParcellesStore = create<ParcellesState>((set) => ({
  parcelles: [],
  selectedParcelle: null,
  isLoading: false,
  setParcelles: (parcelles) => set({ parcelles }),
  setSelectedParcelle: (selectedParcelle) => set({ selectedParcelle }),
  addParcelle: (parcelle) =>
    set((state) => ({ parcelles: [...state.parcelles, parcelle] })),
  updateParcelle: (id, data) =>
    set((state) => ({
      parcelles: state.parcelles.map((p) =>
        p.id === id ? { ...p, ...data } : p
      ),
    })),
  removeParcelle: (id) =>
    set((state) => ({
      parcelles: state.parcelles.filter((p) => p.id !== id),
    })),
  setLoading: (isLoading) => set({ isLoading }),
}))

// Alertes Store
interface AlertesState {
  alertes: Alerte[]
  unreadCount: number
  setAlertes: (alertes: Alerte[]) => void
  addAlerte: (alerte: Alerte) => void
  markAsRead: (id: string) => void
  setUnreadCount: (count: number) => void
}

export const useAlertesStore = create<AlertesState>((set) => ({
  alertes: [],
  unreadCount: 0,
  setAlertes: (alertes) => set({ alertes }),
  addAlerte: (alerte) =>
    set((state) => ({ alertes: [alerte, ...state.alertes] })),
  markAsRead: (id) =>
    set((state) => ({
      alertes: state.alertes.map((a) =>
        a.id === id ? { ...a, status: 'LUE', lu_at: new Date().toISOString() } : a
      ),
      unreadCount: Math.max(0, state.unreadCount - 1),
    })),
  setUnreadCount: (unreadCount) => set({ unreadCount }),
}))

// UI Store
interface UIState {
  sidebarOpen: boolean
  language: 'fr' | 'baoule' | 'malinke' | 'senoufo'
  theme: 'light' | 'dark'
  toggleSidebar: () => void
  setSidebarOpen: (open: boolean) => void
  setLanguage: (lang: 'fr' | 'baoule' | 'malinke' | 'senoufo') => void
  setTheme: (theme: 'light' | 'dark') => void
}

export const useUIStore = create<UIState>()(
  persist(
    (set) => ({
      sidebarOpen: true,
      language: 'fr',
      theme: 'light',
      toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
      setSidebarOpen: (sidebarOpen) => set({ sidebarOpen }),
      setLanguage: (language) => set({ language }),
      setTheme: (theme) => set({ theme }),
    }),
    {
      name: 'ui-storage',
    }
  )
)

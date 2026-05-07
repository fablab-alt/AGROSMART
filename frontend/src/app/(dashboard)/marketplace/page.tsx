'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import {
  ShoppingCart, Plus, Search, Filter, Package, User, Phone, ChevronRight,
  Grid, List, Heart, ClipboardList, Store, Truck, Clock, CheckCircle,
  XCircle, Eye, Trash2, MessageCircle, MapPin, HeartOff,
} from 'lucide-react'
import {
  Card, CardContent, Button, Input, Badge, Skeleton, Select, SelectContent,
  SelectItem, SelectTrigger, SelectValue, Tabs, TabsList, TabsTrigger,
  TabsContent, Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter,
  DialogDescription,
} from '@/components/ui'
import { cn } from '@/lib/utils'
import api, { favoritesApi } from '@/lib/api'
import toast from 'react-hot-toast'

interface Produit {
  id: string; vendeur_id: string; vendeurId?: string; nom: string
  description?: string; categorie: string; prix: number; devise: string
  unite: string; quantite_disponible: number; stock?: number; images?: string[]
  est_actif: boolean; actif?: boolean; vendeur_nom?: string
  vendeur_telephone?: string; type_offre?: 'vente' | 'location'
  prix_location_jour?: number; createdAt?: string; created_at?: string
}

interface Commande {
  id: string; produitId: string; acheteurId: string; vendeurId?: string
  quantite: number; prixUnitaire: number | string; prixTotal: number | string
  statut: string; adresseLivraison?: string; modeLivraison?: string
  notes?: string; dateDebut?: string; dateFin?: string; createdAt: string
  produit_nom?: string; produit_prix?: number | string
  acheteur_nom?: string; acheteur_telephone?: string
  vendeur_nom?: string; vendeur_telephone?: string
}

interface Favorite {
  id: string; userId: string; produitId: string; createdAt: string
  produit: {
    id: string; nom: string; description?: string; prix: number
    unite: string; stock: number; images?: string[]; categorie: string
    actif: boolean; vendeur?: { id: string; nom: string; prenoms?: string }
  }
}

const categories = [
  { value: 'all', label: 'Toutes les catégories' },
  { value: 'semences', label: 'Semences' }, { value: 'engrais', label: 'Engrais' },
  { value: 'pesticides', label: 'Pesticides' }, { value: 'equipements', label: 'Équipements' },
  { value: 'recoltes', label: 'Récoltes' }, { value: 'services', label: 'Services' },
  { value: 'cereale', label: 'Céréales' }, { value: 'legume', label: 'Légumes' },
  { value: 'fruit', label: 'Fruits' }, { value: 'tubercule', label: 'Tubercules' },
  { value: 'intrant', label: 'Intrants' },
]

const statutColors: Record<string, string> = {
  PENDING: 'bg-yellow-100 text-yellow-800', CONFIRMED: 'bg-blue-100 text-blue-800',
  SHIPPED: 'bg-purple-100 text-purple-800', DELIVERED: 'bg-green-100 text-green-800',
  CANCELLED: 'bg-red-100 text-red-800',
}
const statutLabels: Record<string, string> = {
  PENDING: 'En attente', CONFIRMED: 'Confirmée', SHIPPED: 'Expédiée',
  DELIVERED: 'Livrée', CANCELLED: 'Annulée',
}
const statutIcons: Record<string, React.ReactNode> = {
  PENDING: <Clock className="h-4 w-4" />, CONFIRMED: <CheckCircle className="h-4 w-4" />,
  SHIPPED: <Truck className="h-4 w-4" />, DELIVERED: <CheckCircle className="h-4 w-4" />,
  CANCELLED: <XCircle className="h-4 w-4" />,
}

const formatPrice = (prix: number | string) => {
  const num = typeof prix === 'string' ? parseFloat(prix) : prix
  if (isNaN(num)) return '0 FCFA'
  return new Intl.NumberFormat('fr-FR').format(num) + ' FCFA'
}

// ==================== PRODUCT GRID ====================
function ProductGrid({ products, loading, viewMode, searchQuery, setSearchQuery,
  selectedCategory, setSelectedCategory, setViewMode, favorites, onToggleFavorite,
}: {
  products: Produit[]; loading: boolean; viewMode: 'grid' | 'list'
  searchQuery: string; setSearchQuery: (v: string) => void
  selectedCategory: string; setSelectedCategory: (v: string) => void
  setViewMode: (v: 'grid' | 'list') => void
  favorites: Set<string>; onToggleFavorite: (id: string) => void
}) {
  return (
    <>
      <div className="flex flex-col md:flex-row gap-4 mb-6">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input placeholder="Rechercher un produit..." value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)} className="pl-10" />
        </div>
        <Select value={selectedCategory} onValueChange={setSelectedCategory}>
          <SelectTrigger className="w-full md:w-50">
            <Filter className="h-4 w-4 mr-2" /><SelectValue placeholder="Catégorie" />
          </SelectTrigger>
          <SelectContent>
            {categories.map(cat => <SelectItem key={cat.value} value={cat.value}>{cat.label}</SelectItem>)}
          </SelectContent>
        </Select>
        <div className="flex gap-1 border rounded-lg p-1">
          <Button variant={viewMode === 'grid' ? 'default' : 'ghost'} size="sm" onClick={() => setViewMode('grid')} aria-label="Vue grille"><Grid className="h-4 w-4" /></Button>
          <Button variant={viewMode === 'list' ? 'default' : 'ghost'} size="sm" onClick={() => setViewMode('list')} aria-label="Vue liste"><List className="h-4 w-4" /></Button>
        </div>
      </div>

      {loading ? (
        <div className={cn("grid gap-4", viewMode === 'grid' ? 'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3' : 'grid-cols-1')}>
          <Skeleton className="h-64 w-full" /><Skeleton className="h-64 w-full" /><Skeleton className="h-64 w-full" />
        </div>
      ) : products.length === 0 ? (
        <Card><CardContent className="py-12 text-center">
          <Package className="h-12 w-12 mx-auto text-gray-300 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">
            {searchQuery || selectedCategory !== 'all' ? 'Aucun résultat trouvé' : 'Aucun produit disponible'}
          </h3>
          <p className="text-gray-500 mb-4">
            {searchQuery || selectedCategory !== 'all' ? "Essayez avec d'autres filtres" : 'Soyez le premier à publier une annonce!'}
          </p>
          <Link href="/marketplace/nouveau"><Button><Plus className="h-4 w-4 mr-2" />Publier une annonce</Button></Link>
        </CardContent></Card>
      ) : viewMode === 'grid' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {products.map(produit => (
            <Card key={produit.id} className="hover:shadow-md transition-shadow overflow-hidden">
              <div className="relative h-48 bg-gray-100">
                {produit.images && produit.images.length > 0 ? (
                  <Image src={produit.images[0]} alt={produit.nom} fill className="object-cover" />
                ) : (
                  <div className="flex items-center justify-center h-full"><Package className="h-16 w-16 text-gray-300" /></div>
                )}
                <div className="absolute top-2 left-2 flex gap-2">
                  <Badge variant="secondary">{produit.categorie}</Badge>
                  {produit.type_offre === 'location' && <Badge className="bg-blue-600 text-white">Location</Badge>}
                </div>
                <button onClick={(e) => { e.preventDefault(); onToggleFavorite(produit.id) }}
                  aria-label={favorites.has(produit.id) ? 'Retirer des favoris' : 'Ajouter aux favoris'}
                  className="absolute top-2 right-2 p-2 rounded-full bg-white/80 hover:bg-white transition-colors">
                  <Heart className={cn("h-4 w-4", favorites.has(produit.id) ? "fill-red-500 text-red-500" : "text-gray-400")} />
                </button>
              </div>
              <CardContent className="p-4">
                <h3 className="font-semibold text-gray-900 mb-1 truncate">{produit.nom}</h3>
                <p className="text-sm text-gray-500 mb-3 line-clamp-2">{produit.description || 'Pas de description'}</p>
                <div className="flex items-center justify-between mb-3">
                  <p className="text-lg font-bold text-green-600">
                    {produit.type_offre === 'location'
                      ? <>{formatPrice(produit.prix_location_jour || produit.prix)}<span className="text-sm font-normal text-gray-500">/jour</span></>
                      : <>{formatPrice(produit.prix)}<span className="text-sm font-normal text-gray-500">/{produit.unite}</span></>}
                  </p>
                  <Badge variant="outline">{produit.quantite_disponible ?? produit.stock ?? 0} en stock</Badge>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-500 mb-3">
                  <User className="h-4 w-4" />{produit.vendeur_nom || 'Vendeur'}
                </div>
                <Link href={`/marketplace/${produit.id}`}>
                  <Button className="w-full" variant="outline">Voir détails <ChevronRight className="h-4 w-4 ml-2" /></Button>
                </Link>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          {products.map(produit => (
            <Card key={produit.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-4 flex gap-4">
                <div className="relative h-32 w-32 bg-gray-100 rounded-lg shrink-0">
                  {produit.images && produit.images.length > 0 ? (
                    <Image src={produit.images[0]} alt={produit.nom} fill className="object-cover rounded-lg" />
                  ) : (
                    <div className="flex items-center justify-center h-full"><Package className="h-10 w-10 text-gray-300" /></div>
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="font-semibold text-gray-900 mb-1">{produit.nom}</h3>
                      <Badge variant="secondary" className="mb-2">{produit.categorie}</Badge>
                      <p className="text-sm text-gray-500 line-clamp-2 mb-2">{produit.description || 'Pas de description'}</p>
                    </div>
                    <div className="text-right shrink-0 flex flex-col items-end gap-2">
                      <p className="text-lg font-bold text-green-600">
                        {formatPrice(produit.prix)}<span className="text-sm font-normal text-gray-500">/{produit.unite}</span>
                      </p>
                      <button onClick={() => onToggleFavorite(produit.id)} aria-label={favorites.has(produit.id) ? 'Retirer des favoris' : 'Ajouter aux favoris'}>
                        <Heart className={cn("h-5 w-5", favorites.has(produit.id) ? "fill-red-500 text-red-500" : "text-gray-400 hover:text-red-400")} />
                      </button>
                    </div>
                  </div>
                  <div className="flex items-center justify-between mt-2">
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <div className="flex items-center gap-1"><User className="h-4 w-4" />{produit.vendeur_nom || 'Vendeur'}</div>
                      {produit.vendeur_telephone && <div className="flex items-center gap-1"><Phone className="h-4 w-4" />{produit.vendeur_telephone}</div>}
                    </div>
                    <Link href={`/marketplace/${produit.id}`}><Button size="sm">Voir détails</Button></Link>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </>
  )
}

// ==================== MES COMMANDES ====================
function MesCommandesTab({ commandes, loading, onCancel, onViewDetail }: {
  commandes: Commande[]; loading: boolean
  onCancel: (id: string) => void; onViewDetail: (c: Commande) => void
}) {
  const [filter, setFilter] = useState('all')
  const filtered = filter === 'all' ? commandes : commandes.filter(c => c.statut === filter)

  if (loading) return <div className="space-y-4"><Skeleton className="h-32 w-full" /><Skeleton className="h-32 w-full" /></div>

  return (
    <div className="space-y-4">
      <div className="flex gap-2 flex-wrap">
        {[
          { value: 'all', label: 'Toutes', count: commandes.length },
          { value: 'PENDING', label: 'En attente', count: commandes.filter(c => c.statut === 'PENDING').length },
          { value: 'CONFIRMED', label: 'Confirmées', count: commandes.filter(c => c.statut === 'CONFIRMED').length },
          { value: 'SHIPPED', label: 'Expédiées', count: commandes.filter(c => c.statut === 'SHIPPED').length },
          { value: 'DELIVERED', label: 'Livrées', count: commandes.filter(c => c.statut === 'DELIVERED').length },
        ].map(f => (
          <Button key={f.value} variant={filter === f.value ? 'default' : 'outline'} size="sm" onClick={() => setFilter(f.value)}>
            {f.label} {f.count > 0 && <Badge variant="secondary" className="ml-1 text-xs">{f.count}</Badge>}
          </Button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <Card><CardContent className="py-12 text-center">
          <ClipboardList className="h-12 w-12 mx-auto text-gray-300 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune commande</h3>
          <p className="text-gray-500">
            {filter === 'all' ? "Vous n'avez pas encore passé de commande" : 'Aucune commande avec ce statut'}
          </p>
        </CardContent></Card>
      ) : (
        <div className="space-y-3">
          {filtered.map(cmd => (
            <Card key={cmd.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="font-semibold text-gray-900 truncate">{cmd.produit_nom || 'Produit'}</h3>
                      <Badge className={cn("shrink-0 flex items-center gap-1", statutColors[cmd.statut] || 'bg-gray-100')}>
                        {statutIcons[cmd.statut]}{statutLabels[cmd.statut] || cmd.statut}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                      <div><span className="text-gray-500">Quantité</span><p className="font-medium">{cmd.quantite}</p></div>
                      <div><span className="text-gray-500">Prix unitaire</span><p className="font-medium">{formatPrice(cmd.prixUnitaire)}</p></div>
                      <div><span className="text-gray-500">Total</span><p className="font-bold text-green-600">{formatPrice(cmd.prixTotal)}</p></div>
                      <div><span className="text-gray-500">Date</span><p className="font-medium">{cmd.createdAt ? new Date(cmd.createdAt).toLocaleDateString('fr-FR') : 'N/A'}</p></div>
                    </div>
                    {cmd.vendeur_nom && (
                      <div className="flex items-center gap-2 mt-2 text-sm text-gray-500">
                        <User className="h-3.5 w-3.5" /><span>Vendeur : {cmd.vendeur_nom}</span>
                        {cmd.vendeur_telephone && (
                          <a href={`tel:${cmd.vendeur_telephone}`} className="text-green-600 hover:underline flex items-center gap-1">
                            <Phone className="h-3.5 w-3.5" />{cmd.vendeur_telephone}
                          </a>
                        )}
                      </div>
                    )}
                  </div>
                  <div className="flex flex-col gap-2 shrink-0">
                    <Button variant="outline" size="sm" onClick={() => onViewDetail(cmd)}>
                      <Eye className="h-4 w-4 mr-1" /> Détails
                    </Button>
                    {cmd.statut === 'PENDING' && (
                      <Button variant="outline" size="sm" className="text-red-600 border-red-200 hover:bg-red-50" onClick={() => onCancel(cmd.id)}>
                        <XCircle className="h-4 w-4 mr-1" /> Annuler
                      </Button>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}

// ==================== FAVORIS ====================
function FavorisTab({ favorites, loading, onRemove }: {
  favorites: Favorite[]; loading: boolean; onRemove: (id: string) => void
}) {
  if (loading) return <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
    <Skeleton className="h-64 w-full" /><Skeleton className="h-64 w-full" /><Skeleton className="h-64 w-full" />
  </div>

  if (favorites.length === 0) return (
    <Card><CardContent className="py-12 text-center">
      <HeartOff className="h-12 w-12 mx-auto text-gray-300 mb-4" />
      <h3 className="text-lg font-medium text-gray-900 mb-2">Aucun favori</h3>
      <p className="text-gray-500">Ajoutez des produits à vos favoris en cliquant sur le coeur</p>
    </CardContent></Card>
  )

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      {favorites.map(fav => {
        const p = fav.produit
        if (!p) return null
        return (
          <Card key={fav.id} className="hover:shadow-md transition-shadow overflow-hidden">
            <div className="relative h-44 bg-gray-100">
              {p.images && p.images.length > 0 ? (
                <Image src={p.images[0]} alt={p.nom} fill className="object-cover" />
              ) : (
                <div className="flex items-center justify-center h-full"><Package className="h-14 w-14 text-gray-300" /></div>
              )}
              <Badge variant="secondary" className="absolute top-2 left-2">{p.categorie}</Badge>
              <button onClick={() => onRemove(p.id)} aria-label="Retirer des favoris" className="absolute top-2 right-2 p-2 rounded-full bg-white/80 hover:bg-white">
                <Heart className="h-4 w-4 fill-red-500 text-red-500" />
              </button>
            </div>
            <CardContent className="p-4">
              <h3 className="font-semibold text-gray-900 mb-1 truncate">{p.nom}</h3>
              <p className="text-sm text-gray-500 mb-2 line-clamp-2">{p.description || 'Pas de description'}</p>
              <div className="flex items-center justify-between mb-3">
                <p className="text-lg font-bold text-green-600">{formatPrice(p.prix)}<span className="text-sm font-normal text-gray-500">/{p.unite}</span></p>
                <Badge variant="outline">{p.stock} en stock</Badge>
              </div>
              {p.vendeur && (
                <div className="flex items-center gap-2 text-sm text-gray-500 mb-3"><User className="h-4 w-4" />{p.vendeur.nom} {p.vendeur.prenoms || ''}</div>
              )}
              <Link href={`/marketplace/${p.id}`}>
                <Button className="w-full" variant="outline">Voir détails <ChevronRight className="h-4 w-4 ml-2" /></Button>
              </Link>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}

// ==================== MES ANNONCES ====================
function MesAnnoncesTab({ produits, loading, onDelete }: {
  produits: Produit[]; loading: boolean; onDelete: (id: string) => void
}) {
  if (loading) return <div className="space-y-4"><Skeleton className="h-32 w-full" /><Skeleton className="h-32 w-full" /></div>

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-sm text-gray-500">{produits.length} annonce{produits.length !== 1 ? 's' : ''}</p>
        <Link href="/marketplace/nouveau"><Button><Plus className="h-4 w-4 mr-2" />Nouvelle annonce</Button></Link>
      </div>
      {produits.length === 0 ? (
        <Card><CardContent className="py-12 text-center">
          <Store className="h-12 w-12 mx-auto text-gray-300 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Aucune annonce</h3>
          <p className="text-gray-500 mb-4">Publiez votre première annonce pour vendre vos produits</p>
          <Link href="/marketplace/nouveau"><Button><Plus className="h-4 w-4 mr-2" />Publier</Button></Link>
        </CardContent></Card>
      ) : (
        <div className="space-y-3">
          {produits.map(p => (
            <Card key={p.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex items-start gap-4">
                  <div className="relative h-20 w-20 bg-gray-100 rounded-lg shrink-0">
                    {p.images && p.images.length > 0 ? (
                      <Image src={p.images[0]} alt={p.nom} fill className="object-cover rounded-lg" />
                    ) : (
                      <div className="flex items-center justify-center h-full"><Package className="h-8 w-8 text-gray-300" /></div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-semibold text-gray-900 truncate">{p.nom}</h3>
                      <Badge variant={p.actif !== false ? 'default' : 'secondary'}>
                        {p.actif !== false ? 'Actif' : 'Inactif'}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-4 text-sm text-gray-500">
                      <Badge variant="outline">{p.categorie}</Badge>
                      <span>{formatPrice(p.prix)}/{p.unite}</span>
                      <span>{p.quantite_disponible ?? p.stock ?? 0} en stock</span>
                    </div>
                    <p className="text-xs text-gray-400 mt-1">
                      Créé le {(p.createdAt || p.created_at) ? new Date((p.createdAt || p.created_at)!).toLocaleDateString('fr-FR') : 'N/A'}
                    </p>
                  </div>
                  <div className="flex gap-2 shrink-0">
                    <Link href={`/marketplace/${p.id}`}><Button variant="outline" size="sm" aria-label="Voir le produit"><Eye className="h-4 w-4" /></Button></Link>
                    <Button variant="outline" size="sm" className="text-red-600 border-red-200 hover:bg-red-50" onClick={() => onDelete(p.id)} aria-label="Supprimer l'annonce">
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}

// ==================== MAIN PAGE ====================
export default function MarketplacePage() {
  const [produits, setProduits] = useState<Produit[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [activeTab, setActiveTab] = useState('acheter')

  const [commandes, setCommandes] = useState<Commande[]>([])
  const [commandesLoading, setCommandesLoading] = useState(false)
  const [selectedCommande, setSelectedCommande] = useState<Commande | null>(null)
  const [commandeDetailOpen, setCommandeDetailOpen] = useState(false)

  const [favoriteItems, setFavoriteItems] = useState<Favorite[]>([])
  const [favoriteIds, setFavoriteIds] = useState<Set<string>>(new Set())
  const [favoritesLoading, setFavoritesLoading] = useState(false)

  const [mesProduits, setMesProduits] = useState<Produit[]>([])
  const [mesProduitsLoading, setMesProduitsLoading] = useState(false)

  const fetchProduits = useCallback(async () => {
    setLoading(true)
    try {
      const res = await api.get('/marketplace/produits')
      if (res.data.success) setProduits(res.data.data || [])
    } catch (e) { console.error('Error fetching produits:', e) }
    finally { setLoading(false) }
  }, [])

  const fetchCommandes = useCallback(async () => {
    setCommandesLoading(true)
    try {
      const res = await api.get('/marketplace/commandes')
      if (res.data.success) setCommandes(res.data.data || [])
    } catch (e) { console.error('Error fetching commandes:', e) }
    finally { setCommandesLoading(false) }
  }, [])

  const fetchFavorites = useCallback(async () => {
    setFavoritesLoading(true)
    try {
      const res = await favoritesApi.getAll()
      if (res.data.success) {
        const favs = res.data.data || []
        setFavoriteItems(favs)
        setFavoriteIds(new Set(favs.map((f: Favorite) => f.produitId)))
      }
    } catch (e) { console.error('Error fetching favorites:', e) }
    finally { setFavoritesLoading(false) }
  }, [])

  const fetchMesProduits = useCallback(async () => {
    setMesProduitsLoading(true)
    try {
      const res = await api.get('/marketplace/produits/mes-produits')
      if (res.data.success) setMesProduits(res.data.data || [])
    } catch (e) { console.error('Error fetching mes produits:', e) }
    finally { setMesProduitsLoading(false) }
  }, [])

  useEffect(() => { fetchProduits() }, [fetchProduits])

  useEffect(() => {
    if (activeTab === 'commandes') fetchCommandes()
    if (activeTab === 'favoris') fetchFavorites()
    if (activeTab === 'annonces') fetchMesProduits()
  }, [activeTab, fetchCommandes, fetchFavorites, fetchMesProduits])

  useEffect(() => {
    const loadFavIds = async () => {
      try {
        const res = await favoritesApi.getAll()
        if (res.data.success) setFavoriteIds(new Set((res.data.data || []).map((f: Favorite) => f.produitId)))
      } catch { /* ignore - not logged in */ }
    }
    loadFavIds()
  }, [])

  const handleToggleFavorite = async (produitId: string) => {
    try {
      await favoritesApi.toggle(produitId)
      setFavoriteIds(prev => {
        const next = new Set(prev)
        if (next.has(produitId)) { next.delete(produitId); toast.success('Retiré des favoris') }
        else { next.add(produitId); toast.success('Ajouté aux favoris') }
        return next
      })
      if (activeTab === 'favoris') fetchFavorites()
    } catch { toast.error('Connectez-vous pour gérer vos favoris') }
  }

  const handleCancelCommande = async (id: string) => {
    try {
      await api.put(`/marketplace/commandes/${id}/cancel`)
      toast.success('Commande annulée')
      fetchCommandes()
    } catch { toast.error("Erreur lors de l'annulation") }
  }

  const handleDeleteProduit = async (id: string) => {
    if (!confirm('Supprimer cette annonce ?')) return
    try {
      await api.delete(`/marketplace/produits/${id}`)
      toast.success('Annonce supprimée')
      fetchMesProduits()
    } catch { toast.error('Erreur lors de la suppression') }
  }

  const filteredProduits = produits.filter(p => {
    const matchesSearch = p.nom.toLowerCase().includes(searchQuery.toLowerCase()) || p.description?.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = selectedCategory === 'all' || p.categorie === selectedCategory
    const isActive = p.est_actif !== undefined ? p.est_actif : p.actif !== undefined ? p.actif : true
    return matchesSearch && matchesCategory && isActive
  })

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <ShoppingCart className="h-6 w-6 text-green-600" />Marketplace
          </h1>
          <p className="text-gray-500">Achetez, vendez et échangez des produits agricoles entre producteurs et acheteurs</p>
        </div>
        <Link href="/marketplace/nouveau">
          <Button className="w-full sm:w-auto"><Plus className="h-4 w-4 mr-2" />Publier une annonce</Button>
        </Link>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-4 max-w-2xl">
          <TabsTrigger value="acheter" className="flex items-center gap-1.5">
            <ShoppingCart className="h-4 w-4" /><span className="hidden sm:inline">Acheter</span>
          </TabsTrigger>
          <TabsTrigger value="commandes" className="flex items-center gap-1.5">
            <ClipboardList className="h-4 w-4" /><span className="hidden sm:inline">Mes commandes</span>
          </TabsTrigger>
          <TabsTrigger value="favoris" className="flex items-center gap-1.5">
            <Heart className="h-4 w-4" /><span className="hidden sm:inline">Favoris</span>
          </TabsTrigger>
          <TabsTrigger value="annonces" className="flex items-center gap-1.5">
            <Store className="h-4 w-4" /><span className="hidden sm:inline">Mes annonces</span>
          </TabsTrigger>
        </TabsList>

        <TabsContent value="acheter" className="mt-6">
          <ProductGrid products={filteredProduits} loading={loading} viewMode={viewMode}
            searchQuery={searchQuery} setSearchQuery={setSearchQuery}
            selectedCategory={selectedCategory} setSelectedCategory={setSelectedCategory}
            setViewMode={setViewMode} favorites={favoriteIds} onToggleFavorite={handleToggleFavorite} />
        </TabsContent>

        <TabsContent value="commandes" className="mt-6">
          <MesCommandesTab commandes={commandes} loading={commandesLoading}
            onCancel={handleCancelCommande}
            onViewDetail={(c) => { setSelectedCommande(c); setCommandeDetailOpen(true) }} />
        </TabsContent>

        <TabsContent value="favoris" className="mt-6">
          <FavorisTab favorites={favoriteItems} loading={favoritesLoading} onRemove={handleToggleFavorite} />
        </TabsContent>

        <TabsContent value="annonces" className="mt-6">
          <MesAnnoncesTab produits={mesProduits} loading={mesProduitsLoading} onDelete={handleDeleteProduit} />
        </TabsContent>
      </Tabs>

      <Dialog open={commandeDetailOpen} onOpenChange={setCommandeDetailOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2"><ClipboardList className="h-5 w-5" />Détails de la commande</DialogTitle>
            <DialogDescription>Informations détaillées sur votre commande</DialogDescription>
          </DialogHeader>
          {selectedCommande && (
            <div className="space-y-4">
              <Badge className={cn("flex items-center gap-1 w-fit", statutColors[selectedCommande.statut] || 'bg-gray-100')}>
                {statutIcons[selectedCommande.statut]}{statutLabels[selectedCommande.statut] || selectedCommande.statut}
              </Badge>
              <div className="bg-gray-50 rounded-lg p-4 space-y-3">
                <h4 className="font-semibold">{selectedCommande.produit_nom || 'Produit'}</h4>
                <div className="grid grid-cols-2 gap-3 text-sm">
                  <div><span className="text-gray-500">Quantité</span><p className="font-medium">{selectedCommande.quantite}</p></div>
                  <div><span className="text-gray-500">Prix unitaire</span><p className="font-medium">{formatPrice(selectedCommande.prixUnitaire)}</p></div>
                  <div><span className="text-gray-500">Total</span><p className="font-bold text-green-600 text-lg">{formatPrice(selectedCommande.prixTotal)}</p></div>
                  <div><span className="text-gray-500">Date</span><p className="font-medium">{selectedCommande.createdAt ? new Date(selectedCommande.createdAt).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' }) : 'N/A'}</p></div>
                </div>
              </div>
              {selectedCommande.adresseLivraison && (
                <div className="flex items-start gap-2 text-sm">
                  <MapPin className="h-4 w-4 text-gray-400 mt-0.5" />
                  <div><span className="text-gray-500">Adresse</span><p>{selectedCommande.adresseLivraison}</p></div>
                </div>
              )}
              {selectedCommande.notes && (
                <div className="flex items-start gap-2 text-sm">
                  <MessageCircle className="h-4 w-4 text-gray-400 mt-0.5" />
                  <div><span className="text-gray-500">Notes</span><p>{selectedCommande.notes}</p></div>
                </div>
              )}
              <div className="border-t pt-3 space-y-2">
                {selectedCommande.vendeur_nom && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-gray-500">Vendeur</span>
                    <div className="flex items-center gap-2">
                      <span className="font-medium">{selectedCommande.vendeur_nom}</span>
                      {selectedCommande.vendeur_telephone && (
                        <a href={`tel:${selectedCommande.vendeur_telephone}`} className="text-green-600 hover:underline flex items-center gap-1">
                          <Phone className="h-3.5 w-3.5" />{selectedCommande.vendeur_telephone}
                        </a>
                      )}
                    </div>
                  </div>
                )}
                <div className="flex items-center justify-between text-sm">
                  <span className="text-gray-500">N° commande</span>
                  <span className="font-mono text-xs">{selectedCommande.id.slice(0, 8).toUpperCase()}</span>
                </div>
              </div>
            </div>
          )}
          <DialogFooter>
            {selectedCommande?.statut === 'PENDING' && (
              <Button variant="outline" className="text-red-600 border-red-200 hover:bg-red-50"
                onClick={() => { handleCancelCommande(selectedCommande.id); setCommandeDetailOpen(false) }}>
                <XCircle className="h-4 w-4 mr-1" /> Annuler
              </Button>
            )}
            <Button variant="outline" onClick={() => setCommandeDetailOpen(false)}>Fermer</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

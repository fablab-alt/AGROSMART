'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardHeader, CardTitle, CardContent, CardDescription } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Package, Plus, Search, ArrowUpDown, AlertTriangle, TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { stocksApi } from '@/lib/api'

interface Stock {
  id: string
  nom: string
  categorie: string
  quantite: number
  unite?: string
  seuilAlerte?: number
  dateExpiration?: string
  parcelleId?: string
  parcelle?: { nom: string }
  createdAt: string
}

interface StockStats {
  total: number
  alertes: number
  categories: Record<string, number>
}

export default function StocksPage() {
  const [stocks, setStocks] = useState<Stock[]>([])
  const [stats, setStats] = useState<StockStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [showAddForm, setShowAddForm] = useState(false)
  const [newStock, setNewStock] = useState({ nom: '', categorie: 'INTRANT', quantite: 0, seuilAlerte: 10 })
  const [showMouvement, setShowMouvement] = useState<string | null>(null)
  const [mouvement, setMouvement] = useState({ typeMouvement: 'ENTREE', quantite: 0, motif: '' })

  const fetchData = useCallback(async () => {
    try {
      setLoading(true)
      const [stocksRes, statsRes] = await Promise.all([
        stocksApi.getAll(),
        stocksApi.getStats()
      ])
      setStocks(stocksRes.data?.data || [])
      setStats(statsRes.data?.data || null)
    } catch (error) {
      console.error('Erreur chargement stocks:', error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchData() }, [fetchData])

  const handleAddStock = async () => {
    try {
      await stocksApi.create(newStock)
      setShowAddForm(false)
      setNewStock({ nom: '', categorie: 'INTRANT', quantite: 0, seuilAlerte: 10 })
      fetchData()
    } catch (error) {
      console.error('Erreur création stock:', error)
    }
  }

  const handleMouvement = async (stockId: string) => {
    try {
      await stocksApi.addMouvement(stockId, mouvement)
      setShowMouvement(null)
      setMouvement({ typeMouvement: 'ENTREE', quantite: 0, motif: '' })
      fetchData()
    } catch (error) {
      console.error('Erreur mouvement:', error)
    }
  }

  const getStockStatus = (stock: Stock) => {
    if (stock.seuilAlerte && stock.quantite <= stock.seuilAlerte) return { color: 'bg-red-100 text-red-700', label: 'Critique' }
    if (stock.seuilAlerte && stock.quantite <= stock.seuilAlerte * 2) return { color: 'bg-orange-100 text-orange-700', label: 'Bas' }
    return { color: 'bg-green-100 text-green-700', label: 'OK' }
  }

  const filteredStocks = stocks.filter(s =>
    s.nom.toLowerCase().includes(search.toLowerCase()) ||
    s.categorie?.toLowerCase().includes(search.toLowerCase())
  )

  const categories = ['INTRANT', 'RECOLTE', 'EQUIPEMENT', 'SEMENCE', 'ENGRAIS', 'PESTICIDE']

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Gestion des Stocks</h1>
          <p className="text-gray-500 mt-1">Suivez vos intrants, récoltes et équipements</p>
        </div>
        <Button onClick={() => setShowAddForm(!showAddForm)} className="bg-green-600 hover:bg-green-700">
          <Plus className="h-4 w-4 mr-2" /> Nouveau stock
        </Button>
      </div>

      {/* Stats */}
      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <Card>
            <CardContent className="p-4 flex items-center gap-3">
              <div className="h-10 w-10 rounded-lg bg-green-100 flex items-center justify-center">
                <Package className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Total stocks</p>
                <p className="text-xl font-bold">{stats.total}</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 flex items-center gap-3">
              <div className="h-10 w-10 rounded-lg bg-red-100 flex items-center justify-center">
                <AlertTriangle className="h-5 w-5 text-red-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Alertes stock bas</p>
                <p className="text-xl font-bold text-red-600">{stats.alertes}</p>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 flex items-center gap-3">
              <div className="h-10 w-10 rounded-lg bg-blue-100 flex items-center justify-center">
                <ArrowUpDown className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Catégories</p>
                <p className="text-xl font-bold">{Object.keys(stats.categories || {}).length}</p>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Formulaire ajout */}
      {showAddForm && (
        <Card>
          <CardHeader><CardTitle>Ajouter un stock</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input placeholder="Nom du stock" value={newStock.nom} onChange={e => setNewStock({ ...newStock, nom: e.target.value })} />
              <select title="Catégorie" className="border rounded-md px-3 py-2" value={newStock.categorie} onChange={e => setNewStock({ ...newStock, categorie: e.target.value })}>
                {categories.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
              <Input type="number" placeholder="Quantité" value={newStock.quantite} onChange={e => setNewStock({ ...newStock, quantite: parseInt(e.target.value) || 0 })} />
              <Input type="number" placeholder="Seuil d'alerte" value={newStock.seuilAlerte} onChange={e => setNewStock({ ...newStock, seuilAlerte: parseInt(e.target.value) || 0 })} />
            </div>
            <div className="flex gap-2">
              <Button onClick={handleAddStock} className="bg-green-600 hover:bg-green-700">Enregistrer</Button>
              <Button variant="ghost" onClick={() => setShowAddForm(false)}>Annuler</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recherche */}
      <div className="relative">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
        <Input placeholder="Rechercher un stock..." className="pl-10" value={search} onChange={e => setSearch(e.target.value)} />
      </div>

      {/* Liste des stocks */}
      {loading ? (
        <div className="text-center py-12 text-gray-500">Chargement...</div>
      ) : filteredStocks.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Package className="h-12 w-12 text-gray-300 mx-auto mb-4" />
            <p className="text-gray-500">Aucun stock enregistré</p>
            <Button onClick={() => setShowAddForm(true)} className="mt-4 bg-green-600 hover:bg-green-700">
              <Plus className="h-4 w-4 mr-2" /> Ajouter votre premier stock
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4">
          {filteredStocks.map(stock => {
            const status = getStockStatus(stock)
            return (
              <Card key={stock.id} className="hover:shadow-md transition-shadow">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className="h-10 w-10 rounded-lg bg-gray-100 dark:bg-gray-700 flex items-center justify-center">
                        <Package className="h-5 w-5 text-gray-500" />
                      </div>
                      <div>
                        <h3 className="font-semibold">{stock.nom}</h3>
                        <p className="text-sm text-gray-500">{stock.categorie} {stock.parcelle ? `• ${stock.parcelle.nom}` : ''}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="text-right">
                        <p className="text-lg font-bold">{stock.quantite} {stock.unite || 'unités'}</p>
                        {stock.seuilAlerte && <p className="text-xs text-gray-400">Seuil: {stock.seuilAlerte}</p>}
                      </div>
                      <Badge className={status.color}>{status.label}</Badge>
                      <Button size="sm" variant="outline" onClick={() => setShowMouvement(showMouvement === stock.id ? null : stock.id)}>
                        <ArrowUpDown className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>

                  {/* Formulaire mouvement */}
                  {showMouvement === stock.id && (
                    <div className="mt-4 pt-4 border-t space-y-3">
                      <CardDescription>Enregistrer un mouvement</CardDescription>
                      <div className="flex gap-3 items-end">
                        <div className="flex gap-2">
                          <Button size="sm" variant={mouvement.typeMouvement === 'ENTREE' ? 'default' : 'outline'} onClick={() => setMouvement({ ...mouvement, typeMouvement: 'ENTREE' })}>
                            <TrendingUp className="h-3 w-3 mr-1" /> Entrée
                          </Button>
                          <Button size="sm" variant={mouvement.typeMouvement === 'SORTIE' ? 'default' : 'outline'} onClick={() => setMouvement({ ...mouvement, typeMouvement: 'SORTIE' })}>
                            <TrendingDown className="h-3 w-3 mr-1" /> Sortie
                          </Button>
                          <Button size="sm" variant={mouvement.typeMouvement === 'AJUSTEMENT' ? 'default' : 'outline'} onClick={() => setMouvement({ ...mouvement, typeMouvement: 'AJUSTEMENT' })}>
                            <Minus className="h-3 w-3 mr-1" /> Ajustement
                          </Button>
                        </div>
                        <Input type="number" placeholder="Qté" className="w-24" value={mouvement.quantite} onChange={e => setMouvement({ ...mouvement, quantite: parseInt(e.target.value) || 0 })} />
                        <Input placeholder="Motif" className="flex-1" value={mouvement.motif} onChange={e => setMouvement({ ...mouvement, motif: e.target.value })} />
                        <Button size="sm" className="bg-green-600 hover:bg-green-700" onClick={() => handleMouvement(stock.id)}>Valider</Button>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}
    </div>
  )
}

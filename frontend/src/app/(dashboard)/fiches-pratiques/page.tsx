'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { BookOpen, Search, FileText, Download, Filter } from 'lucide-react'
import { fichesPratiquesApi } from '@/lib/api'

interface FichePratique {
  id: string
  titre: string
  categorie?: string
  contenu: string
  fichierUrl?: string
  createdAt: string
}

const CATEGORIE_COLORS: Record<string, string> = {
  'Cultures': 'bg-green-100 text-green-700',
  'Irrigation': 'bg-blue-100 text-blue-700',
  'Fertilisation': 'bg-amber-100 text-amber-700',
  'Protection': 'bg-red-100 text-red-700',
  'Récolte': 'bg-purple-100 text-purple-700',
  'Sol': 'bg-orange-100 text-orange-700',
  'Élevage': 'bg-teal-100 text-teal-700',
}

export default function FichesPratiquesPage() {
  const [fiches, setFiches] = useState<FichePratique[]>([])
  const [categories, setCategories] = useState<string[]>([])
  const [selectedCategorie, setSelectedCategorie] = useState<string>('')
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [selectedFiche, setSelectedFiche] = useState<FichePratique | null>(null)
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  const fetchData = useCallback(async () => {
    try {
      setLoading(true)
      const params: Record<string, unknown> = { page, limit: 12 }
      if (selectedCategorie) params.categorie = selectedCategorie

      let res
      if (search.trim()) {
        res = await fichesPratiquesApi.search({ q: search, categorie: selectedCategorie || undefined })
      } else {
        res = await fichesPratiquesApi.getAll(params as { page?: number; limit?: number; categorie?: string })
      }

      setFiches(res.data?.data || [])
      if (res.data?.pagination) {
        setTotalPages(res.data.pagination.pages || 1)
      }
    } catch (error) {
      console.error('Erreur chargement fiches:', error)
    } finally {
      setLoading(false)
    }
  }, [page, selectedCategorie, search])

  const fetchCategories = useCallback(async () => {
    try {
      const res = await fichesPratiquesApi.getCategories()
      setCategories(res.data?.data || [])
    } catch (error) {
      console.error('Erreur chargement catégories:', error)
    }
  }, [])

  useEffect(() => { fetchCategories() }, [fetchCategories])
  useEffect(() => { fetchData() }, [fetchData])

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
          <BookOpen className="h-7 w-7 text-green-600" />
          Bibliothèque Agricole
        </h1>
        <p className="text-gray-500 mt-1">Fiches pratiques et guides agricoles classés par culture</p>
      </div>

      {/* Filtres */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input placeholder="Rechercher une fiche..." className="pl-10" value={search} onChange={e => { setSearch(e.target.value); setPage(1) }} />
        </div>
        <div className="flex gap-2 flex-wrap">
          <Button variant={selectedCategorie === '' ? 'default' : 'outline'} size="sm" onClick={() => { setSelectedCategorie(''); setPage(1) }}>
            <Filter className="h-3 w-3 mr-1" /> Toutes
          </Button>
          {categories.map(cat => (
            <Button key={cat} variant={selectedCategorie === cat ? 'default' : 'outline'} size="sm" onClick={() => { setSelectedCategorie(cat); setPage(1) }}>
              {cat}
            </Button>
          ))}
        </div>
      </div>

      {/* Fiche détail */}
      {selectedFiche ? (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-xl">{selectedFiche.titre}</CardTitle>
                {selectedFiche.categorie && (
                  <Badge className={CATEGORIE_COLORS[selectedFiche.categorie] || 'bg-gray-100 text-gray-700'} variant="secondary">
                    {selectedFiche.categorie}
                  </Badge>
                )}
              </div>
              <div className="flex gap-2">
                {selectedFiche.fichierUrl && (
                  <a href={selectedFiche.fichierUrl} target="_blank" rel="noopener noreferrer">
                    <Button size="sm" variant="outline"><Download className="h-4 w-4 mr-1" /> Télécharger PDF</Button>
                  </a>
                )}
                <Button variant="ghost" size="sm" onClick={() => setSelectedFiche(null)}>Retour</Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="prose dark:prose-invert max-w-none whitespace-pre-wrap">
              {selectedFiche.contenu}
            </div>
          </CardContent>
        </Card>
      ) : (
        <>
          {/* Grille de fiches */}
          {loading ? (
            <div className="text-center py-12 text-gray-500">Chargement...</div>
          ) : fiches.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <BookOpen className="h-12 w-12 text-gray-300 mx-auto mb-4" />
                <p className="text-gray-500">Aucune fiche pratique disponible</p>
                <p className="text-sm text-gray-400 mt-1">Les fiches pratiques seront ajoutées par les agronomes et conseillers</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {fiches.map(fiche => (
                <Card key={fiche.id} className="hover:shadow-md transition-shadow cursor-pointer" onClick={() => setSelectedFiche(fiche)}>
                  <CardContent className="p-4">
                    <div className="flex items-start gap-3">
                      <div className="h-10 w-10 rounded-lg bg-green-100 flex items-center justify-center shrink-0">
                        <FileText className="h-5 w-5 text-green-600" />
                      </div>
                      <div className="flex-1 min-w-0">
                        <h3 className="font-semibold text-sm truncate">{fiche.titre}</h3>
                        {fiche.categorie && (
                          <Badge variant="secondary" className={`mt-1 text-xs ${CATEGORIE_COLORS[fiche.categorie] || 'bg-gray-100 text-gray-700'}`}>
                            {fiche.categorie}
                          </Badge>
                        )}
                        <p className="text-xs text-gray-500 mt-2 line-clamp-3">{fiche.contenu}</p>
                        <div className="flex items-center gap-2 mt-2">
                          <span className="text-xs text-gray-400">{fiche.createdAt ? new Date(fiche.createdAt).toLocaleDateString('fr-FR') : ''}</span>
                          {fiche.fichierUrl && <Badge variant="outline" className="text-xs"><Download className="h-3 w-3 mr-1" /> PDF</Badge>}
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-center gap-2">
              <Button variant="outline" size="sm" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>Précédent</Button>
              <span className="flex items-center text-sm text-gray-500">Page {page} / {totalPages}</span>
              <Button variant="outline" size="sm" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>Suivant</Button>
            </div>
          )}
        </>
      )}
    </div>
  )
}

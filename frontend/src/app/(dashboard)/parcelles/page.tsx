'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import {
  MapPin,
  Plus,
  Search,
  Filter,
  MoreVertical,
  Eye,
  Edit,
  Trash2,
  Thermometer,
  Droplets,
  Leaf,
  ChevronRight,
} from 'lucide-react'
import {
  Card,
  CardContent,
  Button,
  Input,
  Badge,
  Skeleton,
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '@/components/ui'
import { useParcellesStore, Parcelle } from '@/lib/store'
import api from '@/lib/api'
import { logger } from '@/lib/logger'
import { useErrorHandler } from '@/hooks/useErrorHandler'
import toast from 'react-hot-toast'

export default function ParcellesPage() {
  const { parcelles, setParcelles, removeParcelle } = useParcellesStore()
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [selectedParcelle, setSelectedParcelle] = useState<Parcelle | null>(null)
  const [deleting, setDeleting] = useState(false)
  const { handleError } = useErrorHandler()

  useEffect(() => {
    const fetchParcelles = async () => {
      setLoading(true)
      try {
        logger.info('Fetching parcelles')
        const response = await api.get('/parcelles')
        if (response.data.success) {
          setParcelles(response.data.data)
          logger.debug('Parcelles loaded', { count: response.data.data.length })
        }
      } catch (error) {
        handleError(error, 'Failed to fetch parcelles', {
          toastMessage: 'Erreur lors du chargement des parcelles'
        })
      } finally {
        setLoading(false)
      }
    }

    fetchParcelles()
  }, [setParcelles, handleError])

  const handleDelete = async () => {
    if (!selectedParcelle) return

    setDeleting(true)
    try {
      logger.info('Deleting parcelle', { parcelleId: selectedParcelle.id })
      await api.delete(`/parcelles/${selectedParcelle.id}`)
      removeParcelle(selectedParcelle.id)
      toast.success('Parcelle supprimée avec succès')
      setDeleteDialogOpen(false)
      setSelectedParcelle(null)
    } catch (error) {
      handleError(error, 'Failed to delete parcelle', {
        toastMessage: 'Erreur lors de la suppression'
      })
    } finally {
      setDeleting(false)
    }
  }

  const openDeleteDialog = (parcelle: Parcelle) => {
    setSelectedParcelle(parcelle)
    setDeleteDialogOpen(true)
  }

  const filteredParcelles = parcelles.filter(p =>
    p.nom.toLowerCase().includes(searchQuery.toLowerCase()) ||
    p.type_sol?.toLowerCase().includes(searchQuery.toLowerCase())
  )

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'success'
      case 'inactive':
        return 'warning'
      default:
        return 'secondary'
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mes Parcelles</h1>
          <p className="text-gray-500">
            Gérez vos parcelles agricoles et suivez leur état
          </p>
        </div>
        {parcelles.length > 0 && (
          <Link href="/parcelles/new">
            <Button className="w-full sm:w-auto">
              <Plus className="h-4 w-4 mr-2" />
              Nouvelle parcelle
            </Button>
          </Link>
        )}
      </div>

      {/* Search and filter */}
      <div className="flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Rechercher une parcelle..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10"
          />
        </div>
        <Button variant="outline" className="w-full sm:w-auto">
          <Filter className="h-4 w-4 mr-2" />
          Filtrer
        </Button>
      </div>

      {/* Stats cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center">
              <MapPin className="h-5 w-5 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{parcelles.length}</p>
              <p className="text-sm text-gray-500">Parcelles</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
              <Thermometer className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {parcelles.reduce((acc, p) => acc + (p.nb_stations || 0), 0)}
              </p>
              <p className="text-sm text-gray-500">Stations</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-orange-100 flex items-center justify-center">
              <Leaf className="h-5 w-5 text-orange-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {parcelles.reduce((acc, p) => acc + (p.nb_plantations || 0), 0)}
              </p>
              <p className="text-sm text-gray-500">Plantations</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-purple-100 flex items-center justify-center">
              <Droplets className="h-5 w-5 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                {parcelles.reduce((acc, p) => acc + (p.superficie_hectares || 0), 0).toFixed(1)}
              </p>
              <p className="text-sm text-gray-500">Hectares</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Parcelles list */}
      <div className="grid gap-4">
        {loading ? (
          <>
            <Skeleton className="h-32 w-full" />
            <Skeleton className="h-32 w-full" />
            <Skeleton className="h-32 w-full" />
          </>
        ) : filteredParcelles.length === 0 ? (
          <Card>
            <CardContent className="py-12 text-center">
              <MapPin className="h-12 w-12 mx-auto text-gray-300 mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {searchQuery ? 'Aucune parcelle trouvée' : 'Aucune parcelle'}
              </h3>
              <p className="text-gray-500 mb-4">
                {searchQuery
                  ? 'Essayez avec d\'autres termes de recherche'
                  : 'Commencez par créer votre première parcelle'
                }
              </p>
              {!searchQuery && (
                <Link href="/parcelles/new">
                  <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    Créer une parcelle
                  </Button>
                </Link>
              )}
            </CardContent>
          </Card>
        ) : (
          filteredParcelles.map((parcelle) => (
            <Card key={parcelle.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <Link
                        href={`/parcelles/${parcelle.id}`}
                        className="text-lg font-semibold text-gray-900 hover:text-green-600"
                      >
                        {parcelle.nom}
                      </Link>
                      <Badge variant={getStatusColor(parcelle.status) as 'success' | 'warning' | 'secondary'}>
                        {parcelle.status === 'active' ? 'Active' : 'Inactive'}
                      </Badge>
                    </div>

                    <p className="text-sm text-gray-500 mb-3">
                      {parcelle.description || 'Pas de description'}
                    </p>

                    <div className="flex flex-wrap gap-4 text-sm">
                      <div className="flex items-center gap-1 text-gray-600">
                        <MapPin className="h-4 w-4" />
                        {parcelle.latitude && parcelle.longitude
                          ? `${Number(parcelle.latitude).toFixed(4)}, ${Number(parcelle.longitude).toFixed(4)}`
                          : 'Position non définie'
                        }
                      </div>
                      {parcelle.superficie_hectares && (
                        <div className="flex items-center gap-1 text-gray-600">
                          <Leaf className="h-4 w-4" />
                          {parcelle.superficie_hectares} ha
                        </div>
                      )}
                      {parcelle.type_sol && (
                        <div className="flex items-center gap-1 text-gray-600">
                          <Droplets className="h-4 w-4" />
                          {parcelle.type_sol}
                        </div>
                      )}
                      {parcelle.nb_stations !== undefined && parcelle.nb_stations > 0 && (
                        <div className="flex items-center gap-1 text-gray-600">
                          <Thermometer className="h-4 w-4" />
                          {parcelle.nb_stations} station{parcelle.nb_stations > 1 ? 's' : ''}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <Link href={`/parcelles/${parcelle.id}`}>
                      <Button variant="ghost" size="sm">
                        <ChevronRight className="h-4 w-4" />
                      </Button>
                    </Link>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm">
                          <MoreVertical className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem asChild>
                          <Link href={`/parcelles/${parcelle.id}`} className="flex items-center gap-2 cursor-pointer">
                            <Eye className="h-4 w-4" />
                            Voir détails
                          </Link>
                        </DropdownMenuItem>
                        <DropdownMenuItem asChild>
                          <Link href={`/parcelles/${parcelle.id}/edit`} className="flex items-center gap-2 cursor-pointer">
                            <Edit className="h-4 w-4" />
                            Modifier
                          </Link>
                        </DropdownMenuItem>
                        <DropdownMenuItem
                          onClick={() => openDeleteDialog(parcelle)}
                          className="flex items-center gap-2 text-red-600 focus:text-red-600 focus:bg-red-50"
                        >
                          <Trash2 className="h-4 w-4" />
                          Supprimer
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))
        )}
      </div>

      {/* Delete confirmation dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Supprimer la parcelle</DialogTitle>
            <DialogDescription>
              Êtes-vous sûr de vouloir supprimer la parcelle &quot;{selectedParcelle?.nom}&quot;?
              Cette action est irréversible et supprimera toutes les données associées.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setDeleteDialogOpen(false)}
              disabled={deleting}
            >
              Annuler
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={deleting}
            >
              {deleting ? 'Suppression...' : 'Supprimer'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

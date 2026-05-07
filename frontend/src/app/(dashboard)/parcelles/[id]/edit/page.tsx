'use client'

import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Link from 'next/link'
import {
  ArrowLeft,
  MapPin,
  Leaf,
  Droplets,
  Save,
  Loader2,
} from 'lucide-react'
import { 
  Card, 
  CardContent, 
  CardHeader,
  CardTitle,
  CardDescription,
  Button, 
  Input,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Skeleton,
} from '@/components/ui'
import { useParcellesStore, Parcelle } from '@/lib/store'
import api from '@/lib/api'
import toast from 'react-hot-toast'

const typesSol = [
  { value: 'argileux', label: 'Argileux' },
  { value: 'sablonneux', label: 'Sablonneux' },
  { value: 'limoneux', label: 'Limoneux' },
  { value: 'limono_argileux', label: 'Limono-argileux' },
  { value: 'argilo_sableux', label: 'Argilo-sableux' },
]

const statusOptions = [
  { value: 'active', label: 'Active' },
  { value: 'en_repos', label: 'En repos' },
  { value: 'preparee', label: 'Préparée' },
  { value: 'ensemencee', label: 'Ensemencée' },
  { value: 'en_croissance', label: 'En croissance' },
  { value: 'recolte', label: 'Récolte' },
]

export default function EditParcellePage() {
  const router = useRouter()
  const params = useParams()
  const parcelleId = params.id as string
  const { updateParcelle } = useParcellesStore()
  
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [parcelle, setParcelle] = useState<Parcelle | null>(null)
  const [formData, setFormData] = useState({
    nom: '',
    description: '',
    latitude: '',
    longitude: '',
    superficie_hectares: '',
    type_sol: '',
    status: 'active',
  })

  useEffect(() => {
    const fetchParcelle = async () => {
      try {
        const response = await api.get(`/parcelles/${parcelleId}`)
        if (response.data.success) {
          const data = response.data.data
          setParcelle(data)
          setFormData({
            nom: data.nom || '',
            description: data.description || '',
            latitude: data.latitude?.toString() || '',
            longitude: data.longitude?.toString() || '',
            superficie_hectares: data.superficie_hectares?.toString() || '',
            type_sol: data.type_sol || '',
            status: data.status || 'active',
          })
        }
      } catch (error) {
        console.error('Error fetching parcelle:', error)
        toast.error('Erreur lors du chargement de la parcelle')
        router.push('/parcelles')
      } finally {
        setLoading(false)
      }
    }

    if (parcelleId) {
      fetchParcelle()
    }
  }, [parcelleId, router])

  const handleChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!formData.nom.trim()) {
      toast.error('Le nom de la parcelle est requis')
      return
    }

    setSaving(true)
    try {
      const payload = {
        nom: formData.nom.trim(),
        description: formData.description.trim() || undefined,
        latitude: formData.latitude ? parseFloat(formData.latitude) : undefined,
        longitude: formData.longitude ? parseFloat(formData.longitude) : undefined,
        superficie_hectares: formData.superficie_hectares ? parseFloat(formData.superficie_hectares) : undefined,
        type_sol: formData.type_sol || undefined,
        status: formData.status,
      }

      const response = await api.put(`/parcelles/${parcelleId}`, payload)
      
      if (response.data.success) {
        updateParcelle(parcelleId, response.data.data)
        toast.success('Parcelle mise à jour avec succès!')
        router.push('/parcelles')
      } else {
        toast.error(response.data.message || 'Erreur lors de la mise à jour')
      }
    } catch (error: unknown) {
      console.error('Error updating parcelle:', error)
      const err = error as { response?: { data?: { message?: string } } }
      toast.error(err.response?.data?.message || 'Erreur lors de la mise à jour de la parcelle')
    } finally {
      setSaving(false)
    }
  }

  const getCurrentLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setFormData(prev => ({
            ...prev,
            latitude: position.coords.latitude.toFixed(6),
            longitude: position.coords.longitude.toFixed(6),
          }))
          toast.success('Position récupérée!')
        },
        (error) => {
          console.error('Geolocation error:', error)
          toast.error('Impossible de récupérer votre position')
        }
      )
    } else {
      toast.error('La géolocalisation n\'est pas supportée par votre navigateur')
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-4">
          <Skeleton className="h-10 w-24" />
          <div>
            <Skeleton className="h-8 w-48 mb-2" />
            <Skeleton className="h-4 w-64" />
          </div>
        </div>
        <div className="grid gap-6 lg:grid-cols-2">
          <Skeleton className="h-96" />
          <Skeleton className="h-96" />
        </div>
      </div>
    )
  }

  if (!parcelle) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold text-gray-900 mb-2">Parcelle non trouvée</h2>
        <p className="text-gray-500 mb-4">Cette parcelle n&apos;existe pas ou a été supprimée.</p>
        <Link href="/parcelles">
          <Button>Retour aux parcelles</Button>
        </Link>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/parcelles">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Modifier la Parcelle</h1>
          <p className="text-gray-500">Modifiez les informations de &quot;{parcelle.nom}&quot;</p>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit}>
        <div className="grid gap-6 lg:grid-cols-2">
          {/* Informations générales */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Leaf className="h-5 w-5 text-green-600" />
                Informations générales
              </CardTitle>
              <CardDescription>
                Détails de base de votre parcelle
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Nom de la parcelle *
                </label>
                <Input
                  placeholder="Ex: Parcelle Cacao Nord"
                  value={formData.nom}
                  onChange={(e) => handleChange('nom', e.target.value)}
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Description
                </label>
                <textarea
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 focus:border-transparent"
                  rows={3}
                  placeholder="Description de la parcelle..."
                  value={formData.description}
                  onChange={(e) => handleChange('description', e.target.value)}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Statut
                </label>
                <Select 
                  value={formData.status} 
                  onValueChange={(value) => handleChange('status', value)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Sélectionner un statut" />
                  </SelectTrigger>
                  <SelectContent>
                    {statusOptions.map(option => (
                      <SelectItem key={option.value} value={option.value}>
                        {option.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Superficie (hectares)
                </label>
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="Ex: 2.5"
                  value={formData.superficie_hectares}
                  onChange={(e) => handleChange('superficie_hectares', e.target.value)}
                />
              </div>
            </CardContent>
          </Card>

          {/* Localisation et Sol */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="h-5 w-5 text-blue-600" />
                Localisation et Sol
              </CardTitle>
              <CardDescription>
                Position GPS et type de sol
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Latitude
                  </label>
                  <Input
                    type="number"
                    step="0.000001"
                    placeholder="Ex: 5.3599"
                    value={formData.latitude}
                    onChange={(e) => handleChange('latitude', e.target.value)}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Longitude
                  </label>
                  <Input
                    type="number"
                    step="0.000001"
                    placeholder="Ex: -4.0083"
                    value={formData.longitude}
                    onChange={(e) => handleChange('longitude', e.target.value)}
                  />
                </div>
              </div>

              <Button
                type="button"
                variant="outline"
                className="w-full"
                onClick={getCurrentLocation}
              >
                <MapPin className="h-4 w-4 mr-2" />
                Utiliser ma position actuelle
              </Button>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Type de sol
                </label>
                <Select 
                  value={formData.type_sol} 
                  onValueChange={(value) => handleChange('type_sol', value)}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Sélectionner un type de sol" />
                  </SelectTrigger>
                  <SelectContent>
                    {typesSol.map(type => (
                      <SelectItem key={type.value} value={type.value}>
                        <div className="flex items-center gap-2">
                          <Droplets className="h-4 w-4 text-gray-400" />
                          {type.label}
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Carte placeholder */}
              <div className="h-48 bg-gray-100 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300">
                <div className="text-center text-gray-500">
                  <MapPin className="h-8 w-8 mx-auto mb-2" />
                  <p className="text-sm">Carte de localisation</p>
                  <p className="text-xs">(Bientôt disponible)</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Actions */}
        <div className="flex justify-end gap-4 mt-6">
          <Link href="/parcelles">
            <Button type="button" variant="outline">
              Annuler
            </Button>
          </Link>
          <Button type="submit" disabled={saving}>
            {saving ? (
              <>
                <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                Enregistrement...
              </>
            ) : (
              <>
                <Save className="h-4 w-4 mr-2" />
                Enregistrer les modifications
              </>
            )}
          </Button>
        </div>
      </form>
    </div>
  )
}

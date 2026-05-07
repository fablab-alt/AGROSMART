'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import {
  GraduationCap,
  Play,
  FileText,
  Book,
  Search,
  Filter,
  Clock,
  ChevronRight,
  CheckCircle,
} from 'lucide-react'
import { 
  Card, 
  CardContent, 
  Button, 
  Input, 
  Badge, 
  Skeleton,
  Progress,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Tabs,
  TabsList,
  TabsTrigger,
  TabsContent,
} from '@/components/ui'
import { cn } from '@/lib/utils'
import api from '@/lib/api'
import toast from 'react-hot-toast'

interface Formation {
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

const categories = [
  { value: 'all', label: 'Toutes les catégories' },
  { value: 'cultures', label: 'Cultures' },
  { value: 'irrigation', label: 'Irrigation' },
  { value: 'maladies', label: 'Maladies' },
  { value: 'sols', label: 'Sols' },
  { value: 'business', label: 'Gestion' },
  { value: 'technologie', label: 'Technologie' },
]

export default function FormationsPage() {
  const [formations, setFormations] = useState<Formation[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('all')
  const [selectedType, setSelectedType] = useState<'all' | 'video' | 'pdf' | 'article'>('all')

  const fetchFormations = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get('/formations')
      if (response.data.success) {
        setFormations(response.data.data || [])
      }
    } catch (error) {
      console.error('Error fetching formations:', error)
      toast.error('Erreur lors du chargement des formations')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchFormations()
  }, [fetchFormations])

  const filteredFormations = formations.filter(f => {
    const matchesSearch = f.titre.toLowerCase().includes(searchQuery.toLowerCase()) ||
      f.description?.toLowerCase().includes(searchQuery.toLowerCase())
    const matchesCategory = selectedCategory === 'all' || f.categorie === selectedCategory
    const matchesType = selectedType === 'all' || f.type === selectedType
    return matchesSearch && matchesCategory && matchesType
  })

  const completedCount = formations.filter(f => f.complete).length
  const inProgressCount = formations.filter(f => f.progression && f.progression > 0 && !f.complete).length
  const totalProgress = formations.length > 0 
    ? Math.round(formations.reduce((acc, f) => acc + (f.progression || 0), 0) / formations.length)
    : 0

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'video':
        return <Play className="h-5 w-5" />
      case 'pdf':
        return <FileText className="h-5 w-5" />
      case 'article':
        return <Book className="h-5 w-5" />
      default:
        return <Book className="h-5 w-5" />
    }
  }

  const getTypeBadgeVariant = (type: string) => {
    switch (type) {
      case 'video':
        return 'info'
      case 'pdf':
        return 'warning'
      case 'article':
        return 'success'
      default:
        return 'secondary'
    }
  }

  const formatDuration = (minutes?: number) => {
    if (!minutes) return ''
    if (minutes < 60) return `${minutes} min`
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    return mins > 0 ? `${hours}h ${mins}min` : `${hours}h`
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <GraduationCap className="h-6 w-6 text-green-600" />
            Formations
          </h1>
          <p className="text-gray-500">
            Apprenez les meilleures pratiques agricoles
          </p>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-purple-100 flex items-center justify-center">
              <GraduationCap className="h-5 w-5 text-purple-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{formations.length}</p>
              <p className="text-sm text-gray-500">Formations</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-green-100 flex items-center justify-center">
              <CheckCircle className="h-5 w-5 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{completedCount}</p>
              <p className="text-sm text-gray-500">Complétées</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center">
              <Play className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{inProgressCount}</p>
              <p className="text-sm text-gray-500">En cours</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm text-gray-500">Progression globale</span>
              <span className="text-sm font-medium">{totalProgress}%</span>
            </div>
            <Progress value={totalProgress} className="h-2" />
          </CardContent>
        </Card>
      </div>

      {/* Tabs for different types */}
      <Tabs value={selectedType} onValueChange={(v) => setSelectedType(v as typeof selectedType)}>
        <div className="flex flex-col md:flex-row gap-4 items-start md:items-center justify-between">
          <TabsList>
            <TabsTrigger value="all">Tout</TabsTrigger>
            <TabsTrigger value="video">Vidéos</TabsTrigger>
            <TabsTrigger value="pdf">Documents</TabsTrigger>
            <TabsTrigger value="article">Articles</TabsTrigger>
          </TabsList>

          <div className="flex gap-2 w-full md:w-auto">
            <div className="relative flex-1 md:w-64">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <Input
                placeholder="Rechercher..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={selectedCategory} onValueChange={setSelectedCategory}>
              <SelectTrigger className="w-37.5">
                <Filter className="h-4 w-4 mr-2" />
                <SelectValue placeholder="Catégorie" />
              </SelectTrigger>
              <SelectContent>
                {categories.map((cat) => (
                  <SelectItem key={cat.value} value={cat.value}>
                    {cat.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </div>

        <TabsContent value={selectedType} className="mt-6">
          {/* Formations grid */}
          {loading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              <Skeleton className="h-64 w-full" />
              <Skeleton className="h-64 w-full" />
              <Skeleton className="h-64 w-full" />
            </div>
          ) : filteredFormations.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center">
                <GraduationCap className="h-12 w-12 mx-auto text-gray-300 mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Aucune formation trouvée
                </h3>
                <p className="text-gray-500">
                  Essayez avec d&apos;autres filtres ou termes de recherche
                </p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {filteredFormations.map((formation) => (
                <Card key={formation.id} className="hover:shadow-md transition-shadow overflow-hidden">
                  {/* Formation thumbnail placeholder */}
                  <div className={cn(
                    "h-32 flex items-center justify-center",
                    formation.type === 'video' ? 'bg-blue-50' : 
                    formation.type === 'pdf' ? 'bg-orange-50' : 'bg-green-50'
                  )}>
                    <div className={cn(
                      "h-16 w-16 rounded-full flex items-center justify-center",
                      formation.type === 'video' ? 'bg-blue-100 text-blue-600' : 
                      formation.type === 'pdf' ? 'bg-orange-100 text-orange-600' : 'bg-green-100 text-green-600'
                    )}>
                      {getTypeIcon(formation.type)}
                    </div>
                    {formation.complete && (
                      <div className="absolute top-2 right-2 h-8 w-8 rounded-full bg-green-500 flex items-center justify-center">
                        <CheckCircle className="h-5 w-5 text-white" />
                      </div>
                    )}
                  </div>
                  <CardContent className="p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Badge variant={getTypeBadgeVariant(formation.type) as 'info' | 'warning' | 'success' | 'secondary'}>
                        {formation.type === 'video' ? 'Vidéo' : 
                         formation.type === 'pdf' ? 'PDF' : 'Article'}
                      </Badge>
                      <Badge variant="outline">{formation.categorie}</Badge>
                    </div>
                    
                    <h3 className="font-semibold text-gray-900 mb-1 line-clamp-2">
                      {formation.titre}
                    </h3>
                    <p className="text-sm text-gray-500 mb-3 line-clamp-2">
                      {formation.description || 'Pas de description'}
                    </p>

                    {formation.duree_minutes && (
                      <div className="flex items-center gap-1 text-sm text-gray-500 mb-3">
                        <Clock className="h-4 w-4" />
                        {formatDuration(formation.duree_minutes)}
                      </div>
                    )}

                    {formation.progression !== undefined && formation.progression > 0 && (
                      <div className="mb-3">
                        <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
                          <span>Progression</span>
                          <span>{formation.progression}%</span>
                        </div>
                        <Progress value={formation.progression} className="h-1.5" />
                      </div>
                    )}

                    <Link href={`/formations/${formation.id}`}>
                      <Button className="w-full" variant={formation.complete ? 'outline' : 'default'}>
                        {formation.complete ? 'Revoir' : 
                         formation.progression ? 'Continuer' : 'Commencer'}
                        <ChevronRight className="h-4 w-4 ml-2" />
                      </Button>
                    </Link>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}

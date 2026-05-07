'use client'

import { useState, useRef, useEffect } from 'react'
import {
  Camera,
  Upload,
  Scan,
  Leaf,
  Bug,
  AlertTriangle,
  CheckCircle2,
  RefreshCw,
  History,
  Trash2,
  ChevronRight,
  X,
  Zap,
  Target,
  Lightbulb,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Progress } from '@/components/ui/progress'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Spinner } from '@/components/ui/spinner'
import toast from 'react-hot-toast'
import api from '@/lib/api'

interface DiagnosticResult {
  id: string
  image: string
  date: string
  culture: string
  maladie: string | null
  confiance: number
  severite: 'faible' | 'moyenne' | 'elevee' | null
  recommandations: string[]
  traitements: {
    nom: string
    type: 'biologique' | 'chimique' | 'cultural'
    efficacite: number
    description: string
  }[]
}

export default function DiagnosticPage() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null)
  const [isAnalyzing, setIsAnalyzing] = useState(false)
  const [analysisProgress, setAnalysisProgress] = useState(0)
  const [currentResult, setCurrentResult] = useState<DiagnosticResult | null>(null)
  const [history, setHistory] = useState<DiagnosticResult[]>([])
  const [activeTab, setActiveTab] = useState('nouveau')
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Charger l'historique des diagnostics au montage
  useEffect(() => {
    const loadHistory = async () => {
      try {
        const response = await api.get('/diagnostics/history')
        if (response.data.success && response.data.data) {
          setHistory(response.data.data)
        }
      } catch (error) {
        console.error('Erreur chargement historique diagnostics:', error)
      }
    }
    loadHistory()
  }, [])

  const handleImageUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) {
      const reader = new FileReader()
      reader.onloadend = () => {
        setSelectedImage(reader.result as string)
        setCurrentResult(null)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleCameraCapture = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true })
      // Pour simplifier, on ouvre juste le sélecteur de fichiers
      // Dans une vraie app, on afficherait un modal avec la caméra
      stream.getTracks().forEach(track => track.stop())
      fileInputRef.current?.click()
    } catch {
      toast.error('Impossible d\'accéder à la caméra')
      fileInputRef.current?.click()
    }
  }

  const analyzeImage = async () => {
    if (!selectedImage) return

    setIsAnalyzing(true)
    setAnalysisProgress(0)

    // Simuler la progression de l'analyse
    const progressInterval = setInterval(() => {
      setAnalysisProgress(prev => {
        if (prev >= 90) {
          clearInterval(progressInterval)
          return prev
        }
        return prev + Math.random() * 15
      })
    }, 300)

    try {
      // Appel API réel
      const formData = new FormData()
      const blob = await fetch(selectedImage).then(r => r.blob())
      formData.append('image', blob, 'diagnostic.jpg')

      const response = await api.post('/diagnostic/analyser', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })

      clearInterval(progressInterval)
      setAnalysisProgress(100)

      setTimeout(() => {
        setCurrentResult(response.data)
        setHistory(prev => [response.data, ...prev])
        setIsAnalyzing(false)
        toast.success('Analyse terminée')
      }, 500)
    } catch (error) {
      clearInterval(progressInterval)
      setAnalysisProgress(0)
      setIsAnalyzing(false)
      console.error('Erreur analyse diagnostic:', error)
      toast.error('Erreur lors de l\'analyse. Vérifiez votre connexion et réessayez.')
    }
  }

  const resetDiagnostic = () => {
    setSelectedImage(null)
    setCurrentResult(null)
    setAnalysisProgress(0)
  }

  const getSeverityColor = (severite: string | null) => {
    switch (severite) {
      case 'faible': return 'bg-green-100 text-green-800'
      case 'moyenne': return 'bg-orange-100 text-orange-800'
      case 'elevee': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const getSeverityLabel = (severite: string | null) => {
    switch (severite) {
      case 'faible': return 'Faible'
      case 'moyenne': return 'Moyenne'
      case 'elevee': return 'Élevée'
      default: return 'Inconnue'
    }
  }

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'biologique': return 'bg-green-100 text-green-800'
      case 'chimique': return 'bg-purple-100 text-purple-800'
      case 'cultural': return 'bg-blue-100 text-blue-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  return (
    <div className="p-4 md:p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900">
            Diagnostic IA
          </h1>
          <p className="text-gray-500 mt-1">
            Analysez vos cultures avec l&apos;intelligence artificielle
          </p>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="nouveau" className="flex items-center gap-2">
            <Scan className="h-4 w-4" />
            Nouveau diagnostic
          </TabsTrigger>
          <TabsTrigger value="historique" className="flex items-center gap-2">
            <History className="h-4 w-4" />
            Historique
          </TabsTrigger>
        </TabsList>

        <TabsContent value="nouveau" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Zone de capture/upload */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Camera className="h-5 w-5 text-primary" />
                  Capturer ou importer une image
                </CardTitle>
                <CardDescription>
                  Prenez une photo claire de la feuille ou du fruit affecté
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  onChange={handleImageUpload}
                  className="hidden"
                  title="Sélectionner une image"
                />

                {!selectedImage ? (
                  <div className="border-2 border-dashed border-gray-200 rounded-xl p-8 text-center space-y-4">
                    <div className="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center mx-auto">
                      <Leaf className="h-8 w-8 text-primary" />
                    </div>
                    <div>
                      <p className="text-gray-600 mb-2">
                        Glissez une image ici ou utilisez les boutons ci-dessous
                      </p>
                      <p className="text-sm text-gray-400">
                        Formats acceptés: JPG, PNG, WebP (max 10MB)
                      </p>
                    </div>
                    <div className="flex flex-col sm:flex-row gap-3 justify-center">
                      <Button onClick={handleCameraCapture} className="gap-2">
                        <Camera className="h-4 w-4" />
                        Prendre une photo
                      </Button>
                      <Button
                        variant="outline"
                        onClick={() => fileInputRef.current?.click()}
                        className="gap-2"
                      >
                        <Upload className="h-4 w-4" />
                        Importer
                      </Button>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    <div className="relative">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={selectedImage}
                        alt="Image à analyser"
                        className="w-full h-64 object-cover rounded-xl"
                      />
                      <button
                        onClick={resetDiagnostic}
                        className="absolute top-2 right-2 p-2 bg-black/50 hover:bg-black/70 rounded-full text-white transition-colors"
                        aria-label="Supprimer l'image"
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>

                    {isAnalyzing ? (
                      <div className="space-y-3">
                        <div className="flex items-center gap-3">
                          <Spinner className="h-5 w-5" />
                          <span className="text-sm text-gray-600">
                            Analyse en cours...
                          </span>
                        </div>
                        <Progress value={analysisProgress} className="h-2" />
                        <p className="text-xs text-gray-500 text-center">
                          L&apos;IA analyse votre image pour détecter les maladies
                        </p>
                      </div>
                    ) : !currentResult ? (
                      <Button onClick={analyzeImage} className="w-full gap-2">
                        <Zap className="h-4 w-4" />
                        Lancer l&apos;analyse IA
                      </Button>
                    ) : null}
                  </div>
                )}

                {/* Conseils pour une bonne photo */}
                <div className="bg-blue-50 rounded-lg p-4 space-y-2">
                  <h4 className="font-medium text-blue-900 flex items-center gap-2">
                    <Lightbulb className="h-4 w-4" />
                    Conseils pour une meilleure analyse
                  </h4>
                  <ul className="text-sm text-blue-800 space-y-1">
                    <li>• Photographiez en pleine lumière naturelle</li>
                    <li>• Cadrez la zone affectée de près</li>
                    <li>• Évitez les images floues</li>
                    <li>• Incluez une feuille saine pour comparaison</li>
                  </ul>
                </div>
              </CardContent>
            </Card>

            {/* Résultats */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Target className="h-5 w-5 text-primary" />
                  Résultat du diagnostic
                </CardTitle>
              </CardHeader>
              <CardContent>
                {!currentResult ? (
                  <div className="text-center py-12 text-gray-500">
                    <Bug className="h-16 w-16 mx-auto mb-4 opacity-20" />
                    <p>Importez une image et lancez l&apos;analyse</p>
                    <p className="text-sm mt-1">
                      Les résultats apparaîtront ici
                    </p>
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Statut */}
                    <div className={`p-4 rounded-lg ${currentResult.maladie ? 'bg-red-50' : 'bg-green-50'}`}>
                      <div className="flex items-start gap-3">
                        {currentResult.maladie ? (
                          <AlertTriangle className="h-6 w-6 text-red-600 shrink-0" />
                        ) : (
                          <CheckCircle2 className="h-6 w-6 text-green-600 shrink-0" />
                        )}
                        <div className="flex-1">
                          <h3 className={`font-semibold ${currentResult.maladie ? 'text-red-900' : 'text-green-900'}`}>
                            {currentResult.maladie || 'Plante saine'}
                          </h3>
                          <p className={`text-sm ${currentResult.maladie ? 'text-red-700' : 'text-green-700'}`}>
                            Culture: {currentResult.culture}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* Métriques */}
                    <div className="grid grid-cols-2 gap-4">
                      <div className="bg-gray-50 rounded-lg p-4 text-center">
                        <p className="text-2xl font-bold text-primary">
                          {currentResult.confiance}%
                        </p>
                        <p className="text-sm text-gray-600">Confiance</p>
                      </div>
                      <div className="bg-gray-50 rounded-lg p-4 text-center">
                        <Badge className={getSeverityColor(currentResult.severite)}>
                          {getSeverityLabel(currentResult.severite)}
                        </Badge>
                        <p className="text-sm text-gray-600 mt-2">Sévérité</p>
                      </div>
                    </div>

                    {/* Recommandations */}
                    {(currentResult.recommandations?.length ?? 0) > 0 && (
                      <div>
                        <h4 className="font-medium text-gray-900 mb-3 flex items-center gap-2">
                          <Lightbulb className="h-4 w-4 text-yellow-500" />
                          Recommandations
                        </h4>
                        <ul className="space-y-2">
                          {(currentResult.recommandations || []).map((rec, index) => (
                            <li
                              key={index}
                              className="flex items-start gap-2 text-sm text-gray-700"
                            >
                              <CheckCircle2 className="h-4 w-4 text-green-500 shrink-0 mt-0.5" />
                              {rec}
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {/* Traitements */}
                    {(currentResult.traitements?.length ?? 0) > 0 && (
                      <div>
                        <h4 className="font-medium text-gray-900 mb-3">
                          Traitements recommandés
                        </h4>
                        <div className="space-y-3">
                          {(currentResult.traitements || []).map((traitement, index) => (
                            <div
                              key={index}
                              className="border rounded-lg p-3 hover:border-primary/50 transition-colors"
                            >
                              <div className="flex items-center justify-between mb-2">
                                <span className="font-medium">{traitement.nom}</span>
                                <Badge className={getTypeColor(traitement.type)}>
                                  {traitement.type}
                                </Badge>
                              </div>
                              <p className="text-sm text-gray-600 mb-2">
                                {traitement.description}
                              </p>
                              <div className="flex items-center gap-2">
                                <span className="text-xs text-gray-500">Efficacité:</span>
                                <Progress value={traitement.efficacite} className="flex-1 h-2" />
                                <span className="text-xs font-medium">{traitement.efficacite}%</span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    <Button
                      variant="outline"
                      onClick={resetDiagnostic}
                      className="w-full gap-2"
                    >
                      <RefreshCw className="h-4 w-4" />
                      Nouveau diagnostic
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="historique" className="space-y-4">
          {history.length === 0 ? (
            <Card>
              <CardContent className="py-12 text-center text-gray-500">
                <History className="h-16 w-16 mx-auto mb-4 opacity-20" />
                <p>Aucun diagnostic dans l&apos;historique</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {history.map((diagnostic) => (
                <Card
                  key={diagnostic.id}
                  className="hover:shadow-lg transition-shadow cursor-pointer"
                  onClick={() => {
                    setCurrentResult(diagnostic)
                    setSelectedImage(diagnostic.image)
                    setActiveTab('nouveau')
                  }}
                >
                  <CardContent className="p-4">
                    <div className="flex gap-4">
                      <div className="w-20 h-20 bg-gray-100 rounded-lg shrink-0 overflow-hidden">
                        {diagnostic.image?.startsWith('data:') ? (
                          /* eslint-disable-next-line @next/next/no-img-element */
                          <img
                            src={diagnostic.image}
                            alt="Diagnostic"
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center">
                            <Leaf className="h-8 w-8 text-gray-300" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <h3 className="font-medium text-gray-900 truncate">
                              {diagnostic.maladie || 'Plante saine'}
                            </h3>
                            <p className="text-sm text-gray-500">
                              {diagnostic.culture}
                            </p>
                          </div>
                          <Badge className={getSeverityColor(diagnostic.severite)}>
                            {getSeverityLabel(diagnostic.severite)}
                          </Badge>
                        </div>
                        <div className="flex items-center justify-between mt-2">
                          <span className="text-xs text-gray-400">
                            {diagnostic.date ? new Date(diagnostic.date).toLocaleDateString('fr-FR') : 'N/A'}
                          </span>
                          <span className="text-xs font-medium text-primary">
                            {diagnostic.confiance}% confiance
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center justify-between mt-4 pt-3 border-t">
                      <span className="text-sm text-gray-600">
                        {diagnostic.traitements?.length ?? 0} traitement(s)
                      </span>
                      <ChevronRight className="h-4 w-4 text-gray-400" />
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          {history.length > 0 && (
            <div className="flex justify-center">
              <Button
                variant="outline"
                className="gap-2 text-red-600 hover:text-red-700 hover:bg-red-50"
                onClick={() => {
                  if (confirm('Voulez-vous vraiment supprimer tout l\'historique ?')) {
                    setHistory([])
                    toast.success('Historique supprimé')
                  }
                }}
              >
                <Trash2 className="h-4 w-4" />
                Effacer l&apos;historique
              </Button>
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}

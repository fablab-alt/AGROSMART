'use client'

import { useEffect, useState } from 'react'
import { useParams, useRouter } from 'next/navigation'
import api from '@/lib/api'
import { Card, CardContent, CardHeader, CardTitle, Progress } from '@/components/ui'
import { ArrowLeft, Clock, BookOpen, CheckCircle2, Play, Lock, Trophy, Star, Video, FileText, ChevronDown, Users, Eye } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import toast from 'react-hot-toast'
import Link from 'next/link'

interface Module {
    id: string
    titre: string
    contenu: string
    ordre: number
    videoUrl?: string
    documentsUrl?: string
    quizData?: Record<string, unknown>
}

export default function FormationDetailPage() {
    const params = useParams()
    const router = useRouter()
    const [formation, setFormation] = useState<any>(null)
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState('')
    const [enrolling, setEnrolling] = useState(false)
    const [expandedModule, setExpandedModule] = useState<string | null>(null)

    const fetchFormation = async () => {
        try {
            const response = await api.get(`/formations/${params.id}`)
            const data = response.data?.data || response.data
            if (data) {
                setFormation(data)
                // Auto-expand first module
                if (data.modules?.length > 0) {
                    setExpandedModule(data.modules[0].id)
                }
            }
        } catch (err: any) {
            setError(err.response?.data?.message || 'Erreur lors du chargement de la formation')
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        if (params.id) fetchFormation()
    }, [params.id])

    // Get user's progression from the progressionFormation array
    const userProg = formation?.progressionFormation?.[0] || formation?.progression || null
    const isEnrolled = !!userProg
    const progressPct = userProg?.progression || 0
    const isComplete = userProg?.complete || false
    const completedModules: string[] = userProg?.modulesTermines || []

    const handleEnroll = async () => {
        try {
            setEnrolling(true)
            await api.post(`/formations/${params.id}/inscrire`)
            toast.success('🎉 Inscription réussie ! Vous pouvez commencer.')
            await fetchFormation()
        } catch (err: any) {
            toast.error(err.response?.data?.message || 'Erreur lors de l\'inscription')
        } finally {
            setEnrolling(false)
        }
    }

    const handleModuleComplete = async (moduleId: string) => {
        if (!formation) return
        try {
            const newCompleted = [...completedModules, moduleId]
            const newPct = Math.round((newCompleted.length / (formation.modules?.length || 1)) * 100)
            await api.put(`/formations/${params.id}/progression`, {
                progression: newPct,
                complete: newPct >= 100,
                modulesTermines: newCompleted,
            })
            toast.success(newPct >= 100 ? '🎉 Formation terminée ! Félicitations !' : '✅ Module complété !')
            await fetchFormation()
        } catch {
            toast.error('Erreur lors de la mise à jour')
        }
    }

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600"></div>
            </div>
        )
    }

    if (error || !formation) {
        return (
            <div className="container mx-auto px-4 py-8">
                <Card>
                    <CardContent className="pt-6">
                        <p className="text-red-600 text-center">{error || 'Formation non trouvée'}</p>
                        <div className="flex justify-center mt-4">
                            <Link href="/formations" className="text-green-600 hover:underline flex items-center gap-2">
                                <ArrowLeft className="h-4 w-4" />
                                Retour aux formations
                            </Link>
                        </div>
                    </CardContent>
                </Card>
            </div>
        )
    }

    return (
        <div className="p-4 md:p-6 space-y-6">
            {/* Back Button */}
            <Button variant="ghost" onClick={() => router.push('/formations')} className="gap-2 -ml-2">
                <ArrowLeft className="h-4 w-4" />
                Retour aux formations
            </Button>

            {/* Header */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <div className="lg:col-span-2 space-y-4">
                    <div className="flex flex-wrap items-center gap-2">
                        <Badge className="bg-green-100 text-green-700">{formation.categorie}</Badge>
                        <Badge variant="outline">{formation.niveau}</Badge>
                    </div>
                    <h1 className="text-2xl md:text-3xl font-bold text-gray-900">{formation.titre}</h1>
                    <p className="text-gray-600 text-lg leading-relaxed">{formation.description}</p>
                    <div className="flex flex-wrap items-center gap-4 text-sm text-gray-500">
                        <span className="flex items-center gap-1"><Clock className="h-4 w-4" />{formation.dureeMinutes} min</span>
                        <span className="flex items-center gap-1"><BookOpen className="h-4 w-4" />{formation.modules?.length || 0} modules</span>
                        <span className="flex items-center gap-1"><Eye className="h-4 w-4" />{formation.vues || 0} vues</span>
                        <span className="flex items-center gap-1"><Users className="h-4 w-4" />{formation._count?.progressions || 0} inscrits</span>
                    </div>
                </div>

                {/* Sidebar - Progression / Inscription */}
                <Card>
                    <CardHeader>
                        <CardTitle className="text-lg">
                            {isEnrolled ? 'Votre progression' : 'Commencer'}
                        </CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        {isEnrolled ? (
                            <>
                                {isComplete ? (
                                    <div className="text-center space-y-2">
                                        <div className="inline-flex p-3 bg-green-100 rounded-full">
                                            <Trophy className="h-8 w-8 text-green-600" />
                                        </div>
                                        <p className="font-semibold text-green-700">Formation terminée !</p>
                                        {userProg?.score && (
                                            <div className="flex items-center justify-center gap-1">
                                                <Star className="h-4 w-4 text-yellow-500 fill-yellow-500" />
                                                <span>Score: {userProg.score}%</span>
                                            </div>
                                        )}
                                    </div>
                                ) : (
                                    <>
                                        <div className="flex justify-between text-sm mb-1">
                                            <span className="text-gray-500">
                                                {completedModules.length} / {formation.modules?.length || 0} modules
                                            </span>
                                            <span className="font-semibold text-green-600">{progressPct}%</span>
                                        </div>
                                        <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
                                            <div
                                                className="h-full bg-green-600 rounded-full transition-all duration-500"
                                                style={{ width: `${progressPct}%` }}
                                            />
                                        </div>
                                        <p className="text-sm text-gray-500">Continuez pour obtenir votre certificat !</p>
                                    </>
                                )}
                            </>
                        ) : (
                            <>
                                <div className="text-center space-y-3">
                                    <div className="inline-flex p-3 bg-green-50 rounded-full">
                                        <BookOpen className="h-8 w-8 text-green-600" />
                                    </div>
                                    <p className="text-gray-600 text-sm">
                                        Inscrivez-vous pour suivre votre progression et obtenir un certificat
                                    </p>
                                </div>
                                <Button className="w-full gap-2 bg-green-600 hover:bg-green-700" onClick={handleEnroll} disabled={enrolling}>
                                    {enrolling ? (
                                        <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                                    ) : (
                                        <Play className="h-4 w-4" />
                                    )}
                                    Commencer la formation
                                </Button>
                            </>
                        )}
                    </CardContent>
                </Card>
            </div>

            {/* Modules */}
            <div className="space-y-4">
                <h2 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                    <BookOpen className="h-5 w-5 text-green-600" />
                    Contenu de la formation
                </h2>

                {formation.modules && formation.modules.length > 0 ? (
                    <div className="space-y-3">
                        {[...formation.modules]
                            .sort((a: Module, b: Module) => a.ordre - b.ordre)
                            .map((module: Module, index: number) => {
                                const isModuleComplete = completedModules.includes(module.id)
                                const isExpanded = expandedModule === module.id
                                const isLocked = !isEnrolled && index > 0

                                return (
                                    <Card
                                        key={module.id}
                                        className={`transition-all ${isExpanded ? 'ring-2 ring-green-200 shadow-md' : ''} ${isLocked ? 'opacity-60' : 'cursor-pointer hover:shadow-md'}`}
                                        onClick={() => !isLocked && setExpandedModule(isExpanded ? null : module.id)}
                                    >
                                        <CardHeader className="pb-2">
                                            <div className="flex items-center justify-between">
                                                <div className="flex items-center gap-3">
                                                    <div className={`flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold ${
                                                        isModuleComplete ? 'bg-green-100 text-green-700' :
                                                        isExpanded ? 'bg-green-600 text-white' :
                                                        'bg-gray-100 text-gray-600'
                                                    }`}>
                                                        {isModuleComplete ? <CheckCircle2 className="h-5 w-5" /> :
                                                         isLocked ? <Lock className="h-4 w-4" /> : index + 1}
                                                    </div>
                                                    <div>
                                                        <p className="font-medium text-gray-900">{module.titre}</p>
                                                        <div className="flex items-center gap-2 mt-1">
                                                            {module.videoUrl && <span className="flex items-center gap-1 text-xs text-blue-600"><Video className="h-3 w-3" /> Vidéo</span>}
                                                            {module.documentsUrl && <span className="flex items-center gap-1 text-xs text-orange-600"><FileText className="h-3 w-3" /> Document</span>}
                                                            {module.quizData && <span className="flex items-center gap-1 text-xs text-purple-600"><Star className="h-3 w-3" /> Quiz</span>}
                                                        </div>
                                                    </div>
                                                </div>
                                                <ChevronDown className={`h-5 w-5 text-gray-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`} />
                                            </div>
                                        </CardHeader>

                                        {isExpanded && !isLocked && (
                                            <CardContent className="pt-2 space-y-4 border-t">
                                                <div className="prose prose-sm max-w-none text-gray-700 whitespace-pre-wrap">
                                                    {module.contenu}
                                                </div>

                                                {module.videoUrl && (
                                                    <a
                                                        href={module.videoUrl}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="inline-flex items-center gap-2 px-4 py-2 bg-blue-50 text-blue-700 rounded-lg hover:bg-blue-100 transition-colors"
                                                        onClick={(e) => e.stopPropagation()}
                                                    >
                                                        <Video className="h-4 w-4" /> Voir la vidéo
                                                    </a>
                                                )}

                                                {module.documentsUrl && (
                                                    <a
                                                        href={module.documentsUrl}
                                                        target="_blank"
                                                        rel="noopener noreferrer"
                                                        className="inline-flex items-center gap-2 px-4 py-2 bg-orange-50 text-orange-700 rounded-lg hover:bg-orange-100 transition-colors"
                                                        onClick={(e) => e.stopPropagation()}
                                                    >
                                                        <FileText className="h-4 w-4" /> Télécharger le document
                                                    </a>
                                                )}

                                                {isEnrolled && !isModuleComplete && (
                                                    <Button
                                                        onClick={(e) => { e.stopPropagation(); handleModuleComplete(module.id) }}
                                                        className="gap-2 bg-green-600 hover:bg-green-700"
                                                    >
                                                        <CheckCircle2 className="h-4 w-4" /> Marquer comme terminé
                                                    </Button>
                                                )}

                                                {isModuleComplete && (
                                                    <div className="flex items-center gap-2 text-green-600 font-medium">
                                                        <CheckCircle2 className="h-5 w-5" /> Module terminé
                                                    </div>
                                                )}
                                            </CardContent>
                                        )}
                                    </Card>
                                )
                            })}
                    </div>
                ) : (
                    <Card>
                        <CardContent className="p-8 text-center">
                            <BookOpen className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                            <p className="text-gray-500">Les modules de cette formation seront bientôt disponibles.</p>
                        </CardContent>
                    </Card>
                )}
            </div>
        </div>
    )
}

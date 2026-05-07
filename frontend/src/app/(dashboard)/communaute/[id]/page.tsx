'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import {
  ArrowLeft, MessageCircle, ThumbsUp, Eye, Clock, Crown,
  CheckCircle2, Send, User, Award
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle, Badge, Button, Skeleton } from '@/components/ui'
import { cn } from '@/lib/utils'
import { useAuthStore } from '@/lib/store'
import api from '@/lib/api'
import toast from 'react-hot-toast'

interface ForumReponse {
  id: string
  contenu: string
  auteur_nom: string
  auteur_prenom?: string
  auteur?: { nom: string; prenoms?: string }
  estSolution: boolean
  upvotes: number
  createdAt: string
}

interface ForumPostDetail {
  id: string
  titre: string
  contenu: string
  categorie: string
  tags: string[]
  vues: number
  likes: number
  resolu: boolean
  auteur_nom: string
  auteur_prenom?: string
  auteur?: { nom: string; prenoms?: string }
  reponses: ForumReponse[]
  createdAt: string
}

export default function PostDetailPage() {
  const params = useParams()
  const router = useRouter()
  const { user } = useAuthStore()
  const [post, setPost] = useState<ForumPostDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [reponse, setReponse] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const fetchPost = async () => {
    try {
      setLoading(true)
      const res = await api.get(`/communaute/posts/${params.id}`)
      if (res.data.success) {
        setPost(res.data.data)
      }
    } catch (error) {
      console.error('Erreur chargement post:', error)
      toast.error('Impossible de charger la discussion')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (params.id) fetchPost()
  }, [params.id])

  const handleSubmitReponse = async () => {
    if (!reponse.trim()) {
      toast.error('Veuillez écrire une réponse')
      return
    }
    setSubmitting(true)
    try {
      const res = await api.post(`/communaute/posts/${params.id}/reponses`, {
        contenu: reponse
      })
      if (res.data.success) {
        toast.success('Réponse publiée !')
        setReponse('')
        fetchPost() // Refresh to show the new response
      }
    } catch (error) {
      console.error('Erreur publication réponse:', error)
      toast.error('Impossible de publier la réponse')
    } finally {
      setSubmitting(false)
    }
  }

  const handleMarkSolution = async (reponseId: string) => {
    try {
      const res = await api.put(`/communaute/posts/${params.id}/reponses/${reponseId}/solution`)
      if (res.data.success) {
        toast.success('Solution marquée !')
        fetchPost()
      }
    } catch (error: any) {
      console.error('Erreur marquage solution:', error)
      toast.error(error?.response?.data?.message || 'Erreur lors du marquage')
    }
  }

  const formatDate = (dateStr: string) => {
    if (!dateStr) return ''
    const date = new Date(dateStr)
    if (isNaN(date.getTime())) return ''
    return date.toLocaleDateString('fr-FR', {
      day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit'
    })
  }

  const getAuteurNom = (item: any) => {
    if (item.auteur) return `${item.auteur.nom} ${item.auteur.prenoms || ''}`
    return `${item.auteur_nom || ''} ${item.auteur_prenom || ''}`.trim() || 'Anonyme'
  }

  if (loading) {
    return (
      <div className="space-y-6 max-w-4xl mx-auto">
        <Skeleton className="h-8 w-48" />
        <Skeleton className="h-64 w-full" />
        <Skeleton className="h-32 w-full" />
        <Skeleton className="h-32 w-full" />
      </div>
    )
  }

  if (!post) {
    return (
      <div className="max-w-4xl mx-auto text-center py-16">
        <MessageCircle className="h-16 w-16 mx-auto text-gray-300 mb-4" />
        <h2 className="text-xl font-semibold text-gray-700 mb-2">Discussion introuvable</h2>
        <p className="text-gray-500 mb-6">Cette discussion n&apos;existe pas ou a été supprimée.</p>
        <Link href="/communaute">
          <Button variant="outline">
            <ArrowLeft className="h-4 w-4 mr-2" /> Retour à la communauté
          </Button>
        </Link>
      </div>
    )
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Back link */}
      <Link href="/communaute" className="inline-flex items-center gap-2 text-gray-600 hover:text-green-600 transition-colors">
        <ArrowLeft className="h-4 w-4" /> Retour à la communauté
      </Link>

      {/* Post principal */}
      <Card>
        <CardHeader>
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-2">
                <Badge variant="outline">{post.categorie}</Badge>
                {post.resolu && (
                  <Badge className="bg-green-100 text-green-700">
                    <CheckCircle2 className="h-3 w-3 mr-1" /> Résolu
                  </Badge>
                )}
              </div>
              <CardTitle className="text-xl">{post.titre}</CardTitle>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Author info */}
          <div className="flex items-center gap-3 pb-4 border-b">
            <div className="h-10 w-10 rounded-full bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center text-white font-bold">
              {getAuteurNom(post).charAt(0)}
            </div>
            <div>
              <p className="font-medium text-gray-900">{getAuteurNom(post)}</p>
              <p className="text-sm text-gray-500">{formatDate(post.createdAt)}</p>
            </div>
          </div>

          {/* Content */}
          <div className="prose prose-sm max-w-none text-gray-700 whitespace-pre-wrap">
            {post.contenu}
          </div>

          {/* Tags */}
          {post.tags && post.tags.length > 0 && (
            <div className="flex flex-wrap gap-2 pt-2">
              {post.tags.map((tag: string) => (
                <Badge key={tag} variant="secondary" className="text-xs">#{tag}</Badge>
              ))}
            </div>
          )}

          {/* Stats */}
          <div className="flex items-center gap-6 pt-4 border-t text-sm text-gray-500">
            <span className="flex items-center gap-1"><Eye className="h-4 w-4" /> {post.vues} vues</span>
            <span className="flex items-center gap-1"><ThumbsUp className="h-4 w-4" /> {post.likes} likes</span>
            <span className="flex items-center gap-1"><MessageCircle className="h-4 w-4" /> {post.reponses?.length || 0} réponses</span>
          </div>
        </CardContent>
      </Card>

      {/* Responses section */}
      <div>
        <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <MessageCircle className="h-5 w-5 text-green-600" />
          Réponses ({post.reponses?.length || 0})
        </h2>

        <div className="space-y-4">
          {post.reponses && post.reponses.length > 0 ? (
            post.reponses.map((rep) => (
              <Card key={rep.id} className={cn(
                'transition-colors',
                rep.estSolution ? 'border-green-300 bg-green-50/50' : ''
              )}>
                <CardContent className="p-4">
                  {rep.estSolution && (
                    <div className="flex items-center gap-2 text-green-700 mb-3 pb-3 border-b border-green-200">
                      <CheckCircle2 className="h-5 w-5" />
                      <span className="font-semibold text-sm">Meilleure réponse</span>
                    </div>
                  )}

                  <div className="flex items-start gap-3">
                    <div className="h-8 w-8 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-bold text-sm shrink-0">
                      {getAuteurNom(rep).charAt(0)}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-medium text-gray-900 text-sm">{getAuteurNom(rep)}</span>
                        <span className="text-xs text-gray-500">{formatDate(rep.createdAt)}</span>
                      </div>
                      <div className="text-sm text-gray-700 whitespace-pre-wrap">{rep.contenu}</div>

                      <div className="flex items-center gap-4 mt-3">
                        <span className="flex items-center gap-1 text-xs text-gray-500">
                          <ThumbsUp className="h-3 w-3" /> {rep.upvotes || 0}
                        </span>
                        {!post.resolu && post.auteur?.nom && (
                          <button
                            onClick={() => handleMarkSolution(rep.id)}
                            className="text-xs text-green-600 hover:text-green-800 flex items-center gap-1"
                          >
                            <CheckCircle2 className="h-3 w-3" /> Marquer comme solution
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))
          ) : (
            <Card>
              <CardContent className="py-8 text-center">
                <MessageCircle className="h-12 w-12 mx-auto text-gray-300 mb-3" />
                <p className="text-gray-500">Aucune réponse pour le moment.</p>
                <p className="text-sm text-gray-400">Soyez le premier à répondre !</p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>

      {/* Reply form */}
      <Card>
        <CardContent className="p-4">
          <h3 className="font-semibold text-gray-900 mb-3">Votre réponse</h3>
          <textarea
            value={reponse}
            onChange={(e) => setReponse(e.target.value)}
            placeholder="Partagez votre expérience ou votre conseil..."
            className="w-full min-h-[120px] p-3 border rounded-lg resize-y bg-white dark:bg-gray-800 dark:border-gray-700 focus:ring-2 focus:ring-green-500 focus:border-transparent"
          />
          <div className="flex justify-end mt-3">
            <Button
              onClick={handleSubmitReponse}
              disabled={submitting || !reponse.trim()}
              className="bg-green-600 hover:bg-green-700"
            >
              {submitting ? (
                <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full mr-2" />
              ) : (
                <Send className="h-4 w-4 mr-2" />
              )}
              Publier la réponse
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

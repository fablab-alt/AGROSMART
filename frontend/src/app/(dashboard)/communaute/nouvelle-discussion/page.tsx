'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import {
  ArrowLeft,
  Send,
  Tag,
  MessageSquare,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle, Button, Badge } from '@/components/ui'
import api from '@/lib/api'
import toast from 'react-hot-toast'

const categories = [
  { id: 'maladies', nom: 'Maladies', color: 'bg-red-100 text-red-700' },
  { id: 'irrigation', nom: 'Irrigation', color: 'bg-blue-100 text-blue-700' },
  { id: 'cultures', nom: 'Cultures', color: 'bg-green-100 text-green-700' },
  { id: 'marche', nom: 'Marché', color: 'bg-yellow-100 text-yellow-700' },
  { id: 'technologie', nom: 'Technologie', color: 'bg-purple-100 text-purple-700' },
  { id: 'formations', nom: 'Formations', color: 'bg-indigo-100 text-indigo-700' },
  { id: 'general', nom: 'Général', color: 'bg-gray-100 text-gray-700' },
]

export default function NouvelleDiscussionPage() {
  const router = useRouter()
  const [titre, setTitre] = useState('')
  const [contenu, setContenu] = useState('')
  const [categorie, setCategorie] = useState('general')
  const [tags, setTags] = useState<string[]>([])
  const [tagInput, setTagInput] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const handleAddTag = () => {
    const tag = tagInput.trim().toLowerCase()
    if (tag && !tags.includes(tag) && tags.length < 5) {
      setTags([...tags, tag])
      setTagInput('')
    }
  }

  const handleRemoveTag = (tag: string) => {
    setTags(tags.filter(t => t !== tag))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!titre.trim()) {
      toast.error('Le titre est requis')
      return
    }
    if (!contenu.trim()) {
      toast.error('Le contenu est requis')
      return
    }

    setSubmitting(true)
    try {
      const response = await api.post('/communaute/posts', {
        titre: titre.trim(),
        contenu: contenu.trim(),
        categorie,
        tags,
      })

      if (response.data.success) {
        toast.success('Discussion créée avec succès !')
        router.push('/communaute')
      }
    } catch (error: any) {
      console.error('Error creating post:', error)
      toast.error(error.response?.data?.message || 'Erreur lors de la création de la discussion')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/communaute">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Retour
          </Button>
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <MessageSquare className="h-6 w-6 text-green-600" />
            Nouvelle discussion
          </h1>
          <p className="text-gray-500 dark:text-gray-400">
            Partagez vos questions et connaissances avec la communauté
          </p>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handleSubmit}>
        <Card>
          <CardHeader>
            <CardTitle>Créer une discussion</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Title */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Titre *
              </label>
              <input
                type="text"
                value={titre}
                onChange={(e) => setTitre(e.target.value)}
                placeholder="Ex: Comment traiter le cercosporosis sur mes cacaoyers ?"
                className="w-full px-4 py-3 border rounded-lg bg-white dark:bg-gray-800 dark:border-gray-700 focus:ring-2 focus:ring-green-500 focus:border-transparent"
                maxLength={200}
              />
              <p className="text-xs text-gray-500 mt-1">{titre.length}/200 caractères</p>
            </div>

            {/* Category */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Catégorie
              </label>
              <div className="flex flex-wrap gap-2">
                {categories.map((cat) => (
                  <button
                    key={cat.id}
                    type="button"
                    onClick={() => setCategorie(cat.id)}
                    className={`px-3 py-1.5 rounded-full text-sm font-medium transition-all ${
                      categorie === cat.id
                        ? cat.color + ' ring-2 ring-offset-1 ring-green-500'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-400'
                    }`}
                  >
                    {cat.nom}
                  </button>
                ))}
              </div>
            </div>

            {/* Content */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Contenu *
              </label>
              <textarea
                value={contenu}
                onChange={(e) => setContenu(e.target.value)}
                placeholder="Décrivez votre question ou partagez vos connaissances en détail..."
                rows={8}
                className="w-full px-4 py-3 border rounded-lg bg-white dark:bg-gray-800 dark:border-gray-700 focus:ring-2 focus:ring-green-500 focus:border-transparent resize-y"
                maxLength={5000}
              />
              <p className="text-xs text-gray-500 mt-1">{contenu.length}/5000 caractères</p>
            </div>

            {/* Tags */}
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Tags (optionnel, max 5)
              </label>
              <div className="flex items-center gap-2">
                <div className="relative flex-1">
                  <Tag className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <input
                    type="text"
                    value={tagInput}
                    onChange={(e) => setTagInput(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') {
                        e.preventDefault()
                        handleAddTag()
                      }
                    }}
                    placeholder="Ajouter un tag..."
                    className="w-full pl-10 pr-4 py-2 border rounded-lg bg-white dark:bg-gray-800 dark:border-gray-700"
                  />
                </div>
                <Button type="button" variant="outline" onClick={handleAddTag} disabled={tags.length >= 5}>
                  Ajouter
                </Button>
              </div>
              {tags.length > 0 && (
                <div className="flex flex-wrap gap-2 mt-2">
                  {tags.map((tag) => (
                    <Badge
                      key={tag}
                      variant="secondary"
                      className="cursor-pointer hover:bg-red-100 hover:text-red-700"
                      onClick={() => handleRemoveTag(tag)}
                    >
                      #{tag} ×
                    </Badge>
                  ))}
                </div>
              )}
            </div>

            {/* Submit */}
            <div className="flex justify-end gap-3 pt-4 border-t">
              <Link href="/communaute">
                <Button type="button" variant="outline">
                  Annuler
                </Button>
              </Link>
              <Button type="submit" disabled={submitting || !titre.trim() || !contenu.trim()}>
                {submitting ? (
                  <>
                    <div className="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent mr-2" />
                    Publication...
                  </>
                ) : (
                  <>
                    <Send className="h-4 w-4 mr-2" />
                    Publier la discussion
                  </>
                )}
              </Button>
            </div>
          </CardContent>
        </Card>
      </form>
    </div>
  )
}

'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import {
  Users, UserPlus, UserCheck, UserX, Clock, Search,
  MessageCircle, Trash2, Award, MapPin
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle, Badge, Button, Skeleton } from '@/components/ui'
import api from '@/lib/api'
import toast from 'react-hot-toast'

interface Friend {
  friendshipId: string
  id: string
  nom: string
  prenoms: string
  telephone: string
  role: string
  niveau?: number
  points?: number
  amisDepuis: string
  region?: { nom: string }
}

interface FriendRequest {
  id: string
  from?: { id: string; nom: string; prenoms: string; role: string; niveau?: number }
  to?: { id: string; nom: string; prenoms: string; role: string; niveau?: number }
  sentAt: string
}

interface Suggestion {
  id: string
  nom: string
  prenoms: string
  role: string
  niveau?: number
  region?: { nom: string }
}

type Tab = 'amis' | 'recus' | 'envoyes' | 'suggestions'

export default function AmisPage() {
  const [tab, setTab] = useState<Tab>('amis')
  const [friends, setFriends] = useState<Friend[]>([])
  const [received, setReceived] = useState<FriendRequest[]>([])
  const [sent, setSent] = useState<FriendRequest[]>([])
  const [suggestions, setSuggestions] = useState<Suggestion[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  const fetchAll = async () => {
    setLoading(true)
    try {
      const [friendsRes, recvRes, sentRes, sugRes] = await Promise.all([
        api.get('/friendships'),
        api.get('/friendships/requests/received'),
        api.get('/friendships/requests/sent'),
        api.get('/friendships/suggestions'),
      ])
      setFriends(friendsRes.data?.data || [])
      setReceived(recvRes.data?.data || [])
      setSent(sentRes.data?.data || [])
      setSuggestions(sugRes.data?.data || [])
    } catch (e) {
      console.error('Friends fetch error', e)
      toast.error('Impossible de charger les amis')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchAll() }, [])

  const handleAccept = async (id: string) => {
    try {
      await api.patch(`/friendships/${id}/accept`)
      toast.success('Demande acceptée')
      fetchAll()
    } catch { toast.error('Action impossible') }
  }

  const handleReject = async (id: string) => {
    try {
      await api.patch(`/friendships/${id}/reject`)
      toast.success('Demande refusée')
      fetchAll()
    } catch { toast.error('Action impossible') }
  }

  const handleAdd = async (userId: string) => {
    try {
      await api.post('/friendships', { addresseeId: userId })
      toast.success('Demande envoyée')
      fetchAll()
    } catch { toast.error('Action impossible') }
  }

  const handleRemove = async (friendshipId: string, name: string) => {
    if (!confirm(`Retirer ${name} de vos amis ?`)) return
    try {
      await api.delete(`/friendships/${friendshipId}`)
      toast.success('Ami retiré')
      fetchAll()
    } catch { toast.error('Action impossible') }
  }

  const formatDate = (s: string) => {
    if (!s) return ''
    const d = new Date(s)
    if (isNaN(d.getTime())) return ''
    return d.toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
  }

  const filteredFriends = friends.filter((f) =>
    !search || `${f.prenoms} ${f.nom}`.toLowerCase().includes(search.toLowerCase())
  )

  const tabs: { key: Tab; label: string; icon: any; count: number }[] = [
    { key: 'amis', label: 'Mes amis', icon: Users, count: friends.length },
    { key: 'recus', label: 'Demandes reçues', icon: UserCheck, count: received.length },
    { key: 'envoyes', label: 'Demandes envoyées', icon: Clock, count: sent.length },
    { key: 'suggestions', label: 'Suggestions', icon: UserPlus, count: suggestions.length },
  ]

  return (
    <div className="space-y-6 max-w-5xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Users className="h-6 w-6 text-green-600" />
            Réseau & Amis
          </h1>
          <p className="text-gray-500">Connectez-vous avec d'autres producteurs et agronomes</p>
        </div>
        <div className="relative w-full sm:w-72">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <input
            type="text"
            placeholder="Rechercher un ami..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-green-500"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-2 overflow-x-auto pb-2">
        {tabs.map(({ key, label, icon: Icon, count }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium text-sm transition-colors whitespace-nowrap ${
              tab === key
                ? 'bg-green-600 text-white'
                : 'bg-white text-gray-700 hover:bg-gray-100 border'
            }`}
          >
            <Icon className="h-4 w-4" />
            {label}
            {count > 0 && (
              <span className={`px-2 py-0.5 rounded-full text-xs ${
                tab === key ? 'bg-white/20' : 'bg-green-100 text-green-700'
              }`}>{count}</span>
            )}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {[1,2,3,4].map((i) => <Skeleton key={i} className="h-32 w-full" />)}
        </div>
      ) : (
        <>
          {tab === 'amis' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {filteredFriends.length === 0 ? (
                <Card className="md:col-span-2">
                  <CardContent className="py-12 text-center">
                    <Users className="h-12 w-12 mx-auto text-gray-300 mb-3" />
                    <p className="text-gray-500">{search ? 'Aucun ami trouvé' : 'Pas encore d\'amis'}</p>
                    <Button className="mt-4" onClick={() => setTab('suggestions')}>
                      Voir les suggestions
                    </Button>
                  </CardContent>
                </Card>
              ) : (
                filteredFriends.map((f) => (
                  <Card key={f.id} className="hover:shadow-md transition-shadow">
                    <CardContent className="p-4">
                      <div className="flex items-start gap-4">
                        <div className="h-14 w-14 rounded-full bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center text-white font-bold text-xl shrink-0">
                          {f.prenoms.charAt(0)}{f.nom.charAt(0)}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-semibold text-gray-900">{f.prenoms} {f.nom}</p>
                          <div className="flex items-center gap-2 mt-1 flex-wrap">
                            <Badge variant="outline" className="text-xs">{f.role}</Badge>
                            {f.niveau && (
                              <span className="text-xs text-gray-500 flex items-center gap-1">
                                <Award className="h-3 w-3" /> Niv. {f.niveau}
                              </span>
                            )}
                          </div>
                          {f.region?.nom && (
                            <p className="text-xs text-gray-500 mt-1 flex items-center gap-1">
                              <MapPin className="h-3 w-3" /> {f.region.nom}
                            </p>
                          )}
                          <p className="text-xs text-gray-400 mt-1">Amis depuis {formatDate(f.amisDepuis)}</p>
                          <div className="flex gap-2 mt-3">
                            <Link href="/messages" className="flex-1">
                              <Button size="sm" variant="outline" className="w-full">
                                <MessageCircle className="h-3 w-3 mr-1" /> Message
                              </Button>
                            </Link>
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleRemove(f.friendshipId, `${f.prenoms} ${f.nom}`)}
                              className="text-red-600 hover:bg-red-50"
                            >
                              <Trash2 className="h-3 w-3" />
                            </Button>
                          </div>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          )}

          {tab === 'recus' && (
            <div className="space-y-3">
              {received.length === 0 ? (
                <Card>
                  <CardContent className="py-12 text-center">
                    <UserCheck className="h-12 w-12 mx-auto text-gray-300 mb-3" />
                    <p className="text-gray-500">Aucune demande en attente</p>
                  </CardContent>
                </Card>
              ) : (
                received.map((r) => r.from && (
                  <Card key={r.id}>
                    <CardContent className="p-4 flex items-center gap-4">
                      <div className="h-12 w-12 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-bold">
                        {r.from.prenoms.charAt(0)}{r.from.nom.charAt(0)}
                      </div>
                      <div className="flex-1">
                        <p className="font-semibold">{r.from.prenoms} {r.from.nom}</p>
                        <div className="flex items-center gap-2 mt-1">
                          <Badge variant="outline" className="text-xs">{r.from.role}</Badge>
                          <span className="text-xs text-gray-500">{formatDate(r.sentAt)}</span>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button size="sm" onClick={() => handleAccept(r.id)} className="bg-green-600 hover:bg-green-700">
                          <UserCheck className="h-4 w-4 mr-1" /> Accepter
                        </Button>
                        <Button size="sm" variant="outline" onClick={() => handleReject(r.id)}>
                          <UserX className="h-4 w-4 mr-1" /> Refuser
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          )}

          {tab === 'envoyes' && (
            <div className="space-y-3">
              {sent.length === 0 ? (
                <Card>
                  <CardContent className="py-12 text-center">
                    <Clock className="h-12 w-12 mx-auto text-gray-300 mb-3" />
                    <p className="text-gray-500">Aucune demande envoyée</p>
                  </CardContent>
                </Card>
              ) : (
                sent.map((r) => r.to && (
                  <Card key={r.id}>
                    <CardContent className="p-4 flex items-center gap-4">
                      <div className="h-12 w-12 rounded-full bg-gray-200 flex items-center justify-center text-gray-700 font-bold">
                        {r.to.prenoms.charAt(0)}{r.to.nom.charAt(0)}
                      </div>
                      <div className="flex-1">
                        <p className="font-semibold">{r.to.prenoms} {r.to.nom}</p>
                        <div className="flex items-center gap-2 mt-1">
                          <Badge variant="outline" className="text-xs">{r.to.role}</Badge>
                          <span className="text-xs text-gray-500 flex items-center gap-1">
                            <Clock className="h-3 w-3" /> Envoyée {formatDate(r.sentAt)}
                          </span>
                        </div>
                      </div>
                      <Badge variant="secondary">En attente</Badge>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          )}

          {tab === 'suggestions' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {suggestions.length === 0 ? (
                <Card className="md:col-span-2">
                  <CardContent className="py-12 text-center">
                    <UserPlus className="h-12 w-12 mx-auto text-gray-300 mb-3" />
                    <p className="text-gray-500">Aucune suggestion pour le moment</p>
                  </CardContent>
                </Card>
              ) : (
                suggestions.map((u) => (
                  <Card key={u.id}>
                    <CardContent className="p-4 flex items-center gap-4">
                      <div className="h-12 w-12 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 flex items-center justify-center text-white font-bold">
                        {u.prenoms.charAt(0)}{u.nom.charAt(0)}
                      </div>
                      <div className="flex-1">
                        <p className="font-semibold">{u.prenoms} {u.nom}</p>
                        <div className="flex items-center gap-2 mt-1 flex-wrap">
                          <Badge variant="outline" className="text-xs">{u.role}</Badge>
                          {u.region?.nom && (
                            <span className="text-xs text-gray-500 flex items-center gap-1">
                              <MapPin className="h-3 w-3" /> {u.region.nom}
                            </span>
                          )}
                        </div>
                      </div>
                      <Button size="sm" onClick={() => handleAdd(u.id)} className="bg-green-600 hover:bg-green-700">
                        <UserPlus className="h-4 w-4 mr-1" /> Ajouter
                      </Button>
                    </CardContent>
                  </Card>
                ))
              )}
            </div>
          )}
        </>
      )}
    </div>
  )
}

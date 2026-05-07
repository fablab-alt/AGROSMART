'use client'

import { useState, useEffect, useCallback } from 'react'
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { CalendarDays, Plus, ChevronLeft, ChevronRight, CheckCircle, Clock, AlertCircle } from 'lucide-react'
import { calendrierApi } from '@/lib/api'

interface Activite {
  id: string
  titre: string
  description?: string
  typeActivite: string
  statut: string
  priorite: string
  dateDebut: string
  dateFin?: string
  parcelleId?: string
  parcelle?: { nom: string }
  estRecurrente?: boolean
}

const TYPES = ['SEMIS', 'IRRIGATION', 'FERTILISATION', 'TRAITEMENT', 'RECOLTE', 'LABOUR', 'DESHERBAGE', 'TAILLE', 'AUTRE']
const PRIORITES = ['BASSE', 'MOYENNE', 'HAUTE', 'URGENTE']

const prioriteColors: Record<string, string> = {
  BASSE: 'bg-gray-100 text-gray-700',
  MOYENNE: 'bg-blue-100 text-blue-700',
  HAUTE: 'bg-orange-100 text-orange-700',
  URGENTE: 'bg-red-100 text-red-700'
}

const statutIcons: Record<string, React.ReactNode> = {
  PLANIFIE: <Clock className="h-4 w-4 text-blue-500" />,
  EN_COURS: <AlertCircle className="h-4 w-4 text-orange-500" />,
  TERMINE: <CheckCircle className="h-4 w-4 text-green-500" />,
}

export default function CalendrierPage() {
  const [activites, setActivites] = useState<Activite[]>([])
  const [prochaines, setProchaines] = useState<Activite[]>([])
  const [loading, setLoading] = useState(true)
  const [showAddForm, setShowAddForm] = useState(false)
  const [currentMonth, setCurrentMonth] = useState(new Date())
  const [newActivite, setNewActivite] = useState({
    titre: '', typeActivite: 'SEMIS', dateDebut: new Date().toISOString().slice(0, 10),
    dateFin: '', priorite: 'MOYENNE', description: ''
  })

  const fetchData = useCallback(async () => {
    try {
      setLoading(true)
      const month = currentMonth.getMonth() + 1
      const year = currentMonth.getFullYear()
      const [activitesRes, prochainesRes] = await Promise.all([
        calendrierApi.getAll({ month, year }),
        calendrierApi.getProchaines()
      ])
      setActivites(activitesRes.data?.data || [])
      setProchaines(prochainesRes.data?.data || [])
    } catch (error) {
      console.error('Erreur chargement calendrier:', error)
    } finally {
      setLoading(false)
    }
  }, [currentMonth])

  useEffect(() => { fetchData() }, [fetchData])

  const handleAdd = async () => {
    try {
      await calendrierApi.create(newActivite)
      setShowAddForm(false)
      setNewActivite({ titre: '', typeActivite: 'SEMIS', dateDebut: new Date().toISOString().slice(0, 10), dateFin: '', priorite: 'MOYENNE', description: '' })
      fetchData()
    } catch (error) {
      console.error('Erreur création activité:', error)
    }
  }

  const handleComplete = async (id: string) => {
    try {
      await calendrierApi.markComplete(id)
      fetchData()
    } catch (error) {
      console.error('Erreur complétion:', error)
    }
  }

  const getDaysInMonth = (date: Date) => {
    const year = date.getFullYear()
    const month = date.getMonth()
    const firstDay = new Date(year, month, 1).getDay()
    const daysInMonth = new Date(year, month + 1, 0).getDate()
    return { firstDay: firstDay === 0 ? 6 : firstDay - 1, daysInMonth }
  }

  const getActivitesForDay = (day: number) => {
    const dateStr = `${currentMonth.getFullYear()}-${String(currentMonth.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    return activites.filter(a => a.dateDebut?.startsWith(dateStr))
  }

  const { firstDay, daysInMonth } = getDaysInMonth(currentMonth)
  const monthName = currentMonth.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Calendrier Agricole</h1>
          <p className="text-gray-500 mt-1">Planifiez et suivez vos activités agricoles</p>
        </div>
        <Button onClick={() => setShowAddForm(!showAddForm)} className="bg-green-600 hover:bg-green-700">
          <Plus className="h-4 w-4 mr-2" /> Nouvelle activité
        </Button>
      </div>

      {/* Add Form */}
      {showAddForm && (
        <Card>
          <CardHeader><CardTitle>Planifier une activité</CardTitle></CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <Input placeholder="Titre de l'activité" value={newActivite.titre} onChange={e => setNewActivite({ ...newActivite, titre: e.target.value })} />
              <select title="Type d'activité" className="border rounded-md px-3 py-2" value={newActivite.typeActivite} onChange={e => setNewActivite({ ...newActivite, typeActivite: e.target.value })}>
                {TYPES.map(t => <option key={t} value={t}>{t}</option>)}
              </select>
              <Input type="date" value={newActivite.dateDebut} onChange={e => setNewActivite({ ...newActivite, dateDebut: e.target.value })} />
              <Input type="date" placeholder="Date fin (optionnel)" value={newActivite.dateFin} onChange={e => setNewActivite({ ...newActivite, dateFin: e.target.value })} />
              <select title="Priorité" className="border rounded-md px-3 py-2" value={newActivite.priorite} onChange={e => setNewActivite({ ...newActivite, priorite: e.target.value })}>
                {PRIORITES.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
              <Input placeholder="Description (optionnel)" value={newActivite.description} onChange={e => setNewActivite({ ...newActivite, description: e.target.value })} />
            </div>
            <div className="flex gap-2">
              <Button onClick={handleAdd} className="bg-green-600 hover:bg-green-700">Planifier</Button>
              <Button variant="ghost" onClick={() => setShowAddForm(false)}>Annuler</Button>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Calendar Grid */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <div className="flex items-center justify-between">
              <Button variant="ghost" size="sm" onClick={() => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() - 1))}>
                <ChevronLeft className="h-4 w-4" />
              </Button>
              <CardTitle className="capitalize">{monthName}</CardTitle>
              <Button variant="ghost" size="sm" onClick={() => setCurrentMonth(new Date(currentMonth.getFullYear(), currentMonth.getMonth() + 1))}>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-12 text-gray-500">Chargement...</div>
            ) : (
              <div className="grid grid-cols-7 gap-1">
                {['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map(d => (
                  <div key={d} className="text-center text-xs font-medium text-gray-500 py-2">{d}</div>
                ))}
                {Array.from({ length: firstDay }).map((_, i) => <div key={`empty-${i}`} />)}
                {Array.from({ length: daysInMonth }).map((_, i) => {
                  const day = i + 1
                  const dayActivites = getActivitesForDay(day)
                  const isToday = day === new Date().getDate() && currentMonth.getMonth() === new Date().getMonth() && currentMonth.getFullYear() === new Date().getFullYear()
                  return (
                    <div key={day} className={`min-h-15 border rounded-md p-1 text-xs ${isToday ? 'bg-green-50 border-green-300' : 'border-gray-100'}`}>
                      <span className={`font-medium ${isToday ? 'text-green-700' : 'text-gray-700'}`}>{day}</span>
                      {dayActivites.slice(0, 2).map(a => (
                        <div key={a.id} className={`mt-0.5 truncate rounded px-1 text-[10px] ${a.statut === 'TERMINE' ? 'bg-green-100 text-green-600 line-through' : 'bg-blue-100 text-blue-600'}`}>
                          {a.titre}
                        </div>
                      ))}
                      {dayActivites.length > 2 && (
                        <span className="text-[10px] text-gray-400">+{dayActivites.length - 2}</span>
                      )}
                    </div>
                  )
                })}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Sidebar: Prochaines activités */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <CalendarDays className="h-5 w-5 text-green-600" />
              Prochaines activités
            </CardTitle>
          </CardHeader>
          <CardContent>
            {prochaines.length === 0 ? (
              <p className="text-gray-500 text-sm text-center py-8">Aucune activité planifiée</p>
            ) : (
              <div className="space-y-3">
                {prochaines.slice(0, 10).map(a => (
                  <div key={a.id} className="flex items-start gap-3 p-2 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800">
                    {statutIcons[a.statut] || <Clock className="h-4 w-4 text-gray-400" />}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-medium truncate">{a.titre}</p>
                      <p className="text-xs text-gray-500">{a.typeActivite} • {a.dateDebut ? new Date(a.dateDebut).toLocaleDateString('fr-FR') : 'Date non définie'}</p>
                      {a.parcelle && <p className="text-xs text-gray-400">{a.parcelle.nom}</p>}
                    </div>
                    <div className="flex items-center gap-2">
                      <Badge className={prioriteColors[a.priorite] || 'bg-gray-100 text-gray-700'} variant="secondary">
                        {a.priorite}
                      </Badge>
                      {a.statut !== 'TERMINE' && (
                        <Button size="sm" variant="ghost" onClick={() => handleComplete(a.id)}>
                          <CheckCircle className="h-4 w-4 text-green-500" />
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

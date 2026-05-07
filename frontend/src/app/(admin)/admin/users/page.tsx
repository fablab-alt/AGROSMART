'use client'

import { useEffect, useMemo, useState } from 'react'
import {
    CheckCircle,
    Download,
    Edit,
    Filter,
    Search,
    Trash2,
    UserPlus,
    Users,
    XCircle,
} from 'lucide-react'
import api from '@/lib/api'
import { logger } from '@/lib/logger'
import toast from 'react-hot-toast'

interface AdminUser {
    id: string
    nom: string
    prenoms: string
    email: string | null
    telephone: string
    role: 'ADMIN' | 'CONSEILLER' | 'PRODUCTEUR' | 'ACHETEUR' | 'FOURNISSEUR' | 'PARTENAIRE'
    status: 'ACTIF' | 'INACTIF' | 'SUSPENDU' | 'EN_ATTENTE'
    derniereConnexion?: string | null
}

interface CreateUserForm {
    nom: string
    prenoms: string
    email: string
    telephone: string
    password: string
    role: 'PRODUCTEUR' | 'CONSEILLER' | 'ACHETEUR' | 'FOURNISSEUR' | 'PARTENAIRE'
}

const DEFAULT_FORM: CreateUserForm = {
    nom: '',
    prenoms: '',
    email: '',
    telephone: '',
    password: '',
    role: 'PRODUCTEUR',
}

export default function UsersPage() {
    const [users, setUsers] = useState<AdminUser[]>([])
    const [loading, setLoading] = useState(true)
    const [error, setError] = useState<string | null>(null)
    const [searchTerm, setSearchTerm] = useState('')
    const [roleFilter, setRoleFilter] = useState<string>('ALL')
    const [creating, setCreating] = useState(false)
    const [form, setForm] = useState<CreateUserForm>(DEFAULT_FORM)

    const fetchUsers = async () => {
        setLoading(true)
        setError(null)
        try {
            const response = await api.get('/users', { params: { limit: 200 } })
            const data = (response.data?.data || []) as Array<Record<string, unknown>>
            const normalized: AdminUser[] = data.map((u) => ({
                id: String(u.id || ''),
                nom: String(u.nom || ''),
                prenoms: String(u.prenoms || ''),
                email: (u.email as string | null) || null,
                telephone: String(u.telephone || ''),
                role: String(u.role || 'PRODUCTEUR').toUpperCase() as AdminUser['role'],
                status: String(u.status || 'INACTIF').toUpperCase() as AdminUser['status'],
                derniereConnexion: (u.derniereConnexion as string | null) || null,
            }))
            setUsers(normalized)
        } catch (err: unknown) {
            const message =
                typeof err === 'object' && err !== null && 'response' in err
                    ? String((err as { response?: { data?: { message?: string } } }).response?.data?.message || 'Erreur API')
                    : 'Erreur inconnue'
            logger.error('Error fetching admin users', err instanceof Error ? err : undefined)
            setError(message)
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        fetchUsers()
    }, [])

    const filteredUsers = useMemo(() => {
        return users.filter((user) => {
            const fullName = `${user.prenoms} ${user.nom}`.toLowerCase()
            const email = (user.email || '').toLowerCase()
            const q = searchTerm.toLowerCase().trim()
            const matchesSearch = !q || fullName.includes(q) || email.includes(q) || user.telephone.includes(q)
            const matchesRole = roleFilter === 'ALL' || user.role === roleFilter
            return matchesSearch && matchesRole
        })
    }, [users, searchTerm, roleFilter])

    const getRoleColor = (role: string) => {
        switch (role) {
            case 'ADMIN':
                return 'bg-purple-100 text-purple-800'
            case 'CONSEILLER':
                return 'bg-blue-100 text-blue-800'
            case 'PRODUCTEUR':
                return 'bg-green-100 text-green-800'
            default:
                return 'bg-gray-100 text-gray-700'
        }
    }

    const handleCreateUser = async () => {
        if (!form.nom || !form.prenoms || !form.telephone || !form.password) {
            toast.error('Nom, prénoms, téléphone et mot de passe sont requis')
            return
        }

        setCreating(true)
        try {
            await api.post('/users', {
                nom: form.nom.trim(),
                prenoms: form.prenoms.trim(),
                email: form.email.trim() || undefined,
                telephone: form.telephone.trim(),
                password: form.password,
                role: form.role,
            })
            toast.success('Utilisateur créé avec succès')
            setForm(DEFAULT_FORM)
            await fetchUsers()
        } catch (err) {
            logger.error('Error creating user', err instanceof Error ? err : undefined)
            toast.error('Échec de création utilisateur')
        } finally {
            setCreating(false)
        }
    }

    const handleRoleChange = async (user: AdminUser) => {
        const nextRole = window.prompt(
            `Nouveau rôle pour ${user.prenoms} ${user.nom} (ADMIN, CONSEILLER, PRODUCTEUR, ACHETEUR, FOURNISSEUR, PARTENAIRE)`,
            user.role,
        )
        if (!nextRole) return
        const normalized = nextRole.toUpperCase()

        try {
            await api.put(`/users/${user.id}`, { role: normalized })
            toast.success('Rôle mis à jour')
            await fetchUsers()
        } catch (err) {
            logger.error('Error updating role', err instanceof Error ? err : undefined)
            toast.error('Mise à jour du rôle impossible')
        }
    }

    const handleStatusChange = async (user: AdminUser) => {
        const nextStatus = window.prompt(
            `Nouveau statut pour ${user.prenoms} ${user.nom} (ACTIF, INACTIF, SUSPENDU, EN_ATTENTE)`,
            user.status,
        )
        if (!nextStatus) return

        try {
            await api.put(`/users/${user.id}/status`, { status: nextStatus.toUpperCase() })
            toast.success('Statut mis à jour')
            await fetchUsers()
        } catch (err) {
            logger.error('Error updating status', err instanceof Error ? err : undefined)
            toast.error('Mise à jour du statut impossible')
        }
    }

    const handleDeactivate = async (user: AdminUser) => {
        if (!window.confirm(`Confirmer la désactivation de ${user.prenoms} ${user.nom} ?`)) return
        try {
            await api.delete(`/users/${user.id}`)
            toast.success('Utilisateur désactivé')
            await fetchUsers()
        } catch (err) {
            logger.error('Error deactivating user', err instanceof Error ? err : undefined)
            toast.error('Désactivation impossible')
        }
    }

    const handleExportUsers = async () => {
        try {
            await api.get('/analytics/export', {
                params: {
                    format: 'xlsx',
                    period: 30,
                    types: 'users',
                },
            })
            toast.success('Export utilisateurs lancé')
        } catch (err) {
            logger.error('Error exporting users', err instanceof Error ? err : undefined)
            toast.error('Export utilisateurs indisponible')
        }
    }

    return (
        <div className="p-6 max-w-7xl mx-auto space-y-6">
            <div className="flex justify-between items-center">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 flex items-center">
                        <Users className="w-8 h-8 mr-3 text-green-600" />
                        Gestion des Utilisateurs
                    </h1>
                    <p className="text-gray-500 mt-1">Création, mise à jour des rôles/statuts et désactivation des comptes</p>
                </div>
                <button
                    className="border border-gray-200 px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-gray-50"
                    onClick={handleExportUsers}
                >
                    <Download className="w-4 h-4" />
                    Export Excel
                </button>
            </div>

            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
                <div className="grid grid-cols-1 md:grid-cols-6 gap-3">
                    <input
                        value={form.prenoms}
                        onChange={(e) => setForm((prev) => ({ ...prev, prenoms: e.target.value }))}
                        placeholder="Prénoms"
                        className="border border-gray-200 rounded-lg px-3 py-2"
                    />
                    <input
                        value={form.nom}
                        onChange={(e) => setForm((prev) => ({ ...prev, nom: e.target.value }))}
                        placeholder="Nom"
                        className="border border-gray-200 rounded-lg px-3 py-2"
                    />
                    <input
                        value={form.telephone}
                        onChange={(e) => setForm((prev) => ({ ...prev, telephone: e.target.value }))}
                        placeholder="Téléphone"
                        className="border border-gray-200 rounded-lg px-3 py-2"
                    />
                    <input
                        value={form.email}
                        onChange={(e) => setForm((prev) => ({ ...prev, email: e.target.value }))}
                        placeholder="Email"
                        className="border border-gray-200 rounded-lg px-3 py-2"
                    />
                    <input
                        value={form.password}
                        onChange={(e) => setForm((prev) => ({ ...prev, password: e.target.value }))}
                        placeholder="Mot de passe"
                        type="password"
                        className="border border-gray-200 rounded-lg px-3 py-2"
                    />
                    <select
                        value={form.role}
                        onChange={(e) => setForm((prev) => ({ ...prev, role: e.target.value as CreateUserForm['role'] }))}
                        className="border border-gray-200 rounded-lg px-3 py-2"
                        title="Rôle du nouvel utilisateur"
                        aria-label="Rôle du nouvel utilisateur"
                    >
                        <option value="PRODUCTEUR">PRODUCTEUR</option>
                        <option value="CONSEILLER">CONSEILLER</option>
                        <option value="ACHETEUR">ACHETEUR</option>
                        <option value="FOURNISSEUR">FOURNISSEUR</option>
                        <option value="PARTENAIRE">PARTENAIRE</option>
                    </select>
                </div>
                <div className="mt-3 flex justify-end">
                    <button
                        className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg flex items-center transition-colors shadow-sm disabled:opacity-60"
                        onClick={handleCreateUser}
                        disabled={creating}
                    >
                        <UserPlus className="w-5 h-5 mr-2" />
                        {creating ? 'Création...' : 'Nouvel Utilisateur'}
                    </button>
                </div>
            </div>

            <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex flex-col md:flex-row gap-4 justify-between items-center">
                <div className="relative w-full md:w-96">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
                    <input
                        type="text"
                        placeholder="Rechercher par nom, email, téléphone..."
                        className="w-full pl-10 pr-4 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-green-500 bg-gray-50"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>

                <div className="flex items-center gap-4 w-full md:w-auto">
                    <div className="flex items-center gap-2">
                        <Filter className="w-5 h-5 text-gray-400" />
                        <span className="text-gray-600 font-medium">Rôle:</span>
                    </div>
                    <select
                        className="border border-gray-200 rounded-lg px-3 py-2 bg-gray-50"
                        value={roleFilter}
                        onChange={(e) => setRoleFilter(e.target.value)}
                        aria-label="Filtrer par rôle"
                    >
                        <option value="ALL">Tous les rôles</option>
                        <option value="PRODUCTEUR">PRODUCTEUR</option>
                        <option value="CONSEILLER">CONSEILLER</option>
                        <option value="ADMIN">ADMIN</option>
                        <option value="ACHETEUR">ACHETEUR</option>
                        <option value="FOURNISSEUR">FOURNISSEUR</option>
                        <option value="PARTENAIRE">PARTENAIRE</option>
                    </select>
                </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                <table className="w-full text-left">
                    <thead className="bg-gray-50 border-b border-gray-100">
                        <tr>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Utilisateur</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Rôle</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Statut</th>
                            <th className="px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Dernière connexion</th>
                            <th className="px-6 py-4 text-right text-xs font-semibold text-gray-500 uppercase">Actions</th>
                        </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100">
                        {loading ? (
                            <tr>
                                <td colSpan={5} className="px-6 py-12 text-center text-gray-500">Chargement des utilisateurs...</td>
                            </tr>
                        ) : error ? (
                            <tr>
                                <td colSpan={5} className="px-6 py-8 text-center text-red-500">Erreur: {error}</td>
                            </tr>
                        ) : filteredUsers.length > 0 ? (
                            filteredUsers.map((user) => (
                                <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                                    <td className="px-6 py-4">
                                        <div className="font-semibold text-gray-900">{user.prenoms} {user.nom}</div>
                                        <div className="text-sm text-gray-500">{user.email || user.telephone}</div>
                                    </td>
                                    <td className="px-6 py-4">
                                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${getRoleColor(user.role)}`}>
                                            {user.role}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4">
                                        <div className="flex items-center">
                                            {user.status === 'ACTIF' ? (
                                                <CheckCircle className="w-4 h-4 text-green-500 mr-2" />
                                            ) : (
                                                <XCircle className="w-4 h-4 text-red-500 mr-2" />
                                            )}
                                            <span className={`text-sm ${user.status === 'ACTIF' ? 'text-green-700' : 'text-red-700'}`}>
                                                {user.status}
                                            </span>
                                        </div>
                                    </td>
                                    <td className="px-6 py-4 text-sm text-gray-500">
                                        {user.derniereConnexion
                                            ? new Date(user.derniereConnexion).toLocaleString('fr-FR')
                                            : 'Jamais'}
                                    </td>
                                    <td className="px-6 py-4 text-right">
                                        <div className="flex justify-end gap-2">
                                            <button
                                                className="p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                                                aria-label={`Modifier le rôle de ${user.prenoms} ${user.nom}`}
                                                onClick={() => handleRoleChange(user)}
                                                title="Changer le rôle"
                                            >
                                                <Edit className="w-4 h-4" />
                                            </button>
                                            <button
                                                className="p-2 text-gray-500 hover:text-orange-600 hover:bg-orange-50 rounded-lg transition-colors"
                                                aria-label={`Modifier le statut de ${user.prenoms} ${user.nom}`}
                                                onClick={() => handleStatusChange(user)}
                                                title="Changer le statut"
                                            >
                                                <CheckCircle className="w-4 h-4" />
                                            </button>
                                            <button
                                                className="p-2 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                                                aria-label={`Désactiver ${user.prenoms} ${user.nom}`}
                                                onClick={() => handleDeactivate(user)}
                                                title="Désactiver le compte"
                                            >
                                                <Trash2 className="w-4 h-4" />
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <tr>
                                <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                                    Aucun utilisateur trouvé correspondant à votre recherche.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>

                <div className="bg-gray-50 px-6 py-4 border-t border-gray-100 text-sm text-gray-500">
                    Affichage de {filteredUsers.length} sur {users.length} utilisateurs
                </div>
            </div>
        </div>
    )
}

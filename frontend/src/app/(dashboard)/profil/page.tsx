'use client'

import { useState, useEffect } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import {
  User,
  Phone,
  Mail,
  MapPin,
  Calendar,
  Camera,
  Lock,
  Bell,
  Globe,
  Shield,
  Trash2,
  LogOut,
  Edit,
  Check,
  X,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { Spinner } from '@/components/ui/spinner'
import { useAuthStore } from '@/lib/store'
import toast from 'react-hot-toast'
import api from '@/lib/api'

const profileSchema = z.object({
  nom: z.string().min(2, 'Le nom doit contenir au moins 2 caractères'),
  prenoms: z.string().min(2, 'Le prénom doit contenir au moins 2 caractères'),
  email: z.string().email('Email invalide').optional().or(z.literal('')),
  telephone: z.string().min(10, 'Numéro de téléphone invalide'),
  adresse: z.string().optional(),
  ville: z.string().optional(),
  region: z.string().optional(),
  bio: z.string().max(500, 'La bio ne peut pas dépasser 500 caractères').optional(),
})

const passwordSchema = z.object({
  currentPassword: z.string().min(6, 'Mot de passe actuel requis'),
  newPassword: z.string().min(6, 'Le nouveau mot de passe doit contenir au moins 6 caractères'),
  confirmPassword: z.string(),
}).refine((data) => data.newPassword === data.confirmPassword, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirmPassword'],
})

type ProfileFormData = z.infer<typeof profileSchema>
type PasswordFormData = z.infer<typeof passwordSchema>

export default function ProfilPage() {
  const { user, logout } = useAuthStore()
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [showPasswordDialog, setShowPasswordDialog] = useState(false)
  const [showDeleteDialog, setShowDeleteDialog] = useState(false)
  const [isEditing, setIsEditing] = useState(false)

  const [notifications, setNotifications] = useState({
    alertesSms: true,
    alertesEmail: false,
    alertesPush: true,
    newsletter: false,
    rappels: true,
  })

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<ProfileFormData>({
    resolver: zodResolver(profileSchema),
    defaultValues: {
      nom: user?.nom || '',
      prenoms: user?.prenom || user?.prenoms || '',
      email: user?.email || '',
      telephone: user?.telephone || '',
      adresse: '',
      ville: '',
      region: '',
      bio: '',
    },
  })

  const {
    register: registerPassword,
    handleSubmit: handleSubmitPassword,
    formState: { errors: passwordErrors },
    reset: resetPassword,
  } = useForm<PasswordFormData>({
    resolver: zodResolver(passwordSchema),
  })

  useEffect(() => {
    // Fetch user profile
    const fetchProfile = async () => {
      try {
        const response = await api.get('/auth/me')
        reset(response.data)
      } catch {
        // Use store data as fallback
      }
    }
    fetchProfile()
  }, [reset])

  const onSubmit = async (data: ProfileFormData) => {
    setSaving(true)
    try {
      await api.put('/auth/me', data)
      toast.success('Profil mis à jour avec succès')
      setIsEditing(false)
    } catch {
      toast.error('Erreur lors de la mise à jour')
    } finally {
      setSaving(false)
    }
  }

  const onPasswordSubmit = async (data: PasswordFormData) => {
    setLoading(true)
    try {
      await api.put('/auth/change-password', {
        ancienMotDePasse: data.currentPassword,
        nouveauMotDePasse: data.newPassword,
      })
      toast.success('Mot de passe modifié avec succès')
      setShowPasswordDialog(false)
      resetPassword()
    } catch {
      toast.error('Erreur lors du changement de mot de passe')
    } finally {
      setLoading(false)
    }
  }

  const handleNotificationChange = async (key: keyof typeof notifications) => {
    const newValue = !notifications[key]
    setNotifications(prev => ({ ...prev, [key]: newValue }))
    
    try {
      // Store locally since no dedicated endpoint
      localStorage.setItem('notification_prefs', JSON.stringify({ ...notifications, [key]: newValue }))
      toast.success('Préférence mise à jour')
    } catch {
      setNotifications(prev => ({ ...prev, [key]: !newValue }))
      toast.error('Erreur lors de la mise à jour')
    }
  }

  const handleDeleteAccount = async () => {
    try {
      // Note: This endpoint may need to be implemented in the backend
      await api.delete('/auth/me')
      toast.success('Compte supprimé')
      logout()
    } catch {
      toast.error('Erreur lors de la suppression du compte')
    }
  }

  const handleLogout = () => {
    logout()
    toast.success('Déconnexion réussie')
  }

  return (
    <div className="p-4 md:p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900">
            Mon Profil
          </h1>
          <p className="text-gray-500 mt-1">
            Gérez vos informations personnelles et vos préférences
          </p>
        </div>
      </div>

      <Tabs defaultValue="profil" className="space-y-6">
        <TabsList className="grid w-full max-w-lg grid-cols-3">
          <TabsTrigger value="profil" className="gap-2">
            <User className="h-4 w-4" />
            <span className="hidden sm:inline">Profil</span>
          </TabsTrigger>
          <TabsTrigger value="notifications" className="gap-2">
            <Bell className="h-4 w-4" />
            <span className="hidden sm:inline">Notifications</span>
          </TabsTrigger>
          <TabsTrigger value="securite" className="gap-2">
            <Shield className="h-4 w-4" />
            <span className="hidden sm:inline">Sécurité</span>
          </TabsTrigger>
        </TabsList>

        {/* Profile Tab */}
        <TabsContent value="profil" className="space-y-6">
          {/* Avatar Card */}
          <Card>
            <CardContent className="p-6">
              <div className="flex flex-col sm:flex-row items-center gap-6">
                <div className="relative">
                  <Avatar className="h-24 w-24">
                    <AvatarImage src="" />
                    <AvatarFallback className="text-2xl bg-primary text-white">
                      {(user?.prenom || user?.prenoms)?.[0]}{user?.nom?.[0]}
                    </AvatarFallback>
                  </Avatar>
                  <button
                    className="absolute bottom-0 right-0 p-2 bg-primary text-white rounded-full hover:bg-primary/90 transition-colors"
                    aria-label="Changer la photo"
                  >
                    <Camera className="h-4 w-4" />
                  </button>
                </div>
                <div className="text-center sm:text-left">
                  <h2 className="text-xl font-bold">
                    {user?.prenom || user?.prenoms} {user?.nom}
                  </h2>
                  <p className="text-gray-500">{user?.telephone}</p>
                  <div className="flex items-center gap-2 mt-2 justify-center sm:justify-start">
                    <Badge className="bg-green-100 text-green-800">
                      {user?.role === 'producteur' ? 'Producteur' : 
                       user?.role === 'partenaire' ? 'Partenaire' : 
                       user?.role === 'conseiller' ? 'Conseiller' : 'Admin'}
                    </Badge>
                    <Badge variant="outline">
                      <Calendar className="h-3 w-3 mr-1" />
                      Membre depuis 2024
                    </Badge>
                  </div>
                </div>
                <div className="sm:ml-auto">
                  {!isEditing ? (
                    <Button onClick={() => setIsEditing(true)} className="gap-2">
                      <Edit className="h-4 w-4" />
                      Modifier
                    </Button>
                  ) : (
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        onClick={() => setIsEditing(false)}
                        className="gap-2"
                      >
                        <X className="h-4 w-4" />
                        Annuler
                      </Button>
                      <Button
                        onClick={handleSubmit(onSubmit)}
                        disabled={saving}
                        className="gap-2"
                      >
                        {saving ? (
                          <Spinner className="h-4 w-4" />
                        ) : (
                          <Check className="h-4 w-4" />
                        )}
                        Sauvegarder
                      </Button>
                    </div>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Profile Form */}
          <Card>
            <CardHeader>
              <CardTitle>Informations personnelles</CardTitle>
              <CardDescription>
                Mettez à jour vos informations de contact
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <User className="h-4 w-4 text-gray-500" />
                      Prénoms
                    </label>
                    <Input
                      {...register('prenoms')}
                      disabled={!isEditing}
                      placeholder="Vos prénoms"
                    />
                    {errors.prenoms && (
                      <p className="text-sm text-red-500">{errors.prenoms.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <User className="h-4 w-4 text-gray-500" />
                      Nom
                    </label>
                    <Input
                      {...register('nom')}
                      disabled={!isEditing}
                      placeholder="Votre nom"
                    />
                    {errors.nom && (
                      <p className="text-sm text-red-500">{errors.nom.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <Phone className="h-4 w-4 text-gray-500" />
                      Téléphone
                    </label>
                    <Input
                      {...register('telephone')}
                      disabled={!isEditing}
                      placeholder="+225 XX XX XX XX XX"
                    />
                    {errors.telephone && (
                      <p className="text-sm text-red-500">{errors.telephone.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <Mail className="h-4 w-4 text-gray-500" />
                      Email (optionnel)
                    </label>
                    <Input
                      {...register('email')}
                      disabled={!isEditing}
                      type="email"
                      placeholder="votre@email.com"
                    />
                    {errors.email && (
                      <p className="text-sm text-red-500">{errors.email.message}</p>
                    )}
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <MapPin className="h-4 w-4 text-gray-500" />
                      Région
                    </label>
                    <select
                      {...register('region')}
                      disabled={!isEditing}
                      className="w-full px-4 py-2 border rounded-lg disabled:bg-gray-50"
                      title="Région"
                    >
                      <option value="">Sélectionner une région</option>
                      <option value="abidjan">Abidjan</option>
                      <option value="yamoussoukro">Yamoussoukro</option>
                      <option value="bouake">Bouaké</option>
                      <option value="san-pedro">San-Pédro</option>
                      <option value="daloa">Daloa</option>
                      <option value="korhogo">Korhogo</option>
                    </select>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <MapPin className="h-4 w-4 text-gray-500" />
                      Ville
                    </label>
                    <Input
                      {...register('ville')}
                      disabled={!isEditing}
                      placeholder="Votre ville"
                    />
                  </div>

                  <div className="space-y-2 md:col-span-2">
                    <label className="text-sm font-medium flex items-center gap-2">
                      <MapPin className="h-4 w-4 text-gray-500" />
                      Adresse complète
                    </label>
                    <Input
                      {...register('adresse')}
                      disabled={!isEditing}
                      placeholder="Votre adresse"
                    />
                  </div>

                  <div className="space-y-2 md:col-span-2">
                    <label className="text-sm font-medium">Bio</label>
                    <Textarea
                      {...register('bio')}
                      disabled={!isEditing}
                      placeholder="Parlez-nous de vous et de votre exploitation..."
                      rows={4}
                    />
                    {errors.bio && (
                      <p className="text-sm text-red-500">{errors.bio.message}</p>
                    )}
                  </div>
                </div>
              </form>
            </CardContent>
          </Card>

          {/* Langue */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Globe className="h-5 w-5" />
                Langue
              </CardTitle>
              <CardDescription>
                Choisissez la langue de l&apos;application
              </CardDescription>
            </CardHeader>
            <CardContent>
              <select
                className="w-full max-w-xs px-4 py-2 border rounded-lg"
                title="Langue de l'application"
                defaultValue="fr"
              >
                <option value="fr">Français</option>
                <option value="bci">Baoulé</option>
                <option value="dyu">Dioula</option>
              </select>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Notifications Tab */}
        <TabsContent value="notifications" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Préférences de notifications</CardTitle>
              <CardDescription>
                Configurez comment vous souhaitez être notifié
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between py-3 border-b">
                <div>
                  <p className="font-medium">Alertes SMS</p>
                  <p className="text-sm text-gray-500">
                    Recevez les alertes critiques par SMS
                  </p>
                </div>
                <Switch
                  checked={notifications.alertesSms}
                  onCheckedChange={() => handleNotificationChange('alertesSms')}
                />
              </div>

              <div className="flex items-center justify-between py-3 border-b">
                <div>
                  <p className="font-medium">Alertes Email</p>
                  <p className="text-sm text-gray-500">
                    Recevez un résumé des alertes par email
                  </p>
                </div>
                <Switch
                  checked={notifications.alertesEmail}
                  onCheckedChange={() => handleNotificationChange('alertesEmail')}
                />
              </div>

              <div className="flex items-center justify-between py-3 border-b">
                <div>
                  <p className="font-medium">Notifications Push</p>
                  <p className="text-sm text-gray-500">
                    Notifications sur votre appareil
                  </p>
                </div>
                <Switch
                  checked={notifications.alertesPush}
                  onCheckedChange={() => handleNotificationChange('alertesPush')}
                />
              </div>

              <div className="flex items-center justify-between py-3 border-b">
                <div>
                  <p className="font-medium">Rappels</p>
                  <p className="text-sm text-gray-500">
                    Rappels pour les tâches et les traitements
                  </p>
                </div>
                <Switch
                  checked={notifications.rappels}
                  onCheckedChange={() => handleNotificationChange('rappels')}
                />
              </div>

              <div className="flex items-center justify-between py-3">
                <div>
                  <p className="font-medium">Newsletter</p>
                  <p className="text-sm text-gray-500">
                    Recevez nos conseils et actualités
                  </p>
                </div>
                <Switch
                  checked={notifications.newsletter}
                  onCheckedChange={() => handleNotificationChange('newsletter')}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Security Tab */}
        <TabsContent value="securite" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Lock className="h-5 w-5" />
                Mot de passe
              </CardTitle>
              <CardDescription>
                Gérez la sécurité de votre compte
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button
                variant="outline"
                onClick={() => setShowPasswordDialog(true)}
                className="gap-2"
              >
                <Lock className="h-4 w-4" />
                Changer le mot de passe
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Sessions actives</CardTitle>
              <CardDescription>
                Appareils connectés à votre compte
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg">
                <div className="flex items-center gap-3">
                  <div className="w-2 h-2 bg-green-500 rounded-full" />
                  <div>
                    <p className="font-medium">Cet appareil</p>
                    <p className="text-sm text-gray-500">Navigateur Web - Connecté maintenant</p>
                  </div>
                </div>
                <Badge className="bg-green-100 text-green-800">Actif</Badge>
              </div>
            </CardContent>
          </Card>

          <Card className="border-red-200">
            <CardHeader>
              <CardTitle className="text-red-600 flex items-center gap-2">
                <Trash2 className="h-5 w-5" />
                Zone dangereuse
              </CardTitle>
              <CardDescription>
                Actions irréversibles sur votre compte
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button
                variant="outline"
                onClick={handleLogout}
                className="gap-2"
              >
                <LogOut className="h-4 w-4" />
                Déconnexion
              </Button>
              <Button
                variant="outline"
                className="gap-2 text-red-600 hover:text-red-700 hover:bg-red-50"
                onClick={() => setShowDeleteDialog(true)}
              >
                <Trash2 className="h-4 w-4" />
                Supprimer mon compte
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Password Dialog */}
      <Dialog open={showPasswordDialog} onOpenChange={setShowPasswordDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Changer le mot de passe</DialogTitle>
            <DialogDescription>
              Entrez votre mot de passe actuel et le nouveau mot de passe
            </DialogDescription>
          </DialogHeader>
          <form onSubmit={handleSubmitPassword(onPasswordSubmit)} className="space-y-4">
            <div className="space-y-2">
              <label className="text-sm font-medium">Mot de passe actuel</label>
              <Input
                {...registerPassword('currentPassword')}
                type="password"
                placeholder="••••••••"
              />
              {passwordErrors.currentPassword && (
                <p className="text-sm text-red-500">{passwordErrors.currentPassword.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Nouveau mot de passe</label>
              <Input
                {...registerPassword('newPassword')}
                type="password"
                placeholder="••••••••"
              />
              {passwordErrors.newPassword && (
                <p className="text-sm text-red-500">{passwordErrors.newPassword.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <label className="text-sm font-medium">Confirmer le mot de passe</label>
              <Input
                {...registerPassword('confirmPassword')}
                type="password"
                placeholder="••••••••"
              />
              {passwordErrors.confirmPassword && (
                <p className="text-sm text-red-500">{passwordErrors.confirmPassword.message}</p>
              )}
            </div>
            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                onClick={() => setShowPasswordDialog(false)}
              >
                Annuler
              </Button>
              <Button type="submit" disabled={loading}>
                {loading ? <Spinner className="h-4 w-4" /> : 'Changer'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Delete Account Dialog */}
      <Dialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle className="text-red-600">Supprimer le compte</DialogTitle>
            <DialogDescription>
              Cette action est irréversible. Toutes vos données seront supprimées.
            </DialogDescription>
          </DialogHeader>
          <div className="py-4">
            <p className="text-sm text-gray-600">
              En supprimant votre compte, vous perdrez :
            </p>
            <ul className="mt-2 text-sm text-gray-600 space-y-1">
              <li>• Toutes vos parcelles et données de cultures</li>
              <li>• L&apos;historique de vos mesures et diagnostics</li>
              <li>• Vos commandes et transactions</li>
              <li>• Votre progression dans les formations</li>
            </ul>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setShowDeleteDialog(false)}
            >
              Annuler
            </Button>
            <Button
              variant="destructive"
              onClick={handleDeleteAccount}
              className="bg-red-600 hover:bg-red-700"
            >
              Supprimer définitivement
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

'use client'

import { useState, useEffect } from 'react'
import {
  Settings,
  User,
  Bell,
  Shield,
  Globe,
  Palette,
  Smartphone,
  Database,
  HelpCircle,
  LogOut,
  ChevronRight,
  Moon,
  Sun,
  Volume2,
  VolumeX,
  Mail,
  MessageSquare,
  Wifi,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Switch } from '@/components/ui/switch'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import toast from 'react-hot-toast'
import { useAuthStore } from '@/lib/store'
import api from '@/lib/api'

interface SettingsState {
  // Notifications
  emailNotifications: boolean
  smsNotifications: boolean
  pushNotifications: boolean
  alertesCritiques: boolean
  alertesImportantes: boolean
  alertesInfo: boolean
  // Apparence
  theme: 'light' | 'dark' | 'system'
  langue: string
  // Données
  syncAuto: boolean
  frequenceSync: string
  stockageLocal: boolean
  // Son
  soundEnabled: boolean
}

const defaultSettings: SettingsState = {
  emailNotifications: true,
  smsNotifications: true,
  pushNotifications: true,
  alertesCritiques: true,
  alertesImportantes: true,
  alertesInfo: false,
  theme: 'light',
  langue: 'fr',
  syncAuto: true,
  frequenceSync: '15',
  stockageLocal: true,
  soundEnabled: true,
}

export default function SettingsPage() {
  const [settings, setSettings] = useState<SettingsState>(defaultSettings)
  const { logout } = useAuthStore()

  useEffect(() => {
    // Charger les paramètres depuis l'API, avec fallback localStorage
    const loadSettings = async () => {
      try {
        const res = await api.get('/users/settings')
        if (res.data?.success && res.data.data) {
          setSettings(prev => ({ ...prev, ...res.data.data }))
          localStorage.setItem('agrismart_settings', JSON.stringify(res.data.data))
        }
      } catch {
        // Fallback: charger depuis localStorage (offline)
        const savedSettings = localStorage.getItem('agrismart_settings')
        if (savedSettings) {
          try { setSettings(JSON.parse(savedSettings)) } catch { /* ignore */ }
        }
      }
    }
    loadSettings()
  }, [])

  const updateSetting = <K extends keyof SettingsState>(key: K, value: SettingsState[K]) => {
    setSettings(prev => {
      const newSettings = { ...prev, [key]: value }
      // Sauvegarder en local immédiatement
      localStorage.setItem('agrismart_settings', JSON.stringify(newSettings))
      // Persister vers l'API en arrière-plan
      api.patch('/users/settings', newSettings).catch(() => {
        // Offline: les données sont déjà en localStorage
      })
      return newSettings
    })
    toast.success('Paramètre mis à jour')
  }

  const handleLogout = () => {
    logout()
    window.location.href = '/login'
  }

  const SettingRow = ({ 
    icon: Icon, 
    title, 
    description, 
    children 
  }: { 
    icon: React.ElementType
    title: string
    description?: string
    children: React.ReactNode 
  }) => (
    <div className="flex items-center justify-between py-4 border-b last:border-0">
      <div className="flex items-center gap-3">
        <div className="h-10 w-10 rounded-full bg-gray-100 flex items-center justify-center">
          <Icon className="h-5 w-5 text-gray-600" />
        </div>
        <div>
          <p className="font-medium text-gray-900">{title}</p>
          {description && <p className="text-sm text-gray-500">{description}</p>}
        </div>
      </div>
      {children}
    </div>
  )

  return (
    <div className="p-4 md:p-6 space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl md:text-3xl font-bold text-gray-900 flex items-center gap-2">
          <Settings className="h-7 w-7 text-gray-600" />
          Paramètres
        </h1>
        <p className="text-gray-500 mt-1">
          Gérez vos préférences et paramètres de l&apos;application
        </p>
      </div>

      <Tabs defaultValue="notifications" className="space-y-6">
        <TabsList className="grid grid-cols-2 md:grid-cols-4 w-full">
          <TabsTrigger value="notifications" className="flex items-center gap-2">
            <Bell className="h-4 w-4" />
            <span className="hidden sm:inline">Notifications</span>
          </TabsTrigger>
          <TabsTrigger value="apparence" className="flex items-center gap-2">
            <Palette className="h-4 w-4" />
            <span className="hidden sm:inline">Apparence</span>
          </TabsTrigger>
          <TabsTrigger value="donnees" className="flex items-center gap-2">
            <Database className="h-4 w-4" />
            <span className="hidden sm:inline">Données</span>
          </TabsTrigger>
          <TabsTrigger value="compte" className="flex items-center gap-2">
            <User className="h-4 w-4" />
            <span className="hidden sm:inline">Compte</span>
          </TabsTrigger>
        </TabsList>

        {/* Notifications */}
        <TabsContent value="notifications">
          <Card>
            <CardHeader>
              <CardTitle>Préférences de notification</CardTitle>
              <CardDescription>
                Choisissez comment vous souhaitez être notifié
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-0">
              <SettingRow icon={Mail} title="Notifications par email" description="Recevoir les alertes par email">
                <Switch
                  checked={settings.emailNotifications}
                  onCheckedChange={(checked) => updateSetting('emailNotifications', checked)}
                />
              </SettingRow>
              
              <SettingRow icon={MessageSquare} title="Notifications SMS" description="Recevoir les alertes par SMS">
                <Switch
                  checked={settings.smsNotifications}
                  onCheckedChange={(checked) => updateSetting('smsNotifications', checked)}
                />
              </SettingRow>

              <SettingRow icon={Smartphone} title="Notifications push" description="Notifications dans l'application">
                <Switch
                  checked={settings.pushNotifications}
                  onCheckedChange={(checked) => updateSetting('pushNotifications', checked)}
                />
              </SettingRow>

              <SettingRow icon={settings.soundEnabled ? Volume2 : VolumeX} title="Sons" description="Activer les sons de notification">
                <Switch
                  checked={settings.soundEnabled}
                  onCheckedChange={(checked) => updateSetting('soundEnabled', checked)}
                />
              </SettingRow>
            </CardContent>
          </Card>

          <Card className="mt-6">
            <CardHeader>
              <CardTitle>Types d&apos;alertes</CardTitle>
              <CardDescription>
                Sélectionnez les types d&apos;alertes que vous souhaitez recevoir
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-0">
              <SettingRow icon={Bell} title="Alertes critiques" description="Urgences nécessitant une action immédiate">
                <Switch
                  checked={settings.alertesCritiques}
                  onCheckedChange={(checked) => updateSetting('alertesCritiques', checked)}
                />
              </SettingRow>
              
              <SettingRow icon={Bell} title="Alertes importantes" description="Situations nécessitant attention">
                <Switch
                  checked={settings.alertesImportantes}
                  onCheckedChange={(checked) => updateSetting('alertesImportantes', checked)}
                />
              </SettingRow>

              <SettingRow icon={Bell} title="Informations" description="Mises à jour et conseils généraux">
                <Switch
                  checked={settings.alertesInfo}
                  onCheckedChange={(checked) => updateSetting('alertesInfo', checked)}
                />
              </SettingRow>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Apparence */}
        <TabsContent value="apparence">
          <Card>
            <CardHeader>
              <CardTitle>Apparence</CardTitle>
              <CardDescription>
                Personnalisez l&apos;apparence de l&apos;application
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-0">
              <SettingRow 
                icon={settings.theme === 'dark' ? Moon : Sun} 
                title="Thème" 
                description="Choisissez le thème de l'application"
              >
                <Select 
                  value={settings.theme} 
                  onValueChange={(value: 'light' | 'dark' | 'system') => updateSetting('theme', value)}
                >
                  <SelectTrigger className="w-[140px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="light">Clair</SelectItem>
                    <SelectItem value="dark">Sombre</SelectItem>
                    <SelectItem value="system">Système</SelectItem>
                  </SelectContent>
                </Select>
              </SettingRow>

              <SettingRow icon={Globe} title="Langue" description="Langue de l'interface">
                <Select 
                  value={settings.langue} 
                  onValueChange={(value) => updateSetting('langue', value)}
                >
                  <SelectTrigger className="w-[140px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="fr">Français</SelectItem>
                    <SelectItem value="en">English</SelectItem>
                  </SelectContent>
                </Select>
              </SettingRow>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Données */}
        <TabsContent value="donnees">
          <Card>
            <CardHeader>
              <CardTitle>Synchronisation</CardTitle>
              <CardDescription>
                Gérez la synchronisation de vos données
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-0">
              <SettingRow icon={Wifi} title="Synchronisation automatique" description="Synchroniser les données automatiquement">
                <Switch
                  checked={settings.syncAuto}
                  onCheckedChange={(checked) => updateSetting('syncAuto', checked)}
                />
              </SettingRow>

              <SettingRow icon={Database} title="Fréquence de synchronisation" description="Intervalle entre les synchronisations">
                <Select 
                  value={settings.frequenceSync} 
                  onValueChange={(value) => updateSetting('frequenceSync', value)}
                  disabled={!settings.syncAuto}
                >
                  <SelectTrigger className="w-[140px]">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="5">5 minutes</SelectItem>
                    <SelectItem value="15">15 minutes</SelectItem>
                    <SelectItem value="30">30 minutes</SelectItem>
                    <SelectItem value="60">1 heure</SelectItem>
                  </SelectContent>
                </Select>
              </SettingRow>

              <SettingRow icon={Smartphone} title="Stockage local" description="Sauvegarder les données hors ligne">
                <Switch
                  checked={settings.stockageLocal}
                  onCheckedChange={(checked) => updateSetting('stockageLocal', checked)}
                />
              </SettingRow>
            </CardContent>
          </Card>

          <Card className="mt-6">
            <CardHeader>
              <CardTitle>Gestion des données</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button variant="outline" className="w-full justify-between">
                Exporter mes données
                <ChevronRight className="h-4 w-4" />
              </Button>
              <Button variant="outline" className="w-full justify-between text-red-600 hover:text-red-700">
                Supprimer le cache local
                <ChevronRight className="h-4 w-4" />
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Compte */}
        <TabsContent value="compte">
          <Card>
            <CardHeader>
              <CardTitle>Sécurité</CardTitle>
              <CardDescription>
                Gérez la sécurité de votre compte
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button variant="outline" className="w-full justify-between">
                <div className="flex items-center gap-3">
                  <Shield className="h-5 w-5" />
                  Changer le mot de passe
                </div>
                <ChevronRight className="h-4 w-4" />
              </Button>
              <Button variant="outline" className="w-full justify-between">
                <div className="flex items-center gap-3">
                  <Smartphone className="h-5 w-5" />
                  Authentification à deux facteurs
                </div>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </CardContent>
          </Card>

          <Card className="mt-6">
            <CardHeader>
              <CardTitle>Aide et support</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button variant="outline" className="w-full justify-between">
                <div className="flex items-center gap-3">
                  <HelpCircle className="h-5 w-5" />
                  Centre d&apos;aide
                </div>
                <ChevronRight className="h-4 w-4" />
              </Button>
              <Button variant="outline" className="w-full justify-between">
                <div className="flex items-center gap-3">
                  <MessageSquare className="h-5 w-5" />
                  Contacter le support
                </div>
                <ChevronRight className="h-4 w-4" />
              </Button>
            </CardContent>
          </Card>

          <Card className="mt-6 border-red-200">
            <CardContent className="pt-6">
              <Button 
                variant="outline" 
                className="w-full text-red-600 hover:text-red-700 hover:bg-red-50"
                onClick={handleLogout}
              >
                <LogOut className="h-5 w-5 mr-2" />
                Déconnexion
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}

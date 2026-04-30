'use client'

import { useMemo, useState } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import {
  MapPin,
  Bell,
  TrendingUp,
  Lock,
  ArrowRight,
  CloudSun,
  ShoppingCart,
  FileBarChart,
  MessageSquare,
  Settings2,
  Satellite,
} from 'lucide-react'
import { Button, Card, CardContent, CardHeader, CardTitle, Badge } from '@/components/ui'
import { setDiscoveryMode } from '@/lib/discoveryMode'

const readOnlyModules = [
  {
    title: 'Vue d’ensemble parcelles',
    description: 'Explorez les cartes, indicateurs de santé et alertes en mode lecture seule.',
    icon: MapPin,
    action: 'Explorer',
    href: '/parcelles?discover=1',
  },
  {
    title: 'Tendances de production',
    description: 'Parcourez les courbes de rendement et de progression par période.',
    icon: TrendingUp,
    action: 'Voir les tendances',
    href: '/performance?discover=1',
  },
  {
    title: 'Météo et capteurs',
    description: 'Consultez un aperçu des signaux météo et capteurs sans modifier les réglages.',
    icon: CloudSun,
    action: 'Consulter',
    href: '/meteo?discover=1',
  },
  {
    title: 'Marketplace en lecture',
    description: 'Découvrez le catalogue et les prix du marché sans possibilité de commande.',
    icon: ShoppingCart,
    action: 'Parcourir',
    href: '/marketplace?discover=1',
  },
]

const essentialLockedModules = [
  {
    title: 'Créer / modifier des parcelles',
    description: 'Actions de création et édition réservées aux comptes connectés.',
    icon: MapPin,
  },
  {
    title: 'Envoyer des messages',
    description: 'La messagerie producteur-reseau reste protegee en mode decouverte.',
    icon: MessageSquare,
  },
  {
    title: 'Configurer les capteurs',
    description: 'Aucune modification d’équipement ou de configuration n’est autorisée.',
    icon: Settings2,
  },
  {
    title: 'Exporter des rapports',
    description: 'Les exports et actions sensibles nécessitent une authentification.',
    icon: FileBarChart,
  },
]

const statsByPeriod = {
  '7j': {
    parcelles: '12',
    alertes: '3',
    capteurs: '18',
    production: '2.1t',
    productionLabel: '+6% sur 7 jours',
  },
  '30j': {
    parcelles: '12',
    alertes: '5',
    capteurs: '18',
    production: '8.4t',
    productionLabel: '+14% sur 30 jours',
  },
  '90j': {
    parcelles: '12',
    alertes: '9',
    capteurs: '18',
    production: '24.6t',
    productionLabel: '+18% sur 90 jours',
  },
}

type PeriodKey = keyof typeof statsByPeriod

export default function DashboardProducteurPreviewPage() {
  const [period, setPeriod] = useState<PeriodKey>('30j')
  const stats = useMemo(() => statsByPeriod[period], [period])

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="sticky top-0 z-20 border-b border-slate-200 bg-white/95 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6">
          <Link href="/" className="flex items-center text-slate-900">
            <div className="relative h-11 w-36">
              <Image
                src="/logo.png"
                alt="AgroSmart"
                fill
                className="object-contain object-left"
                priority
              />
            </div>
          </Link>
          <div className="flex items-center gap-2">
            <Link href="/login">
              <Button variant="ghost">Connexion</Button>
            </Link>
            <Link href="/register">
              <Button className="bg-green-600 hover:bg-green-700">Créer un compte</Button>
            </Link>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-6xl space-y-8 px-4 py-8 sm:px-6">
        <section className="rounded-2xl border border-green-100 bg-white p-6 shadow-sm">
          <div className="mb-4 flex items-center gap-3">
            <Badge variant="warning" className="bg-amber-100 text-amber-800 hover:bg-amber-100">
              Mode découverte
            </Badge>
            <Badge variant="outline" className="border-slate-300 text-slate-700">
              Dashboard producteur
            </Badge>
          </div>
          <h1 className="text-2xl font-bold text-slate-900 sm:text-3xl">
            Accès au dashboard producteur
          </h1>
          <p className="mt-2 max-w-3xl text-slate-600">
            Le mode découverte permet de naviguer librement dans les vues de consultation. Seules les
            actions essentielles et sensibles restent bloquées (création, édition, export, messagerie).
          </p>
          <p className="mt-2 text-sm font-medium text-slate-700">
            L’interface admin n’est jamais accessible depuis ce mode.
          </p>
          <div className="mt-5 flex flex-wrap gap-3">
            <Link href="/login">
              <Button className="bg-green-600 hover:bg-green-700">
                Se connecter
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </Link>
            <Link href="/register">
              <Button variant="outline" className="border-green-200 text-green-700 hover:bg-green-50">
                Créer un compte
              </Button>
            </Link>
          </div>
        </section>

        <section className="rounded-2xl border border-slate-200 bg-white p-4 sm:p-6">
          <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
            <h2 className="text-lg font-semibold text-slate-900">Exploration des indicateurs</h2>
            <div className="flex items-center gap-2 rounded-lg bg-slate-100 p-1">
              {(['7j', '30j', '90j'] as PeriodKey[]).map((key) => (
                <button
                  key={key}
                  type="button"
                  onClick={() => setPeriod(key)}
                  className={`rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                    key === period ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  {key}
                </button>
              ))}
            </div>
          </div>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <Card>
              <CardHeader>
                <CardTitle className="text-sm text-slate-500">Parcelles suivies</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-slate-900">{stats.parcelles}</p>
                <p className="mt-1 text-sm text-green-700">Vue disponible</p>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-sm text-slate-500">Alertes actives</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-slate-900">{stats.alertes}</p>
                <p className="mt-1 text-sm text-amber-700">Lecture seule</p>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-sm text-slate-500">Capteurs en ligne</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-slate-900">{stats.capteurs}</p>
                <p className="mt-1 text-sm text-blue-700">Configuration verrouillée</p>
              </CardContent>
            </Card>
            <Card>
              <CardHeader>
                <CardTitle className="text-sm text-slate-500">Production estimee</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-slate-900">{stats.production}</p>
                <p className="mt-1 text-sm text-emerald-700">{stats.productionLabel}</p>
              </CardContent>
            </Card>
          </div>
        </section>

        <section>
          <div className="mb-3 flex items-center gap-2">
            <Satellite className="h-4 w-4 text-green-700" />
            <h2 className="text-lg font-semibold text-slate-900">Modules libres en découverte</h2>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            {readOnlyModules.map((feature) => {
              const Icon = feature.icon
              return (
                <Card key={feature.title} className="relative overflow-hidden">
                  <CardContent className="p-5">
                    <div className="mb-3 flex items-center justify-between">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-green-50 text-green-700">
                        <Icon className="h-5 w-5" />
                      </div>
                      <Badge variant="outline" className="border-green-200 text-green-700">
                        Libre
                      </Badge>
                    </div>
                    <h3 className="text-lg font-semibold text-slate-900">{feature.title}</h3>
                    <p className="mt-1 text-sm text-slate-600">{feature.description}</p>
                    <div className="mt-4">
                      <Link
                        href={feature.href}
                        onClick={() => setDiscoveryMode(true)}
                      >
                        <Button variant="outline" className="w-full border-green-200 text-green-700 hover:bg-green-50">
                          {feature.action}
                        </Button>
                      </Link>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </section>

        <section>
          <div className="mb-3 flex items-center gap-2">
            <Lock className="h-4 w-4 text-amber-700" />
            <h2 className="text-lg font-semibold text-slate-900">Fonctionnalités essentielles limitées</h2>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            {essentialLockedModules.map((feature) => {
              const Icon = feature.icon
              return (
                <Card key={feature.title} className="relative overflow-hidden border-amber-100">
                  <CardContent className="p-5">
                    <div className="mb-3 flex items-center justify-between">
                      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-50 text-amber-700">
                        <Icon className="h-5 w-5" />
                      </div>
                      <Lock className="h-4 w-4 text-slate-400" />
                    </div>
                    <h3 className="text-lg font-semibold text-slate-900">{feature.title}</h3>
                    <p className="mt-1 text-sm text-slate-600">{feature.description}</p>
                    <div className="mt-4">
                      <Link href="/login">
                        <Button variant="outline" className="w-full border-slate-300 text-slate-700 hover:bg-slate-50">
                          Débloquer avec connexion
                        </Button>
                      </Link>
                    </div>
                  </CardContent>
                </Card>
              )
            })}
          </div>
        </section>

        <section className="rounded-2xl border border-green-100 bg-green-50 p-5">
          <div className="flex items-start gap-3">
            <Bell className="mt-0.5 h-4 w-4 text-green-700" />
            <div>
              <p className="text-sm font-semibold text-green-900">Mode découverte sécurisé</p>
              <p className="mt-1 text-sm text-green-800">
                Les parcours admin ne sont pas exposés ici. Pour toute action critique, une authentification
                valide est obligatoire côté frontend et backend.
              </p>
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}

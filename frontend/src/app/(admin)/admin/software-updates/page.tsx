'use client'

import { useEffect, useMemo, useState } from 'react'
import { CheckCircle2, Cpu, RefreshCcw, Save, TriangleAlert, Wrench } from 'lucide-react'
import api from '@/lib/api'
import toast from 'react-hot-toast'
import { logger } from '@/lib/logger'

interface SensorRow {
  id: string
  nom?: string
  firmwareVersion?: string
  status?: string
}

interface UpdateSettings {
  mobile_min_version: string
  mobile_latest_version: string
  backend_target_version: string
  capteur_target_firmware: string
  force_mobile_update: boolean
  force_capteur_update: boolean
  maintenance_window: string
}

const DEFAULT_SETTINGS: UpdateSettings = {
  mobile_min_version: '1.0.0',
  mobile_latest_version: '1.0.0',
  backend_target_version: '1.0.0',
  capteur_target_firmware: '1.0.0',
  force_mobile_update: false,
  force_capteur_update: false,
  maintenance_window: 'none',
}

function parseSemver(input: string): number[] {
  return input
    .split('.')
    .map((v) => parseInt(v, 10))
    .map((v) => (Number.isNaN(v) ? 0 : v))
}

function compareSemver(a: string, b: string): number {
  const av = parseSemver(a)
  const bv = parseSemver(b)
  const max = Math.max(av.length, bv.length)
  for (let i = 0; i < max; i += 1) {
    const ai = av[i] || 0
    const bi = bv[i] || 0
    if (ai > bi) return 1
    if (ai < bi) return -1
  }
  return 0
}

export default function SoftwareUpdatesPage() {
  const [settings, setSettings] = useState<UpdateSettings>(DEFAULT_SETTINGS)
  const [sensors, setSensors] = useState<SensorRow[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  const fetchAll = async () => {
    setLoading(true)
    try {
      const [settingsRes, capteursRes] = await Promise.all([
        api.get('/admin/settings').catch(() => ({ data: { success: false, data: {} } })),
        api.get('/capteurs', { params: { limit: 500 } }).catch(() => ({ data: { data: [] } })),
      ])

      const remote = settingsRes.data?.data || {}
      setSettings({
        mobile_min_version: String(remote.mobile_min_version || DEFAULT_SETTINGS.mobile_min_version),
        mobile_latest_version: String(remote.mobile_latest_version || DEFAULT_SETTINGS.mobile_latest_version),
        backend_target_version: String(remote.backend_target_version || DEFAULT_SETTINGS.backend_target_version),
        capteur_target_firmware: String(remote.capteur_target_firmware || DEFAULT_SETTINGS.capteur_target_firmware),
        force_mobile_update: Boolean(remote.force_mobile_update),
        force_capteur_update: Boolean(remote.force_capteur_update),
        maintenance_window: String(remote.maintenance_window || DEFAULT_SETTINGS.maintenance_window),
      })

      const rows = (capteursRes.data?.data || []) as Array<Record<string, unknown>>
      setSensors(
        rows.map((row) => ({
          id: String(row.id || ''),
          nom: String(row.nom || ''),
          firmwareVersion: String(row.firmware_version || row.firmwareVersion || ''),
          status: String(row.statut || row.status || ''),
        })),
      )
    } catch (error) {
      logger.error('Erreur chargement mises à jour logicielles', error instanceof Error ? error : undefined)
      toast.error('Impossible de charger les informations de mises à jour')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAll()
  }, [])

  const outdatedSensors = useMemo(() => {
    return sensors.filter((sensor) => {
      const current = sensor.firmwareVersion || '0.0.0'
      return compareSemver(current, settings.capteur_target_firmware) < 0
    })
  }, [sensors, settings.capteur_target_firmware])

  const handleSave = async () => {
    if (compareSemver(settings.mobile_latest_version, settings.mobile_min_version) < 0) {
      toast.error('La version mobile latest doit être >= version minimale')
      return
    }

    setSaving(true)
    try {
      await api.put('/admin/settings', settings)
      toast.success('Paramètres de mises à jour enregistrés')
    } catch (error) {
      logger.error('Erreur sauvegarde mises à jour logicielles', error instanceof Error ? error : undefined)
      toast.error('Échec de la sauvegarde des mises à jour')
    } finally {
      setSaving(false)
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-green-600" />
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Mises à Jour Logicielles</h1>
          <p className="text-gray-600 dark:text-gray-400">Pilotez les versions cibles mobile, backend et firmware capteurs</p>
        </div>
        <button
          className="px-4 py-2 rounded-lg border border-gray-200 bg-white hover:bg-gray-50 flex items-center gap-2"
          onClick={fetchAll}
        >
          <RefreshCcw className="h-4 w-4" />
          Recharger
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-500">Capteurs supervisés</p>
            <Cpu className="h-5 w-5 text-blue-600" />
          </div>
          <p className="text-3xl font-bold mt-2">{sensors.length}</p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-500">Capteurs obsolètes</p>
            <TriangleAlert className="h-5 w-5 text-orange-600" />
          </div>
          <p className="text-3xl font-bold mt-2">{outdatedSensors.length}</p>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white p-5">
          <div className="flex items-center justify-between">
            <p className="text-sm text-gray-500">Capteurs à jour</p>
            <CheckCircle2 className="h-5 w-5 text-green-600" />
          </div>
          <p className="text-3xl font-bold mt-2">{Math.max(0, sensors.length - outdatedSensors.length)}</p>
        </div>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5 space-y-4">
        <h2 className="text-lg font-semibold flex items-center gap-2">
          <Wrench className="h-5 w-5 text-gray-700" />
          Politique de versions
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <label className="space-y-2">
            <span className="text-sm text-gray-600">Version mobile minimale</span>
            <input
              className="w-full border border-gray-200 rounded-lg px-3 py-2"
              value={settings.mobile_min_version}
              onChange={(e) => setSettings((prev) => ({ ...prev, mobile_min_version: e.target.value.trim() }))}
            />
          </label>

          <label className="space-y-2">
            <span className="text-sm text-gray-600">Version mobile latest</span>
            <input
              className="w-full border border-gray-200 rounded-lg px-3 py-2"
              value={settings.mobile_latest_version}
              onChange={(e) => setSettings((prev) => ({ ...prev, mobile_latest_version: e.target.value.trim() }))}
            />
          </label>

          <label className="space-y-2">
            <span className="text-sm text-gray-600">Version backend cible</span>
            <input
              className="w-full border border-gray-200 rounded-lg px-3 py-2"
              value={settings.backend_target_version}
              onChange={(e) => setSettings((prev) => ({ ...prev, backend_target_version: e.target.value.trim() }))}
            />
          </label>

          <label className="space-y-2">
            <span className="text-sm text-gray-600">Firmware capteur cible</span>
            <input
              className="w-full border border-gray-200 rounded-lg px-3 py-2"
              value={settings.capteur_target_firmware}
              onChange={(e) => setSettings((prev) => ({ ...prev, capteur_target_firmware: e.target.value.trim() }))}
            />
          </label>

          <label className="space-y-2">
            <span className="text-sm text-gray-600">Fenêtre de maintenance</span>
            <input
              className="w-full border border-gray-200 rounded-lg px-3 py-2"
              placeholder="ex: dimanche 01:00-03:00"
              value={settings.maintenance_window}
              onChange={(e) => setSettings((prev) => ({ ...prev, maintenance_window: e.target.value }))}
            />
          </label>

          <div className="space-y-3 pt-6">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={settings.force_mobile_update}
                onChange={(e) => setSettings((prev) => ({ ...prev, force_mobile_update: e.target.checked }))}
              />
              <span className="text-sm text-gray-700">Forcer mise à jour mobile</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={settings.force_capteur_update}
                onChange={(e) => setSettings((prev) => ({ ...prev, force_capteur_update: e.target.checked }))}
              />
              <span className="text-sm text-gray-700">Forcer mise à jour capteurs</span>
            </label>
          </div>
        </div>

        <div className="flex justify-end">
          <button
            className="px-4 py-2 rounded-lg bg-green-600 hover:bg-green-700 text-white flex items-center gap-2 disabled:opacity-60"
            onClick={handleSave}
            disabled={saving}
          >
            <Save className="h-4 w-4" />
            {saving ? 'Enregistrement...' : 'Enregistrer'}
          </button>
        </div>
      </div>

      <div className="rounded-xl border border-gray-200 bg-white p-5">
        <h2 className="text-lg font-semibold mb-4">Capteurs à mettre à jour</h2>
        {outdatedSensors.length === 0 ? (
          <p className="text-green-700">Tous les capteurs sont alignés sur la version firmware cible.</p>
        ) : (
          <div className="space-y-2">
            {outdatedSensors.slice(0, 30).map((sensor) => (
              <div key={sensor.id} className="flex items-center justify-between border border-gray-100 rounded-lg px-3 py-2">
                <div>
                  <p className="font-medium text-gray-900">{sensor.nom || sensor.id}</p>
                  <p className="text-xs text-gray-500">Statut: {sensor.status || 'inconnu'}</p>
                </div>
                <p className="text-sm text-orange-700">
                  {sensor.firmwareVersion || '0.0.0'} → {settings.capteur_target_firmware}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

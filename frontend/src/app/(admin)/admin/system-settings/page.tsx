'use client'

/**
 * System Settings Page
 * 
 * Administrative interface for configuring platform-wide settings.
 * Allows admins to manage:
 * - Notification preferences (Email, SMS, WhatsApp)
 * - System parameters (Maintenance mode, backups, data retention)
 * - API integrations (Weather API, AI detection, IoT sync)
 * - Security policies (2FA, session timeout, password requirements)
 * 
 * All changes are persisted to the backend via API.
 */

import React, { useState, useEffect } from 'react'
import {
    Settings,
    Save,
    RefreshCw,
    Bell,
    Database,
    Mail,
    Shield,
    Globe,
    Smartphone,
    Cloud
} from 'lucide-react'
import { logger } from '@/lib/logger'
import api from '@/lib/api'
import toast from 'react-hot-toast'

/**
 * Setting section interface
 * Groups related settings under a common category
 */
interface SettingSection {
    title: string
    description: string
    settings: Setting[]
}

/**
 * Individual setting interface
 * Supports toggle (boolean), input (text), and select (dropdown) types
 */
interface Setting {
    id: string
    label: string
    description: string
    type: 'toggle' | 'input' | 'select'
    value: boolean | string
    options?: string[]
}

export default function SettingsPage() {
    // Initial settings configuration
    // In production, these should be loaded from the backend API
    const initialSettings: SettingSection[] = [
        {
            title: 'Notifications',
            description: 'Configurer les alertes et notifications système',
            settings: [
                {
                    id: 'email_notifications',
                    label: 'Notifications par email',
                    description: 'Recevoir des alertes par email',
                    type: 'toggle',
                    value: true
                },
                {
                    id: 'sms_notifications',
                    label: 'Notifications SMS',
                    description: 'Envoyer des SMS aux producteurs',
                    type: 'toggle',
                    value: true
                },
                {
                    id: 'whatsapp_notifications',
                    label: 'Notifications WhatsApp',
                    description: 'Utiliser WhatsApp pour les alertes',
                    type: 'toggle',
                    value: false
                }
            ]
        },
        {
            title: 'Système',
            description: 'Paramètres généraux du système',
            settings: [
                {
                    id: 'maintenance_mode',
                    label: 'Mode maintenance',
                    description: 'Activer pour bloquer l\'accès temporairement',
                    type: 'toggle',
                    value: false
                },
                {
                    id: 'auto_backup',
                    label: 'Sauvegarde automatique',
                    description: 'Backup quotidien de la base de données',
                    type: 'toggle',
                    value: true
                },
                {
                    id: 'data_retention',
                    label: 'Rétention des données',
                    description: 'Durée de conservation des mesures',
                    type: 'select',
                    value: '12',
                    options: ['3', '6', '12', '24', 'illimité']
                }
            ]
        },
        {
            title: 'API & Intégrations',
            description: 'Gestion des services externes',
            settings: [
                {
                    id: 'weather_api',
                    label: 'API Météo',
                    description: 'Activée (OpenWeather)',
                    type: 'toggle',
                    value: true
                },
                {
                    id: 'ai_detection',
                    label: 'Détection IA',
                    description: 'Service d\'analyse d\'images',
                    type: 'toggle',
                    value: true
                },
                {
                    id: 'iot_sync',
                    label: 'Synchronisation IoT',
                    description: 'Collecte automatique des capteurs',
                    type: 'toggle',
                    value: true
                }
            ]
        },
        {
            title: 'Sécurité',
            description: 'Paramètres de sécurité et authentification',
            settings: [
                {
                    id: 'two_factor',
                    label: 'Authentification 2FA',
                    description: 'Obligatoire pour les administrateurs',
                    type: 'toggle',
                    value: false
                },
                {
                    id: 'session_timeout',
                    label: 'Timeout de session',
                    description: 'Déconnexion automatique (minutes)',
                    type: 'select',
                    value: '60',
                    options: ['15', '30', '60', '120', '240']
                },
                {
                    id: 'password_policy',
                    label: 'Politique de mots de passe stricte',
                    description: 'Exiger 12+ caractères, majuscules, chiffres',
                    type: 'toggle',
                    value: true
                }
            ]
        }
    ]

    // State management
    const [settings, setSettings] = useState<SettingSection[]>(initialSettings)
    const [hasChanges, setHasChanges] = useState(false)

    // Initial loading of settings
    useEffect(() => {
        const fetchSettings = async () => {
            try {
                const response = await api.get('/admin/settings');
                if (response.data.success) {
                    const serverSettings = response.data.data;

                    // Update settings state with server values
                    setSettings(prevSettings =>
                        prevSettings.map(section => ({
                            ...section,
                            settings: section.settings.map(setting => ({
                                ...setting,
                                value: serverSettings[setting.id] !== undefined
                                    ? serverSettings[setting.id]
                                    : setting.value
                            }))
                        }))
                    );
                }
            } catch (error) {
                logger.error('Failed to load settings', error as Error);
            }
        };

        fetchSettings();
    }, []);

    /**
     * Handle toggling of boolean settings
     * Updates the setting value and marks form as dirty
     */
    const handleToggle = (sectionIndex: number, settingIndex: number) => {
        const newSettings = [...settings]
        const setting = newSettings[sectionIndex].settings[settingIndex]

        if (setting.type === 'toggle') {
            setting.value = !setting.value
            setSettings(newSettings)
            setHasChanges(true)
            logger.debug('Setting toggled', {
                settingId: setting.id,
                newValue: setting.value
            })
        }
    }

    /**
     * Handle changes to select/input settings
     * Updates the setting value and marks form as dirty
     */
    const handleSelectChange = (sectionIndex: number, settingIndex: number, value: string) => {
        const newSettings = [...settings]
        newSettings[sectionIndex].settings[settingIndex].value = value
        setSettings(newSettings)
        setHasChanges(true)
        logger.debug('Setting changed', {
            settingId: newSettings[sectionIndex].settings[settingIndex].id,
            newValue: value
        })
    }

    /**
     * Save all settings to backend API
     * Transforms settings array into flat object and persists to database
     */
    const handleSave = async () => {
        try {
            logger.info('Saving system settings', { sectionCount: settings.length })

            // Transform settings array into flat key-value object
            const settingsPayload = settings.reduce((acc, section) => {
                section.settings.forEach(setting => {
                    acc[setting.id] = setting.value
                })
                return acc
            }, {} as Record<string, unknown>)

            // Persist to backend
            await api.put('/admin/settings', settingsPayload)

            setHasChanges(false)
            toast.success('Paramètres sauvegardés avec succès !')
            logger.info('Settings saved successfully', { settingsCount: Object.keys(settingsPayload).length })
        } catch (error) {
            logger.error('Failed to save settings', error as Error)
            toast.error('Erreur lors de la sauvegarde des paramètres')
        }
    }

    /**
     * Reset all settings to default values
     * Restores initial configuration (does not save automatically)
     */
    const handleReset = () => {
        if (!confirm('Êtes-vous sûr de vouloir réinitialiser tous les paramètres ?')) {
            return
        }

        logger.warn('Resetting system settings to defaults')
        setSettings([...initialSettings])
        setHasChanges(true)
        toast('Paramètres réinitialisés. Cliquez sur Enregistrer pour confirmer.', {
            icon: '🔄',
            duration: 4000
        })
    }

    return (
        <div className="p-6 max-w-7xl mx-auto">
            {/* Header */}
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900 flex items-center">
                        <Settings className="w-8 h-8 mr-3 text-green-600" />
                        Paramètres Système
                    </h1>
                    <p className="text-gray-500 mt-1">Configuration de la plateforme AgroSmart</p>
                </div>
                <div className="flex gap-3">
                    <button
                        onClick={handleReset}
                        className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center transition-colors"
                        title="Réinitialiser tous les paramètres"
                    >
                        <RefreshCw className="w-5 h-5 mr-2" />
                        Réinitialiser
                    </button>
                    <button
                        onClick={handleSave}
                        disabled={!hasChanges}
                        className={`px-4 py-2 rounded-lg flex items-center transition-colors ${hasChanges
                            ? 'bg-green-600 hover:bg-green-700 text-white'
                            : 'bg-gray-200 text-gray-400 cursor-not-allowed'
                            }`}
                        title={hasChanges ? 'Enregistrer les modifications' : 'Aucune modification'}
                    >
                        <Save className="w-5 h-5 mr-2" />
                        Enregistrer
                    </button>
                </div>
            </div>

            {/* Settings Sections */}
            <div className="space-y-6">
                {settings.map((section, sectionIndex) => (
                    <div key={section.title} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
                        <div className="bg-gray-50 px-6 py-4 border-b border-gray-100">
                            <h2 className="text-lg font-semibold text-gray-900">{section.title}</h2>
                            <p className="text-sm text-gray-600 mt-1">{section.description}</p>
                        </div>
                        <div className="divide-y divide-gray-100">
                            {section.settings.map((setting, settingIndex) => (
                                <div key={setting.id} className="px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
                                    <div className="flex-1">
                                        <h3 className="font-medium text-gray-900">{setting.label}</h3>
                                        <p className="text-sm text-gray-500 mt-1">{setting.description}</p>
                                    </div>
                                    <div className="ml-6">
                                        {setting.type === 'toggle' ? (
                                            <button
                                                onClick={() => handleToggle(sectionIndex, settingIndex)}
                                                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${setting.value ? 'bg-green-600' : 'bg-gray-300'
                                                    }`}
                                                title={`${setting.value ? 'Actif' : 'Inactif'} - Cliquer pour ${setting.value ? 'désactiver' : 'activer'}`}
                                                type="button"
                                                aria-label={setting.label}
                                            >
                                                <span
                                                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${setting.value ? 'translate-x-6' : 'translate-x-1'
                                                        }`}
                                                />
                                            </button>
                                        ) : setting.type === 'select' ? (
                                            <select
                                                value={setting.value as string}
                                                onChange={(e) => handleSelectChange(sectionIndex, settingIndex, e.target.value)}
                                                className="border border-gray-300 rounded-lg px-3 py-2 bg-white focus:outline-none focus:border-green-500"
                                                title={setting.label}
                                                aria-label={setting.label}
                                            >
                                                {setting.options?.map(option => (
                                                    <option key={option} value={option}>
                                                        {option} {setting.id === 'data_retention' && option !== 'illimité' ? 'mois' : ''}
                                                        {setting.id === 'session_timeout' ? 'min' : ''}
                                                    </option>
                                                ))}
                                            </select>
                                        ) : null}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                ))}
            </div>

            {/* System Info */}
            <div className="mt-8 bg-blue-50 border border-blue-200 rounded-xl p-6">
                <h3 className="font-semibold text-blue-900 mb-4">Informations Système</h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                    <div>
                        <p className="text-blue-600 font-medium">Version</p>
                        <p className="text-blue-900">v1.0.0</p>
                    </div>
                    <div>
                        <p className="text-blue-600 font-medium">Base de données</p>
                        <p className="text-blue-900">PostgreSQL 15</p>
                    </div>
                    <div>
                        <p className="text-blue-600 font-medium">Utilisateurs actifs</p>
                        <p className="text-blue-900">3 producteurs</p>
                    </div>
                    <div>
                        <p className="text-blue-600 font-medium">Dernière sauvegarde</p>
                        <p className="text-blue-900">Aujourd'hui 02:00</p>
                    </div>
                </div>
            </div>
        </div>
    )
}

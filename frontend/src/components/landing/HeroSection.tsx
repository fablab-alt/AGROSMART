'use client'

import React from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import { ArrowRight, BarChart, Activity, Users, Cloud } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { setDiscoveryMode } from '@/lib/discoveryMode'

const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.6 }
}

const stagger = {
    animate: {
        transition: {
            staggerChildren: 0.1
        }
    }
}

export function HeroSection() {
    return (
        <section className="relative pt-32 pb-20 overflow-hidden">
            {/* Background Decor */}
            <div className="absolute top-0 right-0 -mr-20 -mt-20 w-[600px] h-[600px] bg-green-50 rounded-full blur-3xl opacity-50 -z-10" />
            <div className="absolute bottom-0 left-0 -ml-20 -mb-20 w-[400px] h-[400px] bg-emerald-50 rounded-full blur-3xl opacity-50 -z-10" />

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
                <div className="grid lg:grid-cols-2 gap-12 lg:gap-8 items-center">
                    <motion.div
                        initial="initial"
                        animate="animate"
                        variants={stagger}
                        className="text-center lg:text-left"
                    >
                        <motion.div variants={fadeInUp} className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-green-50 text-green-700 font-medium text-sm mb-6 border border-green-100">
                            <span className="relative flex h-2 w-2">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                            </span>
                            La plateforme n°1 en Côte d&apos;Ivoire
                        </motion.div>
                        <motion.h1 variants={fadeInUp} className="text-5xl lg:text-7xl font-bold tracking-tight text-gray-900 mb-6 leading-[1.1]">
                            L&apos;agriculture de demain, <span className="text-transparent bg-clip-text bg-gradient-to-r from-green-600 to-emerald-600">aujourd&apos;hui</span>
                        </motion.h1>
                        <motion.p variants={fadeInUp} className="text-xl text-gray-600 mb-8 leading-relaxed max-w-2xl mx-auto lg:mx-0">
                            Optimisez votre production agricole grâce à nos solutions intelligentes. Suivi en temps réel, analyses prédictives et gestion simplifiée.
                        </motion.p>
                        <motion.div variants={fadeInUp} className="flex flex-col sm:flex-row gap-4 justify-center lg:justify-start">
                            <Link href="/register">
                                <Button size="lg" className="bg-green-600 hover:bg-green-700 text-lg px-8 py-6 h-auto shadow-xl shadow-green-600/20 w-full sm:w-auto transition-all hover:scale-105">
                                    Commencer gratuitement
                                    <ArrowRight className="ml-2 h-5 w-5" />
                                </Button>
                            </Link>
                            {/* "Voir la démo" active le mode découverte avant la navigation */}
                            <Link
                                href="/dashboard-producteur"
                                onClick={() => setDiscoveryMode(true)}
                            >
                                <Button size="lg" variant="outline" className="text-lg px-8 py-6 h-auto w-full sm:w-auto border-gray-200 hover:bg-gray-50">
                                    Voir la démo
                                </Button>
                            </Link>
                        </motion.div>

                        <motion.div variants={fadeInUp} className="mt-12 flex items-center justify-center lg:justify-start gap-8 text-gray-400">
                            <div className="flex items-center gap-2">
                                <div className="flex -space-x-2">
                                    {[1, 2, 3, 4].map((i) => (
                                        <div key={i} className="w-8 h-8 rounded-full bg-gray-200 border-2 border-white" />
                                    ))}
                                </div>
                                <span className="text-sm font-medium text-gray-600">Rejoignez +5000 agriculteurs</span>
                            </div>
                        </motion.div>
                    </motion.div>

                    {/* Hero Image/Dashboard Preview */}
                    <motion.div
                        initial={{ opacity: 0, x: 20, rotateY: -10 }}
                        animate={{ opacity: 1, x: 0, rotateY: 0 }}
                        transition={{ duration: 0.8, delay: 0.2 }}
                        className="relative hidden lg:block perspective-1000"
                    >
                        <div className="relative">
                            <div className="bg-gradient-to-br from-green-400 to-emerald-600 rounded-3xl p-8 shadow-2xl transform transition-transform hover:scale-[1.02] duration-500">
                                <div className="bg-white/90 backdrop-blur-xl rounded-2xl shadow-lg p-6 border border-white/20">
                                    <div className="flex items-center justify-between mb-8">
                                        <div className="flex items-center gap-3">
                                            <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                                                <Users className="w-5 h-5 text-green-600" />
                                            </div>
                                            <div>
                                                <p className="font-semibold text-gray-900">Activité Récente</p>
                                                <p className="text-sm text-gray-500">Mise à jour il y a 2m</p>
                                            </div>
                                        </div>
                                    </div>

                                    <div className="space-y-4">
                                        {[1, 2, 3].map((i) => (
                                            <div key={i} className="flex items-center gap-4 p-3 rounded-xl hover:bg-gray-50 transition-colors">
                                                <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                                                    i === 1 ? 'bg-blue-100 text-blue-600' :
                                                    i === 2 ? 'bg-amber-100 text-amber-600' :
                                                              'bg-purple-100 text-purple-600'
                                                }`}>
                                                    <BarChart className="w-5 h-5" />
                                                </div>
                                                <div className="flex-1">
                                                    <div className="h-2 bg-gray-100 rounded-full w-3/4 mb-2" />
                                                    <div className="h-2 bg-gray-100 rounded-full w-1/2" />
                                                </div>
                                                <div className="text-sm font-bold text-gray-900">
                                                    +{20 + (i * 15)}%
                                                </div>
                                            </div>
                                        ))}
                                    </div>

                                    <div className="mt-6 pt-6 border-t border-gray-100 grid grid-cols-2 gap-4">
                                        <div className="p-4 rounded-xl bg-green-50 border border-green-100">
                                            <div className="flex items-center gap-2 mb-2">
                                                <Cloud className="w-4 h-4 text-green-600" />
                                                <span className="text-xs font-medium text-green-700">Météo</span>
                                            </div>
                                            <p className="text-lg font-bold text-green-900">28°C</p>
                                        </div>
                                        <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-100">
                                            <div className="flex items-center gap-2 mb-2">
                                                <Activity className="w-4 h-4 text-emerald-600" />
                                                <span className="text-xs font-medium text-emerald-700">Santé Sols</span>
                                            </div>
                                            <p className="text-lg font-bold text-emerald-900">Bonne</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </motion.div>
                </div>
            </div>
        </section>
    )
}

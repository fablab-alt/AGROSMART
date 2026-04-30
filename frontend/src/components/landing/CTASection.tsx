'use client'

import React from 'react'
import Link from 'next/link'
import { motion } from 'framer-motion'
import { ArrowRight, MapPin, Eye, Zap, CheckCircle2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'

const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.6 }
}

export function CTASection() {
    return (
        <section className="py-24 px-4 bg-gradient-to-br from-green-900 via-emerald-900 to-black relative overflow-hidden">
            {/* Background Elements */}
            <div className="absolute inset-0 opacity-20 bg-[radial-gradient(ellipse_at_center,var(--tw-gradient-stops))] from-green-500 via-green-900 to-black"></div>
            <div className="absolute -top-40 -right-40 w-80 h-80 bg-green-500 rounded-full blur-3xl opacity-10"></div>
            <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-emerald-500 rounded-full blur-3xl opacity-10"></div>

            <div className="max-w-5xl mx-auto relative z-10">
                <motion.div
                    initial="initial"
                    whileInView="whileInView"
                    viewport={{ once: true }}
                    variants={{
                        whileInView: { transition: { staggerChildren: 0.1 } }
                    }}
                    className="space-y-12"
                >
                    {/* Main Heading */}
                    <motion.h2
                        className="text-4xl md:text-5xl font-bold text-white mb-4 tracking-tight text-center"
                        variants={fadeInUp}
                    >
                        Prêt à transformer votre agriculture ?
                    </motion.h2>
                    <motion.p
                        className="text-xl text-green-100 mb-8 leading-relaxed text-center max-w-3xl mx-auto"
                        variants={fadeInUp}
                    >
                        Rejoignez les milliers d&apos;agriculteurs ivoiriens qui utilisent AgroSmart
                        pour une agriculture plus rentable et durable. Commencez gratuitement dès aujourd&apos;hui.
                    </motion.p>

                    {/* Demo Card */}
                    <motion.div variants={fadeInUp}>
                        <Card className="bg-white/10 border-white/20 backdrop-blur-md p-8 mb-8">
                            <div className="grid md:grid-cols-2 gap-8">
                                <div>
                                    <h3 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
                                        <Eye className="h-6 w-6 text-green-400" />
                                        Mode Découverte
                                    </h3>
                                    <p className="text-green-100 mb-6">
                                        Testez gratuitement avant de vous inscrire. Explorez :
                                    </p>
                                    <ul className="space-y-3 mb-8">
                                        <li className="flex items-center gap-3 text-green-100">
                                            <MapPin className="h-5 w-5 text-green-400 shrink-0" />
                                            Détection automatique de votre localisation
                                        </li>
                                        <li className="flex items-center gap-3 text-green-100">
                                            <Zap className="h-5 w-5 text-green-400 shrink-0" />
                                            Démo interactive des parcelles
                                        </li>
                                        <li className="flex items-center gap-3 text-green-100">
                                            <CheckCircle2 className="h-5 w-5 text-green-400 shrink-0" />
                                            Prévisions météo basées sur votre région
                                        </li>
                                    </ul>
                                    <Link href="/demo">
                                        <Button size="lg" className="bg-green-500 hover:bg-green-600 text-white w-full sm:w-auto">
                                            Essayer gratuitement
                                            <Eye className="h-4 w-4 ml-2" />
                                        </Button>
                                    </Link>
                                </div>
                                <div className="flex flex-col justify-center">
                                    <div className="bg-white/5 rounded-lg p-6 border border-white/10">
                                        <p className="text-sm text-green-200 mb-4">Ce que vous découvrirez :</p>
                                        <div className="space-y-3">
                                            <div className="flex items-start gap-2">
                                                <span className="text-green-400">✓</span>
                                                <span className="text-sm text-gray-200">Suivi en temps réel de parcelles</span>
                                            </div>
                                            <div className="flex items-start gap-2">
                                                <span className="text-green-400">✓</span>
                                                <span className="text-sm text-gray-200">Alertes intelligentes basées sur votre position</span>
                                            </div>
                                            <div className="flex items-start gap-2">
                                                <span className="text-green-400">✓</span>
                                                <span className="text-sm text-gray-200">Recommandations IA personnalisées</span>
                                            </div>
                                            <div className="flex items-start gap-2">
                                                <span className="text-green-400">✓</span>
                                                <span className="text-sm text-gray-200">Accès complet sans limite de temps</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </Card>
                    </motion.div>

                    {/* Action Buttons */}
                    <motion.div
                        className="flex flex-col sm:flex-row gap-4 justify-center"
                        variants={fadeInUp}
                    >
                        <Link href="/register">
                            <Button size="lg" className="bg-white text-green-900 hover:bg-gray-100 text-lg px-10 py-7 shadow-xl hover:scale-105 transition-all font-bold">
                                Créer un compte gratuit
                                <ArrowRight className="ml-2 h-5 w-5" />
                            </Button>
                        </Link>
                        <Link href="/login">
                            <Button size="lg" variant="outline" className="border-white/30 text-white hover:bg-white/10 text-lg px-10 py-7 font-medium backdrop-blur-sm">
                                Se connecter
                            </Button>
                        </Link>
                    </motion.div>

                    {/* Stats Footer */}
                    <motion.div 
                        className="grid md:grid-cols-4 gap-4 pt-8 border-t border-white/10"
                        variants={fadeInUp}
                    >
                        {[
                            { number: '5000+', label: 'Agriculteurs actifs' },
                            { number: '50K+', label: 'Hectares surveillés' },
                            { number: '94%', label: 'Précision IA' },
                            { number: '30%', label: 'Productivité gagnée' },
                        ].map((stat, idx) => (
                            <div key={idx} className="text-center">
                                <p className="text-3xl font-bold text-green-400 mb-2">{stat.number}</p>
                                <p className="text-sm text-gray-300">{stat.label}</p>
                            </div>
                        ))}
                    </motion.div>
                </motion.div>
            </div>
        </section>
    )
}

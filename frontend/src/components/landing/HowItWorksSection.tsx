'use client'

import React from 'react'
import { motion } from 'framer-motion'

const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.6 }
}

export function HowItWorksSection() {
    const steps = [
        { step: 1, title: "Installation", desc: "Installation des capteurs IoT solaires dans vos parcelles." },
        { step: 2, title: "Collecte", desc: "Transmission automatique des données toutes les 15 minutes." },
        { step: 3, title: "Analyse", desc: "Notre IA traite les données pour générer des recommandations." },
        { step: 4, title: "Action", desc: "Vous recevez les conseils et alertes sur votre mobile." }
    ]

    return (
        <section id="how-it-works" className="py-24 px-4 bg-gray-50/50">
            <div className="max-w-7xl mx-auto">
                <motion.div className="text-center mb-20" {...fadeInUp}>
                    <h2 className="text-3xl md:text-5xl font-bold text-gray-900 mb-6 tracking-tight">
                        Comment ça marche ?
                    </h2>
                    <p className="text-xl text-gray-600">
                        Un système simple et efficace du champ à l&apos;écran
                    </p>
                </motion.div>
                <div className="grid md:grid-cols-4 gap-8 relative">
                    {/* Connecting line (desktop only) */}
                    <div className="hidden md:block absolute top-12 left-[12%] right-[12%] h-0.5 bg-gray-200 -z-10"></div>

                    {steps.map((item, idx) => (
                        <motion.div
                            key={idx}
                            className="text-center bg-white md:bg-transparent p-6 rounded-2xl md:p-0 shadow-sm md:shadow-none"
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ delay: idx * 0.2 }}
                        >
                            <div className="h-24 w-24 bg-white rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg md:shadow-md border-4 border-green-50">
                                <div className="h-16 w-16 bg-green-600 text-white rounded-full flex items-center justify-center text-2xl font-bold shadow-inner">
                                    {item.step}
                                </div>
                            </div>
                            <h3 className="text-xl font-bold text-gray-900 mb-3">{item.title}</h3>
                            <p className="text-gray-600 leading-relaxed px-4">{item.desc}</p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}

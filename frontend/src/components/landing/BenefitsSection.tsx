'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { Star } from 'lucide-react'

export function BenefitsSection() {
    return (
        <section id="benefits" className="py-24 px-4">
            <div className="max-w-7xl mx-auto">
                <div className="grid lg:grid-cols-2 gap-16 items-center">
                    <motion.div
                        initial={{ opacity: 0, x: -30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                    >
                        <h2 className="text-3xl md:text-5xl font-bold text-gray-900 mb-8 tracking-tight">
                            Des résultats concrets <br />pour votre exploitation
                        </h2>
                        <div className="space-y-8">
                            {[
                                { val: "+25%", title: "Augmentation des rendements", desc: "Optimisation de l'irrigation et nutriments" },
                                { val: "-30%", title: "Économie d'eau", desc: "Irrigation de précision basée sur les besoins réels" },
                                { val: "-40%", title: "Réduction des pertes", desc: "Détection précoce des maladies par l'IA" },
                                { val: "300%", title: "Retour sur investissement", desc: "En moyenne dès la première année" }
                            ].map((item, idx) => (
                                <div key={idx} className="flex gap-6 group">
                                    <div className="h-20 w-20 bg-green-50 rounded-2xl flex items-center justify-center shrink-0 group-hover:bg-green-100 transition-colors">
                                        <span className="text-green-600 font-bold text-xl">{item.val}</span>
                                    </div>
                                    <div>
                                        <h3 className="text-xl font-bold text-gray-900 mb-1">{item.title}</h3>
                                        <p className="text-gray-600">{item.desc}</p>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </motion.div>
                    <motion.div
                        className="relative"
                        initial={{ opacity: 0, x: 30 }}
                        whileInView={{ opacity: 1, x: 0 }}
                        viewport={{ once: true }}
                    >
                        <div className="bg-linear-to-br from-green-100 to-emerald-100 rounded-[2.5rem] p-10 relative overflow-hidden">
                            <div className="absolute top-0 right-0 -mr-16 -mt-16 h-64 w-64 bg-green-200/50 rounded-full blur-3xl"></div>
                            <div className="absolute bottom-0 left-0 -ml-16 -mb-16 h-64 w-64 bg-emerald-200/50 rounded-full blur-3xl"></div>

                            <div className="bg-white/60 backdrop-blur-md rounded-2xl p-8 shadow-xl relative z-10">
                                <div className="flex items-center gap-1 mb-8">
                                    {[1, 2, 3, 4, 5].map(s => <Star key={s} className="h-6 w-6 text-yellow-500 fill-yellow-500" />)}
                                </div>
                                <p className="text-xl text-gray-800 mb-8 italic leading-relaxed font-medium">
                                    &quot;Depuis que j&apos;utilise Agrosmart, j&apos;ai augmenté ma production de riz de 30%
                                    et j&apos;économise beaucoup d&apos;eau. L&apos;application est intuitive et les alertes
                                    m&apos;ont permis de sauver ma récolte d'une attaque de chenilles.&quot;
                                </p>
                                <div className="flex items-center gap-4">
                                    <div className="h-14 w-14 bg-green-600 rounded-full flex items-center justify-center text-white font-bold text-lg shadow-md">
                                        KJ
                                    </div>
                                    <div>
                                        <p className="font-bold text-gray-900 text-lg">Kouassi Jean</p>
                                        <p className="text-sm text-green-700 font-medium">Producteur de riz, Bouaké</p>
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

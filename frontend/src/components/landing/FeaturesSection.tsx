'use client'

import React from 'react'
import { motion } from 'framer-motion'
import { Droplets, Cloud, Bell, BarChart3, ShoppingCart, GraduationCap, Users, TrendingUp, Smartphone } from 'lucide-react'

const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.6 }
}

const staggerChildren = {
    initial: { opacity: 0 },
    whileInView: {
        opacity: 1,
        transition: { staggerChildren: 0.1 }
    },
    viewport: { once: true }
}

// Static class maps — dynamic interpolation (e.g. `bg-${color}-50`) is never
// detected by Tailwind's content scanner, so those classes would be purged in
// production.  Always use fully-qualified static class strings.
const bgLight: Record<string, string> = {
    blue:    'bg-blue-50',
    cyan:    'bg-cyan-50',
    orange:  'bg-orange-50',
    purple:  'bg-purple-50',
    green:   'bg-green-50',
    indigo:  'bg-indigo-50',
    pink:    'bg-pink-50',
    emerald: 'bg-emerald-50',
    slate:   'bg-slate-100',
}
const bgHover: Record<string, string> = {
    blue:    'group-hover:bg-blue-100',
    cyan:    'group-hover:bg-cyan-100',
    orange:  'group-hover:bg-orange-100',
    purple:  'group-hover:bg-purple-100',
    green:   'group-hover:bg-green-100',
    indigo:  'group-hover:bg-indigo-100',
    pink:    'group-hover:bg-pink-100',
    emerald: 'group-hover:bg-emerald-100',
    slate:   'group-hover:bg-slate-200',
}
const textColor: Record<string, string> = {
    blue:    'text-blue-600',
    cyan:    'text-cyan-600',
    orange:  'text-orange-600',
    purple:  'text-purple-600',
    green:   'text-green-600',
    indigo:  'text-indigo-600',
    pink:    'text-pink-600',
    emerald: 'text-emerald-600',
    slate:   'text-slate-600',
}

export function FeaturesSection() {
    const features = [
        { icon: Droplets, color: 'blue',    title: 'Suivi en temps réel',    desc: "Consultez instantanément l'humidité, la température, le pH et les nutriments de vos sols." },
        { icon: Cloud,       color: 'cyan',    title: 'Prévisions météo',       desc: 'Météo hyperlocale sur 10 jours avec alertes pour planifier vos activités.' },
        { icon: Bell,        color: 'orange',  title: 'Alertes intelligentes',  desc: 'Notifications SMS et WhatsApp en cas de stress hydrique ou détection de maladies.' },
        { icon: BarChart3,   color: 'purple',  title: 'Analyse IA',             desc: "Détection automatique de 50+ maladies avec 94% de précision grâce à l'IA." },
        { icon: ShoppingCart,color: 'green',   title: 'Marketplace',            desc: 'Achetez et vendez semences, engrais et équipements directement depuis l\'app.' },
        { icon: GraduationCap,color:'indigo',  title: 'Formations',             desc: 'Accédez à des tutoriels vidéo et fiches pratiques pour améliorer vos techniques.' },
        { icon: Users,       color: 'pink',    title: 'Communauté',             desc: "Échangez avec d'autres agriculteurs, partagez conseils et signalements." },
        { icon: TrendingUp,  color: 'emerald', title: 'Suivi économique',       desc: "Calculez votre ROI, économies d'eau et réduction d'intrants en temps réel." },
        { icon: Smartphone,  color: 'slate',   title: 'Multiplateforme',        desc: 'Disponible sur Android, iOS et web. Interface en français et langues locales.' },
    ]

    return (
        <section id="features" className="py-24 px-4 bg-white">
            <div className="max-w-7xl mx-auto">
                <motion.div
                    className="text-center mb-20"
                    initial={{ opacity: 0, y: 20 }}
                    whileInView={{ opacity: 1, y: 0 }}
                    viewport={{ once: true }}
                >
                    <h2 className="text-3xl md:text-5xl font-bold text-gray-900 mb-6 tracking-tight">
                        Tout ce dont vous avez besoin <br className="hidden md:block" />pour une agriculture moderne
                    </h2>
                    <p className="text-xl text-gray-600 max-w-3xl mx-auto leading-relaxed">
                        Des outils puissants et simples pour surveiller, analyser et optimiser vos exploitations
                        agricoles, accessibles à tous.
                    </p>
                </motion.div>

                <motion.div
                    className="grid md:grid-cols-2 lg:grid-cols-3 gap-8"
                    variants={staggerChildren}
                    initial="initial"
                    whileInView="whileInView"
                    viewport={{ once: true }}
                >
                    {features.map((feature, idx) => (
                        <motion.div
                            key={idx}
                            variants={fadeInUp}
                            className="group bg-white border border-gray-100 rounded-3xl p-8 hover:shadow-xl hover:-translate-y-1 transition-all duration-300"
                        >
                            <div className={`h-14 w-14 rounded-2xl flex items-center justify-center mb-6 transition-colors ${bgLight[feature.color]} ${bgHover[feature.color]}`}>
                                <feature.icon className={`h-7 w-7 ${textColor[feature.color]}`} />
                            </div>
                            <h3 className="text-xl font-bold text-gray-900 mb-3">{feature.title}</h3>
                            <p className="text-gray-600 leading-relaxed">{feature.desc}</p>
                        </motion.div>
                    ))}
                </motion.div>
            </div>
        </section>
    )
}

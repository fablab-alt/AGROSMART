'use client'

import React from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { motion } from 'framer-motion'
import { ArrowRight, Play } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { enterVisitorMode } from '@/lib/visitorActions'

const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.6 }
}

export function CTASection() {
    const router = useRouter()
    return (
        <section className="py-24 px-4 bg-green-900 relative overflow-hidden">
            <div className="absolute inset-0 opacity-20 bg-[radial-gradient(ellipse_at_center,var(--tw-gradient-stops))] from-green-500 via-green-900 to-black"></div>
            <div className="max-w-4xl mx-auto text-center relative z-10">
                <motion.h2
                    className="text-4xl md:text-5xl font-bold text-white mb-8 tracking-tight"
                    {...fadeInUp}
                >
                    Prêt à transformer votre agriculture ?
                </motion.h2>
                <motion.p
                    className="text-xl md:text-2xl text-green-100 mb-12 leading-relaxed"
                    {...fadeInUp}
                    transition={{ delay: 0.1 }}
                >
                    Rejoignez les milliers d&apos;agriculteurs ivoiriens qui utilisent AgroSmart
                    pour une agriculture plus rentable et durable.
                </motion.p>
                <motion.div
                    className="flex flex-col sm:flex-row gap-6 justify-center flex-wrap"
                    {...fadeInUp}
                    transition={{ delay: 0.2 }}
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
                    <Button
                        size="lg"
                        variant="outline"
                        className="border-white/20 text-green-200 hover:bg-white/10 text-lg px-10 py-7 font-medium backdrop-blur-sm"
                        onClick={() => enterVisitorMode(router)}
                    >
                        <Play className="mr-2 h-5 w-5" />
                        Tester en mode démo
                    </Button>
                </motion.div>
            </div>
        </section>
    )
}

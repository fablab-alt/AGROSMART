'use client'

import React from 'react'
import { motion } from 'framer-motion'
import CountUp from 'react-countup'

interface StatsSectionProps {
    stats: {
        hectares: string | number
        agriculteurs: string | number
        cultures: string | number
        precision: string | number
    }
}

const fadeInUp = {
    initial: { opacity: 0, y: 20 },
    whileInView: { opacity: 1, y: 0 },
    viewport: { once: true },
    transition: { duration: 0.6 }
}

export function StatsSection({ stats }: StatsSectionProps) {
    // Helper to parse numbers and remove non-numeric chars for CountUp
    const parseStat = (val: string | number) => {
        if (typeof val === 'number') return val
        return parseInt(val.toString().replace(/\D/g, '')) || 0
    }

    // Helper to determine suffix (e.g. "+" or "%")
    const getSuffix = (val: string | number, key: string) => {
        const strVal = val.toString();
        if (key === 'precision') return '%';
        if (strVal.includes('+')) return '+';
        if (parseStat(val) > 1000) return '+';
        return '';
    }

    return (
        <section className="py-20 bg-green-900 text-white relative overflow-hidden">
            <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-10" />
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                <div className="grid grid-cols-2 lg:grid-cols-4 gap-8 text-center">
                    {Object.entries(stats).map(([key, value], index) => (
                        <motion.div
                            key={key}
                            {...fadeInUp}
                            transition={{ delay: index * 0.1 }}
                        >
                            <p className="text-5xl lg:text-6xl font-bold mb-2 tracking-tight">
                                <CountUp
                                    end={parseStat(value)}
                                    duration={2.5}
                                    separator=","
                                    suffix={getSuffix(value, key)}
                                />
                            </p>
                            <p className="text-green-100 font-medium text-lg capitalize">
                                {key === 'hectares' && 'Hectares connectés'}
                                {key === 'agriculteurs' && 'Agriculteurs'}
                                {key === 'cultures' && 'Cultures supportées'}
                                {key === 'precision' && 'Précision IA'}
                            </p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    )
}

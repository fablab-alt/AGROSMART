'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { ArrowRight, Eye } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { setDiscoveryMode } from '@/lib/discoveryMode'

export function Navbar() {
    const [scrolled, setScrolled] = useState(false)

    useEffect(() => {
        const handleScroll = () => setScrolled(window.scrollY > 20)
        window.addEventListener('scroll', handleScroll)
        return () => window.removeEventListener('scroll', handleScroll)
    }, [])

    return (
        <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
            scrolled ? 'bg-white/95 backdrop-blur-md shadow-sm border-b border-gray-100' : 'bg-transparent'
        }`}>
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center h-20">
                    <Link href="/" className="flex items-center gap-3">
                        <div className="h-16 relative flex items-center justify-start overflow-hidden">
                            <Image
                                src="/logo.png"
                                alt="AgroSmart"
                                width={180}
                                height={64}
                                className="object-contain object-left h-full w-auto"
                                priority
                            />
                        </div>
                    </Link>

                    <div className="flex items-center gap-2">
                        {/* Mode Découverte — visible uniquement sur desktop pour ne pas surcharger mobile */}
                        <Link
                            href="/demo"
                            className="hidden sm:inline-flex items-center gap-1.5 px-3 py-2 rounded-lg text-sm font-medium text-amber-700 bg-amber-50 border border-amber-200 hover:bg-amber-100 transition-colors"
                        >
                            <Eye className="h-4 w-4" />
                            Essayer
                        </Link>
                        <Link href="/login">
                            <Button variant="ghost" className="font-medium hover:text-green-600 hover:bg-green-50">
                                Connexion
                            </Button>
                        </Link>
                        <Link href="/register">
                            <Button className="bg-green-600 hover:bg-green-700 font-medium shadow-lg shadow-green-600/20 transition-all hover:scale-105">
                                S&apos;inscrire
                                <ArrowRight className="ml-2 h-4 w-4" />
                            </Button>
                        </Link>
                    </div>
                </div>
            </div>
        </nav>
    )
}

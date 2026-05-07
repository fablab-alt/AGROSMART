'use client'

import React from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Twitter, Facebook, Instagram, Linkedin, Mail, Phone, MapPin } from 'lucide-react'

export function Footer() {
    return (
        <footer id="contact" className="bg-gray-900 text-gray-400 py-20 px-4 border-t border-gray-800">
            <div className="max-w-7xl mx-auto">
                <div className="grid md:grid-cols-4 gap-12 mb-16">
                    <div className="col-span-1 md:col-span-1">
                        <div className="flex items-center gap-2 mb-6">
                            <div className="h-16 flex items-center justify-start overflow-hidden">
                                <Image 
                                    src="/logo.png" 
                                    alt="AgroSmart" 
                                    width={180} 
                                    height={64} 
                                    className="object-contain object-left h-full w-auto" 
                                />
                            </div>
                        </div>
                        <p className="mb-6 leading-relaxed">
                            La première plateforme d&apos;agriculture de précision en Côte d&apos;Ivoire.
                            Cultivons l&apos;avenir ensemble.
                        </p>
                        <div className="flex gap-4">
                            {[Twitter, Facebook, Instagram, Linkedin].map((Icon, i) => (
                                <a
                                    key={i}
                                    href="#"
                                    className="h-10 w-10 bg-gray-800 rounded-full flex items-center justify-center hover:bg-green-600 hover:text-white transition-all duration-300"
                                    aria-label={`Visit our ${Icon.displayName || 'social'} page`}
                                >
                                    <Icon className="h-5 w-5" />
                                </a>
                            ))}
                        </div>
                    </div>

                    <div>
                        <h3 className="text-white font-bold mb-6 text-lg">Plateforme</h3>
                        <ul className="space-y-4">
                            {['Fonctionnalités', 'Comment ça marche', 'Tarifs', 'Témoignages', 'FAQ'].map((item) => (
                                <li key={item}>
                                    <a href="#" className="hover:text-green-500 transition-colors flex items-center gap-2">
                                        <span className="h-1 w-1 rounded-full bg-green-500"></span>
                                        {item}
                                    </a>
                                </li>
                            ))}
                        </ul>
                    </div>

                    <div>
                        <h3 className="text-white font-bold mb-6 text-lg">Entreprise</h3>
                        <ul className="space-y-4">
                            {['À propos', 'Équipe', 'Carrières', 'Blog', 'Presse'].map((item) => (
                                <li key={item}>
                                    <a href="#" className="hover:text-green-500 transition-colors flex items-center gap-2">
                                        <span className="h-1 w-1 rounded-full bg-green-500"></span>
                                        {item}
                                    </a>
                                </li>
                            ))}
                        </ul>
                    </div>

                    <div>
                        <h3 className="text-white font-bold mb-6 text-lg">Contact</h3>
                        <ul className="space-y-4">
                            <li className="flex items-start gap-3">
                                <Mail className="h-5 w-5 text-green-500 mt-1" />
                                <span>contact@agrosmart.ci</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <Phone className="h-5 w-5 text-green-500 mt-1" />
                                <span>+225 07 07 07 07 07</span>
                            </li>
                            <li className="flex items-start gap-3">
                                <MapPin className="h-5 w-5 text-green-500 mt-1" />
                                <span>Abidjan, Cocody Riviera<br />Côte d&apos;Ivoire</span>
                            </li>
                        </ul>
                    </div>
                </div>

                <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row justify-between items-center gap-4 text-sm">
                    <p>© 2024 AgroSmart. Tous droits réservés.</p>
                    <div className="flex gap-8">
                        <a href="#" className="hover:text-white transition-colors">Confidentialité</a>
                        <a href="#" className="hover:text-white transition-colors">Conditions</a>
                        <a href="#" className="hover:text-white transition-colors">Mentions légales</a>
                    </div>
                </div>
            </div>
        </footer>
    )
}

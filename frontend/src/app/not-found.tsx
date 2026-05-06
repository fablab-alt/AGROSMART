'use client'

import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { Leaf, Home, ArrowLeft } from 'lucide-react'

export default function NotFound() {
  const router = useRouter()
  return (
    <div className="min-h-screen bg-gradient-to-b from-green-50 to-white flex items-center justify-center px-4">
      <div className="text-center max-w-md">
        <div className="flex justify-center mb-6">
          <div className="w-24 h-24 bg-green-100 rounded-full flex items-center justify-center">
            <Leaf className="w-12 h-12 text-green-500" />
          </div>
        </div>

        <h1 className="text-7xl font-extrabold text-green-600 mb-2">404</h1>
        <h2 className="text-2xl font-bold text-gray-900 mb-3">
          Page introuvable
        </h2>
        <p className="text-gray-500 mb-8">
          La page que vous cherchez n&apos;existe pas ou a été déplacée.
          Revenez sur AgroSmart pour continuer.
        </p>

        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <Link
            href="/dashboard"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors font-medium"
          >
            <Home className="w-4 h-4" />
            Tableau de bord
          </Link>
          <button
            onClick={() => router.back()}
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors font-medium"
          >
            <ArrowLeft className="w-4 h-4" />
            Retour
          </button>
        </div>
      </div>
    </div>
  )
}

'use client'

import React from 'react'
import { useRouter } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { exitVisitorMode, exitVisitorModeToRegister } from '@/lib/visitorActions'

/**
 * Bannière persistante affichée en haut du dashboard en mode visiteur.
 * Informe l'utilisateur qu'il explore des données fictives et lui propose
 * de quitter la démo ou de créer un compte.
 */
export function VisitorBanner() {
  const router = useRouter()

  return (
    <div className="bg-amber-50 border-b border-amber-200 text-amber-900 px-4 py-2 flex items-center justify-between gap-4 flex-wrap z-40 relative">
      <div className="flex items-center gap-2 text-sm font-medium">
        <span className="text-base">🎭</span>
        <span>
          <strong>Mode démo</strong> — Vous explorez AgroSmart avec des données fictives.
          <span className="hidden sm:inline text-amber-700 font-normal ml-1">
            Recharger la page met fin à la démo.
          </span>
        </span>
      </div>
      <div className="flex items-center gap-2 shrink-0">
        <Button
          size="sm"
          variant="outline"
          className="border-amber-300 text-amber-800 hover:bg-amber-100 hover:text-amber-900 text-xs h-7 px-3"
          onClick={() => exitVisitorMode(router)}
        >
          Quitter
        </Button>
        <Button
          size="sm"
          className="bg-green-600 hover:bg-green-700 text-white text-xs h-7 px-3"
          onClick={() => exitVisitorModeToRegister(router)}
        >
          Créer un compte
        </Button>
      </div>
    </div>
  )
}

import { NextRequest, NextResponse } from 'next/server'

// Routes nécessitant une authentification
const PROTECTED_PREFIXES = [
  '/dashboard',
  '/alertes',
  '/calendrier',
  '/capteurs',
  '/communaute',
  '/diagnostic',
  '/fiches-pratiques',
  '/formations',
  '/marketplace',
  '/messages',
  '/mesures',
  '/meteo',
  '/parcelles',
  '/performance',
  '/profil',
  '/recommandations',
  '/settings',
  '/stocks',
  '/admin',
  '/dashboard-producteur',
]

// Routes publiques — ne jamais rediriger
const PUBLIC_PREFIXES = [
  '/login',
  '/register',
  '/forgot-password',
  '/demo',
  '/_next',
  '/api',
  '/favicon',
  '/fonts',
]

export function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl

  // Laisser passer les routes publiques
  if (PUBLIC_PREFIXES.some((p) => pathname.startsWith(p))) {
    return NextResponse.next()
  }

  const isProtected = PROTECTED_PREFIXES.some((p) => pathname.startsWith(p))
  if (!isProtected) {
    return NextResponse.next()
  }

  // Vérifier le cookie HttpOnly posé par le backend
  const accessToken = req.cookies.get('access_token')?.value

  if (!accessToken) {
    const loginUrl = req.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.searchParams.set('redirect', pathname)
    return NextResponse.redirect(loginUrl)
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    /*
     * Matcher: toutes les routes sauf les ressources statiques Next.js
     * et les routes d'API.
     */
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
}

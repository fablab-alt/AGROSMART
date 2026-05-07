'use client'

import React, { useState, useEffect } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { Phone, Lock, Eye, EyeOff, ArrowRight, Home } from 'lucide-react'
import { Button, Input, Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui'
import { authApi } from '@/lib/api'
import { useAuthStore } from '@/lib/store'
import toast from 'react-hot-toast'

const loginSchema = z.object({
  identifier: z.string().min(3, 'Email ou numéro de téléphone requis'),
  password: z.string().min(6, 'Le mot de passe doit contenir au moins 6 caractères'),
})

type LoginFormData = z.infer<typeof loginSchema>

export default function LoginPage() {
  const router = useRouter()
  const { login } = useAuthStore()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [requiresOtp, setRequiresOtp] = useState(false)
  const [otpCode, setOtpCode] = useState('')
  const [loginError, setLoginError] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    getValues,
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  })

  // Debug: log validation errors
  useEffect(() => {
    if (Object.keys(errors).length > 0) {
      console.log('Validation errors:', errors)
    }
  }, [errors])

  const [debugMessage, setDebugMessage] = useState<string>('')

  const onSubmit = async (data: LoginFormData) => {
    setDebugMessage('Soumission en cours...')
    setLoginError(null)
    setIsLoading(true)
    try {
      const response = await authApi.login({ telephone: data.identifier, password: data.password })

      if (response.data.success) {
        if (response.data.data.requiresOtp) {
          setRequiresOtp(true)
          toast.success('Code OTP envoyé par SMS')
        } else {
          setDebugMessage('Connexion réussie! Redirection...')
          login(response.data.data.user, response.data.data.accessToken, response.data.data.refreshToken)
          toast.success('Connexion réussie!')

          // Rediriger vers le dashboard admin si l'utilisateur est admin
          const userRole = response.data.data.user.role?.toUpperCase()
          if (userRole === 'ADMIN' || userRole === 'SUPER_ADMIN') {
            router.push('/admin')
          } else {
            router.push('/dashboard')
          }
        }
      } else {
        const errorMsg = response.data.message || 'Identifiants incorrects'
        setLoginError(errorMsg)
        setDebugMessage('Échec: ' + errorMsg)
        toast.error(errorMsg)
      }
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string }, status?: number } }
      let errorMessage = 'Identifiants incorrects'

      if (err.response?.status === 401 || err.response?.status === 404) {
        errorMessage = 'Identifiants incorrects'
      } else if (err.response?.data?.message) {
        errorMessage = err.response.data.message
      }

      setLoginError(errorMessage)
      setDebugMessage('Erreur: ' + errorMessage)
      toast.error(errorMessage)
    } finally {
      setIsLoading(false)
    }
  }

  const handleOtpSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (otpCode.length !== 6) {
      toast.error('Le code OTP doit contenir 6 chiffres')
      return
    }

    setIsLoading(true)
    try {
      const response = await authApi.verifyOtp({ telephone: getValues('identifier'), otp: otpCode })

      if (response.data.success) {
        login(response.data.data.user, response.data.data.accessToken, response.data.data.refreshToken)
        toast.success('Connexion réussie!')
        router.push('/dashboard')
      } else {
        toast.error(response.data.message || 'Code OTP invalide')
      }
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } }
      toast.error(err.response?.data?.message || 'Erreur de vérification')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-linear-to-br from-green-50 to-green-100 px-4">
      {/* Bouton retour accueil */}
      <Link
        href="/"
        className="absolute top-4 left-4 flex items-center gap-2 text-gray-600 hover:text-green-600 transition-colors"
      >
        <Home className="h-5 w-5" />
        <span className="text-sm font-medium">Accueil</span>
      </Link>

      {/* Logo */}
      <div className="flex flex-col items-center gap-2 mb-8">
        <div className="flex h-24 items-center justify-center overflow-hidden">
          <Image 
            src="/logo.png" 
            alt="AgroSmart" 
            width={240} 
            height={96} 
            className="object-contain h-full w-auto" 
            priority 
          />
        </div>
        <div>
          <p className="text-sm font-medium text-gray-500 text-center uppercase tracking-wider">Plateforme Agricole Intelligente</p>
        </div>
      </div>

      <Card className="w-full max-w-md shadow-xl">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">
            {requiresOtp ? 'Vérification OTP' : 'Connexion'}
          </CardTitle>
          <CardDescription>
            {requiresOtp
              ? 'Entrez le code reçu par SMS'
              : 'Connectez-vous à votre compte agriculteur'
            }
          </CardDescription>
        </CardHeader>
        <CardContent>
          {!requiresOtp ? (
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              <div className="relative">
                <Phone className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                <Input
                  label="Email ou Numéro de téléphone"
                  type="text"
                  placeholder="email@exemple.com ou +225 XX XX XX XX XX"
                  className="pl-10"
                  error={errors.identifier?.message}
                  {...register('identifier')}
                />
              </div>

              <div className="relative">
                <Lock className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                <Input
                  label="Mot de passe"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="••••••••"
                  className="pl-10 pr-10"
                  error={errors.password?.message}
                  {...register('password')}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-9 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? (
                    <EyeOff className="h-5 w-5" />
                  ) : (
                    <Eye className="h-5 w-5" />
                  )}
                </button>
              </div>

              <div className="flex items-center justify-between text-sm">
                <label className="flex items-center gap-2">
                  <input type="checkbox" className="rounded border-gray-300" />
                  <span className="text-gray-600">Se souvenir de moi</span>
                </label>
                <Link
                  href="/forgot-password"
                  className="text-green-600 hover:text-green-700"
                >
                  Mot de passe oublié?
                </Link>
              </div>

              {/* Afficher l'erreur de connexion */}
              {loginError && (
                <div className="bg-red-50 border border-red-300 rounded-lg p-3 text-red-700 text-sm flex items-center gap-2">
                  <svg className="h-5 w-5 shrink-0" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                  <span>{loginError}</span>
                </div>
              )}

              {/* Afficher les erreurs de validation */}
              {Object.keys(errors).length > 0 && (
                <div className="bg-red-50 border border-red-200 rounded-lg p-3 text-red-700 text-sm">
                  {errors.identifier && <p>• {errors.identifier.message}</p>}
                  {errors.password && <p>• {errors.password.message}</p>}
                </div>
              )}

              <Button
                type="submit"
                className="w-full"
                disabled={isLoading}
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
                    Connexion...
                  </span>
                ) : (
                  <span className="flex items-center gap-2">
                    Se connecter
                    <ArrowRight className="h-4 w-4" />
                  </span>
                )}
              </Button>


            </form>
          ) : (
            <form onSubmit={handleOtpSubmit} className="space-y-4">
              <div className="text-center mb-4">
                <p className="text-sm text-gray-600">
                  Code envoyé au <strong>{getValues('identifier')}</strong>
                </p>
              </div>

              <Input
                label="Code OTP"
                type="text"
                placeholder="000000"
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
                className="text-center text-2xl tracking-widest"
                maxLength={6}
              />

              <Button
                type="submit"
                className="w-full"
                disabled={isLoading || otpCode.length !== 6}
              >
                {isLoading ? (
                  <span className="flex items-center gap-2">
                    <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
                    Vérification...
                  </span>
                ) : (
                  'Vérifier le code'
                )}
              </Button>

              <button
                type="button"
                onClick={() => setRequiresOtp(false)}
                className="w-full text-sm text-gray-600 hover:text-gray-800"
              >
                ← Retour à la connexion
              </button>
            </form>
          )}

          <div className="mt-6 text-center text-sm">
            <span className="text-gray-600">Pas encore de compte? </span>
            <Link
              href="/register"
              className="text-green-600 hover:text-green-700 font-medium"
            >
              Créer un compte
            </Link>
          </div>
        </CardContent>
      </Card>


    </div>
  )
}

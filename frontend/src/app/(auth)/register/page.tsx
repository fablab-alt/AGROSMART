'use client'

import { useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { useRouter } from 'next/navigation'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { User, Phone, Lock, Eye, EyeOff, ArrowRight, ArrowLeft, MapPin, CheckCircle, Home } from 'lucide-react'
import { Button, Input, Card, CardContent, CardHeader, CardTitle, CardDescription, Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui'
import { authApi } from '@/lib/api'
import { useAuthStore } from '@/lib/store'
import toast from 'react-hot-toast'

const WEAK_PASSWORDS = ['password', '12345678', '123456789', 'qwerty', 'azerty', 'abc123', 'password123']

const passwordCriteria = [
  { key: 'length',    label: 'Au moins 8 caractères',       test: (v: string) => v.length >= 8 },
  { key: 'upper',     label: 'Au moins une majuscule',       test: (v: string) => /[A-Z]/.test(v) },
  { key: 'lower',     label: 'Au moins une minuscule',       test: (v: string) => /[a-z]/.test(v) },
  { key: 'digit',     label: 'Au moins un chiffre',          test: (v: string) => /[0-9]/.test(v) },
  { key: 'uncommon',  label: 'Mot de passe non commun',      test: (v: string) => !WEAK_PASSWORDS.includes(v.toLowerCase().replace(/[0-9]/g, '')) },
]

const registerSchema = z.object({
  nom: z.string().min(2, 'Le nom doit contenir au moins 2 caractères'),
  prenoms: z.string().min(2, 'Le prénom doit contenir au moins 2 caractères'),
  telephone: z.string().min(10, 'Numéro de téléphone invalide'),
  email: z.string().email('Email invalide').optional().or(z.literal('')),
  password: z.string()
    .min(8, 'Le mot de passe doit contenir au moins 8 caractères')
    .regex(/[A-Z]/, 'Le mot de passe doit contenir au moins une majuscule')
    .regex(/[a-z]/, 'Le mot de passe doit contenir au moins une minuscule')
    .regex(/[0-9]/, 'Le mot de passe doit contenir au moins un chiffre')
    .refine(
      (v) => !WEAK_PASSWORDS.includes(v.toLowerCase().replace(/[0-9]/g, '')),
      'Ce mot de passe est trop commun'
    ),
  confirmPassword: z.string(),
  region_id: z.string().optional(),
  production_3_mois_precedents_kg: z.number().min(0, 'La production doit être positive').optional(),
  superficie_exploitee: z.number().min(0, 'La superficie doit être positive').optional(),
  unite_superficie: z.enum(['ha', 'm2']),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirmPassword'],
})

type RegisterFormData = z.infer<typeof registerSchema>

const regions = [
  { id: '1', name: 'Abidjan' },
  { id: '2', name: 'Yamoussoukro' },
  { id: '3', name: 'Bouaké' },
  { id: '4', name: 'Daloa' },
  { id: '5', name: 'San Pedro' },
]

export default function RegisterPage() {
  const router = useRouter()
  const { login } = useAuthStore()
  const [showPassword, setShowPassword] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [step, setStep] = useState(1)
  const [requiresOtp, setRequiresOtp] = useState(false)
  const [otpCode, setOtpCode] = useState('')

  const {
    register,
    handleSubmit,
    formState: { errors },
    getValues,
    setValue,
    trigger,
    watch,
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      unite_superficie: 'ha',
      region_id: '', // Valeur par défaut pour éviter uncontrolled → controlled warning
      email: ''
    }
  })

  const validateStep = async (currentStep: number) => {
    if (currentStep === 1) {
      return await trigger(['nom', 'prenoms', 'telephone'])
    } else if (currentStep === 2) {
      return await trigger(['password', 'confirmPassword'])
    }
    return true
  }

  const nextStep = async () => {
    const isValid = await validateStep(step)
    if (isValid) {
      setStep(step + 1)
    }
  }

  const prevStep = () => {
    setStep(step - 1)
  }

  const onSubmit = async (data: RegisterFormData) => {
    setIsLoading(true)
    try {
      const response = await authApi.register({
        nom: data.nom,
        prenoms: data.prenoms,
        telephone: data.telephone,
        email: data.email || undefined,
        password: data.password,
        production_3_mois_precedents_kg: data.production_3_mois_precedents_kg,
        superficie_exploitee: data.superficie_exploitee,
        unite_superficie: data.unite_superficie,
        region_id: data.region_id
      })

      if (response.data.success) {
        if (response.data.data.requiresOtp) {
          setRequiresOtp(true)
          toast.success('Code OTP envoyé par SMS')
        } else {
          login(response.data.data.user, response.data.data.accessToken)
          toast.success('Compte créé avec succès!')
          router.push('/dashboard')
        }
      } else {
        toast.error(response.data.message || 'Erreur lors de la création du compte')
      }
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } }
      toast.error(err.response?.data?.message || 'Erreur lors de la création du compte')
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
      const response = await authApi.verifyOtp({ telephone: getValues('telephone'), otp: otpCode })

      if (response.data.success) {
        login(response.data.data.user, response.data.data.accessToken)
        toast.success('Compte vérifié avec succès!')
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
    <div className="min-h-screen flex flex-col items-center justify-center bg-linear-to-br from-green-50 to-green-100 px-4 py-8">
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
          <p className="text-sm font-medium text-gray-500 text-center uppercase tracking-wider">Surveillance Agricole Intelligente</p>
        </div>
      </div>

      <Card className="w-full max-w-md shadow-xl">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">
            {requiresOtp ? 'Vérification OTP' : 'Créer un compte'}
          </CardTitle>
          <CardDescription>
            {requiresOtp
              ? 'Entrez le code reçu par SMS'
              : `Étape ${step} sur 3 - ${step === 1 ? 'Informations personnelles' : step === 2 ? 'Sécurité' : 'Informations agricoles'}`
            }
          </CardDescription>

          {/* Progress bar */}
          {!requiresOtp && (
            <div className="flex gap-2 mt-4">
              {[1, 2, 3].map((i) => (
                <div
                  key={i}
                  className={`h-2 flex-1 rounded-full ${i <= step ? 'bg-green-500' : 'bg-gray-200'
                    }`}
                />
              ))}
            </div>
          )}
        </CardHeader>

        <CardContent>
          {!requiresOtp ? (
            <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
              {/* Step 1: Personal info */}
              {step === 1 && (
                <>
                  <div className="relative">
                    <User className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                    <Input
                      label="Nom"
                      placeholder="Votre nom de famille"
                      className="pl-10"
                      error={errors.nom?.message}
                      {...register('nom')}
                    />
                  </div>

                  <div className="relative">
                    <User className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                    <Input
                      label="Prénoms"
                      placeholder="Vos prénoms"
                      className="pl-10"
                      error={errors.prenoms?.message}
                      {...register('prenoms')}
                    />
                  </div>

                  <div className="relative">
                    <Phone className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                    <Input
                      label="Numéro de téléphone"
                      type="tel"
                      placeholder="+225 XX XX XX XX XX"
                      className="pl-10"
                      error={errors.telephone?.message}
                      {...register('telephone')}
                    />
                  </div>

                  <Button
                    type="button"
                    className="w-full"
                    onClick={nextStep}
                  >
                    <span className="flex items-center gap-2">
                      Suivant
                      <ArrowRight className="h-4 w-4" />
                    </span>
                  </Button>
                </>
              )}

              {/* Step 2: Security */}
              {step === 2 && (
                <>
                  <Input
                    label="Email (optionnel)"
                    type="email"
                    placeholder="votre@email.com"
                    error={errors.email?.message}
                    {...register('email')}
                  />

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

                  {/* Real-time password criteria */}
                  {watch('password') && watch('password').length > 0 && (
                    <div className="rounded-lg border border-gray-200 bg-gray-50 p-3 space-y-1.5">
                      <p className="text-xs font-medium text-gray-600 mb-1">Critères du mot de passe :</p>
                      {passwordCriteria.map((c) => {
                        const ok = c.test(watch('password') ?? '')
                        return (
                          <div key={c.key} className={`flex items-center gap-2 text-xs ${ok ? 'text-green-600' : 'text-red-500'}`}>
                            <span className="text-base leading-none">{ok ? '✓' : '✗'}</span>
                            <span>{c.label}</span>
                          </div>
                        )
                      })}
                    </div>
                  )}

                  <div className="relative">
                    <Lock className="absolute left-3 top-9 h-5 w-5 text-gray-400" />
                    <Input
                      label="Confirmer le mot de passe"
                      type={showPassword ? 'text' : 'password'}
                      placeholder="••••••••"
                      className="pl-10"
                      error={errors.confirmPassword?.message}
                      {...register('confirmPassword')}
                    />
                  </div>

                  <div className="flex gap-2">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={prevStep}
                    >
                      <ArrowLeft className="h-4 w-4" />
                    </Button>
                    <Button
                      type="button"
                      className="flex-1"
                      onClick={nextStep}
                    >
                      <span className="flex items-center gap-2">
                        Suivant
                        <ArrowRight className="h-4 w-4" />
                      </span>
                    </Button>
                  </div>
                </>
              )}

              {/* Step 3: Agricultural Info */}
              {step === 3 && (
                <>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Région (optionnel)
                    </label>
                    <Select
                      value={watch('region_id')}
                      onValueChange={(value) => setValue('region_id', value)}
                    >
                      <SelectTrigger>
                        <div className="flex items-center gap-2">
                          <MapPin className="h-4 w-4 text-gray-400" />
                          <SelectValue placeholder="Sélectionnez votre région" />
                        </div>
                      </SelectTrigger>
                      <SelectContent>
                        {regions.map((region) => (
                          <SelectItem key={region.id} value={region.id}>
                            {region.name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-4 pt-2">
                    <h4 className="font-medium text-gray-900 border-b pb-2">Informations d&apos;exploitation</h4>

                    <div>
                      <Input
                        label="Production des 3 derniers mois (Kg)"
                        type="number"
                        placeholder="Ex: 500"
                        error={errors.production_3_mois_precedents_kg?.message}
                        {...register('production_3_mois_precedents_kg', { valueAsNumber: true })}
                      />
                    </div>

                    <div className="flex gap-2">
                      <div className="flex-1">
                        <Input
                          label="Superficie exploitée"
                          type="number"
                          placeholder="Ex: 5"
                          error={errors.superficie_exploitee?.message}
                          {...register('superficie_exploitee', { valueAsNumber: true })}
                        />
                      </div>
                      <div className="w-1/3">
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                          Unité
                        </label>
                        <Select
                          value={watch('unite_superficie')}
                          onValueChange={(value) => setValue('unite_superficie', value as 'ha' | 'm2')}
                        >
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="ha">Hectares</SelectItem>
                            <SelectItem value="m2">m²</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                  </div>

                  <div className="p-4 bg-green-50 rounded-lg border border-green-200 mt-4">
                    <h4 className="font-medium text-green-800 mb-2 flex items-center gap-2">
                      <CheckCircle className="h-4 w-4" />
                      Résumé de votre inscription
                    </h4>
                    <ul className="text-sm text-green-700 space-y-1">
                      <li>• Nom: {getValues('nom')} {getValues('prenoms')}</li>
                      <li>• Téléphone: {getValues('telephone')}</li>
                      {getValues('superficie_exploitee') && (
                        <li>• Superficie: {getValues('superficie_exploitee')} {getValues('unite_superficie')}</li>
                      )}
                    </ul>
                  </div>

                  <div className="flex gap-2">
                    <Button
                      type="button"
                      variant="outline"
                      onClick={prevStep}
                    >
                      <ArrowLeft className="h-4 w-4" />
                    </Button>
                    <Button
                      type="submit"
                      className="flex-1"
                      disabled={isLoading}
                    >
                      {isLoading ? (
                        <span className="flex items-center gap-2">
                          <span className="animate-spin h-4 w-4 border-2 border-white border-t-transparent rounded-full" />
                          Création...
                        </span>
                      ) : (
                        <span className="flex items-center gap-2">
                          Créer mon compte
                          <CheckCircle className="h-4 w-4" />
                        </span>
                      )}
                    </Button>
                  </div>
                </>
              )}
            </form>
          ) : (
            <form onSubmit={handleOtpSubmit} className="space-y-4">
              <div className="text-center mb-4">
                <p className="text-sm text-gray-600">
                  Code envoyé au <strong>{getValues('telephone')}</strong>
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
                ← Retour à l&apos;inscription
              </button>
            </form>
          )}

          <div className="mt-6 text-center text-sm">
            <span className="text-gray-600">Déjà un compte? </span>
            <Link
              href="/login"
              className="text-green-600 hover:text-green-700 font-medium"
            >
              Se connecter
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

import { useState, useEffect, useCallback } from 'react'

interface GeolocationCoordinates {
  latitude: number
  longitude: number
  accuracy: number
  timestamp: number
}

interface UseGeolocationReturn {
  coordinates: GeolocationCoordinates | null
  error: string | null
  loading: boolean
  requestLocation: () => void
  hasPermission: boolean
}

/**
 * Hook personnalisé pour la géolocalisation
 * Utilisé pour la démo visiteur et la création de parcelles
 */
export function useGeolocation(): UseGeolocationReturn {
  const [coordinates, setCoordinates] = useState<GeolocationCoordinates | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [hasPermission, setHasPermission] = useState(false)

  const requestLocation = useCallback(() => {
    if (!navigator.geolocation) {
      setError('La géolocalisation n\'est pas supportée par votre navigateur')
      return
    }

    setLoading(true)
    setError(null)

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude, accuracy } = position.coords
        setCoordinates({
          latitude,
          longitude,
          accuracy,
          timestamp: Date.now(),
        })
        setHasPermission(true)
        setLoading(false)
      },
      (err) => {
        setError(err.message)
        setLoading(false)
        if (err.code === err.PERMISSION_DENIED) {
          setHasPermission(false)
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0,
      }
    )
  }, [])

  return {
    coordinates,
    error,
    loading,
    requestLocation,
    hasPermission,
  }
}

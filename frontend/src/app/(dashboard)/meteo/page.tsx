'use client'

import { useState, useEffect, useCallback } from 'react'
import {
  Cloud,
  Sun,
  CloudRain,
  Wind,
  Droplets,
  Thermometer,
  Eye,
  Gauge,
  MapPin,
  RefreshCw,
  Calendar,
  Sunrise,
  Sunset,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Spinner } from '@/components/ui/spinner'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import toast from 'react-hot-toast'
import api from '@/lib/api'

interface MeteoData {
  temperature: number
  temperatureMin: number
  temperatureMax: number
  humidity: number
  pressure: number
  windSpeed: number
  windDirection: string
  description: string
  icon: string
  visibility: number
  sunrise: string
  sunset: string
  location: string
}

interface Prevision {
  date: string
  jour: string
  tempMin: number
  tempMax: number
  description: string
  icon: string
  precipitation: number
}

const getWmoDescription = (code: number): { label: string; icon: string } => {
  // WMO Weather interpretation codes (WW)
  // 0: Clear sky
  if (code === 0) return { label: 'Ensoleillé', icon: 'sunny' };
  // 1, 2, 3: Mainly clear, partly cloudy, and overcast
  if (code >= 1 && code <= 3) return { label: 'Partiellement nuageux', icon: 'partly-cloudy' };
  // 45, 48: Fog
  if (code === 45 || code === 48) return { label: 'Brumeux', icon: 'cloudy' };
  // 51, 53, 55: Drizzle
  if (code >= 51 && code <= 55) return { label: 'Bruine', icon: 'rainy' };
  // 61, 63, 65: Rain
  if (code >= 61 && code <= 67) return { label: 'Pluie', icon: 'rainy' };
  // 71, 73, 75: Snow fall
  if (code >= 71 && code <= 77) return { label: 'Neige', icon: 'rainy' }; // Using rainy icon as fallback for now
  // 80, 81, 82: Rain showers
  if (code >= 80 && code <= 82) return { label: 'Averses', icon: 'rainy' };
  // 95, 96, 99: Thunderstorm
  if (code >= 95) return { label: 'Orage', icon: 'stormy' };

  return { label: 'Nuageux', icon: 'cloudy' };
}

export default function MeteoPage() {
  const [loading, setLoading] = useState(true)
  const [refreshing, setRefreshing] = useState(false)
  const [meteo, setMeteo] = useState<MeteoData | null>(null) // Allow null
  const [previsions, setPrevisions] = useState<Prevision[]>([])
  const [selectedParcelle, setSelectedParcelle] = useState<string>('all')

  const fetchMeteo = useCallback(async () => {
    try {
      // Get user location first (or default to Abidjan/Parcelle location)
      // For now, let's assume Abidjan if no parcelle selected, or fetch parcelle coords
      let lat = 5.3600; // Abidjan default
      let lon = -4.0083;

      if (selectedParcelle !== 'all') {
        try {
          const pRes = await api.get(`/parcelles/${selectedParcelle}`);
          if (pRes.data.success && pRes.data.data.localisation) {
            lat = pRes.data.data.localisation.latitude;
            lon = pRes.data.data.localisation.longitude;
          }
        } catch (e) {
          console.error('Error fetching parcelle coords', e);
        }
      }

      const [currentRes, forecastRes] = await Promise.all([
        api.get(`/weather/current?lat=${lat}&lon=${lon}`),
        api.get(`/weather/forecast?lat=${lat}&lon=${lon}&days=7`)
      ]);

      if (currentRes.data.success) {
        const current = currentRes.data.data;
        const wmo = getWmoDescription(current.weather_code);
        setMeteo({
          temperature: Number(current.temperature.toFixed(1)),
          temperatureMin: 0, // Not available in current, could get from forecast
          temperatureMax: 0,
          humidity: current.humidity,
          pressure: 1013, // Default not in OpenMeteo basic
          windSpeed: current.wind_speed,
          windDirection: 'N/A', // Need to map degrees to cardio points
          description: wmo.label,
          icon: wmo.icon,
          visibility: 10, // Not in basic
          sunrise: '06:00', // Need daily api for this
          sunset: '18:00',
          location: currentRes.data.data.location ? `${lat.toFixed(2)}, ${lon.toFixed(2)}` : 'Position actuelle'
        });
      }

      if (forecastRes.data.success) {
        const daily = forecastRes.data.data.daily;
        if (daily && daily.length > 0) {
          const newPrevisions = daily.map((d: any) => {
            const wmo = getWmoDescription(d.weather_code);
            const date = d.date ? new Date(d.date) : null;
            return {
              date: d.date,
              jour: date && !isNaN(date.getTime()) ? date.toLocaleDateString('fr-FR', { weekday: 'short' }) : '-',
              tempMin: Math.round(d.temp_min),
              tempMax: Math.round(d.temp_max),
              description: wmo.label,
              icon: wmo.icon,
              precipitation: Math.round(d.precipitation_probability || 0)
            };
          });
          setPrevisions(newPrevisions);

          // Update min/max for current day from forecast
          setMeteo(prev => prev ? ({ ...prev, temperatureMin: Math.round(daily[0].temp_min), temperatureMax: Math.round(daily[0].temp_max) }) : prev);
        }
      }
    } catch (error) {
      console.error('Error fetching weather', error);
      toast.error('Impossible de charger la météo');
      setMeteo(null); // No mock data!
      setPrevisions([]);
    } finally {
      setLoading(false)
      setRefreshing(false)
    }
  }, [selectedParcelle])

  useEffect(() => {
    fetchMeteo()
  }, [fetchMeteo])

  const handleRefresh = async () => {
    setRefreshing(true)
    await fetchMeteo()
    toast.success('Données météo actualisées')
  }

  const getWeatherIcon = (icon: string, size: string = 'h-8 w-8') => {
    switch (icon) {
      case 'sunny':
        return <Sun className={`${size} text-yellow-500`} />
      case 'cloudy':
        return <Cloud className={`${size} text-gray-500`} />
      case 'partly-cloudy':
        return <Cloud className={`${size} text-blue-400`} />
      case 'rainy':
        return <CloudRain className={`${size} text-blue-600`} />
      case 'stormy':
        return <CloudRain className={`${size} text-purple-600`} />
      default:
        return <Sun className={`${size} text-yellow-500`} />
    }
  }


  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-100">
        <Spinner className="h-8 w-8" />
      </div>
    )
  }

  if (!meteo) {
    return (
      <div className="flex flex-col items-center justify-center min-h-100 p-4 text-center">
        <Cloud className="h-16 w-16 text-gray-300 mb-4" />
        <h2 className="text-xl font-semibold text-gray-900 mb-2">Impossible de charger la météo</h2>
        <p className="text-gray-500 mb-6">Vérifiez votre connexion internet ou réessayez plus tard.</p>
        <Button onClick={handleRefresh} disabled={refreshing}>
          <RefreshCw className={`h-4 w-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
          Réessayer
        </Button>
      </div>
    )
  }

  return (
    <div className="p-4 md:p-6 space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold text-gray-900 flex items-center gap-2">
            <Cloud className="h-7 w-7 text-blue-600" />
            Météo
          </h1>
          <p className="text-gray-500 flex items-center gap-1 mt-1">
            <MapPin className="h-4 w-4" />
            {meteo.location}
          </p>
        </div>
        <div className="flex gap-3">
          <Select value={selectedParcelle} onValueChange={setSelectedParcelle}>
            <SelectTrigger className="w-50">
              <SelectValue placeholder="Toutes les parcelles" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Toutes les parcelles</SelectItem>
              <SelectItem value="1">Parcelle Cacao Nord</SelectItem>
              <SelectItem value="2">Parcelle Café Est</SelectItem>
              <SelectItem value="3">Parcelle Hévéa Sud</SelectItem>
            </SelectContent>
          </Select>
          <Button
            variant="outline"
            onClick={handleRefresh}
            disabled={refreshing}
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${refreshing ? 'animate-spin' : ''}`} />
            Actualiser
          </Button>
        </div>
      </div>

      {/* Current Weather */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <Card className="lg:col-span-2">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <div className="flex items-end gap-2">
                  <span className="text-6xl font-bold text-gray-900">
                    {meteo.temperature}°
                  </span>
                  <span className="text-2xl text-gray-500 mb-2">C</span>
                </div>
                <p className="text-xl text-gray-600 mt-2">{meteo.description}</p>
                <p className="text-sm text-gray-500 mt-1">
                  Min: {meteo.temperatureMin}° / Max: {meteo.temperatureMax}°
                </p>
              </div>
              <div className="text-right">
                {getWeatherIcon(meteo.icon, 'h-24 w-24')}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-lg">Lever & Coucher du soleil</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Sunrise className="h-6 w-6 text-orange-500" />
                <div>
                  <p className="text-sm text-gray-500">Lever</p>
                  <p className="text-lg font-semibold">{meteo.sunrise}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <Sunset className="h-6 w-6 text-orange-600" />
                <div>
                  <p className="text-sm text-gray-500">Coucher</p>
                  <p className="text-lg font-semibold">{meteo.sunset}</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Weather Details */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
              <Droplets className="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Humidité</p>
              <p className="text-xl font-bold">{meteo.humidity}%</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center">
              <Wind className="h-6 w-6 text-green-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Vent</p>
              <p className="text-xl font-bold">{meteo.windSpeed} km/h</p>
              <p className="text-xs text-gray-400">{meteo.windDirection}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-12 w-12 rounded-full bg-purple-100 flex items-center justify-center">
              <Gauge className="h-6 w-6 text-purple-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Pression</p>
              <p className="text-xl font-bold">{meteo.pressure} hPa</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4 flex items-center gap-3">
            <div className="h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center">
              <Eye className="h-6 w-6 text-gray-600" />
            </div>
            <div>
              <p className="text-sm text-gray-500">Visibilité</p>
              <p className="text-xl font-bold">{meteo.visibility} km</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* 7-Day Forecast */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5" />
            Prévisions sur 7 jours
          </CardTitle>
          <CardDescription>
            Planifiez vos activités agricoles en fonction de la météo
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-4">
            {previsions.map((prev, index) => (
              <div
                key={prev.date}
                className={`p-4 rounded-lg text-center ${index === 0 ? 'bg-blue-50 border-2 border-blue-200' : 'bg-gray-50'
                  }`}
              >
                <p className="font-semibold text-gray-900">{prev.jour}</p>
                <div className="my-3 flex justify-center">
                  {getWeatherIcon(prev.icon, 'h-10 w-10')}
                </div>
                <p className="text-sm text-gray-600">{prev.description}</p>
                <div className="mt-2">
                  <span className="font-bold text-gray-900">{prev.tempMax}°</span>
                  <span className="text-gray-400 mx-1">/</span>
                  <span className="text-gray-500">{prev.tempMin}°</span>
                </div>
                <div className="mt-2 flex items-center justify-center gap-1 text-xs text-blue-600">
                  <Droplets className="h-3 w-3" />
                  {prev.precipitation}%
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Agricultural Advice */}
      <Card className="bg-green-50 border-green-200">
        <CardHeader>
          <CardTitle className="text-green-800">Conseils agricoles du jour</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-start gap-3">
            <div className="h-8 w-8 rounded-full bg-green-200 flex items-center justify-center shrink-0">
              <Droplets className="h-4 w-4 text-green-700" />
            </div>
            <div>
              <p className="font-medium text-green-900">Irrigation</p>
              <p className="text-sm text-green-700">
                Avec une humidité de {meteo.humidity}%, réduisez l&apos;irrigation de 20% aujourd&apos;hui.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <div className="h-8 w-8 rounded-full bg-green-200 flex items-center justify-center shrink-0">
              <Thermometer className="h-4 w-4 text-green-700" />
            </div>
            <div>
              <p className="font-medium text-green-900">Température</p>
              <p className="text-sm text-green-700">
                Température idéale pour le travail aux champs entre 6h-10h et 16h-18h.
              </p>
            </div>
          </div>
          <div className="flex items-start gap-3">
            <div className="h-8 w-8 rounded-full bg-green-200 flex items-center justify-center shrink-0">
              <CloudRain className="h-4 w-4 text-green-700" />
            </div>
            <div>
              <p className="font-medium text-green-900">Prévisions</p>
              <p className="text-sm text-green-700">
                Pluies prévues jeudi - Planifiez les traitements phytosanitaires avant.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

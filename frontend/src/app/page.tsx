'use client'

import React, { useState, useEffect } from 'react'
import { Navbar } from '@/components/landing/Navbar'
import { HeroSection } from '@/components/landing/HeroSection'
import { StatsSection } from '@/components/landing/StatsSection'
import { FeaturesSection } from '@/components/landing/FeaturesSection'
import { HowItWorksSection } from '@/components/landing/HowItWorksSection'
import { BenefitsSection } from '@/components/landing/BenefitsSection'
import { CTASection } from '@/components/landing/CTASection'
import { Footer } from '@/components/landing/Footer'

export default function LandingPage() {
  const [stats, setStats] = useState({
    hectares: '10K+',
    agriculteurs: '5000+',
    cultures: '25+',
    precision: '94%'
  })

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3600/api/v1'}/analytics/public`)
        if (response.ok) {
          const data = await response.json()
          if (data.success && data.data) {
            setStats(data.data)
          }
        }
      } catch (error) {
        console.error('Error fetching stats:', error)
      }
    }

    fetchStats()
  }, [])

  return (
    <div className="min-h-screen bg-gray-50 font-sans selection:bg-green-100 selection:text-green-900">
      <Navbar />

      <main>
        <HeroSection />
        <StatsSection stats={stats} />
        <FeaturesSection />
        <HowItWorksSection />
        <BenefitsSection />
        <CTASection />
      </main>

      <Footer />
    </div>
  )
}

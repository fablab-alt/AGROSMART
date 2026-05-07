// Helpers utilitaires pour générer des mocks réalistes

export function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

export function uid(prefix = 'mock'): string {
  return `${prefix}-${Math.random().toString(36).slice(2, 10)}`
}

export function daysAgo(n: number): string {
  const d = new Date()
  d.setDate(d.getDate() - n)
  return d.toISOString()
}

export function daysAhead(n: number): string {
  const d = new Date()
  d.setDate(d.getDate() + n)
  return d.toISOString()
}

export function hoursAgo(n: number): string {
  const d = new Date()
  d.setHours(d.getHours() - n)
  return d.toISOString()
}

export function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

export function range(n: number): number[] {
  return Array.from({ length: n }, (_, i) => i)
}

// Génère une valeur quasi sinusoïdale pour des séries de mesures réalistes
export function sineSeries(
  count: number,
  base: number,
  amplitude: number,
  noise = 0.1
): number[] {
  return range(count).map((i) => {
    const v = base + amplitude * Math.sin((i / count) * Math.PI * 2)
    const n = (Math.random() - 0.5) * amplitude * noise
    return Number((v + n).toFixed(2))
  })
}

export function paginate<T>(items: T[], page = 1, limit = 20) {
  const start = (page - 1) * limit
  return {
    items: items.slice(start, start + limit),
    total: items.length,
    page,
    limit,
    totalPages: Math.ceil(items.length / limit),
  }
}

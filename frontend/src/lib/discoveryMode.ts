const DISCOVERY_MODE_KEY = 'agrosmart:discovery-mode'

export function setDiscoveryMode(enabled: boolean): void {
  if (typeof window === 'undefined') return
  try {
    if (enabled) {
      sessionStorage.setItem(DISCOVERY_MODE_KEY, '1')
    } else {
      sessionStorage.removeItem(DISCOVERY_MODE_KEY)
    }
  } catch {
    // ignore storage errors in private mode
  }
}

export function isDiscoveryModeEnabled(): boolean {
  if (typeof window === 'undefined') return false
  try {
    return sessionStorage.getItem(DISCOVERY_MODE_KEY) === '1'
  } catch {
    return false
  }
}

export function clearDiscoveryMode(): void {
  setDiscoveryMode(false)
}

export function isReadOnlyHttpMethod(method?: string): boolean {
  const normalized = (method || 'get').toLowerCase()
  return normalized === 'get' || normalized === 'head' || normalized === 'options'
}

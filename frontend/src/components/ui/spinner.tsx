import { cn } from "@/lib/utils"
import { Loader2 } from "lucide-react"

interface SpinnerProps {
  size?: "sm" | "md" | "lg"
  className?: string
}

const sizeClasses = {
  sm: "h-4 w-4",
  md: "h-6 w-6",
  lg: "h-8 w-8",
}

export function Spinner({ size = "md", className }: SpinnerProps) {
  return (
    <Loader2
      className={cn("animate-spin text-green-600", sizeClasses[size], className)}
    />
  )
}

interface LoadingOverlayProps {
  message?: string
}

export function LoadingOverlay({ message = "Chargement..." }: LoadingOverlayProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="rounded-lg bg-white p-6 shadow-xl flex flex-col items-center gap-4">
        <Spinner size="lg" />
        <p className="text-gray-700">{message}</p>
      </div>
    </div>
  )
}

interface LoadingCardProps {
  message?: string
}

export function LoadingCard({ message = "Chargement..." }: LoadingCardProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 text-center">
      <Spinner size="lg" />
      <p className="mt-4 text-gray-600">{message}</p>
    </div>
  )
}

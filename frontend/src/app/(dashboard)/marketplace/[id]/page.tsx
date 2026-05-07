'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import Image from 'next/image'
import {
    ArrowLeft,
    ShoppingBag,
    Calendar,
    MapPin,
    User,
    Phone,
    Shield,
    Truck,
    Loader2,
    Clock
} from 'lucide-react'
import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
    CardFooter,
    Button,
    Badge,
    Input,
    Label,
    Textarea,
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
    DialogFooter
} from '@/components/ui'
import api from '@/lib/api'
import toast from 'react-hot-toast'

interface Product {
    id: string
    nom: string
    description?: string
    categorie: string
    prix: number
    devise: string
    unite: string
    quantite_disponible: number // Mapped to stock on backend
    stock?: number // just in case
    images?: string[]
    vendeur_nom: string
    vendeur_telephone?: string
    type_offre?: 'vente' | 'location'
    prix_location_jour?: number
    duree_min_location?: number
    caution?: number
    localisation?: string
}

export default function ProductDetailPage({ params }: { params: Promise<{ id: string }> }) {
    const router = useRouter()
    const [product, setProduct] = useState<Product | null>(null)
    const [loading, setLoading] = useState(true)
    const [orderOpen, setOrderOpen] = useState(false)
    const [orderLoading, setOrderLoading] = useState(false)
    const [productId, setProductId] = useState<string | null>(null)

    // Order Form State
    const [quantity, setQuantity] = useState(1)
    const [address, setAddress] = useState('')
    const [notes, setNotes] = useState('')
    const [dateDebut, setDateDebut] = useState('')
    const [dateFin, setDateFin] = useState('')
    const [rentalDays, setRentalDays] = useState(0)
    const [totalPrice, setTotalPrice] = useState(0)

    useEffect(() => {
        const fetchProduct = async () => {
            // Await params dans Next.js 16+
            const resolvedParams = await params
            const id = resolvedParams.id

            // Vérification que l'ID est valide avant l'appel API
            if (!id || id === 'undefined') {
                toast.error('ID produit invalide')
                router.push('/marketplace')
                setLoading(false)
                return
            }

            setProductId(id)

            try {
                const res = await api.get(`/marketplace/produits/${id}`)
                if (res.data.success) {
                    setProduct(res.data.data)
                }
            } catch (error) {
                console.error(error)
                toast.error('Produit introuvable')
                router.push('/marketplace')
            } finally {
                setLoading(false)
            }
        }
        fetchProduct()
    }, [params, router])

    // Calculate total price when inputs change
    useEffect(() => {
        if (!product) return

        if (product.type_offre === 'location') {
            if (dateDebut && dateFin) {
                const start = new Date(dateDebut)
                const end = new Date(dateFin)
                const diffTime = Math.abs(end.getTime() - start.getTime())
                const days = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
                setRentalDays(days)
                const pricePerDay = product.prix_location_jour || product.prix
                setTotalPrice(pricePerDay * days * quantity)
            } else {
                setRentalDays(0)
                setTotalPrice(0)
            }
        } else {
            // Sale
            setTotalPrice(product.prix * quantity)
        }
    }, [product, quantity, dateDebut, dateFin])

    const handleOrder = async () => {
        setOrderLoading(true)
        try {
            const payload: any = {
                produit_id: product?.id,
                quantite: quantity,
                adresse_livraison: address,
                notes,
                mode_livraison: 'standard' // Default for now
            }

            if (product?.type_offre === 'location') {
                if (!dateDebut || !dateFin) {
                    toast.error('Veuillez sélectionner les dates')
                    setOrderLoading(false)
                    return
                }
                if (rentalDays < (product.duree_min_location || 1)) {
                    toast.error(`La durée minimum est de ${product.duree_min_location || 1} jours`)
                    setOrderLoading(false)
                    return
                }
                payload.date_debut = new Date(dateDebut).toISOString()
                payload.date_fin = new Date(dateFin).toISOString()
            }

            const res = await api.post('/marketplace/commandes', payload)
            if (res.data.success) {
                toast.success(product?.type_offre === 'location' ? 'Location confirmée !' : 'Commande passée avec succès !')
                setOrderOpen(false)
                router.refresh() // Refresh to update stock if needed (or fetch again)
                // Optionally redirect to orders page
            }
        } catch (error: any) {
            console.error(error)
            toast.error(error.response?.data?.message || 'Erreur lors de la commande')
        } finally {
            setOrderLoading(false)
        }
    }

    const formatPrice = (p: number) => {
        return new Intl.NumberFormat('fr-FR', {
            style: 'currency',
            currency: product?.devise || 'XOF'
        }).format(p)
    }

    if (loading) {
        return (
            <div className="flex h-[50vh] items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-green-600" />
            </div>
        )
    }

    if (!product) return null

    const isRental = product.type_offre === 'location'

    return (
        <div className="max-w-4xl mx-auto space-y-6">
            <Link href="/marketplace">
                <Button variant="ghost" size="sm">
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    Retour au marketplace
                </Button>
            </Link>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                {/* Images */}
                <div className="space-y-4">
                    <div className="relative aspect-square bg-gray-100 rounded-xl overflow-hidden">
                        {product.images && product.images.length > 0 ? (
                            <Image
                                src={product.images[0]}
                                alt={product.nom}
                                fill
                                className="object-cover"
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full text-gray-400">
                                Image non disponible
                            </div>
                        )}
                        <div className="absolute top-4 left-4 flex gap-2">
                            {isRental && (
                                <Badge className="bg-blue-600 hover:bg-blue-700">Location</Badge>
                            )}
                            <Badge variant="secondary">{product.categorie}</Badge>
                        </div>
                    </div>
                </div>

                {/* Info */}
                <div className="space-y-6">
                    <div>
                        <h1 className="text-3xl font-bold text-gray-900">{product.nom}</h1>
                        <div className="flex items-center gap-2 mt-2 text-gray-500">
                            <MapPin className="h-4 w-4" />
                            {product.localisation || 'Localisation non spécifiée'}
                        </div>
                    </div>

                    <div className="p-4 bg-gray-50 rounded-lg space-y-2">
                        <div className="flex items-end gap-2">
                            <span className="text-3xl font-bold text-green-600">
                                {formatPrice(isRental ? (product.prix_location_jour || product.prix) : product.prix)}
                            </span>
                            <span className="text-gray-600 mb-1">
                                {isRental ? '/ jour' : ` / ${product.unite}`}
                            </span>
                        </div>
                        {isRental && product.caution && (
                            <div className="text-sm text-gray-500 flex items-center gap-1">
                                <Shield className="h-3 w-3" />
                                Caution: {formatPrice(product.caution)}
                            </div>
                        )}
                        {isRental && product.duree_min_location && (
                            <div className="text-sm text-gray-500 flex items-center gap-1">
                                <Clock className="h-3 w-3" />
                                Min. {product.duree_min_location} jours
                            </div>
                        )}
                        <div className="text-sm text-gray-600">
                            Stock: {product.quantite_disponible || product.stock || 0}
                        </div>
                    </div>

                    <div className="space-y-2">
                        <h3 className="font-semibold text-gray-900">Description</h3>
                        <p className="text-gray-600 leading-relaxed">
                            {product.description || "Aucune description fournie par le vendeur."}
                        </p>
                    </div>

                    <div className="flex items-center gap-4 py-4 border-t border-b">
                        <div className="flex h-12 w-12 items-center justify-center rounded-full bg-slate-100">
                            <User className="h-6 w-6 text-slate-500" />
                        </div>
                        <div>
                            <p className="font-medium text-gray-900">{product.vendeur_nom}</p>
                            <div className="flex items-center gap-2 text-sm text-gray-500">
                                <Phone className="h-3 w-3" />
                                {product.vendeur_telephone || 'Non spécifié'}
                            </div>
                        </div>
                    </div>

                    <Dialog open={orderOpen} onOpenChange={setOrderOpen}>
                        <DialogTrigger asChild>
                            <Button size="lg" className="w-full">
                                {isRental ? 'Louer cet article' : 'Commander maintenant'}
                            </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-md">
                            <DialogHeader>
                                <DialogTitle>{isRental ? 'Demande de location' : 'Passer commande'}</DialogTitle>
                                <DialogDescription>
                                    {product.nom} - {formatPrice(isRental ? (product.prix_location_jour || product.prix) : product.prix)}
                                    {isRental ? '/jour' : `/${product.unite}`}
                                </DialogDescription>
                            </DialogHeader>

                            <div className="space-y-4 py-4">
                                {isRental && (
                                    <div className="grid grid-cols-2 gap-4">
                                        <div className="space-y-2">
                                            <Label>Date de début</Label>
                                            <Input
                                                type="date"
                                                value={dateDebut}
                                                onChange={(e) => setDateDebut(e.target.value)}
                                                min={new Date().toISOString().split('T')[0]}
                                            />
                                        </div>
                                        <div className="space-y-2">
                                            <Label>Date de fin</Label>
                                            <Input
                                                type="date"
                                                value={dateFin}
                                                onChange={(e) => setDateFin(e.target.value)}
                                                min={dateDebut || new Date().toISOString().split('T')[0]}
                                            />
                                        </div>
                                    </div>
                                )}

                                <div className="space-y-2">
                                    <Label>Quantité</Label>
                                    <Input
                                        type="number"
                                        min="1"
                                        max={product.quantite_disponible || product.stock}
                                        value={quantity}
                                        onChange={(e) => setQuantity(Number(e.target.value))}
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label>Adresse/Lieu de livraison</Label>
                                    <Input
                                        value={address}
                                        onChange={(e) => setAddress(e.target.value)}
                                        placeholder="Votre adresse..."
                                    />
                                </div>

                                <div className="space-y-2">
                                    <Label>Notes (Optionnel)</Label>
                                    <Textarea
                                        value={notes}
                                        onChange={(e) => setNotes(e.target.value)}
                                        placeholder="Instructions particulières..."
                                    />
                                </div>

                                {/* Summary */}
                                <div className="bg-slate-50 p-4 rounded-lg space-y-2 text-sm">
                                    <div className="flex justify-between">
                                        <span>Prix unitaire:</span>
                                        <span>{formatPrice(isRental ? (product.prix_location_jour || product.prix) : product.prix)}</span>
                                    </div>
                                    {isRental && (
                                        <div className="flex justify-between">
                                            <span>Durée:</span>
                                            <span>{rentalDays} jours</span>
                                        </div>
                                    )}
                                    <div className="flex justify-between border-t pt-2 font-bold text-lg">
                                        <span>Total:</span>
                                        <span>{formatPrice(totalPrice)}</span>
                                    </div>
                                </div>

                            </div>

                            <DialogFooter>
                                <Button variant="outline" onClick={() => setOrderOpen(false)}>Annuler</Button>
                                <Button onClick={handleOrder} disabled={orderLoading || totalPrice <= 0}>
                                    {orderLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Confirmer'}
                                </Button>
                            </DialogFooter>
                        </DialogContent>
                    </Dialog>
                </div>
            </div>
        </div>
    )
}

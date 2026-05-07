'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import {
    ArrowLeft,
    Upload,
    Loader2,
    DollarSign,
    Calendar,
    AlertCircle
} from 'lucide-react'
import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
    CardDescription,
    Button,
    Input,
    Label,
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
    Textarea,
    Switch
} from '@/components/ui'
import api from '@/lib/api'
import toast from 'react-hot-toast'

const categories = [
    { value: 'cereale', label: 'Céréales' },
    { value: 'legume', label: 'Légumes' },
    { value: 'fruit', label: 'Fruits' },
    { value: 'tubercule', label: 'Tubercules' },
    { value: 'oleagineux', label: 'Oléagineux' },
    { value: 'intrant', label: 'Intrants' },
    { value: 'equipement', label: 'Équipements' },
    { value: 'service', label: 'Services' },
    { value: 'autre', label: 'Autre' },
]

export default function NewProductPage() {
    const router = useRouter()
    const [loading, setLoading] = useState(false)
    const [formData, setFormData] = useState({
        nom: '',
        description: '',
        categorie: '',
        prix: '',
        unite: 'kg',
        quantite_disponible: '',
        localisation: '',
        type_offre: 'vente',
        prix_location_jour: '',
        duree_min_location: '1',
        caution: ''
    })

    // Gestion des images
    const [images, setImages] = useState<File[]>([])

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault()
        setLoading(true)

        try {
            // Validate
            if (!formData.nom || !formData.categorie || !formData.quantite_disponible) {
                toast.error('Veuillez remplir les champs obligatoires')
                setLoading(false)
                return
            }

            if (formData.type_offre === 'vente' && !formData.prix) {
                toast.error('Le prix est requis pour la vente')
                setLoading(false)
                return
            }

            if (formData.type_offre === 'location' && !formData.prix_location_jour) {
                toast.error('Le prix par jour est requis pour la location')
                setLoading(false)
                return
            }

            const payload = new FormData()
            Object.entries(formData).forEach(([key, value]) => {
                if (value) payload.append(key, value)
            })

            // Default price to 0 if not set (e.g. for rental where we use prix_location_jour)
            if (formData.type_offre === 'location') {
                payload.append('prix', '0')
            }

            // Add images
            images.forEach(img => payload.append('images', img))

            const res = await api.post('/marketplace/produits', payload, {
                headers: { 'Content-Type': 'multipart/form-data' }
            })

            if (res.data.success) {
                toast.success('Annonce publiée avec succès')
                router.push('/marketplace')
            }
        } catch (error: any) {
            console.error(error)
            toast.error(error.response?.data?.message || 'Erreur lors de la publication')
        } finally {
            setLoading(false)
        }
    }

    return (
        <div className="max-w-2xl mx-auto space-y-6">
            <div className="flex items-center gap-4">
                <Link href="/marketplace">
                    <Button variant="ghost" size="icon">
                        <ArrowLeft className="h-4 w-4" />
                    </Button>
                </Link>
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Nouvelle Annonce</h1>
                    <p className="text-gray-500">Publiez un produit à vendre ou à louer</p>
                </div>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Détails de l'annonce</CardTitle>
                    <CardDescription>Fournissez les informations sur votre produit</CardDescription>
                </CardHeader>
                <CardContent>
                    <form onSubmit={handleSubmit} className="space-y-6">

                        {/* Type d'offre */}
                        <div className="grid grid-cols-2 gap-4 p-4 bg-gray-50 rounded-lg">
                            <div
                                className={`cursor-pointer border rounded-lg p-4 text-center transition-all ${formData.type_offre === 'vente' ? 'border-green-600 bg-green-50 text-green-700' : 'hover:bg-gray-100'}`}
                                onClick={() => setFormData({ ...formData, type_offre: 'vente' })}
                            >
                                <DollarSign className="h-6 w-6 mx-auto mb-2" />
                                <div className="font-semibold">Vente</div>
                            </div>
                            <div
                                className={`cursor-pointer border rounded-lg p-4 text-center transition-all ${formData.type_offre === 'location' ? 'border-blue-600 bg-blue-50 text-blue-700' : 'hover:bg-gray-100'}`}
                                onClick={() => setFormData({ ...formData, type_offre: 'location' })}
                            >
                                <Calendar className="h-6 w-6 mx-auto mb-2" />
                                <div className="font-semibold">Location</div>
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label>Nom du produit/service *</Label>
                            <Input
                                value={formData.nom}
                                onChange={e => setFormData({ ...formData, nom: e.target.value })}
                                placeholder="Ex: Maï, Tracteur, Semoir..."
                                required
                            />
                        </div>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label>Catégorie *</Label>
                                <Select
                                    value={formData.categorie}
                                    onValueChange={v => setFormData({ ...formData, categorie: v })}
                                >
                                    <SelectTrigger>
                                        <SelectValue placeholder="Sélectionner" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        {categories.map(c => (
                                            <SelectItem key={c.value} value={c.value}>{c.label}</SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>

                            <div className="space-y-2">
                                <Label>Quantité disponible *</Label>
                                <Input
                                    type="number"
                                    value={formData.quantite_disponible}
                                    onChange={e => setFormData({ ...formData, quantite_disponible: e.target.value })}
                                    placeholder="1"
                                    min="0"
                                    step="1"
                                    required
                                />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label>Description</Label>
                            <Textarea
                                value={formData.description}
                                onChange={e => setFormData({ ...formData, description: e.target.value })}
                                placeholder="Décrivez votre produit..."
                                className="h-24"
                            />
                        </div>

                        {/* Price Section - Conditional */}
                        {formData.type_offre === 'vente' ? (
                            <div className="grid grid-cols-2 gap-4">
                                <div className="space-y-2">
                                    <Label>Prix (FCFA) *</Label>
                                    <Input
                                        type="number"
                                        value={formData.prix}
                                        onChange={e => setFormData({ ...formData, prix: e.target.value })}
                                        placeholder="0"
                                        min="0"
                                    />
                                </div>
                                <div className="space-y-2">
                                    <Label>Unité *</Label>
                                    <Select
                                        value={formData.unite}
                                        onValueChange={v => setFormData({ ...formData, unite: v })}
                                    >
                                        <SelectTrigger>
                                            <SelectValue placeholder="Unité" />
                                        </SelectTrigger>
                                        <SelectContent>
                                            <SelectItem value="kg">Kg</SelectItem>
                                            <SelectItem value="tonne">Tonne</SelectItem>
                                            <SelectItem value="unite">Unité</SelectItem>
                                            <SelectItem value="sac">Sac</SelectItem>
                                            <SelectItem value="litre">Litre</SelectItem>
                                        </SelectContent>
                                    </Select>
                                </div>
                            </div>
                        ) : (
                            <div className="space-y-4 border-t pt-4">
                                <div className="flex items-center gap-2 text-blue-600 mb-2">
                                    <AlertCircle className="h-4 w-4" />
                                    <span className="font-semibold">Options de Location</span>
                                </div>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                    <div className="space-y-2">
                                        <Label>Prix par jour (FCFA) *</Label>
                                        <Input
                                            type="number"
                                            value={formData.prix_location_jour}
                                            onChange={e => setFormData({ ...formData, prix_location_jour: e.target.value })}
                                            placeholder="Ex: 5000"
                                            min="0"
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label>Caution (FCFA)</Label>
                                        <Input
                                            type="number"
                                            value={formData.caution}
                                            onChange={e => setFormData({ ...formData, caution: e.target.value })}
                                            placeholder="Ex: 50000"
                                            min="0"
                                        />
                                    </div>
                                    <div className="space-y-2">
                                        <Label>Durée min. (Jours)</Label>
                                        <Input
                                            type="number"
                                            value={formData.duree_min_location}
                                            onChange={e => setFormData({ ...formData, duree_min_location: e.target.value })}
                                            placeholder="1"
                                            min="1"
                                        />
                                    </div>
                                    <div className="space-y-2 hidden">
                                        {/* Hidden Unit for logic consistency */}
                                        <Input value="jour" readOnly />
                                    </div>
                                </div>
                            </div>
                        )}

                        <div className="space-y-2">
                            <Label>Localisation (Ville/Village)</Label>
                            <Input
                                value={formData.localisation}
                                onChange={e => setFormData({ ...formData, localisation: e.target.value })}
                                placeholder="Ex: Bouaké, Quartier Commerce"
                            />
                        </div>

                        <div className="pt-4">
                            <Button type="submit" className="w-full" disabled={loading}>
                                {loading ? <Loader2 className="h-4 w-4 mr-2 animate-spin" /> : null}
                                Publier l'annonce
                            </Button>
                        </div>

                    </form>
                </CardContent>
            </Card>
        </div>
    )
}

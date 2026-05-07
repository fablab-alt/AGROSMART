/**
 * Equipment Rental Controller
 * AgroSmart - Marketplace Location d'Équipements
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * Get all available equipment (optionally filtered by category)
 * GET /api/equipment
 */
exports.getEquipments = async (req, res, next) => {
    try {
        const { categorie, disponible } = req.query;

        const where = {};
        if (categorie) where.categorie = categorie;
        if (disponible !== undefined) where.disponible = disponible === 'true';

        const equipments = await prisma.equipementLocation.findMany({
            where,
            include: {
                proprietaire: {
                    select: { nom: true, telephone: true }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        // Compute stats manually or via separate queries to match legacy 'left join' behavior with counts/avgs.
        const equipmentsWithStats = await Promise.all(equipments.map(async (e) => {
            const stats = await prisma.location.aggregate({
                where: { equipementId: e.id, statut: 'terminee' },
                _count: { id: true },
                _avg: { evaluationNote: true }
            });

            return {
                ...e,
                proprietaire_nom: e.proprietaire?.nom,
                proprietaire_tel: e.proprietaire?.telephone,
                total_locations: stats._count.id,
                note_moyenne: stats._avg.evaluationNote || null
            };
        }));

        res.json({
            success: true,
            data: equipmentsWithStats
        });
    } catch (error) {
        logger.error('Error fetching equipment:', error);
        next(error);
    }
};

/**
 * Get single equipment details
 * GET /api/equipment/:id
 */
exports.getEquipmentById = async (req, res, next) => {
    try {
        const { id } = req.params;

        const equipment = await prisma.equipementLocation.findUnique({
            where: { id },
            include: {
                proprietaire: {
                    select: { nom: true, telephone: true, email: true }
                }
            }
        });

        if (!equipment) {
            return res.status(404).json({
                success: false,
                message: 'Équipement non trouvé'
            });
        }

        const stats = await prisma.location.aggregate({
            where: { equipementId: id, statut: 'terminee' },
            _count: { id: true },
            _avg: { evaluationNote: true }
        });

        // Get upcoming rentals
        const rentalsUpcoming = await prisma.location.findMany({
            where: {
                equipementId: id,
                statut: { in: ['confirmee', 'en_cours'] },
                dateFin: { gte: new Date() }
            },
            select: { dateDebut: true, dateFin: true, statut: true },
            orderBy: { dateDebut: 'asc' }
        });

        res.json({
            success: true,
            data: {
                ...equipment,
                proprietaire_nom: equipment.proprietaire.nom,
                proprietaire_tel: equipment.proprietaire.telephone,
                proprietaire_email: equipment.proprietaire.email,
                total_locations: stats._count.id,
                note_moyenne: stats._avg.evaluationNote,
                rentals_upcoming: rentalsUpcoming.map(r => ({
                    date_debut: r.dateDebut,
                    date_fin: r.dateFin,
                    statut: r.statut
                }))
            }
        });
    } catch (error) {
        logger.error('Error fetching equipment details:', error);
        next(error);
    }
};

/**
 * Create new equipment listing (for owners)
 * POST /api/equipment
 */
exports.createEquipment = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const {
            nom,
            categorie,
            description,
            prix_jour,
            caution,
            etat,
            localisation,
            latitude,
            longitude,
            images,
            specifications
        } = req.body;

        const equipment = await prisma.equipementLocation.create({
            data: {
                proprietaireId: userId,
                nom,
                categorie,
                description,
                prixJour: prix_jour,
                caution: caution || 0,
                etat: etat || 'bon',
                localisation,
                latitude,
                longitude,
                images: images || [],
                specifications: specifications || {}
            }
        });

        res.status(201).json({
            success: true,
            message: 'Équipement ajouté avec succès',
            data: equipment
        });
    } catch (error) {
        logger.error('Error creating equipment:', error);
        next(error);
    }
};

/**
 * Create rental request
 * POST /api/equipment/:id/rent
 */
exports.createRentalRequest = async (req, res, next) => {
    try {
        const { id: equipementId } = req.params;
        const userId = req.user.id;
        const { date_debut, date_fin } = req.body;

        // Verify equipment exists
        const equipment = await prisma.equipementLocation.findUnique({
            where: { id: equipementId }
        });

        if (!equipment) {
            return res.status(404).json({
                success: false,
                message: 'Équipement non trouvé'
            });
        }

        if (!equipment.disponible) {
            return res.status(400).json({
                success: false,
                message: 'Équipement non disponible'
            });
        }

        const start = new Date(date_debut);
        const end = new Date(date_fin);

        // Check for conflicts
        const conflict = await prisma.location.findFirst({
            where: {
                equipementId: equipementId,
                statut: { in: ['confirmee', 'en_cours'] },
                OR: [
                    { AND: [{ dateDebut: { lte: start } }, { dateFin: { gte: start } }] },
                    { AND: [{ dateDebut: { lte: end } }, { dateFin: { gte: end } }] },
                    { AND: [{ dateDebut: { gte: start } }, { dateFin: { lte: end } }] }
                ]
            }
        });

        if (conflict) {
            return res.status(400).json({
                success: false,
                message: 'Dates non disponibles. Équipement déjà loué pour cette période.'
            });
        }

        // Calculate duration and price
        const dureeJours = Math.ceil((end - start) / (1000 * 60 * 60 * 24));
        const prixTotal = dureeJours * parseFloat(equipment.prixJour);

        // Create rental request
        const rental = await prisma.location.create({
            data: {
                equipementId,
                locataireId: userId,
                dateDebut: start,
                dateFin: end,
                dureeJours,
                prixTotal,
                cautionVersee: equipment.caution,
                statut: 'demande'
            }
        });

        res.status(201).json({
            success: true,
            message: 'Demande de location créée. En attente de confirmation du propriétaire.',
            data: rental
        });
    } catch (error) {
        logger.error('Error creating rental request:', error);
        next(error);
    }
};

/**
 * Get user's rentals (as renter)
 * GET /api/rentals/my-rentals
 */
exports.getMyRentals = async (req, res, next) => {
    try {
        const userId = req.user.id;

        const rentals = await prisma.location.findMany({
            where: { locataireId: userId },
            include: {
                equipement: {
                    include: {
                        proprietaire: { select: { nom: true, telephone: true } }
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        const formatted = rentals.map(r => ({
            ...r,
            equipement_nom: r.equipement.nom,
            equipement_categorie: r.equipement.categorie,
            equipement_images: r.equipement.images,
            proprietaire_nom: r.equipement.proprietaire.nom,
            proprietaire_tel: r.equipement.proprietaire.telephone
        }));

        res.json({
            success: true,
            data: formatted
        });
    } catch (error) {
        logger.error('Error fetching user rentals:', error);
        next(error);
    }
};

/**
 * Get rental requests for owner's equipment
 * GET /api/rentals/requests
 */
exports.getRentalRequests = async (req, res, next) => {
    try {
        const userId = req.user.id;

        const requests = await prisma.location.findMany({
            where: {
                equipement: { proprietaireId: userId },
                statut: 'demande'
            },
            include: {
                equipement: true,
                locataire: { select: { nom: true, telephone: true, email: true } }
            },
            orderBy: { createdAt: 'desc' }
        });

        const formatted = requests.map(r => ({
            ...r,
            equipement_nom: r.equipement.nom,
            equipement_categorie: r.equipement.categorie,
            locataire_nom: r.locataire.nom,
            locataire_tel: r.locataire.telephone,
            locataire_email: r.locataire.email
        }));

        res.json({
            success: true,
            data: formatted
        });
    } catch (error) {
        logger.error('Error fetching rental requests:', error);
        next(error);
    }
};

/**
 * Update rental status (confirm, reject, complete)
 * PUT /api/rentals/:id/status
 */
exports.updateRentalStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;
        const { statut, commentaire } = req.body;

        const rental = await prisma.location.findUnique({
            where: { id },
            include: { equipement: true }
        });

        if (!rental) {
            return res.status(404).json({
                success: false,
                message: 'Location non trouvée'
            });
        }

        const isOwner = rental.equipement.proprietaireId === userId;
        const isRenter = rental.locataireId === userId;

        if (!isOwner && !isRenter) {
            return res.status(403).json({
                success: false,
                message: 'Non autorisé'
            });
        }

        const data = { statut };
        if (isOwner) data.commentaireProprio = commentaire;
        else data.commentaireLocataire = commentaire;

        const updatedRental = await prisma.location.update({
            where: { id },
            data
        });

        res.json({
            success: true,
            message: 'Statut mis à jour',
            data: updatedRental
        });
    } catch (error) {
        logger.error('Error updating rental status:', error);
        next(error);
    }
};

/**
 * Cancel rental
 * DELETE /api/rentals/:id
 */
exports.cancelRental = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const result = await prisma.location.updateMany({
            where: {
                id,
                locataireId: userId,
                statut: 'demande'
            },
            data: { statut: 'annulee' }
        });

        if (result.count === 0) {
            return res.status(404).json({
                success: false,
                message: 'Location non trouvée ou ne peut pas être annulée'
            });
        }

        res.json({
            success: true,
            message: 'Location annulée'
        });
    } catch (error) {
        logger.error('Error canceling rental:', error);
        next(error);
    }
};

module.exports = exports;

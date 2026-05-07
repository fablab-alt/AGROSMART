/**
 * Routes pour les avis produits
 * AgroSmart - Système Agricole Intelligent
 */

const express = require('express');
const router = express.Router();
const { authenticate } = require('../middlewares/auth');
const prisma = require('../config/prisma');
const logger = require('../utils/logger');

/**
 * @route   GET /api/v1/reviews/produits/:produitId
 * @desc    Récupérer les avis d'un produit
 * @access  Public
 */
router.get('/produits/:produitId', async (req, res) => {
  try {
    const { produitId } = req.params;

    const reviews = await prisma.avis.findMany({
      where: { produitId },
      include: {
        utilisateur: {
          select: {
            id: true,
            nom: true,
            prenoms: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const formattedReviews = reviews.map(review => ({
      id: review.id,
      produitId: review.produitId,
      utilisateurId: review.utilisateurId,
      utilisateurNom: `${review.utilisateur.prenoms} ${review.utilisateur.nom}`,
      note: review.note,
      commentaire: review.commentaire,
      images: review.images ? JSON.parse(review.images) : null,
      createdAt: review.createdAt,
    }));

    res.json({ success: true, data: formattedReviews });
  } catch (error) {
    logger.error('Erreur récupération avis:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des avis' });
  }
});

/**
 * @route   GET /api/v1/reviews/produits/:produitId/stats
 * @desc    Récupérer les statistiques d'avis d'un produit
 * @access  Public
 */
router.get('/produits/:produitId/stats', async (req, res) => {
  try {
    const { produitId } = req.params;

    const reviews = await prisma.avis.findMany({
      where: { produitId },
      select: { note: true },
    });

    if (reviews.length === 0) {
      return res.json({
        success: true,
        data: {
          moyenneNote: 0,
          nombreAvis: 0,
          repartitionNotes: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
        },
      });
    }

    const totalNotes = reviews.reduce((sum, r) => sum + r.note, 0);
    const moyenneNote = totalNotes / reviews.length;
    const repartitionNotes = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
    reviews.forEach(r => { repartitionNotes[r.note]++; });

    res.json({
      success: true,
      data: { moyenneNote, nombreAvis: reviews.length, repartitionNotes },
    });
  } catch (error) {
    logger.error('Erreur récupération stats avis:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la récupération des statistiques' });
  }
});

/**
 * @route   POST /api/v1/reviews
 * @desc    Créer un avis
 * @access  Private
 */
router.post('/', authenticate, async (req, res) => {
  try {
    const { produitId, note, commentaire, images } = req.body;
    const utilisateurId = req.user.id;

    if (!produitId) {
      return res.status(400).json({ success: false, message: 'produitId est requis' });
    }

    if (!note || note < 1 || note > 5) {
      return res.status(400).json({ success: false, message: 'La note doit être entre 1 et 5' });
    }

    const existingReview = await prisma.avis.findUnique({
      where: { produitId_utilisateurId: { produitId, utilisateurId } },
    });

    if (existingReview) {
      return res.status(409).json({
        success: false,
        message: 'Vous avez déjà donné un avis pour ce produit'
      });
    }

    const review = await prisma.avis.create({
      data: {
        produitId,
        utilisateurId,
        note,
        commentaire,
        images: images ? JSON.stringify(images) : null,
      },
      include: {
        utilisateur: {
          select: { id: true, nom: true, prenoms: true },
        },
      },
    });

    res.status(201).json({
      success: true,
      data: {
        id: review.id,
        produitId: review.produitId,
        utilisateurId: review.utilisateurId,
        utilisateurNom: `${review.utilisateur.prenoms} ${review.utilisateur.nom}`,
        note: review.note,
        commentaire: review.commentaire,
        images: review.images ? JSON.parse(review.images) : null,
        createdAt: review.createdAt,
      },
    });
  } catch (error) {
    logger.error('Erreur création avis:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la création de l\'avis' });
  }
});

/**
 * @route   PUT /api/v1/reviews/:id
 * @desc    Mettre à jour un avis
 * @access  Private
 */
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { note, commentaire } = req.body;
    const utilisateurId = req.user.id;

    if (note && (note < 1 || note > 5)) {
      return res.status(400).json({ success: false, message: 'La note doit être entre 1 et 5' });
    }

    const existingReview = await prisma.avis.findUnique({ where: { id } });

    if (!existingReview) {
      return res.status(404).json({ success: false, message: 'Avis non trouvé' });
    }

    if (existingReview.utilisateurId !== utilisateurId) {
      return res.status(403).json({ success: false, message: 'Non autorisé' });
    }

    const updatedReview = await prisma.avis.update({
      where: { id },
      data: {
        ...(note && { note }),
        ...(commentaire !== undefined && { commentaire }),
      },
      include: {
        utilisateur: {
          select: { id: true, nom: true, prenoms: true },
        },
      },
    });

    res.json({
      success: true,
      data: {
        id: updatedReview.id,
        produitId: updatedReview.produitId,
        utilisateurId: updatedReview.utilisateurId,
        utilisateurNom: `${updatedReview.utilisateur.prenoms} ${updatedReview.utilisateur.nom}`,
        note: updatedReview.note,
        commentaire: updatedReview.commentaire,
        images: updatedReview.images ? JSON.parse(updatedReview.images) : null,
        createdAt: updatedReview.createdAt,
      },
    });
  } catch (error) {
    logger.error('Erreur mise à jour avis:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour de l\'avis' });
  }
});

/**
 * @route   DELETE /api/v1/reviews/:id
 * @desc    Supprimer un avis
 * @access  Private
 */
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const utilisateurId = req.user.id;

    const existingReview = await prisma.avis.findUnique({ where: { id } });

    if (!existingReview) {
      return res.status(404).json({ success: false, message: 'Avis non trouvé' });
    }

    if (existingReview.utilisateurId !== utilisateurId) {
      return res.status(403).json({ success: false, message: 'Non autorisé' });
    }

    await prisma.avis.delete({ where: { id } });
    res.status(204).send();
  } catch (error) {
    logger.error('Erreur suppression avis:', { error: error.message });
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression de l\'avis' });
  }
});

module.exports = router;

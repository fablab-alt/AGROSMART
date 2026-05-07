/**
 * Diagnostics Controller
 * AgroSmart - Plant disease diagnostics
 */

const prisma = require('../config/prisma');
const logger = require('../utils/logger');
const { errors } = require('../middlewares/errorHandler');

/**
 * Analyze plant image for disease detection
 * TODO: Integrate with AI/ML model
 */
exports.analyzePlant = async (req, res, next) => {
    try {
        const { parcelle_id, crop_type } = req.body;
        let image_url = '';
        let image_path = '';

        if (req.file) {
            image_url = `/uploads/diagnostics/${req.file.filename}`;
            image_path = req.file.path;
        } else if (req.body.image_url) {
            // Handle case where URL is passed directly (less common for upload)
            image_url = req.body.image_url;
            // Would need to resolve local path if possible, or skip analysis
        }

        const userId = req.user.id;

        if (!image_path) {
            return res.status(400).json({ success: false, message: 'Image requise pour l\'analyse' });
        }

        // Call Python script for analysis
        const { spawn } = require('child_process');
        const pythonProcess = spawn('python3', ['src/scripts/analyze_plant.py', image_path, crop_type || 'default']);

        let dataString = '';
        let errorString = '';

        pythonProcess.stdout.on('data', (data) => {
            dataString += data.toString();
        });

        pythonProcess.stderr.on('data', (data) => {
            errorString += data.toString();
        });

        pythonProcess.on('close', async (code) => {
            if (code !== 0) {
                logger.error(`Python script exited with code ${code}: ${errorString}`);
                return next(errors.external('Analyse IA indisponible. Veuillez réessayer plus tard.'));
            }

            try {
                const analysisResult = JSON.parse(dataString);

                if (analysisResult.error) {
                    logger.error('Analysis Error:', analysisResult.error);
                    return next(errors.external('Le service d\'analyse IA a retourné une erreur.'));
                }

                await saveAndSendResponse(analysisResult);

            } catch (e) {
                logger.error('Error parsing Python output:', e, dataString);
                return next(errors.external('Réponse IA invalide. Veuillez réessayer plus tard.'));
            }
        });

        async function saveAndSendResponse(diagnosticData) {
            try {
                // Save diagnostic to database
                const diagnostic = await prisma.diagnostic.create({
                    data: {
                        userId,
                        parcelleId: parcelle_id || null,
                        diseaseName: diagnosticData.disease_name,
                        cropType: crop_type,
                        confidenceScore: parseFloat(diagnosticData.confidence_score),
                        severity: diagnosticData.severity,
                        imageUrl: image_url,
                        recommendations: diagnosticData.recommendations,
                        treatmentSuggestions: diagnosticData.treatment_suggestions
                    }
                });

                res.json({
                    success: true,
                    data: diagnostic
                });
            } catch (dbError) {
                next(dbError);
            }
        }

    } catch (error) {
        logger.error('Error analyzing plant:', error.message);
        next(error);
    }
};

/**
 * Get diagnostic history for user
 */
exports.getHistory = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const skip = (page - 1) * limit;

        const [diagnostics, total] = await Promise.all([
            prisma.diagnostic.findMany({
                where: { userId },
                include: {
                    parcelle: { select: { nom: true } }
                },
                orderBy: { createdAt: 'desc' },
                take: limit,
                skip
            }),
            prisma.diagnostic.count({ where: { userId } })
        ]);

        const data = diagnostics.map(d => ({
            ...d,
            parcelle_nom: d.parcelle ? d.parcelle.nom : null,
            parcelle: undefined
        }));

        res.json({
            success: true,
            data: data,
            total,
            limit,
            offset: skip // Keeping 'offset' key for backward compatibility if frontend expects it
        });
    } catch (error) {
        logger.error('Error fetching diagnostic history:', error.message);
        next(error);
    }
};

/**
 * Get diagnostic by ID
 */
exports.getDiagnosticById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.id;

        const diagnostic = await prisma.diagnostic.findFirst({
            where: { id, userId }, // Ensure user owns it
            include: {
                parcelle: { select: { nom: true } }
            }
        });

        if (!diagnostic) {
            return res.status(404).json({
                success: false,
                message: 'Diagnostic non trouvé'
            });
        }

        const data = {
            ...diagnostic,
            parcelle_nom: diagnostic.parcelle ? diagnostic.parcelle.nom : null,
            parcelle: undefined
        };

        res.json({
            success: true,
            data
        });
    } catch (error) {
        next(error);
    }
};

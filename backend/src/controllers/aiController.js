/**
 * Contrôleur pour les fonctionnalités IA
 */
const predictionService = require('../services/predictionService');
const logger = require('../utils/logger');

exports.getPestHeatmap = async (req, res) => {
    try {
        const { regionId } = req.query;
        const data = await predictionService.getPestHeatmapData(regionId);
        res.json({
            success: true,
            data: data
        });
    } catch (error) {
        logger.error('Erreur controller pest heatmap', error);
        res.status(500).json({ success: false, message: "Erreur serveur" });
    }
};

exports.predictYield = async (req, res) => {
    try {
        const { parcelleId } = req.params;
        const result = await predictionService.predictYield(parcelleId);
        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

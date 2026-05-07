/**
 * Utilitaire de formatage et normalisation des numéros de téléphone
 * AgroSmart CI - Côte d'Ivoire
 */

/**
 * Normalise un numéro de téléphone ivoirien au format international
 * Accepte les formats suivants:
 * - 0701000001 → +2250701000001
 * - 0701000001 → +2250701000001
 * - 225 0701000001 → +2250701000001
 * - +225 0701000001 → +2250701000001
 * - +2250701000001 → +2250701000001 (déjà normalisé)
 * 
 * @param {string} phone - Numéro de téléphone à normaliser
 * @returns {string} Numéro normalisé au format +2250XXXXXXXXX
 */
function normalizePhoneNumber(phone) {
  if (!phone) return phone;

  // Enlever tous les espaces, tirets et parenthèses
  let cleaned = phone.replace(/[\s()-]/g, '');

  // Si le numéro commence par +225, on le retourne tel quel
  if (cleaned.startsWith('+225')) {
    return cleaned;
  }

  // Si le numéro commence par 225 (sans +)
  if (cleaned.startsWith('225')) {
    return '+' + cleaned;
  }

  // Si le numéro commence par 0 (format local ivoirien)
  if (cleaned.startsWith('0')) {
    return '+225' + cleaned;
  }

  // Si le numéro ne commence par rien de reconnu, supposer format local
  // et ajouter +225 et 0
  if (cleaned.length === 9) {
    return '+2250' + cleaned;
  }

  // Si le numéro a 10 chiffres et ne commence pas par 0, ajouter +225
  if (cleaned.length === 10 && !cleaned.startsWith('0')) {
    return '+225' + cleaned;
  }

  // Retourner le numéro nettoyé avec +225 par défaut
  return '+225' + cleaned;
}

/**
 * Vérifie si un numéro de téléphone est valide pour la Côte d'Ivoire
 * Format attendu: +2250XXXXXXXXX (13 caractères)
 * Préfixes valides: 01, 05, 07 (opérateurs ivoiriens)
 * 
 * @param {string} phone - Numéro de téléphone à valider
 * @returns {boolean} true si valide, false sinon
 */
function isValidIvoryCoastPhone(phone) {
  if (!phone) return false;

  const normalized = normalizePhoneNumber(phone);
  
  // Format: +2250XXXXXXXXX (13 caractères)
  if (!normalized.startsWith('+225') || normalized.length !== 13) {
    return false;
  }

  // Extraire le préfixe de l'opérateur (après +2250)
  const operatorPrefix = normalized.substring(5, 7);
  
  // Préfixes valides en Côte d'Ivoire:
  // 01 - Orange
  // 05 - MTN
  // 07 - Moov
  const validPrefixes = ['01', '05', '07'];
  
  return validPrefixes.includes(operatorPrefix);
}

/**
 * Format un numéro pour l'affichage
 * +2250701000001 → +225 07 01 00 00 01
 * 
 * @param {string} phone - Numéro de téléphone
 * @returns {string} Numéro formaté pour affichage
 */
function formatPhoneForDisplay(phone) {
  if (!phone) return '';

  const normalized = normalizePhoneNumber(phone);
  
  if (normalized.length === 13 && normalized.startsWith('+225')) {
    // +225 07 01 00 00 01
    return `${normalized.substring(0, 4)} ${normalized.substring(4, 6)} ${normalized.substring(6, 8)} ${normalized.substring(8, 10)} ${normalized.substring(10, 12)} ${normalized.substring(12)}`;
  }

  return normalized;
}

/**
 * Génère des variantes de numéro pour la recherche
 * Permet de chercher un utilisateur avec différents formats
 * 
 * @param {string} phone - Numéro de téléphone
 * @returns {Array<string>} Liste des variantes possibles
 */
function getPhoneVariants(phone) {
  if (!phone) return [];

  const normalized = normalizePhoneNumber(phone);
  const variants = [normalized];

  // Ajouter variantes sans +
  if (normalized.startsWith('+225')) {
    variants.push(normalized.substring(1)); // 2250701000001
    variants.push(normalized.substring(4)); // 0701000001
  }

  // Format avec espaces
  variants.push(normalized.replace(/[\s-]/g, ''));

  // Retourner uniquement les variantes uniques
  return [...new Set(variants)];
}

module.exports = {
  normalizePhoneNumber,
  isValidIvoryCoastPhone,
  formatPhoneForDisplay,
  getPhoneVariants
};

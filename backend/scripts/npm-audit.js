#!/usr/bin/env node

/**
 * Script d'Audit de Sécurité des Dépendances npm
 * AgriSmart CI - Conformité OWASP A06
 * 
 * Ce script effectue un audit automatique des vulnérabilités connues
 * dans les dépendances npm du projet.
 * 
 * Usage:
 *   node scripts/npm-audit.js
 *   npm run audit:security
 * 
 * Exit codes:
 *   0 - Aucune vulnérabilité ou seulement low
 *   1 - Vulnérabilités moderate/high/critical trouvées
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// Configuration
const AUDIT_LEVEL = process.env.AUDIT_LEVEL || 'moderate'; // low, moderate, high, critical
const OUTPUT_DIR = path.join(__dirname, '../audit-reports');
const TIMESTAMP = new Date().toISOString().replace(/:/g, '-').split('.')[0];
const REPORT_FILE = path.join(OUTPUT_DIR, `npm-audit-${TIMESTAMP}.json`);

// Couleurs pour le terminal
const colors = {
    reset: '\x1b[0m',
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    cyan: '\x1b[36m'
};

/**
 * Logger avec couleurs
 */
const log = {
    info: (msg) => console.log(`${colors.blue}ℹ ${msg}${colors.reset}`),
    success: (msg) => console.log(`${colors.green}✓ ${msg}${colors.reset}`),
    warning: (msg) => console.log(`${colors.yellow}⚠ ${msg}${colors.reset}`),
    error: (msg) => console.log(`${colors.red}✗ ${msg}${colors.reset}`),
    title: (msg) => console.log(`\n${colors.cyan}${'='.repeat(50)}\n${msg}\n${'='.repeat(50)}${colors.reset}\n`)
};

/**
 * Créer le répertoire de rapports s'il n'existe pas
 */
function ensureOutputDir() {
    if (!fs.existsSync(OUTPUT_DIR)) {
        fs.mkdirSync(OUTPUT_DIR, { recursive: true });
        log.info(`Répertoire créé: ${OUTPUT_DIR}`);
    }
}

/**
 * Exécuter npm audit et retourner les résultats
 */
function runNpmAudit() {
    try {
        log.info('Exécution de npm audit...');

        const output = execSync('npm audit --json', {
            encoding: 'utf-8',
            stdio: ['pipe', 'pipe', 'pipe']
        });

        return JSON.parse(output);
    } catch (error) {
        // npm audit retourne un exit code non-zero si des vulnérabilités sont trouvées
        if (error.stdout) {
            try {
                return JSON.parse(error.stdout);
            } catch (parseError) {
                log.error('Erreur lors du parsing du résultat npm audit');
                console.error(parseError);
                process.exit(1);
            }
        }

        log.error('Erreur lors de l\'exécution de npm audit');
        console.error(error);
        process.exit(1);
    }
}

/**
 * Analyser les résultats de l'audit
 */
function analyzeResults(auditData) {
    const vulnerabilities = auditData.metadata?.vulnerabilities || {
        info: 0,
        low: 0,
        moderate: 0,
        high: 0,
        critical: 0
    };

    const totalVulnerabilities = Object.values(vulnerabilities).reduce((a, b) => a + b, 0);

    return {
        vulnerabilities,
        totalVulnerabilities,
        totalDependencies: auditData.metadata?.dependencies || 0,
        auditReportVersion: auditData.auditReportVersion || 'unknown'
    };
}

/**
 * Afficher le résumé des vulnérabilités
 */
function displaySummary(analysis) {
    const { vulnerabilities, totalVulnerabilities, totalDependencies } = analysis;

    log.title('Résumé de l\'Audit de Sécurité npm');

    console.log(`Total dépendances: ${totalDependencies}`);
    console.log(`Total vulnérabilités: ${totalVulnerabilities}\n`);

    console.log('Détail par sévérité:');
    if (vulnerabilities.critical > 0) {
        log.error(`  Critical: ${vulnerabilities.critical}`);
    }
    if (vulnerabilities.high > 0) {
        log.error(`  High: ${vulnerabilities.high}`);
    }
    if (vulnerabilities.moderate > 0) {
        log.warning(`  Moderate: ${vulnerabilities.moderate}`);
    }
    if (vulnerabilities.low > 0) {
        log.warning(`  Low: ${vulnerabilities.low}`);
    }
    if (vulnerabilities.info > 0) {
        log.info(`  Info: ${vulnerabilities.info}`);
    }

    console.log('');
}

/**
 * Sauvegarder le rapport complet
 */
function saveReport(auditData, analysis) {
    const report = {
        timestamp: new Date().toISOString(),
        summary: analysis,
        fullAudit: auditData
    };

    fs.writeFileSync(REPORT_FILE, JSON.stringify(report, null, 2));
    log.success(`Rapport sauvegardé: ${REPORT_FILE}`);
}

/**
 * Déterminer si l'audit a échoué selon le niveau configuré
 */
function shouldFail(vulnerabilities) {
    const levels = {
        'low': ['critical', 'high', 'moderate', 'low'],
        'moderate': ['critical', 'high', 'moderate'],
        'high': ['critical', 'high'],
        'critical': ['critical']
    };

    const relevantLevels = levels[AUDIT_LEVEL] || levels['moderate'];

    for (const level of relevantLevels) {
        if (vulnerabilities[level] > 0) {
            return true;
        }
    }

    return false;
}

/**
 * Afficher les recommandations
 */
function displayRecommendations(vulnerabilities) {
    if (vulnerabilities.critical > 0 || vulnerabilities.high > 0) {
        log.title('🚨 ACTIONS IMMÉDIATES REQUISES');
        console.log('1. Exécutez: npm audit fix');
        console.log('2. Si échec automatique: npm audit fix --force (ATTENTION: peut causer des breaking changes)');
        console.log('3. Consultez le rapport détaillé et mettez à jour manuellement les dépendances problématiques');
        console.log('4. Vérifiez les changelogs des dépendances avant mise à jour');
    } else if (vulnerabilities.moderate > 0) {
        log.title('⚠️ ACTIONS RECOMMANDÉES');
        console.log('1. Plannifiez une mise à jour des dépendances dans les prochains jours');
        console.log('2. Exécutez: npm audit fix');
        console.log('3. Testez l\'application après les mises à jour');
    } else if (vulnerabilities.low > 0) {
        log.title('ℹ️ MAINTENANCE SUGGÉRÉE');
        console.log('1. Planifiez une revue des dépendances lors de la prochaine itération');
        console.log('2. Considérez: npm audit fix');
    } else {
        log.title('✅ AUCUNE ACTION REQUISE');
        console.log('Toutes les dépendances sont à jour et sécurisées!');
    }
}

/**
 * Main
 */
function main() {
    log.title('AgriSmart CI - Audit de Sécurité npm');

    log.info(`Niveau d'audit: ${AUDIT_LEVEL.toUpperCase()}`);
    log.info(`Date: ${new Date().toLocaleString()}`);

    // Créer le répertoire de sortie
    ensureOutputDir();

    // Exécuter l'audit
    const auditData = runNpmAudit();

    // Analyser les résultats
    const analysis = analyzeResults(auditData);

    // Afficher le résumé
    displaySummary(analysis);

    // Sauvegarder le rapport
    saveReport(auditData, analysis);

    // Afficher les recommandations
    displayRecommendations(analysis.vulnerabilities);

    // Déterminer le statut de sortie
    if (shouldFail(analysis.vulnerabilities)) {
        log.error(`\nÉCHEC: Vulnérabilités ${AUDIT_LEVEL}+ détectées`);
        process.exit(1);
    } else {
        log.success('\nSUCCÈS: Aucune vulnérabilité significative détectée');
        process.exit(0);
    }
}

// Exécuter le script
if (require.main === module) {
    main();
}

module.exports = { runNpmAudit, analyzeResults };

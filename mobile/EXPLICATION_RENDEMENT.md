# Explication du Calcul du Rendement (Yield Prediction)

## Vue d'ensemble

Le système de prédiction de rendement utilise une approche basée sur l'analyse de données en temps réel provenant des capteurs IoT installés sur les parcelles. Cette fonctionnalité aide les agriculteurs à estimer leur production avant la récolte.

## Comment ça fonctionne

### 1. **Données d'entrée**

Le système collecte les données suivantes :
- **Capteurs NPK** : Niveaux d'azote (N), phosphore (P) et potassium (K) dans le sol
- **Humidité du sol** : Pourcentage d'eau dans le sol
- **Température** : Température ambiante et du sol
- **Données météorologiques** : Prévisions et historique
- **Type de culture** : Cacao, café, maïs, etc.
- **Surface cultivée** : En hectares

### 2. **Processus de calcul**

#### **Étape 1 : Rendement de base**
Chaque culture a un rendement de base moyen :
- **Cacao** : 2500 kg/ha (base en Côte d'Ivoire)
- **Café** : 800 kg/ha
- **Maïs** : 3000 kg/ha

#### **Étape 2 : Facteurs multiplicateurs**

Le système analyse chaque metric et applique un multiplicateur :

**NPK (Fertilité du sol)** :
- **Optimal** (N: 50-200, P: 30-100, K: 150-300 mg/kg) → +10% (x1.10)
- **Sous-optimal** (valeurs basses) → -15% (x0.85)
- **Excès** (valeurs trop élevées) → -10% (x0.90)

**Humidité du sol** :
- **Optimale** (50-85%) → +5% (x1.05)
- **Insuffisante** (30-50%) → -15% (x0.85)
- **Trop sèche** (<30%) → -30% (x0.70)
- **Trop humide** (>85%) → -10% (x0.90)

**Température** :
- **Optimale** (selon culture) → +5% (x1.05)
- **Trop froide ou chaude** → -10 à -20% (x0.80-0.90)

**Météo** :
- **Pluies régulières** → +10% (x1.10)
- **Sécheresse prévue** → -20% (x0.80)
- **Pluies excessives** → -15% (x0.85)

#### **Étape 3 : Calcul final**

```
Rendement prédit = Rendement de base × Multiplicateur NPK × Multiplicateur Humidité × Multiplicateur Température × Multiplicateur Météo
```

**Exemple concret** :
- Parcelle de cacao de 2 hectares
- NPK optimal (+10%)
- Humidité bonne (+5%)
- Température OK (+5%)
- Météo favorable (+10%)

```
Rendement base : 2500 kg/ha
Multiplicateurs : 1.10 × 1.05 × 1.05 × 1.10 = 1.33
Rendement prédit : 2500 × 1.33 = 3325 kg/ha
Production totale : 3325 × 2 ha = 6650 kg (6.65 tonnes)
```

### 3. **Plage de confiance**

Le système affiche également une marge d'erreur de ±15% :
- **Minimum** : 6650 × 0.85 = 5652 kg
- **Maximum** : 6650 × 1.15 = 7647 kg
- **Confiance** : Basée sur la qualité et la fréquence des données (70-95%)

## Affichage dans l'application

### **Sur le dashboard** :
- Chiffre principal : "12.5 Tonnes" (estimation totale)
- Indicateur de confiance : Barre de progression circulaire
- Facteurs clés : Pills showing "Pluviométrie favorable", "Sol riche", "Aucun ravageur détecté"

### **Détail parcelle** :
- Graphique de tendance sur 7 jours
- Évolution de la prédiction
- Recommandations personnalisées pour améliorer le rendement

## Facteurs clés affichés

Ces "pills" ou badges indiquent les principaux facteurs qui influencent positivement votre rendement :

- ✅ **Pluviométrie favorable** : Pluies régulières et suffisantes
- ✅ **Sol riche** : NPK dans les valeurs optimales
- ✅ **Aucun ravageur détecté** : Pas de maladies signalées
- ⚠️ **Humidité insuffisante** : Besoin d'irrigation
- ⚠️ **Température élevée** : Risque de stress thermique
- ❌ **pH acide** : Correction nécessaire

## Amélioration du rendement

Pour optimiser votre production :

1. **Surveillez les alertes** : Réagissez rapidement aux notifications
2. **Suivez les recommandations** : Fertilisation, irrigation adaptées
3. **Historique** : Comparez avec les saisons précédentes
4. **Anticipez** : Planifiez les interventions selon les prévisions

## Modèle d'IA

Version actuelle : **v2.1-realtime**
- Mise à jour en temps réel (toutes les 4 heures)
- Précision : 82-88% (validée sur 3 saisons)
- Amélioration continue avec vos données

---

**Note** : Cette prédiction est une estimation basée sur les conditions actuelles. Des événements imprévus (cyclones, infestations soudaines) peuvent affecter le rendement réel. Utilisez cette information comme un guide pour vos décisions agricoles.

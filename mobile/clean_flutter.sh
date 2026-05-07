#!/bin/bash

# Script de nettoyage Flutter pour éviter les problèmes de build
# À exécuter si vous rencontrez des erreurs de build après un redémarrage

echo "🧹 Nettoyage du projet Flutter..."

# 1. Vérifier Java 17
echo "☕ Vérification de Java 17..."
if ! /usr/libexec/java_home -v 17 &>/dev/null; then
    echo "⚠️  Java 17 non trouvé. Installation..."
    brew install --cask temurin@17
else
    echo "✅ Java 17 trouvé"
fi

# 2. Vérifier gradle.properties
echo "📝 Configuration Gradle..."
JAVA17_PATH="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
if ! grep -q "org.gradle.java.home" android/gradle.properties; then
    echo "org.gradle.java.home=$JAVA17_PATH" >> android/gradle.properties
    echo "✅ Java 17 configuré dans gradle.properties"
fi

# 3. Supprimer les fichiers avec espaces (duplicatas macOS)
echo "📁 Suppression des fichiers avec espaces..."
find . -name "* *" -type f -not -path "*/build/*" -not -path "*/.dart_tool/*" -not -path "*/.gradle/*" -exec rm -f {} \;

# 4. Flutter clean
echo "🔧 Flutter clean..."
flutter clean

# 5. Nettoyer les caches Android
echo "🤖 Nettoyage des caches Android..."
rm -rf android/.gradle android/build

# 6. Récupérer les dépendances
echo "📦 Récupération des dépendances..."
flutter pub get

echo "✅ Nettoyage terminé ! Vous pouvez maintenant lancer 'flutter run'"

# Troubleshooting Guide - Application Mobile

## Problème : Build Android échoue après redémarrage

### Symptômes
- Erreur `Failed file name validation for file .../ic_launcher 2.png`
- Erreur `Cannot find a Java installation on your machine matching this tasks requirements: {languageVersion=17}`
- Build qui fonctionnait avant redémarrage

### Causes
1. **Fichiers dupliqués avec espaces** : macOS crée parfois des duplicatas de fichiers avec des espaces (ex: `ic_launcher 2.png`)
2. **Java 17 manquant ou mal configuré** : Gradle nécessite Java 17 spécifiquement
3. **Cache Gradle corrompu** : Peut contenir des références à des fichiers avec espaces

### Solution automatique

Exécutez le script de nettoyage :
```bash
cd mobile
./clean_flutter.sh
```

### Solution manuelle

Si le script ne fonctionne pas, suivez ces étapes :

1. **Vérifier et installer Java 17** :
```bash
# Vérifier les versions Java installées
/usr/libexec/java_home -V

# Installer Java 17 si absent
brew install --cask temurin@17
```

2. **Configurer Gradle pour Java 17** :
Ajoutez dans `android/gradle.properties` :
```properties
org.gradle.java.home=/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home
```

3. **Nettoyer les fichiers avec espaces** :
```bash
cd mobile
find . -name "* *" -type f -not -path "*/build/*" -not -path "*/.dart_tool/*" -not -path "*/.gradle/*" -exec rm -f {} \;
```

4. **Nettoyer complètement le projet** :
```bash
flutter clean
rm -rf android/.gradle android/build
flutter pub get
```

5. **Relancer le build** :
```bash
flutter run
```

## Prévention

### Pour éviter ce problème à l'avenir :

1. **Ne jamais supprimer le cache Gradle global** (`~/.gradle`) sauf en cas de corruption
2. **Exécuter le script de nettoyage** après chaque redémarrage d'ordinateur
3. **Vérifier Java 17** reste configuré dans `gradle.properties`

### Vérifications rapides

**Java installé ?**
```bash
/usr/libexec/java_home -V
# Doit afficher Java 17.x
```

**Gradle configuré ?**
```bash
grep "org.gradle.java.home" android/gradle.properties
# Doit afficher le chemin vers Java 17
```

## Autres erreurs courantes

### Erreur de traductions manquantes
Messages `"bci": 40 untranslated message(s)` sont des **avertissements**, pas des erreurs. L'app fonctionne normalement.

### Gradle daemon timeout
Si le build est très lent :
```bash
cd android
./gradlew --stop
cd ..
flutter run
```

### Emulator ne démarre pas
```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

## Support

En cas de problème persistant :
1. Exécuter `./clean_flutter.sh`
2. Vérifier que Java 17 est installé
3. Supprimer `~/.gradle` en dernier recours
4. Redémarrer Android Studio/VS Code

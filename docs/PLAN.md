# AF Players — Plan d'implémentation Android-first

**Approche** : Flutter + modules Kotlin natifs (Approche 2)
**Périmètre** : Android uniquement. iOS sera ajouté dans une phase ultérieure.
**Interface** : Style MX Player Pro (immersif, gestes, panneaux audio/sous-titres)

---

## Objectif

Application mobile publique permettant à des apprenants francophones de regarder des formations anglaises avec une voix française synthétique lisant les sous-titres, et des contrôles audio indépendants pour l'anglais et le français.

## Architecture

```
Flutter (Dart)
  UI, navigation, modèles, parseur SRT/VTT
  Coordinateur de synchronisation
  |
  +-- PlayerBridge (MethodChannel)
  +-- SpeechBridge (MethodChannel)
  +-- AudioMixerBridge (MethodChannel)
  |
Kotlin natif (Android)
  Media3/ExoPlayer | TextToSpeech | AudioFocus
```

## Interface — Style MX Player Pro

- Plein écran immersif, barres système masquées pendant la lecture
- Geste vertical gauche : luminosité
- Geste vertical droit : volume audio anglais
- Double appui gauche/droit : recul/avance 10 secondes
- Appui simple : afficher/masquer les contrôles
- Verrouillage tactile
- Panneau audio avec deux sliders (EN volume + FR volume) et boutons muet
- Panneau sous-titres (taille, couleur, position)
- Sélecteur de vitesse TTS en overlay

---

## Étapes d'implémentation

### Étape 1 — Initialisation Flutter Android-only et conventions
- Nettoyer le projet pour Android uniquement
- Configurer les Platform Channels pour les bridges Kotlin
- Validation : flutter analyze, flutter build apk --debug

### Étape 2 — Modèle de sous-titres et analyse SRT/VTT
- Existant : SubtitleEntry, SubtitleFile, SubtitleParser, extensions
- Vérifier les tests unitaires et ajouter cas limites
- Validation : flutter test

### Étape 3 — Import local et bibliothèque
- Existant : VideoItem (Hive), VideoStorageService, FilePickerService, écrans
- Ajouter import depuis la galerie
- Validation : import, bibliothèque, réouverture après redémarrage

### Étape 4 — Lecture vidéo Android via Media3/ExoPlayer
- Créer PlayerBridge.kt : ExoPlayer via MethodChannel
- Créer NativePlayerController.dart : wrapper Flutter
- Exposer : open, play, pause, seek, position stream, duration, volume, erreurs
- Validation : lecture d'un fichier local sur appareil Android

### Étape 5 — Synchronisation des sous-titres
- Existant : SubtitleController, SubtitleOverlay
- Connecter au NativePlayerController (position stream)
- Validation : sous-titres synchronisés avec la vidéo

### Étape 6 — Synthèse vocale française Android
- Créer SpeechBridge.kt : Android TextToSpeech via MethodChannel
- Créer NativeTtsController.dart : wrapper Flutter
- Exposer : speak, stop, setSpeechRate, setPitch, setVolume, getVoices, onComplete
- Validation : phrase française prononcée par l'appareil

### Étape 7 — Mixage audio, volumes et sourdine
- Créer AudioMixerBridge.kt : AudioFocus, gestion des interruptions
- Deux volumes indépendants : ExoPlayer.setVolume() + TextToSpeech volume
- Boutons muet séparés pour EN et FR
- Gestion casque, appels entrants, focus audio
- Validation : EN à 20% + FR à 100% simultanément

### Étape 8 — Coordinateur de lecture et synchronisation complète
- Existant : SyncController (à adapter)
- Mode voix complète : pause vidéo si TTS dépasse le cue
- Gestion seek, pause, fin de vidéo
- Validation : lecture complète sans coupure anormale

### Étape 9 — Interface MX Player Pro, thèmes et accessibilité
- Gestes : luminosité (gauche), volume (droite), double-tap seek, verrouillage
- Panneau audio overlay (deux sliders + muet)
- Panneau sous-titres (taille, couleur)
- Thème sombre ET clair
- Accessibilité : contraste, grandes polices
- Validation : parcours manuel complet

### Étape 10 — Historique, reprise, erreurs et performance
- Position de reprise (lastPosition)
- Gros fichiers sans ralentissement
- Fichiers corrompus, sous-titres manquants
- Mémoire sur appareils modestes
- Validation : reprise après fermeture, vidéo volumineuse

### Étape 11 — Validation Android et livraison
- Permissions minimales dans AndroidManifest
- APK de test, AAB signé si nécessaire
- Suite finale de tests
- Documentation des limites
- Validation : installation sur appareil physique, hors connexion

---

## Fichiers existants réutilisés

- lib/data/models/subtitle_entry.dart — conservé
- lib/data/models/subtitle_file.dart — conservé
- lib/data/models/video_item.dart — conservé
- lib/data/models/tts_settings.dart — conservé
- lib/data/services/subtitle_parser.dart — conservé
- lib/data/services/video_storage_service.dart — conservé
- lib/data/services/file_picker_service.dart — conservé
- lib/core/ (utils, constants, theme) — conservé
- lib/presentation/library/ — conservé
- lib/presentation/add_video/ — conservé
- lib/presentation/settings/ — modifié

## Fichiers à créer

- android/.../PlayerBridge.kt — ExoPlayer via MethodChannel
- android/.../SpeechBridge.kt — TextToSpeech via MethodChannel
- android/.../AudioMixerBridge.kt — AudioFocus et interruptions
- lib/controllers/native_player_controller.dart — wrapper Flutter
- lib/controllers/native_tts_controller.dart — wrapper Flutter
- lib/presentation/player/ — refonte style MX Player Pro

## Fichiers à remplacer

- lib/data/services/tts_service.dart — remplacé par SpeechBridge
- lib/controllers/player_controller.dart — remplacé par NativePlayerController
- lib/controllers/tts_controller.dart — remplacé par NativeTtsController

## Risques

- Voix française absente sur certains appareils Android
- Contrôle séparé des volumes selon versions Android
- Dépassement de durée d'un sous-titre par la synthèse vocale
- Performance sur appareils modestes avec grandes vidéos

## Critères de succès

- Import vidéo + SRT/VTT fonctionnel
- Lecture Android fluide via ExoPlayer
- Sous-titres français synchronisés
- Voix française audible et contrôlable indépendamment
- Audio anglais réglable ou muet indépendamment
- Gestes MX Player Pro fonctionnels
- Fonctionnement hors connexion après import
- Interface sombre/clair, moderne, accessible
- Aucun développement iOS dans cette phase

# AF Players

Lecteur video mobile Flutter avec synthese vocale francaise (TTS) a partir des sous-titres. Concu pour les francophones qui apprennent l'anglais via des formations video.

## Fonctionnalites

- **Lecteur video natif** — ExoPlayer via MethodChannel, supporte MP4, MKV, AVI, WebM, MOV, FLV, 3GP
- **Synthese vocale francaise** — lit les sous-titres en francais via Android TextToSpeech
- **3 modes de synchronisation TTS** :
  - **File d'attente** — la voix termine chaque phrase, enchaine la suivante, la video continue
  - **File + pause auto** — pause la video si la voix est en retard, reprend automatiquement
  - **File + vitesse auto** — accelere la voix si elle est en retard, revient a la normale
- **Explorateur de fichiers** — navigation dossier par dossier, style MX Player Pro
- **Selection de sous-titres** — detection automatique des .srt/.vtt dans le meme dossier
- **Deux volumes independants** — anglais (video) et francais (voix) reglables separement
- **Interface MX Player Pro** — gestes tactiles, mode immersif, verrouillage ecran, auto-hide
- **Sous-titres SRT/VTT** — parsing avec recherche binaire, affichage synchronise
- **Parametres complets** — voix, vitesse, tonalite, taille sous-titres, theme sombre/clair

## Architecture

```
Flutter (Dart)          <-->  MethodChannel  <-->  Kotlin (Android natif)
                                                    |-- PlayerBridge (ExoPlayer/Media3)
                                                    |-- SpeechBridge (Android TTS)
                                                    |-- AudioMixerBridge (AudioFocus)
```

### Structure du projet

```
lib/
  main.dart                              # Point d'entree
  app.dart                               # GetMaterialApp, DI controllers

  controllers/
    explorer_controller.dart             # Navigation fichiers
    native_player_controller.dart        # Wrapper ExoPlayer via MethodChannel
    native_tts_controller.dart           # Wrapper TTS via MethodChannel
    sync_controller.dart                 # Synchronisation video/TTS (3 modes)
    subtitle_controller.dart             # Chargement et suivi sous-titres
    settings_controller.dart             # Parametres persistants
    library_controller.dart              # Bibliotheque de videos (Hive)
    audio_mixer_controller.dart          # AudioFocus Android

  data/
    models/
      video_item.dart                    # Metadonnees video (Hive)
      subtitle_entry.dart                # Un cue : start, end, text
      subtitle_file.dart                 # Liste triee + recherche binaire
      tts_settings.dart                  # Langue, vitesse, pitch, voix
    services/
      subtitle_parser.dart               # Parsing SRT + VTT
      video_storage_service.dart         # CRUD Hive
      file_picker_service.dart           # Abstraction file_picker

  presentation/
    explorer/
      explorer_screen.dart               # Explorateur de fichiers (accueil)
    player/
      player_screen.dart                 # Lecteur video immersif
      widgets/
        player_controls.dart             # Barre de controles
        subtitle_overlay.dart            # Sous-titres sur la video
        dual_volume_bar.dart             # 2 sliders volume
        tts_speed_selector.dart          # Selecteur vitesse voix
        gesture_overlay.dart             # Gestes MX Player Pro
        lock_overlay.dart                # Verrouillage ecran
        seek_indicator.dart              # Indicateur de seek
        tts_indicator.dart               # Indicateur TTS actif
    settings/
      settings_screen.dart               # Ecran parametres
    library/
      library_screen.dart                # Ancienne bibliotheque

  core/
    constants/
      app_colors.dart                    # Palette de couleurs
      app_constants.dart                 # Constantes globales
    theme/
      app_theme.dart                     # Themes sombre et clair
    utils/
      duration_extensions.dart           # Parse timestamps SRT/VTT
      string_extensions.dart             # Strip HTML tags

android/app/src/main/kotlin/com/afplayers/af_players/
  MainActivity.kt                        # Enregistrement des bridges
  PlayerBridge.kt                        # ExoPlayer, Texture, position stream
  SpeechBridge.kt                        # Android TTS, callbacks main thread
  AudioMixerBridge.kt                    # AudioFocus management
```

## Prerequis

- Flutter SDK >= 3.10
- Android SDK (minSdk 21)
- Un appareil Android (le TTS et ExoPlayer ne fonctionnent pas sur emulateur de maniere fiable)
- Google TTS installe sur l'appareil (voix francaise)

## Installation

```bash
# Cloner le depot
git clone https://github.com/BambaDev/AF-Players.git
cd AF-Players

# Installer les dependances
flutter pub get

# Generer les fichiers Hive
dart run build_runner build

# Lancer sur un appareil Android connecte
flutter run
```

## Utilisation

1. **Demarrage** — l'explorateur de fichiers s'ouvre, naviguez vers vos videos
2. **Selectionner une video** — tapez sur un fichier video
3. **Choisir les sous-titres** — les fichiers .srt/.vtt du meme dossier sont proposes automatiquement
4. **Lecture** — la video demarre, la voix francaise lit les sous-titres
5. **Gestes** :
   - Double-tap gauche/droite : recul/avance 10s
   - Glisser vertical gauche : luminosite
   - Glisser vertical droite : volume
   - Tap simple : afficher/masquer les controles
6. **Modes TTS** — cyclez entre les 3 modes avec le bouton dans les controles

## Configuration

### Voix francaise
- Allez dans Parametres > Voix francaise
- Selectionnez une voix parmi celles installees
- Ajustez la vitesse (x0.5 a x2.0) et la tonalite
- Testez avec le bouton "Tester la voix"

### Volumes independants
- Dans le lecteur, tapez l'icone tune
- Slider anglais : volume de la video originale
- Slider francais : volume de la voix TTS

## Technologies

| Composant | Technologie |
|---|---|
| Framework | Flutter 3.10+ |
| State management | GetX |
| Video | ExoPlayer/Media3 via MethodChannel |
| TTS | Android TextToSpeech via MethodChannel |
| Stockage | Hive + SharedPreferences |
| Permissions | permission_handler |

## Licence

Projet prive.

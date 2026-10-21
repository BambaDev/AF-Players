# AF Players

Lecteur video mobile Flutter avec synthese vocale francaise (TTS) a partir des sous-titres. Concu pour les francophones qui suivent des formations video en langue etrangere.

## Fonctionnalites

### Lecteur video
- **Lecteur video natif** — ExoPlayer/Media3 via MethodChannel, supporte MP4, MKV, AVI, WebM, MOV, FLV, 3GP
- **Gestes style MX Player Pro** — double-tap seek, glisser vertical gauche (luminosite), glisser vertical droite (volume), verrouillage ecran
- **Picture-in-Picture** — mode PIP automatique quand on quitte l'app
- **Signets (bookmarks)** — marquer et retrouver des moments dans la video
- **Detection de chapitres** — decoupe automatique des longues videos

### Synthese vocale francaise
- **6 modes de synchronisation TTS** :
  - **0 — File d'attente** — la voix termine chaque phrase, enchaine la suivante, la video continue
  - **1 — File + pause auto** — pause la video si la voix est en retard, reprend automatiquement
  - **2 — File + sync auto** — accelere la voix et ralentit la video si retard, retour progressif
  - **3 — Fusion** — regroupe les fragments de sous-titres en phrases completes avant lecture
  - **4 — Fusion sync** — fusion + synchronisation bidirectionnelle : TTS et video s'attendent mutuellement
  - **5 — Smart** — lecture intelligente inspiree VideoTranslatorAI : fusion avancee, vitesse TTS adaptative par segment (1.05x-1.40x), zero retard
- **Deux volumes independants** — anglais (video) et francais (voix TTS) reglables separement
- **Audio ducking** — baisse automatique du volume video pendant la lecture vocale
- **Volume TTS independant** — controle fin du volume de la voix francaise

### Navigation et organisation
- **Explorateur de fichiers** — navigation dossier par dossier, style MX Player Pro
- **Selection de sous-titres** — detection automatique des .srt/.vtt dans le meme dossier
- **Recherche dans les sous-titres** — trouver un mot dans tous les sous-titres charges
- **Playlists** — creer et gerer des listes de lecture
- **Statistiques** — suivi du temps de visionnage et de la progression
- **Onglet accueil** — recents, favoris, playlists

### Parametres
- **Voix francaise** — choix parmi les voix installees, vitesse (x0.5-x2.0), tonalite
- **Sous-titres** — taille, couleur du texte, couleur de fond, position (haut/bas)
- **Theme** — sombre et clair

## Architecture

```
Flutter (Dart)          <-->  MethodChannel  <-->  Kotlin (Android natif)
                                                    |-- PlayerBridge (ExoPlayer/Media3)
                                                    |-- SpeechBridge (Android TTS)
                                                    |-- AudioMixerBridge (AudioFocus)
                                                    |-- ThumbnailBridge (miniatures video)
                                                    |-- StorageBridge (acces fichiers)
                                                    |-- MainActivity (PIP, luminosite)
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
    sync_controller.dart                 # Synchronisation video/TTS (6 modes)
    subtitle_controller.dart             # Chargement et suivi sous-titres
    settings_controller.dart             # Parametres persistants
    library_controller.dart              # Bibliotheque de videos (Hive)
    audio_mixer_controller.dart          # AudioFocus Android
    bookmark_controller.dart             # Signets par video (Hive)
    playlist_controller.dart             # Gestion des playlists (Hive)
    thumbnail_controller.dart            # Miniatures video
    stats_controller.dart                # Statistiques de visionnage
    subtitle_search_controller.dart      # Recherche dans les sous-titres
    youtube_controller.dart              # Integration YouTube

  data/
    models/
      video_item.dart                    # Metadonnees video (Hive)
      subtitle_entry.dart                # Un cue : start, end, text
      subtitle_file.dart                 # Liste triee + recherche binaire
      tts_settings.dart                  # Langue, vitesse, pitch, voix
      bookmark.dart                      # Signet : position, note (Hive)
      playlist.dart                      # Playlist : nom, videos (Hive)
    services/
      subtitle_parser.dart               # Parsing SRT + VTT
      subtitle_merger.dart               # Fusion de phrases (modes 3-4)
      smart_subtitle_merger.dart         # Fusion intelligente (mode 5 Smart)
      video_storage_service.dart         # CRUD Hive
      file_picker_service.dart           # Abstraction file_picker
      chapter_detector.dart              # Detection de chapitres

  presentation/
    home/
      home_screen.dart                   # Ecran d'accueil avec onglets
      recents_tab.dart                   # Videos recentes
      favorites_tab.dart                 # Videos favorites
      playlists_tab.dart                 # Liste des playlists
    explorer/
      explorer_screen.dart               # Explorateur de fichiers
    player/
      player_screen.dart                 # Lecteur video immersif
      widgets/
        player_controls.dart             # Barre de controles
        subtitle_overlay.dart            # Sous-titres sur la video
        dual_volume_bar.dart             # 2 sliders volume (EN + FR)
        tts_speed_selector.dart          # Selecteur vitesse voix
        gesture_overlay.dart             # Gestes (volume, luminosite)
        lock_overlay.dart                # Verrouillage ecran
        seek_indicator.dart              # Indicateur de seek
        tts_indicator.dart               # Indicateur TTS actif
        bookmark_list_sheet.dart         # Liste des signets
        chapter_list_sheet.dart          # Liste des chapitres
    settings/
      settings_screen.dart               # Ecran parametres
    search/
      subtitle_search_screen.dart        # Recherche dans sous-titres
    stats/
      stats_screen.dart                  # Statistiques de visionnage
    playlist/
      playlist_screen.dart               # Contenu d'une playlist
    library/
      library_screen.dart                # Bibliotheque de videos
    youtube/
      youtube_screen.dart                # Ecran YouTube

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
  MainActivity.kt                        # Bridges, PIP, luminosite
  PlayerBridge.kt                        # ExoPlayer, Texture, position stream
  SpeechBridge.kt                        # Android TTS, volume, callbacks
  AudioMixerBridge.kt                    # AudioFocus management
  ThumbnailBridge.kt                     # Extraction miniatures video
  StorageBridge.kt                       # Acces fichiers Android
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

1. **Demarrage** — l'ecran d'accueil affiche les videos recentes, favoris et playlists
2. **Explorateur** — naviguez vers vos videos via l'explorateur de fichiers
3. **Choisir les sous-titres** — les fichiers .srt/.vtt du meme dossier sont proposes automatiquement
4. **Lecture** — la video demarre, la voix francaise lit les sous-titres
5. **Gestes** :
   - Double-tap gauche/droite : recul/avance
   - Glisser vertical gauche : luminosite
   - Glisser vertical droite : volume
   - Tap simple : afficher/masquer les controles
6. **Modes TTS** — cyclez entre les 6 modes avec le bouton dans les controles
7. **Signets** — tapez l'icone signet pour marquer un moment
8. **Mode Smart** — selectionnez le mode 5 pour une lecture fluide comme VideoTranslatorAI

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

### Mode Smart (mode 5)
Le mode Smart fusionne intelligemment les sous-titres fragmentes en phrases completes (3-20 secondes) et adapte automatiquement la vitesse TTS par segment (1.05x a 1.40x) pour coller parfaitement au timing video. Inspire des algorithmes de VideoTranslatorAI.

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

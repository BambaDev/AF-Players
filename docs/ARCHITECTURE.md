# Architecture technique — AF Players

## Vue d'ensemble

AF Players utilise une architecture hybride Flutter + Kotlin natif. Flutter gère l'UI et la logique métier, tandis que les composants critiques (vidéo, TTS, audio) sont implémentés en Kotlin natif via MethodChannel/EventChannel.

```
┌─────────────────────────────────────────────────────┐
│                    Flutter (Dart)                     │
│                                                       │
│  ExplorerScreen ──► PlayerScreen ──► SettingsScreen   │
│       │                  │                │           │
│  ExplorerCtrl    SyncController     SettingsCtrl      │
│                  /      |      \                      │
│          PlayerCtrl  SubtitleCtrl  TtsCtrl             │
│              │                       │                │
├──────────────┼───────────────────────┼────────────────┤
│         MethodChannel           MethodChannel          │
├──────────────┼───────────────────────┼────────────────┤
│         PlayerBridge            SpeechBridge           │
│        (ExoPlayer)           (Android TTS)             │
│              │                       │                │
│         AudioMixerBridge (AudioFocus)                  │
└─────────────────────────────────────────────────────┘
```

## Bridges natifs (Kotlin)

### PlayerBridge
- **Canal** : `com.afplayers/player` (MethodChannel) + `com.afplayers/player_events` (EventChannel)
- **Méthodes** : `init`, `open`, `play`, `pause`, `seek`, `setVolume`, `dispose`
- **Événements** : `position` (toutes les 200ms), `durationChanged`, `playingChanged`, `stateChanged`, `error`
- **Implémentation** : ExoPlayer/Media3 1.5.1, rendu via `TextureRegistry`

### SpeechBridge
- **Canal** : `com.afplayers/speech` (MethodChannel bidirectionnel)
- **Méthodes Dart→Kotlin** : `speak`, `stop`, `setSpeechRate`, `setPitch`, `getVoices`, `setVoice`
- **Méthodes Kotlin→Dart** : `onStart`, `onComplete`, `onError`, `onInitStatus`
- **Important** : Les callbacks `UtteranceProgressListener` s'exécutent sur un thread secondaire. Tous les `channel.invokeMethod` sont postés sur le main thread via `Handler(Looper.getMainLooper())`.

### AudioMixerBridge
- **Canal** : `com.afplayers/audio_mixer`
- **Rôle** : Gestion AudioFocus pour le mixage audio vidéo + TTS

## Synchronisation TTS (SyncController)

Le cœur de l'application. Coordonne la vidéo, les sous-titres et la voix.

### Flux principal

```
Position vidéo (200ms) ──► _onPositionChanged()
    │
    ├── SubtitleController.updatePosition() ──► binary search
    │
    └── Nouveau sous-titre détecté?
        │
        └── Oui ──► _queue.add(entry) ──► _processLoop()
                                              │
                                    ┌─────────┴─────────┐
                                    │   while queue      │
                                    │   not empty:       │
                                    │   await speak()    │
                                    └─────────┬─────────┘
                                              │
                                    Queue vide ──► _onAllDone()
```

### Les 3 modes

| Mode | Comportement | Déclencheur |
|------|-------------|-------------|
| 0 — File | Enfile les phrases, la vidéo continue | Par défaut |
| 1 — Pause | Pause la vidéo quand `_loopRunning && nouveau sous-titre`, reprend quand la file est vide | `_videoPausedForTts` |
| 2 — Vitesse | Accélère la voix quand `_loopRunning && nouveau sous-titre`, restaure quand la file est vide | `_adjustSpeed()` |

### Draining (mode 1)

Quand l'utilisateur pause manuellement en mode 1 :
1. `_draining = true` — la boucle continue de lire la file
2. `_onPositionChanged` ignore les nouveaux sous-titres
3. La boucle termine toutes les phrases en attente
4. `syncStatus = userPaused` — pause complète

### NativeTtsController.speak()

```dart
Future<void> speak(String text) async {
    _speakCompleter = Completer<void>();
    await _channel.invokeMethod('speak', {'text': text});
    return _speakCompleter!.future;  // attend onComplete du natif
}
```

Le `Completer` est complété par le callback `onComplete` du bridge natif, ou par `stop()` avec une garde `!isCompleted` pour éviter les doubles complétions.

## Parseur de sous-titres

Supporte SRT et VTT :
- Détection automatique du format par extension
- Parsing des timestamps `HH:MM:SS,mmm` (SRT) et `HH:MM:SS.mmm` (VTT)
- Suppression des tags HTML (`<b>`, `<i>`, etc.)
- Stockage dans `SubtitleFile` avec recherche binaire O(log n)

## Stockage

- **Hive** : bibliothèque de vidéos (`VideoItem` avec position de reprise)
- **SharedPreferences** : paramètres utilisateur (volumes, vitesse TTS, thème, mode sync)

## Gestes du lecteur

Style MX Player Pro :
- **Tap** : afficher/masquer les contrôles (auto-hide 4s)
- **Double-tap gauche** : reculer de N secondes
- **Double-tap droite** : avancer de N secondes
- **Glisser vertical gauche** : luminosité
- **Glisser vertical droite** : volume
- **Verrouillage** : désactive tous les gestes sauf le déverrouillage

## Permissions Android

| SDK | Permission |
|-----|-----------|
| >= 33 (Android 13+) | `Permission.videos` |
| >= 30 (Android 11-12) | `Permission.manageExternalStorage` |
| < 30 (Android 10-) | `Permission.storage` |

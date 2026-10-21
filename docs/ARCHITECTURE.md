# Architecture technique — AF Players

## Vue d'ensemble

AF Players utilise une architecture hybride Flutter + Kotlin natif. Flutter gere l'UI et la logique metier, tandis que les composants critiques (video, TTS, audio) sont implementes en Kotlin natif via MethodChannel/EventChannel.

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter (Dart)                         │
│                                                           │
│  HomeScreen ──► ExplorerScreen ──► PlayerScreen           │
│       │              │                  │                 │
│  LibraryCtrl   ExplorerCtrl      SyncController           │
│  PlaylistCtrl                    /    |    \    \          │
│  StatsCtrl              PlayerCtrl SubCtrl TtsCtrl        │
│  BookmarkCtrl                │                │           │
│                              │                │           │
├──────────────────────────────┼────────────────┼───────────┤
│                         MethodChannel                     │
├──────────────────────────────┼────────────────┼───────────┤
│  PlayerBridge  SpeechBridge  AudioMixerBridge             │
│  (ExoPlayer)   (Android TTS) (AudioFocus)                 │
│  ThumbnailBridge  StorageBridge  MainActivity (PIP)       │
└─────────────────────────────────────────────────────────┘
```

## Bridges natifs (Kotlin)

### PlayerBridge
- **Canal** : `com.afplayers/player` (MethodChannel) + `com.afplayers/player_events` (EventChannel)
- **Methodes** : `init`, `open`, `play`, `pause`, `seek`, `setVolume`, `setPlaybackSpeed`, `dispose`
- **Evenements** : `position` (toutes les 200ms), `durationChanged`, `playingChanged`, `stateChanged`, `error`
- **Implementation** : ExoPlayer/Media3 1.5.1, rendu via `TextureRegistry`

### SpeechBridge
- **Canal** : `com.afplayers/speech` (MethodChannel bidirectionnel)
- **Methodes Dart→Kotlin** : `speak`, `stop`, `setSpeechRate`, `setPitch`, `setVolume`, `getVoices`, `setVoice`
- **Methodes Kotlin→Dart** : `onStart`, `onComplete`, `onError`, `onInitStatus`
- **Volume TTS** : `KEY_PARAM_VOLUME` dans le Bundle de `speak()` pour controle par utterance
- **Important** : Les callbacks `UtteranceProgressListener` s'executent sur un thread secondaire. Tous les `channel.invokeMethod` sont postes sur le main thread via `Handler(Looper.getMainLooper())`.

### AudioMixerBridge
- **Canal** : `com.afplayers/audio_mixer`
- **Role** : Gestion AudioFocus pour le mixage audio video + TTS

### ThumbnailBridge
- **Canal** : `com.afplayers/thumbnail`
- **Role** : Extraction de miniatures video depuis le cache

### StorageBridge
- **Canal** : `com.afplayers/storage`
- **Role** : Acces aux fichiers Android (SAF, MediaStore)

### MainActivity — PIP et luminosite
- **Canal** : `com.afplayers/pip`
- **Methodes** : `enterPip`, `setAutoPip`, `setBrightness`, `getBrightness`
- **PIP** : `PictureInPictureParams` avec ratio 16:9, auto-PIP via `onUserLeaveHint`
- **Luminosite** : `window.attributes.screenBrightness`, restauration a -1 (systeme) en quittant

## Synchronisation TTS (SyncController)

Le coeur de l'application. Coordonne la video, les sous-titres et la voix.

### Flux principal

```
Position video (200ms) ──► _onPositionChanged()
    │
    ├── SubtitleController.updatePosition() ──► binary search
    │
    └── Nouveau sous-titre detecte?
        │
        ├── Modes 0-2 ──► _queue.add(entry.text)
        ├── Modes 3-4 ──► _entryToGroupIndex ──► _queue.add(group.text)
        └── Mode 5   ──► _smartEntryToGroupIndex ──► _queue.add(smartGroup.text)
                                                      + _smartGroupIndexQueue.add(idx)
                         │
                         └──► _processLoop()
                                │
                      ┌─────────┴─────────┐
                      │   while queue      │
                      │   not empty:       │
                      │   await speak()    │
                      └─────────┬─────────┘
                                │
                      Queue vide ──► _onAllDone()
```

### Les 6 modes

| Mode | Nom | Comportement | Manipulation video |
|------|-----|-------------|-------------------|
| 0 | File | Enfile les phrases, video continue | Aucune |
| 1 | Pause | Pause video quand TTS en retard, reprend quand file vide | Pause/Play |
| 2 | Sync auto | Accelere TTS + ralentit video si retard, retour progressif | Vitesse video |
| 3 | Fusion | SubtitleMerger regroupe en phrases completes, lecture sequentielle | Aucune |
| 4 | Fusion sync | Fusion + sync bidirectionnelle, TTS et video s'attendent | Vitesse video + wait |
| 5 | Smart | SmartSubtitleMerger + vitesse TTS adaptative par segment | Aucune (attente passive) |

### Mode 5 — Smart (detail)

Pipeline de traitement inspire de VideoTranslatorAI (`segments.py`, `timing.py`) :

1. **repair_split_sentences** — Detecte les coupures en milieu de clause via :
   - Continuation tokens francais (`de`, `du`, `les`, `que`, `avec`, etc.)
   - Elisions (`l'`, `d'`, `qu'`, `jusqu'`, etc.)
   - Mots orphelins en fin de texte (articles, pronoms, prepositions)
   - Cascade : fusionne tant que la condition tient, gap max 500ms

2. **merge_short_segments** — Fusionne les segments < 3s avec voisins si :
   - Gap entre eux <= 2s
   - Duree fusionnee <= 20s
   - Passe orphelins (≤ 5 mots) dans le groupe precedent (gap <= 3s, total <= 25s)

3. **expand_tight_slots** — Si ratio TTS estime/slot > 1.5 :
   - Emprunte du temps aux gaps adjacents (avant et apres)
   - Max 1.5s emprunte, garde 0.15s de marge minimum

4. **compute suggestedSpeed** — Vitesse TTS adaptative :
   - `estimatedDuration = text.length / 13.0` (chars/sec Android TTS francais)
   - `suggestedSpeed = (estimatedDuration / slotDuration).clamp(1.05, 1.40)`
   - Appliquee avant chaque groupe, restauree apres

**Resultat** : ~3x consolidation (1.9s/entree → 5-7s/groupe), ~20 mots/groupe, phrases completes, zero gaps.

**Playback** : la video joue normalement. Apres chaque groupe, si le TTS finit avant le prochain segment, attente passive (poll 100ms) sans manipulation de vitesse video.

### Draining (mode 1)

Quand l'utilisateur pause manuellement en mode 1 :
1. `_draining = true` — la boucle continue de lire la file
2. `_onPositionChanged` ignore les nouveaux sous-titres
3. La boucle termine toutes les phrases en attente
4. `syncStatus = userPaused` — pause complete

### Audio ducking

Quand la boucle TTS demarre (`_processLoop`) :
- `_duckVideo()` : baisse le volume video au niveau `duckingLevel` (defaut 0.1)
- `_unduckVideo()` : restaure le volume original quand la file est vide

### Arret TTS a la fermeture

L'ordre dans `dispose()` de PlayerScreen est critique :
1. `isTtsEnabled.value = false` — bloque les nouvelles entrees
2. `_playerController.pause()` — stoppe les events position
3. `NativeTtsController.stop()` — arrete la parole en cours
4. `_syncController.reset()` — vide les queues
5. Restauration luminosite + desactivation PIP

Des gardes `!isTtsEnabled.value` dans `_processLoop`, `_speakWithPauses` et `_waitForNextGroup` empechent toute reprise entre les etapes.

## NativeTtsController.speak()

```dart
Future<void> speak(String text) async {
    _speakCompleter = Completer<void>();
    await _channel.invokeMethod('speak', {'text': text});
    return _speakCompleter!.future;  // attend onComplete du natif
}
```

Le `Completer` est complete par le callback `onComplete` du bridge natif, ou par `stop()` avec une garde `!isCompleted` pour eviter les doubles completions.

## Fusion de sous-titres

### SubtitleMerger (modes 3-4)
- Fusion basique : gap <= 200ms, pas de fin de phrase, elisions, orphelins
- Max 8 entrees par groupe
- Produit `MergedSubtitleGroup` (start, end, text, entryIndices)

### SmartSubtitleMerger (mode 5)
- Pipeline en 4 etapes (voir Mode 5 ci-dessus)
- Produit `SmartMergedGroup` (start, end, text, entryIndices, suggestedSpeed)
- Cible : segments de 3-20s, phrases completes, vitesse TTS optimisee

## Parseur de sous-titres

Supporte SRT et VTT :
- Detection automatique du format par extension
- Parsing des timestamps `HH:MM:SS,mmm` (SRT) et `HH:MM:SS.mmm` (VTT)
- Suppression des tags HTML (`<b>`, `<i>`, etc.)
- Stockage dans `SubtitleFile` avec recherche binaire O(log n)

## Stockage

- **Hive** : bibliotheque de videos (`VideoItem`), signets (`Bookmark`), playlists (`Playlist`)
- **SharedPreferences** : parametres utilisateur (volumes, vitesse TTS, theme, mode sync, taille sous-titres, couleurs)

## Gestes du lecteur

Style MX Player Pro :
- **Tap** : afficher/masquer les controles (auto-hide 4s)
- **Double-tap gauche** : reculer de N secondes
- **Double-tap droite** : avancer de N secondes
- **Glisser vertical gauche** : luminosite (via `window.attributes.screenBrightness`)
- **Glisser vertical droite** : volume
- **Verrouillage** : desactive tous les gestes sauf le deverrouillage

## Permissions Android

| SDK | Permission |
|-----|-----------|
| >= 33 (Android 13+) | `Permission.videos` |
| >= 30 (Android 11-12) | `Permission.manageExternalStorage` |
| < 30 (Android 10-) | `Permission.storage` |

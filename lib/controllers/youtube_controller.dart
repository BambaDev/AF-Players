import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeController extends GetxController {
  final isLoading = false.obs;
  final progress = 0.0.obs;
  final statusText = ''.obs;
  final errorText = ''.obs;

  String? lastVideoPath;
  String? lastSubtitlePath;
  String? lastTitle;

  Future<bool> download(String url) async {
    isLoading.value = true;
    progress.value = 0;
    errorText.value = '';
    statusText.value = '';
    lastVideoPath = null;
    lastSubtitlePath = null;

    final yt = YoutubeExplode();
    try {
      statusText.value = 'Récupération des infos...';
      final video = await yt.videos.get(url);
      lastTitle = video.title;

      final dir = await getApplicationDocumentsDirectory();
      final dlDir = Directory('${dir.path}/youtube');
      if (!await dlDir.exists()) await dlDir.create(recursive: true);

      final safeTitle = video.title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
          .trim();

      statusText.value = 'Recherche des sous-titres FR...';
      try {
        final manifest = await yt.videos.closedCaptions.getManifest(video.id);
        final frTracks = manifest.tracks
            .where((t) => t.language.code.startsWith('fr'));
        if (frTracks.isNotEmpty) {
          statusText.value = 'Téléchargement des sous-titres...';
          final captions = await yt.videos.closedCaptions.get(frTracks.first);
          final srtContent = _captionsToSrt(captions);
          final subFile = File('${dlDir.path}/$safeTitle.srt');
          await subFile.writeAsString(srtContent);
          lastSubtitlePath = subFile.path;
        }
      } catch (_) {}

      statusText.value = 'Téléchargement de la vidéo...';
      final streamManifest = await yt.videos.streamsClient.getManifest(video.id);
      final streamInfo = streamManifest.muxed.withHighestBitrate();

      final videoFile = File('${dlDir.path}/$safeTitle.mp4');
      final fileStream = videoFile.openWrite();
      final dataStream = yt.videos.streamsClient.get(streamInfo);
      final totalSize = streamInfo.size.totalBytes;
      var downloaded = 0;

      await for (final chunk in dataStream) {
        fileStream.add(chunk);
        downloaded += chunk.length;
        progress.value = downloaded / totalSize;
        statusText.value = 'Téléchargement: ${(progress.value * 100).toStringAsFixed(0)}%';
      }

      await fileStream.flush();
      await fileStream.close();
      lastVideoPath = videoFile.path;

      statusText.value = 'Terminé!';
      isLoading.value = false;
      return true;
    } catch (e) {
      errorText.value = 'Erreur: $e';
      statusText.value = '';
      isLoading.value = false;
      return false;
    } finally {
      yt.close();
    }
  }

  String _captionsToSrt(ClosedCaptionTrack captions) {
    final buf = StringBuffer();
    for (var i = 0; i < captions.captions.length; i++) {
      final cap = captions.captions[i];
      final start = cap.offset;
      final end = cap.offset + cap.duration;
      buf.writeln('${i + 1}');
      buf.writeln('${_formatSrtTime(start)} --> ${_formatSrtTime(end)}');
      buf.writeln(cap.text);
      buf.writeln();
    }
    return buf.toString();
  }

  String _formatSrtTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$h:$m:$s,$ms';
  }
}

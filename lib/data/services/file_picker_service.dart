import 'package:file_picker/file_picker.dart';

class FilePickerService {
  Future<String?> pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', 'wmv'],
    );
    return result?.files.single.path;
  }

  Future<String?> pickSubtitleFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'sub', 'ass'],
    );
    return result?.files.single.path;
  }
}

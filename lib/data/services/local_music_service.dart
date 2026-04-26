import 'package:file_picker/file_picker.dart';

import '../models/music.dart';

class LocalMusicService {
  Future<List<MediaItem>> getMusic() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, type: FileType.audio);

    if (result == null) return [];

    final list = result.files.where((e) => e.path != null && e.path!.isNotEmpty).map((e) {
      return MediaItem(name: e.name, path: e.path!, type: MediaType.audio);
    }).toList();

    return list;
  }

  Future<List<MediaItem>> getVideo() async {
    final result = await FilePicker.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['mp4', 'mkv', 'avi']);

    if (result == null) return [];

    final list = result.files.where((e) => e.path != null && e.path!.isNotEmpty).map((e) {
      return MediaItem(name: e.name, path: e.path!, type: MediaType.video);
    }).toList();

    return list;
  }
}

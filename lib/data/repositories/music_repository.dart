import 'package:file_picker/file_picker.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
import '../models/music.dart';
import '../services/local_music_service.dart';
import '../services/player_service.dart';

class MusicRepository {
  final local = LocalMusicService();
  final player = PlayerService();
  // late final VideoController videoController = VideoController(player.player);
  Future<List<MediaItem>> loadMusic() async {
    final list = await local.getMusic();
    player.setPlaylist(list);
    return list;
  }

  Future<List<MediaItem>> loadVideo() async {
    final list = await local.getVideo();
    player.setPlaylist(list);
    return list;
  }

  Future<void> play(int index) => player.play(index);
  Future<void> toggle() => player.toggle();
  Future<void> next() => player.next();
  Future<void> prev() => player.prev();

  bool get isPlaying => player.isPlaying;
}

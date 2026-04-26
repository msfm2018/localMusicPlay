import 'package:media_kit/media_kit.dart';
import '../models/music.dart';

class PlayerService {
  final player = Player();

  PlayerStream get stream => player.stream;

  List<MediaItem> _playlist = [];
  int _index = 0;

  MediaItem? get current =>
      (_playlist.isNotEmpty && _index < _playlist.length)
          ? _playlist[_index]
          : null;

  /// 设置播放列表
  void setPlaylist(List<MediaItem> list) {
    _playlist = list;
  }

  /// 播放指定索引
  Future<void> play(int index) async {
    if (_playlist.isEmpty) return;
    if (index < 0 || index >= _playlist.length) return;

    _index = index;

    final item = _playlist[index];

    await player.open(
      Media(item.path),
      play: true,
    );
  }

  /// 暂停 / 播放
  Future<void> toggle() async {
    if (player.state.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  /// 下一首
  Future<void> next() async {
    if (_playlist.isEmpty) return;

    _index = (_index + 1) % _playlist.length;
    await play(_index);
  }

  /// 上一首
  Future<void> prev() async {
    if (_playlist.isEmpty) return;

    _index = (_index - 1 + _playlist.length) % _playlist.length;
    await play(_index);
  }

  /// 跳转进度
  Future<void> seek(Duration duration) async {
    await player.seek(duration);
  }

  bool get isPlaying => player.state.playing;
}
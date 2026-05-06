import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../data/models/music.dart';
import '../data/repositories/music_repository.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart'; // 必须导入这个

class MusicController extends ChangeNotifier {
  final repo = MusicRepository();

  final ScrollController scrollController = ScrollController();

  final songs = <MediaItem>[].obs;
  final currentIndex = (-1).obs;
  final isPlaying = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final isAlwaysOnTop = false.obs;
  late final VideoController videoController;
  MusicController() {
    videoController = VideoController(repo.player.player);
    _initStreams();
  }

  // 在 MusicController 类中
  // 假设你的 repo 里面有一个 media_kit 的 Player 实例
  Object get player => repo.player.player;
  // VideoController get videoController => repo.videoController;
  void _initStreams() {
    // 1. 监听进度 (Position)
    repo.player.stream.position.listen((Duration p) {
      position.value = p;
    });

    // 2. 监听总时长 (Duration)
    repo.player.stream.duration.listen((Duration d) {
      duration.value = d;
    });

    // 3. 监听播放状态 (Playing)
    repo.player.stream.playing.listen((bool playing) {
      isPlaying.value = playing;
    });

    // 4. 监听播放完成 (Completed)
    repo.player.stream.completed.listen((bool completed) {
      if (completed) {
        next(); // 自动播放下一首
      }
    });
  }

  void scrollToCurrent() {
    if (currentIndex.value < 0) return;

    // 假设每个 Item 高度固定为 72.0
    double offset = currentIndex.value * 72.0;

    if (scrollController.hasClients) {
      scrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // 删除单首音乐
  void removeMusic_(int index) {
    // 1. 如果删除的是当前正在播放的，先停掉或切到下一首
    if (currentIndex.value == index) {
      repo.player.player.stop(); // 停止播放
      isPlaying.value = false;
    }

    // 2. 从响应式列表中移除
    songs.value.removeAt(index);

    // 3. 通知 RxFlare 列表已更新（如果是使用 .value = ... 方式则不需要手动 refresh）
    songs.refresh();

    // 4. 修正 currentIndex，防止越界
    if (currentIndex.value >= songs.value.length && songs.value.isNotEmpty) {
      currentIndex.value = songs.value.length - 1;
    }
  }

  void removeMusic(int index) {
    // 1. 安全检查
    if (index < 0 || index >= songs.value.length) return;

    // 2. 如果删除的是当前正在播放的
    if (currentIndex.value == index) {
      repo.player.player.stop();
      isPlaying.value = false;
    }

    // 3. 执行删除
    songs.value.removeAt(index);
    songs.refresh(); // 触发 rxflare 监听器更新 UI

    // 4. 关键：修正 currentIndex
    if (songs.value.isEmpty) {
      currentIndex.value = -1; // 列表空了，重置索引
    } else if (index < currentIndex.value) {
      // 如果删除的是当前项之前的歌曲，当前索引需要减1以保持指向同一首歌
      currentIndex.value--;
    } else if (currentIndex.value >= songs.value.length) {
      // 如果删除的是最后一项且当前索引溢出，指向新的末尾
      currentIndex.value = songs.value.length - 1;
    }
  }

  // 清空所有音乐
  void clearPlaylist() {
    repo.player.player.stop();
    songs.value.clear();
    songs.refresh();
    currentIndex.value = 0;
    isPlaying.value = false;
  }

  // 在 MusicController 类内部添加
  void seek(Duration duration) {
    // 调用 repo -> playerService -> nativePlayer 进行跳转
    repo.player.seek(duration);
  }

  MediaItem? get currentSong => currentIndex.value >= 0 && songs.value.isNotEmpty ? songs.value[currentIndex.value] : null;



Future<void> loadMusic() async {
  await songs.runAsync(() async {
    final list = await repo.loadMusic();
    // 加载完成后，如果有歌曲，自动选中第一首
    if (list.isNotEmpty) {
      currentIndex.value = 0;
    }
    return list;
  });
}

Future<void> loadVideo() async {
  await songs.runAsync(() async {
    final list = await repo.loadVideo();
    // 加载完成后，如果有视频，自动选中第一首
    if (list.isNotEmpty) {
      currentIndex.value = 0;
    }
    return list;
  });
}
  Future<void> play(int index) async {
    await repo.play(index);

    currentIndex.value = index;
    isPlaying.value = true;

    // 播放后延迟一小会儿滚动，确保 UI 已经响应索引变化
    Future.delayed(const Duration(milliseconds: 100), () => scrollToCurrent());
  }

  Future<void> toggle() async {
    await repo.toggle();
    // 修正：确保 repo.isPlaying 同步到 Rx 状态
    isPlaying.value = !isPlaying.value;
  }

  // Future<void> next() async {
  //   if (songs.value.isEmpty) return;
  //   await repo.next();
  //   currentIndex.value = (currentIndex.value + 1) % songs.value.length;
  //   isPlaying.value = true;
  // }
  Future<void> next() async {
    if (songs.value.isEmpty) return; // 必须有这一行
    await repo.next();
    // 建议先计算新索引再赋值
    final nextIdx = (currentIndex.value + 1) % songs.value.length;
    currentIndex.value = nextIdx;
    isPlaying.value = true;
    scrollToCurrent(); // 切换下一首自动滚动
  }

  Future<void> prev() async {
    if (songs.value.isEmpty) return;
    await repo.prev();
    currentIndex.value = (currentIndex.value - 1 + songs.value.length) % songs.value.length;
    isPlaying.value = true;
  }

  @override
  void dispose() {
    super.dispose();
    songs.dispose();
    currentIndex.dispose();
    isPlaying.dispose();
    scrollController.dispose();

    // print("MusicController 已安全销毁");
  }

  void pause() {
    repo.player.player.pause();
    isPlaying.value = false;
  }

  void playCurrent() {
    repo.player.player.play();
    isPlaying.value = true;
  }

  void scrollToTop() {
  if (scrollController.hasClients) {
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
}

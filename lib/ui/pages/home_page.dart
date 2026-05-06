import 'dart:ui';

import 'package:cv/data/models/music.dart';
import 'package:flutter/gestures.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:rxflare/rxflare.dart';
import '../../state/music_controller.dart';
import '../widgets/player_controls.dart';
import '../widgets/music_visualizer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

final showSidebar = true.obs;
final MusicController controller = MusicController();
final GlobalKey<VideoState> videoKey = GlobalKey<VideoState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isHoveringVideo = false;
  bool _showProgressBar = false;

  @override
  void initState() {
    super.initState();
    _applyAcrylic();
  }

  void _applyAcrylic() async {
    await Window.setEffect(effect: WindowEffect.acrylic, color: const Color(0xCC1E1E1E));
  }

  void _onMouseEnterVideo(PointerEnterEvent e) {
    setState(() {
      _isHoveringVideo = true;
      _showProgressBar = true;
    });
  }

  void _onMouseExitVideo(PointerExitEvent e) {
    setState(() => _isHoveringVideo = false);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_isHoveringVideo && mounted) {
        setState(() => _showProgressBar = false);
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 32,
                color: const Color(0xf6252526),
                child: Row(
                  children: [
                    Expanded(
                      child: DragToMoveArea(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Icon(Icons.music_note, color: Colors.greenAccent, size: 10),
                                Text("音视频播放器", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const CustomWindowButtons(),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Rx(() {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeInOutCubic,
                        width: showSidebar.value ? 80 : 0,
                        child: ClipRect(
                          child: showSidebar.value
                              ? Container(
                                  color: const Color(0xFF1E1E1E),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 40),
                                      _buildSidebarTile(icon: Icons.library_music, onTap: () => controller.loadMusic()),
                                      const SizedBox(height: 18),
                                      _buildSidebarTile(icon: Icons.video_library, onTap: () => controller.loadVideo()),
                                      const Spacer(),
                                      const Divider(color: Colors.white12),
                                      const SizedBox(height: 12),
                                      const Text("v1.0.0", style: TextStyle(color: Colors.white38, fontSize: 12)),
                                    ],
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      );
                    }),
                    Flexible(
                      fit: FlexFit.loose, //tight,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 300),
                        color: const Color(0xee1E1E1E),
                        child: 
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Rx(() {
                                final song = controller.currentSong;
                                if (song == null) {
                                  return Center(
                                    child: 
                                     ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: Image.asset('assets/default_cover.jpg', fit: BoxFit.cover),
                                        ),    
                                  );
                                }

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (song.type == MediaType.video)
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: MouseRegion(
                                            onEnter: _onMouseEnterVideo,
                                            onExit: _onMouseExitVideo,
                                            child: Stack(
                                              children: [
                                                Video(key: videoKey, controller: controller.videoController),
                                                Center(
                                                  child: Rx(() {
                                                    return AnimatedOpacity(
                                                      opacity: controller.isPlaying.value ? 0.0 : 1.0,
                                                      duration: const Duration(milliseconds: 200),
                                                      child: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                                                    );
                                                  }),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: IgnorePointer(
                                                    child: Container(
                                                      padding: const EdgeInsets.all(20),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(song.name, style: TextStyle(color: Colors.white)),
                                                          Text("本地音视频", style: TextStyle(color: Colors.white70)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: GestureDetector(
                                                    behavior: HitTestBehavior.opaque,
                                                    onTap: () {
                                                      if (controller.isPlaying.value) {
                                                        controller.pause();
                                                      } else {
                                                        controller.playCurrent();
                                                      }
                                                    },
                                                    onDoubleTap: () async {
                                                      await videoKey.currentState?.enterFullscreen();
                                                    },
                                                  ),
                                                ),

                                                /// 进度条：可点击、可拖拽 + 悬停显示隐藏
                                                Positioned(
                                                  bottom: 0,
                                                  left: 0,
                                                  right: 0,
                                                  child: AnimatedOpacity(
                                                    opacity: _showProgressBar ? 1.0 : 0.0,
                                                    duration: _isHoveringVideo ? const Duration(milliseconds: 200) : const Duration(milliseconds: 400),
                                                    child: MouseRegion(
                                                      onEnter: (_) {
                                                        setState(() {
                                                          _isHoveringVideo = true;
                                                          _showProgressBar = true;
                                                        });
                                                      },
                                                      onExit: (_) {
                                                        setState(() => _isHoveringVideo = false);
                                                        Future.delayed(const Duration(milliseconds: 800), () {
                                                          if (!_isHoveringVideo && mounted) {
                                                            setState(() => _showProgressBar = false);
                                                          }
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                        child: Rx(() {
                                                          final position = controller.position.value;
                                                          final duration = controller.duration.value;
                                                          double sliderValue = position.inSeconds.toDouble();
                                                          double maxValue = duration.inSeconds.toDouble();
                                                          if (sliderValue > maxValue) sliderValue = maxValue;

                                                          return Column(
                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                            children: [
                                                              SliderTheme(
                                                                data: SliderTheme.of(context).copyWith(
                                                                  trackHeight: 4,
                                                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                                                  activeTrackColor: Colors.greenAccent,
                                                                  inactiveTrackColor: Colors.white24,
                                                                  thumbColor: Colors.white,
                                                                ),
                                                                child: Slider(
                                                                  value: sliderValue,
                                                                  max: maxValue > 0 ? maxValue : 1.0,
                                                                  onChanged: (value) {
                                                                    controller.seek(Duration(seconds: value.toInt()));
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                  children: [
                                                                    Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                                    Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        }),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 380,
                                          decoration: BoxDecoration(
                                            image: DecorationImage(image: AssetImage('assets/default_cover.jpg'), fit: BoxFit.cover),
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                            child: Container(color: Colors.black.withOpacity(0.4)),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                            // Padding(
                            //   padding: const EdgeInsets.symmetric(horizontal: 16),
                            //   child: PlayerControls(controller: controller),
                            // ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Rx(() {
                                final list = controller.songs.value;
                                if (list.isEmpty) {
                                  return Container();
                                  //  const Center(
                                  //   child: Text("列表空空如也，快去导入音乐吧~", style: TextStyle(color: Colors.white, fontSize: 16)),
                                  // );
                                }
                                return ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  controller: controller.scrollController,
                                  itemCount: list.length,
                                  itemBuilder: (context, i) {
                                    final music = list[i];
                                    return Rx(() {
                                      final isCurrent = controller.currentIndex.value == i;
                                      final isPlaying = controller.isPlaying.value;
                                      return AnimatedScale(
                                        key: ValueKey(music.path), // 关键修复：添加 ValueKey
                                        scale: isCurrent ? 1.03 : 1.0,
                                        duration: const Duration(milliseconds: 180),
                                        curve: Curves.easeOutCubic,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOutCubic,
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isCurrent ? Colors.greenAccent.withOpacity(0.12) : const Color(0xFF2D2D30),
                                            borderRadius: BorderRadius.circular(14),
                                            border: isCurrent ? Border.all(color: Colors.greenAccent.withOpacity(0.55), width: 1.5) : null,
                                            boxShadow: isCurrent
                                                ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.25), blurRadius: 12, spreadRadius: 1, offset: const Offset(0, 4))]
                                                : null,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(14),
                                            child: ListTile(
                                              visualDensity: VisualDensity.compact,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              leading: SizedBox(
                                                width: 32,
                                                height: 32,
                                                child: isCurrent && isPlaying
                                                    ? const MusicVisualizer(speaking: true, barCount: 5)
                                                    : const Icon(Icons.music_note, color: Colors.white70, size: 28),
                                              ),
                                              title: Text(
                                                music.name,
                                                style: TextStyle(color: isCurrent ? Colors.white : Colors.white70, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              trailing: isCurrent
                                                  ? const Icon(Icons.play_circle_fill, color: Colors.greenAccent, size: 28)
                                                  : IconButton(
                                                      icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                                                      splashRadius: 20,
                                                      onPressed: () => controller.removeMusic(i),
                                                    ),
                                              onTap: () => controller.play(i),
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // 或者使用悬浮按钮
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => controller.scrollToTop(),
      //   child: const Icon(Icons.arrow_upward),
      // ),
    );
  }
}

Future<void> _enterFullScreen() async {
  await videoKey.currentState?.enterFullscreen();
}

Widget _buildSidebarIconButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onPressed}) {
  return Tooltip(
    message: tooltip,
    child: IconButton(
      icon: Icon(icon, color: color, size: 14),
      splashRadius: 24,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    ),
  );
}

Widget _buildSidebarTile({required IconData icon, required VoidCallback onTap}) {
  return Tooltip(
    message: icon == Icons.library_music ? "本地音乐" : "本地视频",
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: onTap,
        hoverColor: Colors.greenAccent.withOpacity(0.15),
        splashColor: Colors.greenAccent.withOpacity(0.25),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.8),
          ),
          child: Icon(icon, color: Colors.white70, size: 30),
        ),
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}

class CustomWindowButtons extends StatelessWidget {
  const CustomWindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Rx(
          () => _buildSidebarIconButton(
            icon: Icons.push_pin,
            color: controller.isAlwaysOnTop.value ? Colors.greenAccent : Colors.white70,
            tooltip: "窗口置顶",
            onPressed: () async {
              bool isTop = await windowManager.isAlwaysOnTop();
              await windowManager.setAlwaysOnTop(!isTop);
              controller.isAlwaysOnTop.value = !isTop;
            },
          ),
        ),
        _buildSidebarIconButton(icon: Icons.delete_sweep, color: Colors.white70, tooltip: "清空播放列表", onPressed: () => controller.clearPlaylist()),
        Rx(
          () => IconButton(
            icon: Icon(showSidebar.value ? Icons.swipe_left : Icons.swipe_right, color: Colors.white54),
            onPressed: () {
              showSidebar.value = !showSidebar.value;
            },
          ),
        ),
        _buildBtn(Icons.horizontal_rule, () => windowManager.minimize()),
        _buildBtn(Icons.crop_square, () async {
          if (await windowManager.isMaximized()) {
            windowManager.unmaximize();
          } else {
            windowManager.maximize();
          }
        }),
        _buildBtn(Icons.close, () => windowManager.close(), isClose: true),
      ],
    );
  }

  Widget _buildBtn(IconData icon, VoidCallback onPressed, {bool isClose = false}) {
    return InkWell(
      onTap: onPressed,
      hoverColor: isClose ? Colors.red : Colors.white10,
      child: SizedBox(width: 46, height: 32, child: Icon(icon, color: Colors.white, size: 16)),
    );
  }
}

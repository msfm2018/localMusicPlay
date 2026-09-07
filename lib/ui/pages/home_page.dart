import 'dart:ui';

import 'package:cv/data/models/music.dart';
import 'package:flutter/gestures.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart';
import '../../main.dart';
import 'package:media_kit_video/media_kit_video.dart';

final showTopBar = true.obs;
final showProgressBar = false.obs;
final GlobalKey<VideoState> videoKey = GlobalKey<VideoState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isHoveringVideo = false;

  void _onMouseEnterVideo(PointerEnterEvent e) {
    _isHoveringVideo = true;
    showTopBar.value = true;
    showProgressBar.value = true;
  }

  void _onMouseExitVideo(PointerExitEvent e) {
    _isHoveringVideo = false;

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_isHoveringVideo) return; // 如果在1.2秒内鼠标又进来了，就不隐藏

      showTopBar.value = false;
      showProgressBar.value = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final song = controller.currentSong;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MouseRegion(
        onEnter: _onMouseEnterVideo,
        onExit: _onMouseExitVideo,
        hitTestBehavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: Rx(() {
                // final song = controller.currentSong;
           
                // if (song == null) {
                //   return Image.asset('assets/default_cover.jpg', fit: BoxFit.cover);
                // }

                final songsList = controller.songs.value;
        final index = controller.currentIndex.value;

        // 💡 核心安全防御：判断索引是否合法、列表是否为空
        if (index < 0 || songsList.isEmpty || index >= songsList.length) {
          return Image.asset('assets/default_cover.jpg', fit: BoxFit.cover);
        }

        // 安全地取出当前歌曲
        final song = songsList[index];

                if (song.type == MediaType.video) {
                  return
                  //  Video(key: videoKey, controller: controller.videoController, fill: Colors.black,fit: BoxFit.fill,);
                  Video(key: ValueKey(song.path), controller: controller.videoController, fill: Colors.black, fit: BoxFit.fill);
                } else {
                  return Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(image: AssetImage('assets/default_cover.jpg'), fit: BoxFit.cover),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(color: Colors.black.withValues(alpha: 0.4)),
                    ),
                  );
                }
              }),
            ),

            // 2. 次底层：全屏点击/双击手势层
            // 💡 修复核心：这里只管视频中间大面积的点击，不要让它把底部的进度条给盖住
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
                // 💡 故意放一个空 child 占位响应手势
                child: const SizedBox.expand(),
              ),
            ),

            // 3. 中间层：暂停/播放大图标
            Center(
              child: Rx(() {
                return AnimatedOpacity(
                  opacity: controller.isPlaying.value ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: const IgnorePointer(
                    // 图标不响应鼠标，防止挡住点击
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 72,
                      color: Colors.white,
                      shadows: [BoxShadow(color: Colors.black54, blurRadius: 8, spreadRadius: 2)],
                    ),
                  ),
                );
              }),
            ),

            // 4. 次顶层：底部歌名与控制进度条（放在全屏手势层之上，确保不被拦截）
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Rx(() {
                final visible = showProgressBar.value;
                final song = controller.currentSong;
                if (song == null || song.type != MediaType.video) return const SizedBox.shrink();

                return AnimatedOpacity(
                  opacity: visible ? 1.0 : 0.0,
                  duration: _isHoveringVideo ? const Duration(milliseconds: 200) : const Duration(milliseconds: 400),
                  child: Container(
                    // 渐变黑底，衬托文字和进度条
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54]),
                    ),
                    padding: const EdgeInsets.only(top: 40, bottom: 12, left: 20, right: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.name,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Rx(() {
                          final position = controller.position.value;
                          final duration = controller.duration.value;
                          double sliderValue = position.inSeconds.toDouble();
                          double maxValue = duration.inSeconds.toDouble();
                          if (sliderValue > maxValue) sliderValue = maxValue;

                          return Column(
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
                                    Rx(
                                      () => TextButton(
                                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), minimumSize: const Size(40, 20)),
                                        onPressed: () => controller.cycleSpeed(),
                                        child: Text("${controller.playSpeed.value}x", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ),
                                    ),
                                    Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ),

            // 5. 最顶层：自定义标题栏（支持隐藏）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: buildToBar(), // 里面使用上次给你的 Stack + DragToMoveArea 即可
            ),
          ],
        ),
      ),
    );
  }

  Widget buildToBar() {
    return Rx(() {
      final visible = showTopBar.value;

      return AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !visible, // 隐藏时释放点击权限，透传给底层
          child: Container(
            height: 32,
            color: const Color(0xf6252526),
            child: Stack(
              // 💡 改变结构：使用 Stack 分离拖拽区和按钮区
              children: [
                // 1. 底层：纯粹的窗口拖拽响应区（填满整行）
                const Positioned.fill(child: DragToMoveArea(child: SizedBox.expand())),

                // 2. 顶层：真正的按钮与标题内容（忽略拖拽干扰，正常响应手势）
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              // 💡 关键：只让非按钮区域触发拖拽，按钮自己保持独立
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.music_note, color: Colors.greenAccent, size: 10),
                                const SizedBox(width: 4),
                                const Text("音视频播放器", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                const SizedBox(width: 34),

                                // 本地音乐
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    hoverColor: Colors.white.withValues(alpha: 0.1),
                                    splashColor: Colors.white.withValues(alpha: 0.2),
                                    onTap: () => controller.loadMusic(),
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.library_music, color: Colors.white60, size: 14),
                                          SizedBox(width: 4),
                                          Text("本地音乐", style: TextStyle(color: Colors.white60, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8), // 稍微加点间距
                                // 本地视频
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    hoverColor: Colors.white.withValues(alpha: 0.1),
                                    splashColor: Colors.white.withValues(alpha: 0.15),
                                    onTap: () => controller.loadVideo(),
                                    child: Container(
                                      height: 32,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      alignment: Alignment.center,
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.video_library, color: Colors.white60, size: 14),
                                          SizedBox(width: 4),
                                          Text("本地视频", style: TextStyle(color: Colors.white60, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // 播放速度
                                Rx(
                                  () => Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(4),
                                      hoverColor: Colors.white.withValues(alpha: 0.1),
                                      splashColor: Colors.white.withValues(alpha: 0.15),
                                      onTap: () => controller.cycleSpeed(),
                                      child: Container(
                                        height: 24,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        alignment: Alignment.center,
                                        child: Text("播放速度 ${controller.playSpeed.value}x", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const CustomWindowButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildToBar11() {
    return Rx(() {
      final visible = showTopBar.value;

      return AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !visible, // 隐藏时释放点击权限，透传给底层
          child: Container(
            height: 32,
            color: const Color(0xf6252526),
            child: Row(
              children: [
                Expanded(
                  child: DragToMoveArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            const Icon(Icons.music_note, color: Colors.greenAccent, size: 10),
                            const SizedBox(width: 4),
                            const Text("音视频播放器", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            SizedBox(width: 34),

                            Material(
                              color: Colors.transparent, // 保持背景透明
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4), // 悬停变色区域的圆角
                                hoverColor: Colors.white.withValues(alpha: 0.1), // 💡 鼠标进入时的变色效果（10% 透明度的白色）
                                splashColor: Colors.white.withValues(alpha: 0.2), // 点击时的水波纹颜色
                                onTap: () => controller.loadMusic(),
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.library_music, color: Colors.white60, size: 14),
                                      SizedBox(width: 4),
                                      Text("本地音乐", style: TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 1. 本地视频 按钮
                            Material(
                              color: Colors.transparent, // 保持背景透明
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4), // 悬停变色的圆角
                                hoverColor: Colors.white.withValues(alpha: 0.1), // 鼠标移入时的背景色
                                splashColor: Colors.white.withValues(alpha: 0.15), // 点击时的水波纹颜色
                                onTap: () => controller.loadVideo(),
                                child: Container(
                                  height: 32,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.video_library, color: Colors.white60, size: 14),
                                      SizedBox(width: 4),
                                      Text("本地视频", style: TextStyle(color: Colors.white60, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // 2. 播放速度 按钮（包裹在 Rx 中以响应速度变化）
                            Rx(
                              () => Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(4),
                                  hoverColor: Colors.white.withValues(alpha: 0.1),
                                  splashColor: Colors.white.withValues(alpha: 0.15),
                                  onTap: () => controller.cycleSpeed(),
                                  child: Container(
                                    height: 24, // 稍微缩矮一点，更符合小标签/小按钮的视觉
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    alignment: Alignment.center,
                                    child: Text("播放速度 ${controller.playSpeed.value}x", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ),
                                ),
                              ),
                            ),
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
        ),
      );
    });
  }
}



Widget _buildSidebarIconButton({
  required IconData icon,
  required Color color,
  required String tooltip,
  required VoidCallback onPressed,
}) {
  return Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.transparent, // 确保基础背景透明
      type: MaterialType.circle, // 让悬停和点击波纹呈圆形
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: color, size: 14),
        hoverColor: Colors.white.withValues(alpha: 0.1), // 鼠标悬停时的背景颜色
        splashColor: Colors.white.withValues(alpha: 0.2), // 点击时的水波纹颜色
        highlightColor: Colors.white.withValues(alpha: 0.05), // 长按/按下时的颜色
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
        // Rx(
        //   () =>
        _buildSidebarIconButton(
          icon: Icons.push_pin,
          color: controller.isAlwaysOnTop.value ? Colors.greenAccent : Colors.white70,
          tooltip: "窗口置顶",
          onPressed: () async {
            bool isTop = await windowManager.isAlwaysOnTop();
            await windowManager.setAlwaysOnTop(!isTop);
            controller.isAlwaysOnTop.value = !isTop;
          },
        ),
        // ),
        _buildSidebarIconButton(icon: Icons.delete_sweep, color: Colors.white70, tooltip: "清空播放列表", onPressed: () => controller.clearPlaylist()),

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

  // Widget _buildBtn(IconData icon, VoidCallback onPressed, {bool isClose = false}) {
  //   return InkWell(
  //     onTap: onPressed,
  //     hoverColor: isClose ? Colors.red : Colors.white10,
  //     child: SizedBox(width: 46, height: 32, child: Icon(icon, color: Colors.white, size: 16)),
  //   );
  // }

  Widget _buildBtn(IconData icon, VoidCallback onPressed, {bool isClose = false}) {
  return Material(
    color: Colors.transparent, // 保持透明背景
    child: InkWell(
      onTap: onPressed,
      hoverColor: isClose ? Colors.red : Colors.white.withValues(alpha: 0.1), // 悬停时的颜色
      splashColor: isClose ? Colors.redAccent : Colors.white.withValues(alpha: 0.2), // 点击水波纹颜色
      child: SizedBox(
        width: 46,
        height: 32,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    ),
  );
}
}

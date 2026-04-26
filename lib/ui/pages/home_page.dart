// import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:ui';

import 'package:cv/data/models/music.dart';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MusicController controller;

  @override
  void initState() {
    super.initState();
    controller = MusicController();
    _applyAcrylic();
  }

  void _applyAcrylic() async {
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0xCC1E1E1E), // 这里的 CC 是透明度，1E1E1E 是底色
      // color: const Color(0x22121212), // 这里的 CC 是透明度，1E1E1E 是底色
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemKey = GlobalKey();
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 32, // 标准标题栏高度
                color: const Color(0xf6252526), // 保持和 Sidebar 颜色一致或透明
                child: Row(
                  children: [
                    // 1. 拖拽区域：点击这里可以移动窗口
                    Expanded(
                      child: DragToMoveArea(
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("自制播放器", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                    // 2. 窗口操作按钮：最小化、最大化、关闭
                    const CustomWindowButtons(),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// 🟦 左侧 Sidebar
                    Container(
                      width: 120,
                      // color: const Color(0x66252526),
                      color: const Color(0xea1E1E1E),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// 🪟 自定义标题栏（让无边框窗口可以拖动和关闭）
                          // const Text(
                          //   "🎵 Local 音乐",
                          //   style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          // ),
                          Row(
                            children: [
                              Rx(() {
                                return IconButton(
                                  icon: Icon(Icons.push_pin, color: controller.isAlwaysOnTop.value ? Colors.greenAccent : Colors.white54, size: 20),
                                  onPressed: () async {
                                    bool isTop = await windowManager.isAlwaysOnTop();
                                    await windowManager.setAlwaysOnTop(!isTop);
                                    controller.isAlwaysOnTop.value = !isTop; // 需要在 controller 定义这个 Rx 变量
                                  },
                                  tooltip: "置顶窗口",
                                );
                              }),

                              // 🟢 新增清空按钮
                              IconButton(
                                icon: const Icon(Icons.delete_sweep, color: Colors.white54, size: 20),
                                onPressed: () => controller.clearPlaylist(),
                                tooltip: "清空列表",
                              ),
                            ],
                          ),

                          // 在 Sidebar 内部
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(color: const Color(0xFF2D2D30), borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: const Icon(Icons.add, color: Colors.greenAccent),
                              title: const Text("音乐", style: TextStyle(color: Colors.white, fontSize: 10)),
                              onTap: () => controller.loadMusic(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            decoration: BoxDecoration(color: const Color(0xff2D2D30), borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              leading: const Icon(Icons.add, color: Colors.greenAccent),
                              title: const Text("视频", style: TextStyle(color: Colors.white, fontSize: 10)),
                              onTap: () => controller.loadVideo(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// 🟩 主区域
                    Expanded(
                      child: Container(
                        // color: const Color(0xCC1E1E1E),
                        color: const Color(0xee1E1E1E),
                        child: Column(
                          children: [
                            /// 🎶 当前播放卡片
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child:
                                  // Rx(() {
                                  //   final song = controller.currentSong;
                                  //   // 1. 如果没有播放内容
                                  //   // if (song == null) {
                                  //   //   return const Center(
                                  //   //     child: Text("等待播放...", style: TextStyle(color: Colors.white24)),
                                  //   //   );
                                  //   // }
                                  //   if (song == null) {
                                  //     return Center(
                                  //       child: Column(
                                  //         mainAxisSize: MainAxisSize.min,
                                  //         children: [
                                  //           Icon(Icons.music_note, size: 80, color: Colors.white24),
                                  //           const SizedBox(height: 16),
                                  //           Text("等待播放...", style: TextStyle(color: Colors.white38, fontSize: 18)),
                                  //         ],
                                  //       ),
                                  //     );
                                  //   }
                                  //   if (song.type == MediaType.video) {
                                  //     return SizedBox(
                                  //       height: 300, // ✨ 修改点：显式指定高度
                                  //       child:
                                  //           // 在主内容 Container 或 Card 上包裹
                                  //           ClipRRect(
                                  //             borderRadius: BorderRadius.circular(20),
                                  //             child: BackdropFilter(
                                  //               filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // 增大模糊
                                  //               child: Container(
                                  //                 // decoration: BoxDecoration(
                                  //                 //   color: Colors.white.withOpacity(0.08), // 半透明白 + 低不透明度
                                  //                 //   borderRadius: BorderRadius.circular(20),
                                  //                 //   border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                                  //                 // ),
                                  //                 decoration: BoxDecoration(
                                  //                   gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1E1E1E), Color(0xFF2A2A2E)]),
                                  //                 ),
                                  //                 child: Video(controller: controller.videoController), // 你的内容
                                  //               ),
                                  //             ),
                                  //           ),
                                  //     );
                                  //   }
                                  //   return Container(
                                  //     padding: const EdgeInsets.all(20),
                                  //     decoration: BoxDecoration(color: const Color(0xFF2D2D30), borderRadius: BorderRadius.circular(16)),
                                  //     child: Row(
                                  //       children: [
                                  //         Rx(() {
                                  //           return MusicVisualizer(speaking: controller.isPlaying.value, barCount: 12, color: Colors.greenAccent);
                                  //         }),
                                  //         const SizedBox(width: 16),
                                  //         /// 🎵 歌曲信息
                                  //         Expanded(
                                  //           child: Column(
                                  //             crossAxisAlignment: CrossAxisAlignment.start,
                                  //             children: [
                                  //               Text(
                                  //                 song?.name ?? "未播放",
                                  //                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  //               ),
                                  //               const SizedBox(height: 4),
                                  //               // const Text("本地音乐", style: TextStyle(color: Colors.grey)),
                                  //               Text("本地音乐", style: TextStyle(color: Colors.white70)),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   );
                                  // }),
                                  Rx(() {
                                    final song = controller.currentSong;
                                    if (song == null) {
                                      return Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.music_note, size: 80, color: Colors.white24),
                                            const SizedBox(height: 16),
                                            Text("等待播放...", style: TextStyle(color: Colors.white38, fontSize: 18)),
                                          ],
                                        ),
                                      );
                                    }

                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // 背景（视频或图片）
                                          if (song.type == MediaType.video)
                                            SizedBox(height: 380, child: Video(controller: controller.videoController))
                                          else
                                            Container(
                                              height: 380,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: AssetImage('assets/default_cover.jpg'), // 或从 song 获取封面
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              child: BackdropFilter(
                                                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                                child: Container(color: Colors.black.withOpacity(0.4)),
                                              ),
                                            ),

                                          // 前景信息 + 波形
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(20),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87]),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    song.name,
                                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                  Text("本地音乐", style: TextStyle(color: Colors.white70)),
                                                  const SizedBox(height: 12),
                                                  Rx(() => MusicVisualizer(speaking: controller.isPlaying.value, barCount: 12, color: Colors.greenAccent)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                            ),
                            // 📺 媒体播放容器 (视频或音频卡片)

                            // --- 第二层：高斯模糊遮罩 (新增) ---
                            //         BackdropFilter(
                            //           filter: ImageFilter.blur(sigmaX:
                            // 60, sigmaY: 60), // 模糊程度，越大越柔和
                            //           child: Container(color: Colors.black.withOpacity(
                            // 0.3)), // 压暗一点，突出文字
                            //         ),
                            /// ▶ 控制器
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: PlayerControls(controller: controller),
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              child: Rx(() {
                                final position = controller.position.value;
                                final duration = controller.duration.value;

                                // 防止除以零或进度超过总时长
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
                                          Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),

                            const SizedBox(height: 10),

                            /// 📃 歌单
                            // Expanded(
                            //   child: Rx(() {
                            //     final list = controller.songs.value;
                            //     if (list.isEmpty) {
                            //       return const Center(
                            //         child: Text("列表空空如也，快去导入音乐吧~", style: TextStyle(color: Colors.white, fontSize: 16)),
                            //       );
                            //     }
                            //     return ListView.builder(
                            //       padding: const EdgeInsets.all(12),
                            //       itemCount: list.length,
                            //       itemBuilder: (context, i) {
                            //         final music = list[i];

                            //         return Rx(() {
                            //           final isCurrent = controller.currentIndex.value == i;

                            //           return Container(
                            //             margin: const EdgeInsets.symmetric(vertical: 4),
                            //             decoration: BoxDecoration(color: isCurrent ? const Color(0xFF3E3E42) : const Color(0xFF2D2D30), borderRadius: BorderRadius.circular(10)),
                            //             child: ListTile(
                            //               leading: isCurrent && controller.isPlaying.value ? const MusicVisualizer(speaking: true) : const Icon(Icons.music_note, color: Colors.white70),

                            //               title: Text(music.name, style: const TextStyle(color: Colors.white)),

                            //               // trailing: isCurrent ? const Icon(Icons.play_circle_fill, color: Colors.greenAccent) : null,
                            //               trailing: isCurrent
                            //                   ? const Icon(Icons.play_circle_fill, color: Colors.greenAccent)
                            //                   : IconButton(
                            //                       icon: const Icon(Icons.close, color: Colors.white30, size: 18),
                            //                       onPressed: () => controller.removeMusic(i),
                            //                       // 调用删除
                            //                     ),
                            //               onTap: () => controller.play(i),
                            //             ),

                            //           );
                            //         });
                            //       },
                            //     );
                            //   }),
                            // ),

                            // /// 📃 歌单列表 - 美化 + 动画版本
                            // Expanded(
                            //   child: Rx(() {
                            //     final list = controller.songs.value;
                            //     if (list.isEmpty) {
                            //       return const Center(
                            //         child: Text("列表空空如也，快去导入音乐吧~",
                            //             style: TextStyle(color: Colors.white, fontSize: 16)),
                            //       );
                            //     }

                            //     return ListView.builder(
                            //       padding: const EdgeInsets.all(12),
                            //       itemCount: list.length,
                            //       itemBuilder: (context, i) {
                            //         final music = list[i];

                            //         return Rx(() {                    // ← rxflare 细粒度响应式
                            //           final isCurrent = controller.currentIndex.value == i;
                            //           final isPlaying = controller.isPlaying.value;

                            //           return AnimatedScale(
                            //             scale: isCurrent ? 1.03 : 1.0,           // 轻微放大，更优雅
                            //             duration: const Duration(milliseconds: 180),
                            //             curve: Curves.easeOutCubic,              // 更自然的缓动曲线
                            //             child: AnimatedContainer(
                            //               duration: const Duration(milliseconds: 200),
                            //               curve: Curves.easeOutCubic,
                            //               margin: const EdgeInsets.symmetric(vertical: 5),
                            //               decoration: BoxDecoration(
                            //                 color: isCurrent
                            //                     ? Colors.greenAccent.withOpacity(0.12)
                            //                     : const Color(0xFF2D2D30),
                            //                 borderRadius: BorderRadius.circular(14),
                            //                 border: isCurrent
                            //                     ? Border.all(color: Colors.greenAccent.withOpacity(0.55), width: 1.5)
                            //                     : null,
                            //                 boxShadow: isCurrent
                            //                     ? [
                            //                         BoxShadow(
                            //                           color: Colors.greenAccent.withOpacity(0.25),
                            //                           blurRadius: 12,
                            //                           spreadRadius: 1,
                            //                           offset: const Offset(0, 4),
                            //                         )
                            //                       ]
                            //                     : null,
                            //               ),
                            //               child: Material(                       // 提升点击水波纹效果
                            //                 color: Colors.transparent,
                            //                 borderRadius: BorderRadius.circular(14),
                            //                 child: ListTile(
                            //                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            //                   shape: RoundedRectangleBorder(
                            //                     borderRadius: BorderRadius.circular(14),
                            //                   ),
                            //                   leading: SizedBox(
                            //                     width: 40,
                            //                     child: isCurrent && isPlaying
                            //                         ? const MusicVisualizer(speaking: true, barCount: 5)
                            //                         : const Icon(Icons.music_note, color: Colors.white70, size: 28),
                            //                   ),
                            //                   title: Text(
                            //                     music.name,
                            //                     style: TextStyle(
                            //                       color: isCurrent ? Colors.white : Colors.white70,
                            //                       fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            //                       fontSize: 15,
                            //                     ),
                            //                     maxLines: 1,
                            //                     overflow: TextOverflow.ellipsis,
                            //                   ),
                            //                   trailing: isCurrent
                            //                       ? const Icon(Icons.play_circle_fill,
                            //                           color: Colors.greenAccent, size: 28)
                            //                       : IconButton(
                            //                           icon: const Icon(Icons.close,
                            //                               color: Colors.white38, size: 20),
                            //                           splashRadius: 20,
                            //                           onPressed: () => controller.removeMusic(i),
                            //                         ),
                            //                   onTap: () => controller.play(i),
                            //                 ),
                            //               ),
                            //             ),
                            //           );
                            //         });
                            //       },
                            //     );
                            //   }),
                            // ),

                            /// 📃 歌单列表 - 美化 + 动画 + 自动滚动到当前播放项
                            Expanded(
                              child: Rx(() {
                                final list = controller.songs.value;
                                if (list.isEmpty) {
                                  return const Center(
                                    child: Text("列表空空如也，快去导入音乐吧~", style: TextStyle(color: Colors.white, fontSize: 16)),
                                  );
                                }

                                return ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  controller: controller.scrollController, // ← 新增：绑定 ScrollController
                                  itemCount: list.length,
                                  itemBuilder: (context, i) {
                                    final music = list[i];

                                    return Rx(() {
                                      // rxflare 细粒度响应式
                                      final isCurrent = controller.currentIndex.value == i;
                                      final isPlaying = controller.isPlaying.value;

                                      // 自动滚动逻辑（放在这里最合适，利用 rxflare 响应式）
                                      // if (isCurrent) {
                                      //   WidgetsBinding.instance.addPostFrameCallback((_) {
                                      //     final scrollController = controller.scrollController;
                                      //     if (scrollController.hasClients) {
                                      //       // 计算目标位置，让当前项尽量居中
                                      //       final itemHeight = 72.0; // 估算每项高度（可根据实际 ListTile 高度微调）
                                      //       final targetOffset = (i * itemHeight) - (MediaQuery.of(context).size.height / 3); // 大致居中

                                      //       scrollController.animateTo(
                                      //         targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
                                      //         duration: const Duration(milliseconds: 400),
                                      //         curve: Curves.easeOutCubic,
                                      //       );
                                      //     }
                                      //   });
                                      // }



                                      return AnimatedScale(
                                        scale: isCurrent ? 1.03 : 1.0,
                                        duration: const Duration(milliseconds: 180),
                                        curve: Curves.easeOutCubic,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOutCubic,
                                          margin: const EdgeInsets.symmetric(vertical: 15),
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
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                              leading: SizedBox(
                                                width: 40,
                                                child: isCurrent && isPlaying
                                                    ? const MusicVisualizer(speaking: true, barCount: 5)
                                                    : const Icon(Icons.music_note, color: Colors.white70, size: 28),
                                              ),
                                              title: Text(
                                                music.name,
                                                style: TextStyle(color: isCurrent ? Colors.white : Colors.white70, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal, fontSize: 15),
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

          // );
          // floatingActionButton: FloatingActionButton(
          //   backgroundColor: Colors.greenAccent,
          //   child: const Icon(Icons.folder_open, color: Colors.black),
          //   onPressed: () => controller.loadMusic(),
          // ),
        ],
      ),
    );
  }
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
      children: [
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

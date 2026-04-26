import 'package:flutter/material.dart';
import 'package:rxflare/rxflare.dart'; // 确保导入 Rx 组件所在包
import '../../state/music_controller.dart';

class PlayerControls extends StatelessWidget {
  final MusicController controller;

  const PlayerControls({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // 使用你定义的 Rx 组件，它会自动追踪 controller.isPlaying.value
    return Rx(() {
      final playing = controller.isPlaying.value; // 自动推断为 bool 类型

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: controller.prev,
          ),
          IconButton(
            icon: Icon(
              playing ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: controller.toggle,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: controller.next,
          ),
        ],
      );
    });
  }
}
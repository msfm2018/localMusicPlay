import 'package:flutter/material.dart';
import 'dart:math' as math;

class MusicVisualizer extends StatefulWidget {
  final bool speaking;
  final Color color;
  final int barCount;

  const MusicVisualizer({
    super.key,
    required this.speaking,
    this.color = Colors.blue,
    this.barCount = 4, // 默认4根柱子，适合放在 ListTile 的 leading
  });

  @override
  State<MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<MusicVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.speaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(MusicVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 根据播放状态切换动画
    if (widget.speaking != oldWidget.speaking) {
      widget.speaking ? _controller.repeat() : _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(24, 24), // 刚好适配 Icon 大小
          painter: _VisualizerPainter(
            progress: _controller.value,
            color: widget.color,
            barCount: widget.barCount,
            isAnimating: widget.speaking,
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int barCount;
  final bool isAnimating;

  _VisualizerPainter({
    required this.progress,
    required this.color,
    required this.barCount,
    required this.isAnimating,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double spacing = 2.0; // 柱子间距
    double barWidth = (size.width - (spacing * (barCount - 1))) / barCount;

    for (int i = 0; i < barCount; i++) {
      double minHeight = 4.0;
      double maxHeight = size.height;
      double currentHeight;

      if (isAnimating) {
        // 利用正弦函数和相位差 i 实现错落有致的跳动
        double variance = math.sin((progress * math.pi * 2) + (i * 1.5));
        currentHeight = minHeight + (maxHeight - minHeight) * (variance.abs());
      } else {
        currentHeight = minHeight; // 静止时显示最低高度
      }

      double x = i * (barWidth + spacing);
      double y = size.height - currentHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, currentHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) {
    // 只有在动画运行或者是颜色等参数改变时才重绘
    return isAnimating || oldDelegate.color != color;
  }
}
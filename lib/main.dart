import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'state/music_controller.dart';
import 'ui/pages/home_page.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:flutter_acrylic/flutter_acrylic.dart';

final MusicController controller = MusicController();
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 初始化亚克力效果
  // await Window.initialize();
  // await Window.makeTitlebarTransparent(); // 使标题栏透明
  // 初始化 media_kit
  MediaKit.ensureInitialized();

  // 必须初始化
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    // size: Size(1100, 750),
    center: true,
    backgroundColor: Colors.transparent,
    // skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });


  runApp(const MyApp());
  // ✅ 再处理参数（不阻塞 UI）
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (args.length == 1) {
      await controller.openFile(args.first);
    } else if (args.length > 1) {
      await controller.openFiles(args);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'views/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const AnMatesApp(),
    ),
  );
}

class AnMatesApp extends StatelessWidget {
  const AnMatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ĂnMates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
      builder: _webFrameBuilder,
    );
  }
}

Widget _webFrameBuilder(BuildContext context, Widget? child) {
  if (!kIsWeb) return child!;
  final mq = MediaQuery.of(context);
  if (mq.size.width <= 600) return child!;

  const frameW = 430.0;
  final frameH = (mq.size.height - 48).clamp(600.0, 900.0);

  return ColoredBox(
    color: const Color(0xFF0C0B18),
    child: Center(
      child: Container(
        width: frameW,
        height: frameH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(44),
          boxShadow: [
            BoxShadow(
              color: AppColors.berry.withValues(alpha: 0.25),
              blurRadius: 80,
              spreadRadius: -10,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: MediaQuery(
          data: mq.copyWith(
            size: const Size(frameW, 900),
            padding: const EdgeInsets.only(top: 44, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
            viewInsets: EdgeInsets.zero,
          ),
          child: child!,
        ),
      ),
    ),
  );
}

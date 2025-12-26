import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/drive_service.dart';
import 'screens/home_screen.dart';
import 'screens/lock_setup_screen.dart';
import 'screens/drive_screen.dart';
import 'screens/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const KingGalleryApp());
}

class KingGalleryApp extends StatelessWidget {
  const KingGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => DriveService()),
      ],
      child: MaterialApp(
        title: 'King Gallery',
        theme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        initialRoute: '/lock',
        routes: {
          '/': (_) => const HomeScreen(),
          '/lock': (_) => const LockScreen(),
          '/lock-setup': (_) => const LockSetupScreen(),
          '/drive': (_) => const DriveScreen(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/config_model.dart';
import 'models/server_model.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/vpn_service.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation en mode portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser dotenv
  await dotenv.load(fileName: '.env');

  // Initialiser Hive et les adaptateurs
  await Hive.initFlutter();
  // Vérification si les adaptateurs sont déjà enregistrés
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ConfigModelAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ServerModelAdapter());
  }

  // Initialiser le service de stockage
  final storageService = StorageService();
  await storageService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VpnService()),
      ],
      child: MaterialApp(
        title: 'VPN MASTER BY BEDEZO',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}
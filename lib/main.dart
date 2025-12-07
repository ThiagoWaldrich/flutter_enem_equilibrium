import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'services/mind_map_service.dart';

// Configurar FFI para Windows/Linux/Mac
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/calendar_screen.dart';
import 'services/storage_service.dart';
import 'services/database_service.dart';
import 'services/calendar_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CONFIGURAR FFI APENAS PARA DESKTOP (não-web)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Inicializar FFI para sqflite em desktop
    sqfliteFfiInit();
    // Usar factory FFI para desktop
    databaseFactory = databaseFactoryFfi;
  }
  
  // Inicializar serviços
  final storageService = StorageService();
  await storageService.init();
  
  final databaseService = DatabaseService();
  await databaseService.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<DatabaseService>.value(value: databaseService),
        ChangeNotifierProvider(create: (_) => CalendarService(storageService)),
        ChangeNotifierProvider(create: (context) => MindMapService(context.read<StorageService>(),
          ),
        ),
      ],
      
      child: const EquilibriumApp(),
    ),
  );
}

class EquilibriumApp extends StatelessWidget {
  const EquilibriumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Equilibrium - Calendário de Estudos',
      theme: AppTheme.lightTheme,
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
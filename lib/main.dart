import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// Configurar FFI para Windows/Linux/Mac
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// IMPORTANTE: Adicionar para inicializar formatos de data
import 'package:intl/date_symbol_data_local.dart';

// Importar serviços
import 'services/storage_service.dart';
import 'services/database_service.dart';
import 'services/calendar_service.dart';
import 'services/mind_map_service.dart';
import 'services/monthly_goals_service.dart';

// Importar utils
import 'utils/theme.dart';

// Importar telas
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZAR FORMATOS DE DATA (RESOLVE O ERRO DO intl)
  await initializeDateFormatting();
  
  // 2. CONFIGURAR FFI APENAS PARA DESKTOP
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(
    MultiProvider(
      providers: [
        // Serviços principais (inicializados primeiro)
        FutureProvider<StorageService?>(
          create: (_) async {
            final service = StorageService();
            await service.init();
            return service;
          },
          initialData: null,
        ),
        
        FutureProvider<DatabaseService?>(
          create: (_) async {
            final service = DatabaseService();
            await service.init();
            return service;
          },
          initialData: null,
        ),
        
        // Serviços dependentes (usam ProxyProvider)
        ChangeNotifierProxyProvider<StorageService, CalendarService>(
          create: (context) {
            final storage = context.read<StorageService>();
            return CalendarService(storage);
          },
          update: (context, storage, previous) {
            return previous ?? CalendarService(storage);
          },
        ),
        
        ChangeNotifierProxyProvider<StorageService, MindMapService>(
          create: (context) {
            final storage = context.read<StorageService>();
            return MindMapService(storage);
          },
          update: (context, storage, previous) {
            return previous ?? MindMapService(storage);
          },
        ),
        
        ChangeNotifierProxyProvider2<StorageService, DatabaseService, MonthlyGoalsService>(
          create: (context) {
            final storage = context.read<StorageService>();
            final database = context.read<DatabaseService>();
            return MonthlyGoalsService(storage, database);
          },
          update: (context, storage, database, previous) {
            return previous ?? MonthlyGoalsService(storage, database);
          },
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
    final storageService = context.watch<StorageService?>();
    final databaseService = context.watch<DatabaseService?>();
    
    // Mostrar tela de carregamento se serviços não estiverem prontos
    if (storageService == null || databaseService == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Inicializando serviços...'),
              ],
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Equilibrium - Calendário de Estudos',
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// Configurar FFI para Windows/Linux/Mac
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// IMPORTANTE: Adicionar para inicializar formatos de data
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

// Importar serviços
import 'services/storage_service.dart';
import 'services/database_service.dart';
import 'services/calendar_service.dart';
import 'services/mind_map_service.dart';
import 'services/monthly_goals_service.dart';
import 'services/enhanced_database_service.dart';

// Importar utils
import 'utils/theme.dart';

// Importar telas
import 'screens/calendar_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/access_logs_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZAR FORMATOS DE DATA (RESOLVE O ERRO DO intl)
  await initializeDateFormatting();
  
  // 2. CONFIGURAR FFI APENAS PARA DESKTOP
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // 3. INICIALIZAR BANCO DE DADOS APERFEIÇOADO
  final db = EnhancedDatabaseService();
  await db.init();
  
  // 4. REGISTRAR ACESSO INICIAL
  await db.registerAccess();
  
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final EnhancedDatabaseService db;

  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
        
        // Banco de dados aperfeiçoado (já inicializado)
        Provider<EnhancedDatabaseService>.value(value: db),
        
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
    );
  }
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
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Inicializando serviços...'),
              ],
            ),
          ),
        ),
      );
    }
    
    return MaterialApp(
      title: 'Equilibrium',
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      home: const CalendarScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}
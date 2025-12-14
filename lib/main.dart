// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';

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
import 'services/supabase_service.dart';
import 'services/auth_service.dart'; // ← Adicionado

// Importar utils
import 'utils/theme.dart';

// Importar telas
import 'screens/calendar_screen.dart';
import 'screens/flashcards_screen.dart';
import 'screens/access_logs_screen.dart';
import 'screens/question_bank_screen.dart';
import 'screens/add_question_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/review_screen.dart';
import 'screens/autodiagnostico_screen.dart';
import 'screens/manage_subjects_screen.dart';
import 'screens/login_screen.dart'; // ← Adicionado

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await Supabase.initialize(
    url: '',
    anonKey: '',
  );
  
  if (kIsWeb) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
  
  await initializeDateFormatting();
  

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  

  final db = EnhancedDatabaseService();
  await db.init();
  
 
  await db.registerAccess();
  
  runApp(MyApp(db: db));
}

class MyApp extends StatelessWidget {
  final EnhancedDatabaseService db;

  const MyApp({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return provider_package.MultiProvider(
      providers: [
        provider_package.Provider<SupabaseClient>(
          create: (_) => Supabase.instance.client,
        ),
        
        provider_package.Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        
        provider_package.FutureProvider<StorageService?>(
          create: (_) async {
            final service = StorageService();
            await service.init();
            return service;
          },
          initialData: null,
        ),
        
        provider_package.FutureProvider<DatabaseService?>(
          create: (_) async {
            final service = DatabaseService();
            await service.init();
            return service;
          },
          initialData: null,
        ),
        
        // Banco de dados aperfeiçoado (já inicializado)
        provider_package.Provider<EnhancedDatabaseService>.value(value: db),
        
        // Serviços dependentes (usam ProxyProvider)
        provider_package.ChangeNotifierProxyProvider<StorageService, CalendarService>(
          create: (context) {
            final storage = context.read<StorageService>();
            return CalendarService(storage);
          },
          update: (context, storage, previous) {
            return previous ?? CalendarService(storage);
          },
        ),
        
        provider_package.ChangeNotifierProxyProvider<StorageService, MindMapService>(
          create: (context) {
            final storage = context.read<StorageService>();
            return MindMapService(storage);
          },
          update: (context, storage, previous) {
            return previous ?? MindMapService(storage);
          },
        ),
        
        provider_package.ChangeNotifierProxyProvider2<StorageService, DatabaseService, MonthlyGoalsService>(
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
    final storageService = provider_package.Provider.of<StorageService?>(context);
    final databaseService = provider_package.Provider.of<DatabaseService?>(context);
    final authService = provider_package.Provider.of<AuthService>(context);
    
    // Verificar autenticação
    final isAuthenticated = AuthService.isAuthenticated;
    
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
    
    // Se não estiver autenticado, mostrar tela de login
    if (!isAuthenticated) {
      return MaterialApp(
        title: 'Equilibrium',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
    
    // Se autenticado, mostrar app normal
    return MaterialApp(
      title: 'Equilibrium',
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
      
      // Rotas nomeadas para facilitar navegação
      routes: {
        '/calendar': (context) => const CalendarScreen(),
        '/question-bank': (context) => const QuestionBankScreen(),
        '/add-question': (context) => const AddQuestionScreen(),
        '/flashcards': (context) => const FlashcardsScreen(),
        '/access-logs': (context) => const AccessLogsScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/review': (context) => const ReviewScreen(),
        '/autodiagnostico': (context) => const AutodiagnosticoScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
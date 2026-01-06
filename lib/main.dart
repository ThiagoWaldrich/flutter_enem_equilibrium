import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_package;
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'services/database_service.dart';
import 'services/calendar_service.dart';
import 'services/mind_map_service.dart';
import 'services/monthly_goals_service.dart';
import 'services/enhanced_database_service.dart';
import 'services/auth_service.dart'; 
import 'utils/theme.dart';
import 'screens/calendar_screen.dart';
import 'screens/question_bank_screen.dart';
import 'screens/add_edit_question_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/review_screen.dart';
import 'screens/autodiagnostico_screen.dart';
import 'screens/login_screen.dart'; 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ynxotlrtabypnxwslxry.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlueG90bHJ0YWJ5cG54d3NseHJ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyOTUwNDksImV4cCI6MjA4MDg3MTA0OX0.alZ1Zxg6mrlUfVyVRKZQptDNqB7K5EC2g4XubNfSXFM',
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
        

        provider_package.Provider<EnhancedDatabaseService>.value(value: db),
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
    //final authService = provider_package.Provider.of<AuthService>(context);
    final isAuthenticated = AuthService.isAuthenticated;
    
    if (storageService == null || databaseService == null) {
      return const MaterialApp(
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
    
    if (!isAuthenticated) {
      return MaterialApp(
        title: 'Equilibrium',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
        debugShowCheckedModeBanner: false,
      );
    }
    
    return MaterialApp(
      title: 'Equilibrium',
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
      
      routes: {
        '/calendar': (context) => const CalendarScreen(),
        '/question-bank': (context) => const QuestionBankScreen(),
        '/add-question': (context) => const AddEditQuestionScreen(),
        '/goals': (context) => const GoalsScreen(),
        '/review': (context) => const ReviewScreen(),
        '/autodiagnostico': (context) => const AutodiagnosticoScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
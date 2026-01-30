import 'package:equilibrium/features/core/services/file_upload_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'features/core/services/storage_service.dart';
import 'features/core/services/database_service.dart';
import 'features/calendar/logic/calendar_service.dart';
import 'features/mindmaps/logic/mind_map_service.dart';
import 'features/goals/logic/monthly_goals_service.dart';
import 'features/core/services/enhanced_database_service.dart';
import 'features/core/theme/theme.dart';
import 'features/calendar/screen/calendar_screen.dart';
import 'features/subjects/screen/weekly_schedule_screen.dart';
import 'features/goals/screen/goals_screen.dart';
import 'features/questions/screen/autodiagnostico_screen.dart';

void main() async {
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
    return MultiProvider(
      providers: [
        Provider<FileUploadService>(
          create: (context) => FileUploadService(),
        ),
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
        Provider<EnhancedDatabaseService>.value(value: db),
        ChangeNotifierProxyProvider<StorageService, CalendarService>(
          create: (context) => CalendarService(context.read<StorageService>()),
          update: (_, storage, previous) =>
              previous ?? CalendarService(storage),
        ),
        ChangeNotifierProxyProvider<StorageService, MindMapService>(
          create: (context) => MindMapService(context.read<StorageService>()),
          update: (_, storage, previous) => previous ?? MindMapService(storage),
        ),
        ChangeNotifierProxyProvider2<StorageService, DatabaseService,
            MonthlyGoalsService>(
          create: (context) => MonthlyGoalsService(
            context.read<StorageService>(),
            context.read<DatabaseService>(),
          ),
          update: (_, storage, database, previous) =>
              previous ?? MonthlyGoalsService(storage, database),
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
    final storageService = Provider.of<StorageService?>(context);
    final databaseService = Provider.of<DatabaseService?>(context);

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

    return MaterialApp(
      title: 'Equilibrium',
      theme: AppTheme.lightTheme,
      locale: const Locale('pt', 'BR'),
      home: const CalendarScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/calendar': (_) => const CalendarScreen(),
        '/weekly-schedule': (_) => const WeeklyScheduleScreen(),
        '/goals': (_) => const GoalsScreen(),
        '/autodiagnostico': (_) => const AutodiagnosticoScreen(),
      },
    );
  }
}

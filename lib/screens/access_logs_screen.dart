import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/enhanced_database_service.dart';
import '../models/access_log.dart';
import '../utils/theme.dart';

class AccessLogsScreen extends StatefulWidget {
  const AccessLogsScreen({super.key});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen> {
  List<AccessLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    
    final db = context.read<EnhancedDatabaseService>();
    final logs = await db.getAccessLogs();
    
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  Map<String, int> _getMonthlyStats() {
    final now = DateTime.now();
    final thisMonth = DateFormat('yyyy-MM').format(now);
    final lastMonth = DateFormat('yyyy-MM').format(DateTime(now.year, now.month - 1));
    
    int thisMonthCount = 0;
    int lastMonthCount = 0;
    
    for (final log in _logs) {
      final logMonth = log.date.substring(0, 7);
      if (logMonth == thisMonth) {
        thisMonthCount++;
      } else if (logMonth == lastMonth) {
        lastMonthCount++;
      }
    }
    
    return {
      'thisMonth': thisMonthCount,
      'lastMonth': lastMonthCount,
      'total': _logs.length,
    };
  }

  int _getCurrentStreak() {
    if (_logs.isEmpty) return 0;
    
    int streak = 0;
    final today = DateTime.now();
    
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(checkDate);
      
      final hasAccess = _logs.any((log) => log.date == dateStr);
      
      if (hasAccess) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    
    return streak;
  }

  Color _getAccessColor(int accessCount) {
    if (accessCount >= 10) return Colors.green[900]!;
    if (accessCount >= 5) return Colors.green[700]!;
    if (accessCount >= 3) return Colors.green[500]!;
    if (accessCount >= 1) return Colors.green[300]!;
    return Colors.grey[200]!;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('📊 Histórico de Acessos')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final stats = _getMonthlyStats();
    final streak = _getCurrentStreak();

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Histórico de Acessos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cards de estatísticas
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.calendar_today,
                  value: stats['total'].toString(),
                  label: 'Total de Dias',
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  value: streak.toString(),
                  label: 'Sequência Atual',
                  color: AppTheme.warningColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.trending_up,
                  value: stats['thisMonth'].toString(),
                  label: 'Este Mês',
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.history,
                  value: stats['lastMonth'].toString(),
                  label: 'Mês Passado',
                  color: AppTheme.infoColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Calendário visual
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mapa de Atividade (Últimos 90 dias)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActivityMap(),
                const SizedBox(height: 16),
                _buildLegend(),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Lista de acessos
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Histórico Detalhado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._logs.take(30).map((log) => _buildLogItem(log)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMap() {
    final now = DateTime.now();
    final squares = <Widget>[];
    
    for (int i = 89; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final log = _logs.firstWhere(
        (l) => l.date == dateStr,
        orElse: () => AccessLog(
          id: '',
          date: dateStr,
          accessCount: 0,
          firstAccessTime: '',
          lastAccessTime: '',
        ),
      );
      
      squares.add(
        Tooltip(
          message: '${DateFormat('dd/MM').format(date)}\n${log.accessCount} acessos',
          child: Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _getAccessColor(log.accessCount),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: squares,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Menos', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(width: 8),
        Container(width: 12, height: 12, color: Colors.grey[200]),
        const SizedBox(width: 4),
        Container(width: 12, height: 12, color: Colors.green[300]),
        const SizedBox(width: 4),
        Container(width: 12, height: 12, color: Colors.green[500]),
        const SizedBox(width: 4),
        Container(width: 12, height: 12, color: Colors.green[700]),
        const SizedBox(width: 4),
        Container(width: 12, height: 12, color: Colors.green[900]),
        const SizedBox(width: 8),
        const Text('Mais', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildLogItem(AccessLog log) {
    final date = DateTime.parse(log.date);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == log.date;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? AppTheme.primaryColor : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getAccessColor(log.accessCount),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.check, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOJE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.accessCount} acesso${log.accessCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(DateTime.parse(log.firstAccessTime)),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (log.accessCount > 1)
                Text(
                  'até ${DateFormat('HH:mm').format(DateTime.parse(log.lastAccessTime))}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
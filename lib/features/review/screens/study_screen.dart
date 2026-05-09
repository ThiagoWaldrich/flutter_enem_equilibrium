import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/study_topic_model.dart';
import '../models/study_session_model.dart';
import '../widgets/shimmer_progress_bar.dart';
import 'focus_screen.dart';
import '../../core/services/database_service.dart';
import '../../core/theme/theme.dart';
import '../logic/study_scheduler.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GroupedTopic> _groupedTopics = [];
  List<StudySession> _sessions = [];
  List<GroupedTopic> _todayStudy = [];
  bool _isLoading = true;
  late StudyScheduler _scheduler;
  
  int _monthlyGoal = 20;
  int _monthlyProgress = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final dbService = context.read<DatabaseService>();
    final db = await dbService.database;
    _scheduler = StudyScheduler(db);
    await _scheduler.initTable();
    await _syncWithQuestions();
    await _loadData();
  }

  Future<void> _syncWithQuestions() async {
    final dbService = context.read<DatabaseService>();
    final questions = await dbService.getQuestions(limit: 1000);
    final existing = await _scheduler.getAllTopics();
    final existingIds = existing.map((t) => t.id).toSet();

    for (final q in questions) {
      if (!existingIds.contains(q.id)) {
        final newTopic = StudyTopic(
          id: q.id,
          subject: q.subject,
          topic: q.topic,
          subtopic: q.subtopic,
        );
        await _scheduler.upsertTopic(newTopic);
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final topics = await _scheduler.getAllTopics();
    final sessions = await _scheduler.getAllSessions();
    
    final Map<String, GroupedTopic> groupMap = {};
    for (final topic in topics) {
      final key = '${topic.subject}|${topic.topic}';
      if (!groupMap.containsKey(key)) {
        groupMap[key] = GroupedTopic(
          subject: topic.subject,
          topic: topic.topic,
          questions: [],
        );
      }
      groupMap[key]!.questions.add(topic);
    }
    
    final grouped = groupMap.values.toList();
    grouped.sort((a, b) => b.count.compareTo(a.count));
    
    final now = DateTime.now();
    final goal = await _scheduler.getMonthlyGoal(now);
    if (goal != null) {
      _monthlyGoal = goal.targetMinutes ~/ 60;
    }
    _monthlyProgress = await _scheduler.getTotalMinutesStudiedInMonth(now);
    
    setState(() {
      _groupedTopics = grouped;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _resetTopicReviews(GroupedTopic groupedTopic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zerar revisões'),
        content: Text('Tem certeza que deseja zerar todas as revisões de "${groupedTopic.topic}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Zerar')),
        ],
      ),
    );
    
    if (confirm == true) {
      for (final question in groupedTopic.questions) {
        await _scheduler.resetTopicReviews(question);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revisões zeradas!'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Future<void> _updateMonthlyGoal() async {
    final newGoal = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Meta mensal (horas)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quantas horas você quer estudar este mês?'),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(ctx, (_monthlyGoal - 5).clamp(1, 200)),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Horas',
                    ),
                    controller: TextEditingController(text: _monthlyGoal.toString()),
                    onSubmitted: (value) {
                      final hours = int.tryParse(value) ?? _monthlyGoal;
                      Navigator.pop(ctx, hours.clamp(1, 200));
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx, (_monthlyGoal + 5).clamp(1, 200)),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, _monthlyGoal), child: const Text('Salvar')),
        ],
      ),
    );
    
    if (newGoal != null && newGoal != _monthlyGoal) {
      _monthlyGoal = newGoal;
      await _scheduler.setMonthlyGoal(DateTime.now(), newGoal * 60);
      await _loadData();
    }
  }

  void _addToTodayStudy(GroupedTopic topic) {
    setState(() {
      if (!_todayStudy.contains(topic)) {
        _todayStudy.add(topic);
      }
    });
  }

  void _removeFromTodayStudy(GroupedTopic topic) {
    setState(() {
      _todayStudy.remove(topic);
    });
  }

  void _clearTodayStudy() {
    setState(() {
      _todayStudy.clear();
    });
  }

  void _startStudySession(GroupedTopic topic) async {
    final startedAt = DateTime.now();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusScreen(
          topic: topic,
          onComplete: (quality, minutes) async {
            final finishedAt = DateTime.now();
            
            final session = StudySession(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              topicId: topic.questions.first.id,
              topicName: topic.topic,
              subject: topic.subject,
              startedAt: startedAt,
              finishedAt: finishedAt,
              durationMinutes: minutes,
              qualityScore: quality,
            );
            await _scheduler.saveSession(session);
            
            for (final question in topic.questions) {
              await _scheduler.recordSession(question, quality, minutes ~/ topic.count);
            }
            
            setState(() {
              _todayStudy.remove(topic);
            });
            
            await _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Sessão concluída! +$minutes minutos'), backgroundColor: Colors.green),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteSession(StudySession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir sessão'),
        content: Text('Tem certeza que deseja excluir a sessão de ${session.topicName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Excluir')),
        ],
      ),
    );
    
    if (confirm == true) {
      await _scheduler.deleteSession(session.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sessão excluída'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'ESTUDAR', icon: Icon(Icons.play_circle)),
              Tab(text: 'HISTÓRICO', icon: Icon(Icons.history)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildStudyTab(),
              _buildHistoryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyTab() {
    final progressPercent = (_monthlyProgress / 60 / _monthlyGoal).clamp(0.0, 1.0);
    
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                Colors.purple.shade700,
                Colors.deepPurple.shade900,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'META DO MÊS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _updateMonthlyGoal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_monthlyGoal}h',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              ShimmerProgressBar(value: progressPercent),
              
              const SizedBox(height: 12),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_monthlyProgress / 60).round()}h concluídas',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${(progressPercent * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bolt, color: Colors.yellow[400], size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Continue assim! Cada minuto conta para sua meta.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.today, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'SELECIONAR ESTUDOS DE HOJE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Spacer(),
              if (_todayStudy.isNotEmpty)
                TextButton(
                  onPressed: _clearTodayStudy,
                  child: const Text('Limpar tudo'),
                ),
            ],
          ),
        ),
        
        if (_todayStudy.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                ..._todayStudy.map((topic) => _buildTodayStudyCard(topic)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _todayStudy.isNotEmpty ? () => _startStudySession(_todayStudy.first) : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text('INICIAR SESSÃO (${_todayStudy.length} tópico${_todayStudy.length > 1 ? 's' : ''})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.grey),
              const SizedBox(width: 8),
              const Text(
                'TÓPICOS DISPONÍVEIS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_groupedTopics.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _groupedTopics.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('Nenhum tópico encontrado'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _groupedTopics.length,
                  itemBuilder: (ctx, index) => _buildTopicCard(_groupedTopics[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildTodayStudyCard(GroupedTopic topic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text('${_todayStudy.indexOf(topic) + 1}', style: const TextStyle(color: AppTheme.primaryColor)),
        ),
        title: Text(topic.topic, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${topic.subject} • ${topic.count} questões'),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle, color: Colors.red),
          onPressed: () => _removeFromTodayStudy(topic),
          tooltip: 'Remover',
        ),
      ),
    );
  }

  Widget _buildTopicCard(GroupedTopic topic) {
    final subtopicsPreview = topic.subtopics.take(3).join(', ');
    final isInTodayStudy = _todayStudy.contains(topic);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: topic.priorityColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: topic.priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          topic.subject,
                          style: TextStyle(fontSize: 11, color: topic.priorityColor, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: topic.priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            topic.priorityLabel,
                            style: TextStyle(fontSize: 9, color: topic.priorityColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.quiz, size: 10, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(
                                '${topic.count} questões',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.topic,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (subtopicsPreview.isNotEmpty)
                      Text(
                        subtopicsPreview,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${topic.totalReviewCount} revisões',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _resetTopicReviews(topic),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Zerar', style: TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              if (!isInTodayStudy)
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor, size: 32),
                  onPressed: () => _addToTodayStudy(topic),
                  tooltip: 'Adicionar ao estudo de hoje',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              else
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  onPressed: () => _removeFromTodayStudy(topic),
                  tooltip: 'Remover do estudo de hoje',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Nenhuma sessão registrada ainda'),
            const SizedBox(height: 8),
            Text(
              'Complete uma sessão de estudo para ver seu histórico',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final today = _sessions.where((s) => 
      s.startedAt.day == now.day && 
      s.startedAt.month == now.month && 
      s.startedAt.year == now.year
    ).toList();
    
    final yesterday = _sessions.where((s) => 
      s.startedAt.day == now.day - 1 && 
      s.startedAt.month == now.month && 
      s.startedAt.year == now.year
    ).toList();
    
    final older = _sessions.where((s) => 
      s.startedAt.isBefore(now.subtract(const Duration(days: 1)))
    ).toList();

    return ListView(
      children: [
        if (today.isNotEmpty) _buildSessionGroup('Hoje', today),
        if (yesterday.isNotEmpty) _buildSessionGroup('Ontem', yesterday),
        if (older.isNotEmpty) _buildSessionGroup('Anterior', older),
      ],
    );
  }

  Widget _buildSessionGroup(String title, List<StudySession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ),
        ...sessions.map((session) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.school, size: 20, color: AppTheme.primaryColor),
            ),
            title: Text(session.topicName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              '${session.subject} • ${DateFormat('dd/MM/yyyy HH:mm').format(session.startedAt)} • ${session.durationMinutes} min',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (session.qualityScore != null)
                  Chip(
                    label: Text(
                      _qualityText(session.qualityScore!),
                      style: TextStyle(fontSize: 10, color: _qualityColor(session.qualityScore!)),
                    ),
                    backgroundColor: _qualityColor(session.qualityScore!).withOpacity(0.1),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => _deleteSession(session),
                  tooltip: 'Excluir sessão',
                ),
              ],
            ),
          ),
        )).toList(),
        const SizedBox(height: 8),
      ],
    );
  }

  String _qualityText(int quality) {
    switch (quality) {
      case 1: return 'Muito difícil';
      case 2: return 'Difícil';
      case 3: return 'Boa';
      case 4: return 'Muito boa';
      default: return 'Não avaliado';
    }
  }

  Color _qualityColor(int quality) {
    switch (quality) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.green;
      case 4: return Colors.blue;
      default: return Colors.grey;
    }
  }
}
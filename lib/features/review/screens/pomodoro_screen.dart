// lib/features/review/screens/pomodoro_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
//  Paleta centralizada
// ─────────────────────────────────────────────
abstract class _C {
  static const bg         = Color(0xFF080B10);
  static const surface    = Color(0xFF0F1420);
  static const card       = Color(0xFF161D2C);
  static const border     = Color(0xFF1E2840);
  static const track      = Color(0xFF232E44);

  static const textPrimary   = Color(0xFFEEF2FB);
  static const textSecondary = Color(0xFF8A9DBF);
  static const textMuted     = Color(0xFF4C5F7A);

  static const accent   = Color(0xFF3BE6A0);
  static const accentDim = Color(0xFF1F9E6A);
  static const info     = Color(0xFF60A5FA);
  static const danger   = Color(0xFFF28080);
  static const warning  = Color(0xFFF7C060);

  static const lightBg       = Color(0xFFF5F5F5);
  static const lightSurface  = Color(0xFFFFFFFF);
  static const darkText      = Color(0xFF000000);
  static const darkSecondary = Color(0xFF666666);

  static const inputText = darkText;
  static const inputHint = darkSecondary;
}

// ─────────────────────────────────────────────
//  Modelo
// ─────────────────────────────────────────────
class StudyBlock {
  final String id;
  final String date;
  final String name;
  final String subject;
  final int durationMinutes;
  String status;
  int remainingSeconds;
  int realTimeSeconds;
  String note;

  StudyBlock({
    required this.id,
    required this.name,
    required this.subject,
    required this.durationMinutes,
    required this.date,
    this.status = 'pending',
    int? remainingSeconds,
    this.realTimeSeconds = 0,
    this.note = '',
  }) : remainingSeconds = remainingSeconds ?? durationMinutes * 60;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'durationMinutes': durationMinutes,
    'status': status,
    'remainingSeconds': remainingSeconds,
    'realTimeSeconds': realTimeSeconds,
    'note': note,
    'date': date,
  };

  factory StudyBlock.fromJson(Map<String, dynamic> json) => StudyBlock(
    id: json['id'] as String,
    name: json['name'] as String,
    subject: json['subject'] as String,
    durationMinutes: json['durationMinutes'] as int,
    status: json['status'] as String,
    remainingSeconds: json['remainingSeconds'] as int,
    realTimeSeconds: json['realTimeSeconds'] as int,
    note: (json['note'] as String?) ?? '',
    date: json['date'] as String,
  );
}

// ─────────────────────────────────────────────
//  Histórico
// ─────────────────────────────────────────────
class HistoryRecord {
  final String date;
  int blocks;
  int minutes;

  HistoryRecord({
    required this.date,
    required this.blocks,
    required this.minutes,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'blocks': blocks,
    'minutes': minutes,
  };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
    date: json['date'] as String,
    blocks: json['blocks'] as int,
    minutes: json['minutes'] as int,
  );
}

// ─────────────────────────────────────────────
//  Tela principal
// ─────────────────────────────────────────────
class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<StudyBlock> _blocks = [];
  Map<String, HistoryRecord> _history = {};
  int _dailyGoal = 3;
  final Map<String, Timer> _timers = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSoundEnabled = true;

  final _nameCtrl     = TextEditingController();
  final _subjectCtrl  = TextEditingController();
  final _durationCtrl = TextEditingController(text: '90');

  int _histWeekOffset = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    for (final t in _timers.values) t.cancel();
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    final raw = prefs.getStringList('study_blocks');
    if (raw != null) {
      _blocks = raw
          .map((s) => StudyBlock.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    }

    final historyRaw = prefs.getStringList('study_history');
    if (historyRaw != null) {
      _history = {};
      for (final h in historyRaw) {
        final record = HistoryRecord.fromJson(jsonDecode(h) as Map<String, dynamic>);
        _history[record.date] = record;
      }
    }

    _dailyGoal = prefs.getInt('daily_goal') ?? 3;
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;

    for (final b in _blocks) {
      if (b.status == 'running') b.status = 'pending';
    }

    setState(() {});
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setStringList(
      'study_blocks',
      _blocks.map((b) => jsonEncode(b.toJson())).toList(),
    );
    
    await prefs.setStringList(
      'study_history',
      _history.values.map((h) => jsonEncode(h.toJson())).toList(),
    );
    
    await prefs.setInt('daily_goal', _dailyGoal);
    await prefs.setBool('sound_enabled', _isSoundEnabled);
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  int get _todayCompletedCount {
    final today = _todayKey();
    return _blocks.where((b) => b.date == today && b.status == 'done').length;
  }

  double get _goalProgress =>
      _dailyGoal == 0 ? 0 : (_todayCompletedCount / _dailyGoal).clamp(0.0, 1.0);

  void _recordToHistory(StudyBlock block) {
    final date = block.date;
    final current = _history[date];
    final newBlocks = (current?.blocks ?? 0) + 1;
    final newMinutes = (current?.minutes ?? 0) + block.durationMinutes;
    
    _history[date] = HistoryRecord(
      date: date,
      blocks: newBlocks,
      minutes: newMinutes,
    );
    _saveState();
  }

  void _removeFromHistory(StudyBlock block) {
    final date = block.date;
    final current = _history[date];
    if (current == null) return;
    
    final newBlocks = current.blocks - 1;
    if (newBlocks <= 0) {
      _history.remove(date);
    } else {
      final newMinutes = current.minutes - block.durationMinutes;
      _history[date] = HistoryRecord(
        date: date,
        blocks: newBlocks,
        minutes: newMinutes,
      );
    }
    _saveState();
  }

  void _addBlock() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final duration = (int.tryParse(_durationCtrl.text) ?? 90).clamp(1, 480);

    final block = StudyBlock(
      id: 'b${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      subject: _subjectCtrl.text.trim().isEmpty ? 'Geral' : _subjectCtrl.text.trim(),
      durationMinutes: duration,
      date: _todayKey(),
    );

    setState(() => _blocks.add(block));
    _saveState();

    _nameCtrl.clear();
    _subjectCtrl.clear();
    _durationCtrl.text = '90';
  }

  void _startTimer(String id) {
    for (final b in _blocks.where((b) => b.status == 'running' && b.id != id)) {
      _pauseTimer(b.id);
    }

    final index = _blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    setState(() => _blocks[index].status = 'running');
    _saveState();
    _playSound();

    _timers[id] = Timer.periodic(const Duration(seconds: 1), (timer) {
      final i = _blocks.indexWhere((b) => b.id == id);
      if (i == -1) {
        timer.cancel();
        _timers.remove(id);
        return;
      }
      if (_blocks[i].remainingSeconds <= 1) {
        _completeBlock(id);
      } else {
        setState(() {
          _blocks[i].remainingSeconds--;
          _blocks[i].realTimeSeconds++;
        });
      }
    });
  }

  void _pauseTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);

    final index = _blocks.indexWhere((b) => b.id == id);
    if (index != -1 && _blocks[index].status == 'running') {
      setState(() => _blocks[index].status = 'pending');
      _saveState();
    }
    _stopSound();
  }

  void _completeBlock(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);

    final index = _blocks.indexWhere((b) => b.id == id);
    if (index != -1) {
      setState(() {
        _blocks[index].status = 'done';
        _blocks[index].remainingSeconds = 0;
      });
      _recordToHistory(_blocks[index]);
    }
    _stopSound();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Bloco concluído!'),
          backgroundColor: _C.accentDim,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteBlock(String id) {
    final index = _blocks.indexWhere((b) => b.id == id);
    if (index != -1 && _blocks[index].status == 'done') {
      _removeFromHistory(_blocks[index]);
    }
    _pauseTimer(id);
    setState(() => _blocks.removeWhere((b) => b.id == id));
    _saveState();
  }

  void _toggleCheck(String id) {
    final index = _blocks.indexWhere((b) => b.id == id);
    if (index == -1) return;

    if (_blocks[index].status == 'done') {
      _removeFromHistory(_blocks[index]);
      setState(() {
        _blocks[index].status = 'pending';
        _blocks[index].remainingSeconds = _blocks[index].durationMinutes * 60;
        _blocks[index].realTimeSeconds = 0;
      });
    } else {
      _pauseTimer(id);
      setState(() {
        _blocks[index].status = 'done';
        _blocks[index].remainingSeconds = 0;
      });
      _recordToHistory(_blocks[index]);
    }
    _saveState();
  }

  void _updateGoal() {
    int temp = _dailyGoal;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setD) => AlertDialog(
          backgroundColor: _C.lightSurface,
          title: const Text('Meta diária', style: TextStyle(color: _C.darkText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Quantos blocos você quer concluir hoje?',
                style: TextStyle(color: _C.darkSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => setD(() => temp = (temp - 1).clamp(1, 20)),
                    icon: const Icon(Icons.remove, color: _C.darkSecondary),
                  ),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: _C.border),
                      borderRadius: BorderRadius.circular(8),
                      color: _C.lightBg,
                    ),
                    child: Text(
                      '$temp',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.darkText),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setD(() => temp = (temp + 1).clamp(1, 20)),
                    icon: const Icon(Icons.add, color: _C.darkSecondary),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: _C.darkSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _C.accentDim),
              onPressed: () {
                setState(() => _dailyGoal = temp);
                _saveState();
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playSound() async {
    if (!_isSoundEnabled) return;
    try {
      await _audioPlayer.setSourceAsset('sounds/rain.mp3');
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.3);
      await _audioPlayer.resume();
    } catch (e) {
      debugPrint('Erro ao carregar áudio: $e');
    }
  }

  void _stopSound() => _audioPlayer.pause();

  void _toggleSound() {
    setState(() => _isSoundEnabled = !_isSoundEnabled);
    _saveState();
    if (!_isSoundEnabled) {
      _stopSound();
    } else if (_blocks.any((b) => b.status == 'running')) {
      _playSound();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatHours(int minutes) {
    if (minutes == 0) return '0min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0) return m > 0 ? '${h}h ${m}min' : '${h}h';
    return '${m}min';
  }

  String _dayLabel(DateTime date) {
    const days = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    return '${days[date.weekday % 7]} ${date.day}/${date.month}';
  }

  List<DateTime> _getWeekDates(int offset) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1 + offset * 7));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final todayBlocks = _blocks.where((b) => b.date == _todayKey()).toList();
    final completed = _todayCompletedCount;
    final exceeded = completed > _dailyGoal;

    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(todayBlocks, completed, exceeded),
                  _buildHistoryTab(),
                  _buildCompareTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(60),
        border: Border.all(color: _C.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _C.accentDim,
          borderRadius: BorderRadius.circular(60),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _C.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Hoje'),
          Tab(text: 'Histórico'),
          Tab(text: 'Semanas'),
        ],
      ),
    );
  }

  Widget _buildTodayTab(List<StudyBlock> todayBlocks, int completed, bool exceeded) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTodayHeader(),
          const SizedBox(height: 24),
          _buildGoalBar(completed, exceeded),
          const SizedBox(height: 24),
          _buildAddForm(),
          const SizedBox(height: 24),
          _buildBlockListHeader(todayBlocks.length),
          const SizedBox(height: 12),
          todayBlocks.isEmpty
              ? _buildEmptyBlocks()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayBlocks.length,
                  itemBuilder: (_, i) => _buildBlockCard(todayBlocks[i]),
                ),
        ],
      ),
    );
  }

  Widget _buildTodayHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: _C.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text(
              'Estúdio Foco',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _C.textPrimary),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _toggleSound,
          icon: Icon(_isSoundEnabled ? Icons.volume_up : Icons.volume_off, size: 16),
          label: Text(_isSoundEnabled ? 'Chuva' : 'Silêncio'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _C.card,
            foregroundColor: _isSoundEnabled ? _C.accent : _C.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalBar(int completed, bool exceeded) {
    return GestureDetector(
      onTap: _updateGoal,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _C.surface,
          border: Border.all(color: _C.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Meta diária', style: TextStyle(fontSize: 12, color: _C.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: _goalProgress,
                          minHeight: 4,
                          backgroundColor: _C.track,
                          valueColor: AlwaysStoppedAnimation<Color>(exceeded ? _C.warning : _C.accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completed / $_dailyGoal blocos concluídos${exceeded ? ' 🎯' : ''}',
                        style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 12, color: _C.textMuted),
                      const SizedBox(width: 4),
                      Text('$_dailyGoal', style: const TextStyle(fontSize: 13, color: _C.textPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '+ NOVO BLOCO',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _C.textMuted),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _C.surface,
            border: Border.all(color: _C.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: _C.inputText),
                  decoration: const InputDecoration(
                    hintText: 'Ex: Revisão de Cálculo...',
                    hintStyle: TextStyle(color: _C.inputHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _addBlock(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _subjectCtrl,
                  style: const TextStyle(color: _C.inputText),
                  decoration: const InputDecoration(
                    hintText: 'Matéria',
                    hintStyle: TextStyle(color: _C.inputHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                child: TextField(
                  controller: _durationCtrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _C.inputText),
                  decoration: const InputDecoration(
                    hintText: '90',
                    hintStyle: TextStyle(color: _C.inputHint),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Text('min', style: TextStyle(fontSize: 11, color: _C.textSecondary)),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addBlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.accentDim,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('+ Criar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('BLOCOS DE HOJE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _C.textMuted)),
        Text('$count blocos', style: const TextStyle(fontSize: 11, color: _C.textMuted)),
      ],
    );
  }

  Widget _buildEmptyBlocks() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border.all(color: _C.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          'Nenhum bloco para hoje.\nAdicione o primeiro foco acima.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _C.textMuted),
        ),
      ),
    );
  }

  Widget _buildBlockCard(StudyBlock block) {
    final isDone = block.status == 'done';
    final isRunning = block.status == 'running';
    final elapsedMinutes = block.realTimeSeconds ~/ 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _C.card,
        border: Border.all(color: isRunning ? _C.accentDim : _C.border),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isRunning
            ? [BoxShadow(color: _C.accent.withOpacity(0.18), blurRadius: 20)]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleCheck(block.id),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDone ? _C.accent : _C.textMuted, width: 1.5),
                  color: isDone ? _C.accent : Colors.transparent,
                ),
                child: isDone ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDone ? _C.textSecondary : _C.textPrimary,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${block.durationMinutes} min • ${block.subject}',
                    style: const TextStyle(fontSize: 11, color: _C.textMuted),
                  ),
                  if (isRunning && elapsedMinutes > 0)
                    Text(
                      '$elapsedMinutes min estudados',
                      style: const TextStyle(fontSize: 10, color: _C.accent),
                    ),
                ],
              ),
            ),

            _StatusBadge(isDone: isDone, isRunning: isRunning),
            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(40)),
              child: Text(
                isDone ? '00:00' : _formatTime(block.remainingSeconds),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isRunning ? _C.accent : _C.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),

            if (!isDone)
              isRunning
                  ? TextButton(
                      onPressed: () => _pauseTimer(block.id),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
                      child: const Text('Pausar', style: TextStyle(fontSize: 11, color: _C.textSecondary)),
                    )
                  : TextButton(
                      onPressed: () => _startTimer(block.id),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
                      child: const Text('▶ Iniciar', style: TextStyle(fontSize: 11, color: _C.accent)),
                    ),

            IconButton(
              onPressed: () => _deleteBlock(block.id),
              icon: const Icon(Icons.close, size: 16, color: _C.danger),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Aba Histórico (com blocos detalhados) ──────────────────────────
  Widget _buildHistoryTab() {
    final weekDates = _getWeekDates(_histWeekOffset);
    
    final Map<String, List<StudyBlock>> blocksByDay = {};
    
    for (final d in weekDates) {
      final key = _dateKey(d);
      final dayBlocks = _blocks.where((b) => b.date == key && b.status == 'done').toList();
      if (dayBlocks.isNotEmpty) {
        blocksByDay[key] = dayBlocks;
      }
    }
    
    int totalBlocks = 0;
    int totalMins = 0;
    for (final blocks in blocksByDay.values) {
      totalBlocks += blocks.length;
      totalMins += blocks.fold(0, (sum, b) => sum + b.durationMinutes);
    }
    final avg = totalBlocks / 7;

    final Map<String, Map<String, int>> catData = {};
    for (final blocks in blocksByDay.values) {
      for (final block in blocks) {
        if (!catData.containsKey(block.subject)) {
          catData[block.subject] = {'blocks': 0, 'minutes': 0};
        }
        catData[block.subject]!['blocks'] = catData[block.subject]!['blocks']! + 1;
        catData[block.subject]!['minutes'] = catData[block.subject]!['minutes']! + block.durationMinutes;
      }
    }

    final cats = catData.entries.toList()..sort((a, b) => b.value['minutes']!.compareTo(a.value['minutes']!));
    final maxMins = cats.isEmpty ? 1 : cats.first.value['minutes']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _histWeekOffset++),
                child: const Text('← Anterior', style: TextStyle(color: _C.textSecondary)),
              ),
              Text(
                '${weekDates.first.day}/${weekDates.first.month} – ${weekDates.last.day}/${weekDates.last.month}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: _C.textPrimary),
              ),
              TextButton(
                onPressed: _histWeekOffset > 0 ? () => setState(() => _histWeekOffset--) : null,
                child: Text(
                  'Próxima →',
                  style: TextStyle(color: _histWeekOffset > 0 ? _C.textSecondary : _C.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _StatCard('Blocos concluídos', '$totalBlocks')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('Tempo total', _formatHours(totalMins))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard('Média/dia', avg.toStringAsFixed(1))),
            ],
          ),
          const SizedBox(height: 24),

          const Text('📅 Detalhamento diário',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.textPrimary)),
          const SizedBox(height: 12),
          
          ...weekDates.map((d) {
            final key = _dateKey(d);
            final dayBlocks = blocksByDay[key] ?? [];
            final dayTotalMinutes = dayBlocks.fold(0, (sum, b) => sum + b.durationMinutes);
            final isToday = key == _todayKey();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _C.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _C.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isToday ? _C.accent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              _dayLabel(d),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isToday ? _C.accent : _C.textPrimary,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _C.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'HOJE',
                                  style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${dayBlocks.length} blocos • ${_formatHours(dayTotalMinutes)}',
                          style: const TextStyle(fontSize: 12, color: _C.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  
                  if (dayBlocks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('Nenhum bloco concluído neste dia',
                            style: TextStyle(fontSize: 12, color: _C.textMuted)),
                      ),
                    )
                  else
                    Column(
                      children: dayBlocks.map((block) => _buildHistoryBlockCard(block)).toList(),
                    ),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 24),

          if (cats.isNotEmpty) ...[
            const Text('📚 Por matéria',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.textPrimary)),
            const SizedBox(height: 8),
            ...cats.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(e.key, style: const TextStyle(fontSize: 13, color: _C.textSecondary))),
                  Expanded(
                    flex: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: e.value['minutes']! / maxMins,
                        minHeight: 4,
                        backgroundColor: _C.track,
                        valueColor: const AlwaysStoppedAnimation(_C.accent),
                      ),
                    ),
                  ),
                  SizedBox(width: 70, child: Text('${e.value['blocks']} blocos', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: _C.textMuted))),
                  SizedBox(width: 80, child: Text(_formatHours(e.value['minutes']!), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: _C.textMuted))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryBlockCard(StudyBlock block) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: _C.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${block.subject} • ${block.durationMinutes} min',
                  style: const TextStyle(fontSize: 11, color: _C.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatHours(block.durationMinutes),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.accent),
            ),
          ),
        ],
      ),
    );
  }

  // ── Aba Comparativo ────────────────────────
  Widget _buildCompareTab() {
    final currDates = _getWeekDates(0);
    final prevDates = _getWeekDates(1);
    
    int currBlocks = 0, currMins = 0, prevBlocks = 0, prevMins = 0;
    
    for (final d in currDates) {
      final key = _dateKey(d);
      currBlocks += _history[key]?.blocks ?? 0;
      currMins += _history[key]?.minutes ?? 0;
    }
    
    for (final d in prevDates) {
      final key = _dateKey(d);
      prevBlocks += _history[key]?.blocks ?? 0;
      prevMins += _history[key]?.minutes ?? 0;
    }

    final diffBlocks = currBlocks - prevBlocks;
    final diffMins = currMins - prevMins;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _buildCompareRow(
                  label: 'Blocos',
                  current: '$currBlocks',
                  previous: '$prevBlocks',
                  diff: diffBlocks,
                  diffLabel: '${diffBlocks >= 0 ? '+' : ''}$diffBlocks',
                ),
                const SizedBox(height: 16),
                _buildCompareRow(
                  label: 'Tempo',
                  current: _formatHours(currMins),
                  previous: _formatHours(prevMins),
                  diff: diffMins,
                  diffLabel: '${diffMins >= 0 ? '+' : ''}$diffMins min',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('📋 Dia a dia',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _C.textPrimary)),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16)),
            child: Table(
              columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1)},
              children: [
                TableRow(children: [
                  _th('Dia'),
                  _th('Atual', align: TextAlign.right),
                  _th('Anterior', align: TextAlign.right),
                ]),
                ...List.generate(7, (i) {
                  final cKey = _dateKey(currDates[i]);
                  final pKey = _dateKey(prevDates[i]);
                  final cB = _history[cKey]?.blocks ?? 0;
                  final pB = _history[pKey]?.blocks ?? 0;
                  final isToday = cKey == _todayKey();

                  return TableRow(children: [
                    _td(_dayLabel(currDates[i]), isToday: isToday),
                    _td(cB == 0 ? '—' : '$cB', isToday: isToday, align: TextAlign.right),
                    _td(pB == 0 ? '—' : '$pB', align: TextAlign.right),
                  ]);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareRow({
    required String label,
    required String current,
    required String previous,
    required int diff,
    required String diffLabel,
  }) {
    final diffColor = diff > 0 ? _C.accent : (diff < 0 ? _C.danger : _C.textSecondary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _CompareCell(title: '$label — atual', value: current, color: _C.accent),
        _CompareCell(title: 'diferença', value: diffLabel, color: diffColor),
        _CompareCell(title: '$label — anterior', value: previous, color: _C.textSecondary),
      ],
    );
  }

  Widget _th(String t, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(t, textAlign: align, style: const TextStyle(color: _C.textMuted)),
  );

  Widget _td(String t, {bool isToday = false, TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(
      t,
      textAlign: align,
      style: TextStyle(
        color: isToday ? _C.accent : _C.textSecondary,
        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
      ),
    ),
  );
}

// ─────────────────────────────────────────────
//  Widgets auxiliares
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isDone;
  final bool isRunning;
  const _StatusBadge({required this.isDone, required this.isRunning});

  @override
  Widget build(BuildContext context) {
    final label = isDone ? 'concluído' : (isRunning ? 'em andamento' : 'pendente');
    final color = isDone ? _C.info : (isRunning ? _C.accent : _C.textMuted);
    final bg = isDone ? _C.surface : (isRunning ? _C.accent.withOpacity(0.08) : _C.track);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: _C.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _C.accent)),
        ],
      ),
    );
  }
}

class _CompareCell extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _CompareCell({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: _C.textMuted)),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
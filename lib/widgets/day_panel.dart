import 'package:equilibrium/models/day_data.dart';
import 'package:equilibrium/services/monthly_goals_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_service.dart';
import '../utils/theme.dart';
import '../screens/manage_subjects_screen.dart';

class DayPanel extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  const DayPanel({
    super.key,
    required this.selectedDate,
    required this.onClose,
    this.scrollController,
  });

  @override
  State<DayPanel> createState() => _DayPanelState();
}

class _DayPanelState extends State<DayPanel> {
  // Mapa para armazenar controllers por data
  final Map<String, TextEditingController> _notesControllers = {};

  // Data atual sendo exibida
  String _currentDateKey = '';

  @override
  void initState() {
    super.initState();
    _initializeForDate();
  }

  void _initializeForDate() {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    _currentDateKey = dateStr;

    // Garantir que temos um controller para esta data
    if (!_notesControllers.containsKey(dateStr)) {
      final calendarService = context.read<CalendarService>();
      final dayData = calendarService.getDayData(dateStr);
      _notesControllers[dateStr] = TextEditingController(
        text: dayData?.notes ?? '',
      );
    }
  }

  TextEditingController _getCurrentNotesController() {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

    // Se mudou de data, atualizar o controller
    if (dateStr != _currentDateKey) {
      _currentDateKey = dateStr;

      // Criar novo controller se não existir para esta data
      if (!_notesControllers.containsKey(dateStr)) {
        final calendarService = context.read<CalendarService>();
        final dayData = calendarService.getDayData(dateStr);
        _notesControllers[dateStr] = TextEditingController(
          text: dayData?.notes ?? '',
        );
      }
    }

    return _notesControllers[dateStr]!;
  }

  @override
  void didUpdateWidget(DayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);


    if (widget.selectedDate != oldWidget.selectedDate) {
      final newDateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      // final oldDateStr =
      //     DateFormat('yyyy-MM-dd').format(oldWidget.selectedDate);

      if (!_notesControllers.containsKey(newDateStr)) {
        final calendarService = context.read<CalendarService>();
        final dayData = calendarService.getDayData(newDateStr);
        _notesControllers[newDateStr] = TextEditingController(
          text: dayData?.notes ?? '',
        );
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    _notesControllers.clear();
    super.dispose();
  }

  void _saveNotes(String notes) {
    final calendarService = context.read<CalendarService>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    calendarService.updateNotes(dateStr, notes);
  }

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final dayData = calendarService.getDayData(dateStr);
    final subjects = calendarService.getDaySubjects(dateStr);

    // Verificar se as notas no service estão sincronizadas com o controller
    final controller = _getCurrentNotesController();
    final serviceNotes = dayData?.notes ?? '';

    // Sincronizar se necessário (após carregar dados do service)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.text != serviceNotes) {
        controller.text = serviceNotes;
      }
    });

    final formattedDate =
        DateFormat("d 'de' MMMM, EEEE", 'pt_BR').format(widget.selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      margin: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Cabeçalho
          Container (
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF042044),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                topRight: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 10),
                    onPressed: widget.onClose,
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(10),
              children: [
                // Humor
                const Text(
                  'Humor:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _MoodSelector(
                  dateStr: dateStr,
                  currentMood: dayData?.mood,
                ),

                const SizedBox(height: 20),

                // Energia
                const Text(
                  'Energia:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _EnergySelector(
                  dateStr: dateStr,
                  currentEnergy: dayData?.energy,
                ),

                const SizedBox(height: 20),


                const Text(
                  '📝 Anotações do dia:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  key: ValueKey('notes_$dateStr'),
                  controller: controller,
                  maxLines: 8,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF021328),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText:
                        'Horário de início / Horário de término - Lista/Livro - Pág...',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  onChanged: _saveNotes,
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '📚 Rotina de Estudos do Dia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis, 
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageSubjectsScreen(
                              date: widget.selectedDate,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Adicionar matérias',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Lista de matérias ou mensagem vazia
                if (subjects.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray.withValues(alpha:0.3),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: AppTheme.lightGray),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.book_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nenhuma matéria agendada para hoje',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adicione matérias usando o botão acima',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...subjects.map((subject) {
                    final subjectProgress =
                        dayData?.studyProgress[subject.id] ?? [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SubjectCard(
                        subject: subject,
                        dateStr: dateStr,
                        completedSessions: subjectProgress,
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Botão para adicionar mais matérias
                if (subjects.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageSubjectsScreen(
                            date: widget.selectedDate,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Adicionar mais matérias'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  final String dateStr;
  final int? currentMood;

  const _MoodSelector({
    required this.dateStr,
    required this.currentMood,
  });

  @override
  Widget build(BuildContext context) {
    final calendarService = context.read<CalendarService>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isActive = currentMood == value;
        return Flexible(
          child: _EmojiButton(
            emoji: ['😞', '😕', '😊', '😄', '🤩'][index],
            isActive: isActive,
            onTap: () {
              calendarService.updateMood(dateStr, value);
            },
          ),
        );
      }),
    );
  }
}

class _EnergySelector extends StatelessWidget {
  final String dateStr;
  final int? currentEnergy;

  const _EnergySelector({
    required this.dateStr,
    required this.currentEnergy,
  });

  @override
  Widget build(BuildContext context) {
    final calendarService = context.read<CalendarService>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final value = index + 1;
        final isActive = currentEnergy == value;
        return Flexible(
          child: _EmojiButton(
            emoji: ['🪫', '🔋', '🔋', '🔋', '⚡'][index],
            isActive: isActive,
            onTap: () {
              calendarService.updateEnergy(dateStr, value);
            },
          ),
        );
      }),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha:0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFFFF8000) : AppTheme.primaryColor,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 28,
              color: isActive ? null : Colors.white.withValues(alpha:0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final dynamic subject;
  final String dateStr;
  final List<StudySession> completedSessions;

  const _SubjectCard({
    required this.subject,
    required this.dateStr,
    required this.completedSessions,
  });

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final goalsService = context.read<MonthlyGoalsService>();
    final color = AppTheme.getSubjectColor(subject.name);
    final totalSessions = subject.sessions;

    // Calcular sessões completadas e questões
    final completedCount = completedSessions.length;
    final totalQuestions = completedSessions.fold(
        0, (sum, session) => sum + session.questionCount);

    final progress = totalSessions > 0 ? completedCount / totalSessions : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF021328),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da matéria
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sessões: $completedCount/$totalSessions • Questões: $totalQuestions',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha:0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Barra de progresso
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withValues(alpha:0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),

          // Sessões com contador de questões
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              children: List.generate(totalSessions, (index) {
                final sessionNumber = index + 1;
                final session = completedSessions.firstWhere(
                  (s) => s.sessionNumber == sessionNumber,
                  orElse: () => StudySession(sessionNumber, questionCount: 0),
                );

                final isCompleted = completedSessions
                    .any((s) => s.sessionNumber == sessionNumber);

                return _SessionWidget(
                  sessionNumber: sessionNumber,
                  isCompleted: isCompleted,
                  questionCount: session.questionCount,
                  color: color,
                  onToggleSession: () {
                    calendarService.toggleStudySession(
                      dateStr,
                      subject.id,
                      sessionNumber,
                    );
                  },
                  onUpdateQuestionCount: (change) {
                    final newCount =
                        (session.questionCount + change).clamp(0, 999);
                    calendarService.updateQuestionCount(
                      dateStr,
                      subject.id,
                      sessionNumber,
                      newCount,
                    );

                    // Atualizar questões mensais
                    if (change != 0) {
                      goalsService.updateSubjectQuestions(subject.name, change);
                    }
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionWidget extends StatelessWidget {
  final int sessionNumber;
  final bool isCompleted;
  final int questionCount;
  final Color color;
  final VoidCallback onToggleSession;
  final Function(int) onUpdateQuestionCount;

  const _SessionWidget({
    required this.sessionNumber,
    required this.isCompleted,
    required this.questionCount,
    required this.color,
    required this.onToggleSession,
    required this.onUpdateQuestionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Botão da sessão
        InkWell(
          onTap: onToggleSession,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCompleted ? color : AppTheme.lightGray,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '$sessionNumber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),

        // Contador de questões (apenas se sessão completada)
        if (isCompleted) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, size: 14, color: color),
                  onPressed: () => onUpdateQuestionCount(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                Text(
                  '$questionCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add, size: 14, color: color),
                  onPressed: () => onUpdateQuestionCount(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

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
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final calendarService = context.read<CalendarService>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final dayData = calendarService.getDayData(dateStr);
    _notesController = TextEditingController(text: dayData?.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
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

    // Formatar data corretamente
    final formattedDate =
        DateFormat("d 'de' MMMM, EEEE", 'pt_BR').format(widget.selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF042044),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(20),
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
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: widget.onClose,
                    color: Colors.black,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo scrollável
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(20),
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

                const SizedBox(height: 24),

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

                const SizedBox(height: 24),

                // Anotações
                const Text(
                  '📝 Anotações do dia:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    fillColor: const Color(0xFF021328),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Adicione suas anotações aqui...',
                    hintStyle:
                        const TextStyle(fontSize: 14, color: Colors.white54),
                  ),
                  onChanged: _saveNotes,
                ),

                const SizedBox(height: 24),

                // Rotina de Estudos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📚 Rotina de Estudos do Dia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                      color: AppTheme.lightGray.withOpacity(0.3),
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
                        completedSessions: subjectProgress.length,
                        dateStr: dateStr,
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
          // ← ADICIONE AQUI
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
        return Flexible( // ← ADICIONE AQUI
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
              ? AppTheme.primaryColor.withOpacity(0.1)
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
              color: isActive ? null : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final dynamic subject;
  final int completedSessions;
  final String dateStr;

  const _SubjectCard({
    required this.subject,
    required this.completedSessions,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    final calendarService = context.watch<CalendarService>();
    final color = AppTheme.getSubjectColor(subject.name);
    final totalSessions = subject.sessions;
    final progress =
        totalSessions > 0 ? completedSessions / totalSessions : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF021328),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  '$completedSessions/$totalSessions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
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
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),

          // Sessões
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(totalSessions, (index) {
                final sessionNumber = index + 1;
                final isCompleted = completedSessions >= sessionNumber;

                return InkWell(
                  onTap: () {
                    calendarService.toggleStudySession(
                      dateStr,
                      subject.id,
                      sessionNumber,
                    );
                  },
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
                          color: isCompleted
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

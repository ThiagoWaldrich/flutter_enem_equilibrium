import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/enhanced_database_service.dart';
import '../../core/theme/constants.dart';
import '../../core/theme/theme.dart';
import '../../calendar/widgets/schedule_cell.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> 
    with AutomaticKeepAliveClientMixin {
  List<String> _timeSlots = [];
  List<List<ScheduleCell>> _schedule = [];
  bool _isEditingTimes = false;
  bool _isLoading = true;
  final TextEditingController _timeController = TextEditingController();
  int? _editingTimeIndex;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _timeSlots = List.from(AppConstants.defaultTimeSlots);
    _initializeEmptySchedule();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedule();
    });
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  void _initializeEmptySchedule() {
    _schedule = List.generate(
      AppConstants.weekDays.length,
      (dayIndex) => List.generate(
        _timeSlots.length,
        (timeIndex) => ScheduleCell(
          dayIndex: dayIndex,
          timeIndex: timeIndex,
          subject: '',
          color: Colors.transparent,
        ),
      ),
    );
  }

  Future<void> _loadSchedule() async {
    try {
      final db = context.read<EnhancedDatabaseService>();
      final savedSchedule = await db.getWeeklyScheduleWithCells();

      if (!mounted) return;

      setState(() {
        if (savedSchedule['timeSlots'] != null && 
            (savedSchedule['timeSlots'] as List).isNotEmpty) {
          _timeSlots = List<String>.from(savedSchedule['timeSlots']);
        }
        
        if (savedSchedule['schedule'] != null && 
            (savedSchedule['schedule'] as List).isNotEmpty) {
          _schedule = List<List<ScheduleCell>>.from(savedSchedule['schedule']);
        } else {
          _schedule = List.generate(
            AppConstants.weekDays.length,
            (dayIndex) => List.generate(
              _timeSlots.length,
              (timeIndex) => ScheduleCell(
                dayIndex: dayIndex,
                timeIndex: timeIndex,
                subject: '',
                color: Colors.transparent,
              ),
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar horários: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _editTimeSlot(int index) {
    setState(() {
      _isEditingTimes = true;
      _editingTimeIndex = index;
      _timeController.text = _timeSlots[index];
    });
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add('22:00');
      for (var daySchedule in _schedule) {
        daySchedule.add(ScheduleCell(
          dayIndex: _schedule.indexOf(daySchedule),
          timeIndex: _timeSlots.length - 1,
          subject: '',
          color: Colors.transparent,
        ));
      }
    });
  }

  void _removeTimeSlot(int index) {
    if (_timeSlots.length <= 1) return;

    setState(() {
      _timeSlots.removeAt(index);
      for (var daySchedule in _schedule) {
        daySchedule.removeAt(index);
        for (var i = 0; i < daySchedule.length; i++) {
          daySchedule[i] = daySchedule[i].copyWith(timeIndex: i);
        }
      }
    });
  }

  void _saveTimeSlot() {
    if (_editingTimeIndex != null) {
      final time = _timeController.text.trim();
      if (time.isNotEmpty) {
        setState(() {
          _timeSlots[_editingTimeIndex!] = time;
        });
      }
    }
    _cancelTimeEdit();
  }

  void _cancelTimeEdit() {
    setState(() {
      _isEditingTimes = false;
      _editingTimeIndex = null;
      _timeController.clear();
    });
  }

  void _editCell(int dayIndex, int timeIndex) {
    showDialog(
      context: context,
      builder: (context) => _EditCellDialog(
        currentSubject: _schedule[dayIndex][timeIndex].subject,
        currentColor: _schedule[dayIndex][timeIndex].color,
        onSave: (subject, color) {
          setState(() {
            _schedule[dayIndex][timeIndex] =
                _schedule[dayIndex][timeIndex].copyWith(
              subject: subject,
              color: color,
            );
          });
        },
      ),
    );
  }

  Future<void> _saveSchedule() async {
    try {
      final db = context.read<EnhancedDatabaseService>();
      await db.saveWeeklyScheduleWithCells(
        timeSlots: _timeSlots,
        schedule: _schedule,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Horários salvos com sucesso!'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao salvar: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _clearDay(int dayIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Limpar Dia'),
          ],
        ),
        content: Text(
          'Deseja limpar todos os horários de ${AppConstants.weekDays[dayIndex]}?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                for (var i = 0; i < _timeSlots.length; i++) {
                  _schedule[dayIndex][i] = _schedule[dayIndex][i].copyWith(
                    subject: '',
                    color: Colors.transparent,
                  );
                }
              });
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Horários Semanais'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horários Semanais'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _saveSchedule,
            tooltip: 'Salvar Horários',
          ),
          IconButton(
            icon: Icon(
              _isEditingTimes ? Icons.check_rounded : Icons.edit_calendar_rounded,
            ),
            onPressed: _isEditingTimes
                ? _cancelTimeEdit
                : () => setState(() => _isEditingTimes = !_isEditingTimes),
            tooltip: _isEditingTimes ? 'Cancelar Edição' : 'Editar Horários',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _schedule.isEmpty || _timeSlots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.secondaryContainer,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellWidth = (constraints.maxWidth - 100) / AppConstants.weekDays.length;
                      
                      return Row(
                        children: [
                          Container(
                            width: 100,
                            alignment: Alignment.center,
                            child: const Icon(Icons.schedule_rounded, size: 20),
                          ),
                          ...List.generate(
                            AppConstants.weekDays.length,
                            (dayIndex) => SizedBox(
                              width: cellWidth,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Card(
                                  elevation: 0,
                                  color: Colors.white.withValues(alpha:0.9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          AppConstants.weekDays[dayIndex],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: cellWidth > 100 ? 13 : 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                                        onPressed: () => _clearDay(dayIndex),
                                        tooltip: 'Limpar',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellWidth = (constraints.maxWidth - 100) / AppConstants.weekDays.length;
                      final cellHeight = constraints.maxHeight / _timeSlots.length;
                      
                      return Column(
                        children: List.generate(
                          _timeSlots.length,
                          (timeIndex) => Container(
                            height: cellHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Colors.grey[100]!,
                                        Colors.grey[50]!,
                                      ],
                                    ),
                                  ),
                                  child: _isEditingTimes && _editingTimeIndex == timeIndex
                                      ? TextFormField(
                                          controller: _timeController,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: cellHeight > 60 ? 15 : 12,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                          ),
                                          onFieldSubmitted: (_) => _saveTimeSlot(),
                                        )
                                      : InkWell(
                                          onTap: _isEditingTimes
                                              ? () => _editTimeSlot(timeIndex)
                                              : null,
                                          borderRadius: BorderRadius.circular(8),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _isEditingTimes 
                                                  ? Colors.blue[50]
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _timeSlots[timeIndex],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: cellHeight > 60 ? 15 : 12,
                                                  ),
                                                ),
                                                if (_isEditingTimes && _timeSlots.length > 1 && cellHeight > 50)
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete_outline_rounded,
                                                      size: cellHeight > 60 ? 16 : 12,
                                                      color: Colors.red[400],
                                                    ),
                                                    onPressed: () => _removeTimeSlot(timeIndex),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ),
                                

                                ...List.generate(
                                  AppConstants.weekDays.length,
                                  (dayIndex) {
                                    if (dayIndex >= _schedule.length || 
                                        timeIndex >= _schedule[dayIndex].length) {
                                      return SizedBox(width: cellWidth);
                                    }
                                    
                                    final cell = _schedule[dayIndex][timeIndex];
                                    final hasContent = cell.subject.isNotEmpty;
                                    
                                    return SizedBox(
                                      width: cellWidth,
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _editCell(dayIndex, timeIndex),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: hasContent
                                                    ? LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          cell.color.withValues(alpha:0.3),
                                                          cell.color.withValues(alpha:0.15),
                                                        ],
                                                      )
                                                    : null,
                                                color: hasContent ? null : Colors.grey[50],
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: hasContent 
                                                      ? cell.color.withValues(alpha:0.4)
                                                      : Colors.grey[300]!,
                                                  width: 1.5,
                                                ),
                                                boxShadow: hasContent
                                                    ? [
                                                        BoxShadow(
                                                          color: cell.color.withValues(alpha:0.2),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              alignment: Alignment.center,
                                              padding: EdgeInsets.all(cellHeight > 60 ? 8 : 4),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  hasContent ? cell.subject : '+',
                                                  textAlign: TextAlign.center,
                                                  maxLines: cellHeight > 60 ? 2 : 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: hasContent 
                                                        ? Colors.black87 
                                                        : Colors.grey[400],
                                                    fontSize: hasContent 
                                                        ? (cellHeight > 60 ? 13 : 11) 
                                                        : (cellHeight > 60 ? 20 : 16),
                                                    fontWeight: hasContent 
                                                        ? FontWeight.w500 
                                                        : FontWeight.w300,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),


                if (_isEditingTimes)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Adicionar'),
                            onPressed: _addTimeSlot,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Concluir'),
                            onPressed: _saveTimeSlot,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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

class _EditCellDialog extends StatefulWidget {
  final String currentSubject;
  final Color currentColor;
  final Function(String subject, Color color) onSave;

  const _EditCellDialog({
    required this.currentSubject,
    required this.currentColor,
    required this.onSave,
  });

  @override
  State<_EditCellDialog> createState() => __EditCellDialogState();
}

class __EditCellDialogState extends State<_EditCellDialog> {
  late TextEditingController _subjectController;
  late Color _selectedColor;
  
  final List<Color> _colorOptions = [
    const Color(0xFF6366F1), 
    const Color(0xFF8B5CF6), 
    const Color(0xFFEC4899), 
    const Color(0xFFEF4444), 
    const Color(0xFFF59E0B), 
    const Color(0xFF10B981), 
    const Color(0xFF06B6D4), 
    const Color(0xFF3B82F6), 
    const Color(0xFF14B8A6), 
    const Color(0xFF84CC16), 
  ];

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.currentSubject);
    _selectedColor = widget.currentColor == Colors.transparent 
        ? _colorOptions[0] 
        : widget.currentColor;
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.edit_calendar_rounded, size: 24),
          SizedBox(width: 12),
          Text('Editar Horário'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Matéria/Atividade',
                hintText: 'Ex: Matemática, Descanso...',
                prefixIcon: const Icon(Icons.book_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            const Text(
              'Escolha uma cor',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () {
            widget.onSave(_subjectController.text.trim(), _selectedColor);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.check_rounded),
          label: const Text('Salvar'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../calendar/logic/calendar_service.dart';
import '../models/subject.dart';
import '../../core/theme/constants.dart';
import '../../core/theme/theme.dart';

class ManageSubjectsScreen extends StatefulWidget {
  final DateTime date;

  const ManageSubjectsScreen({
    super.key,
    required this.date,
  });

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  String? _selectedSubject;
  int _sessions = 1;
  late List<Subject> _subjects;

  @override
void initState() {
  super.initState();
  final calendarService = context.read<CalendarService>();
  final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
  _subjects = List.from(calendarService.getDaySubjects(dateStr));
}

  void _addSubject() {
    if (_selectedSubject == null || _selectedSubject!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma matéria!')),
      );
      return;
    }

    if (_subjects.any((s) => s.name == _selectedSubject)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta matéria já foi adicionada!')),
      );
      return;
    }

    setState(() {
      _subjects.add(Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _selectedSubject!,
        sessions: _sessions,
      ));
      _selectedSubject = null;
      _sessions = 1;
    });
  }

  void _editSubject(int index) async {
    final subject = _subjects[index];
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _EditSessionsDialog(
        subjectName: subject.name,
        currentSessions: subject.sessions,
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        _subjects[index] = subject.copyWith(sessions: result);
      });
    }
  }

  void _deleteSubject(int index) {
    final subject = _subjects[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Matéria'),
        content: Text('Tem certeza que deseja excluir "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _subjects.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Excluir',
                style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }

  void _resetToDefault() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar Matérias Padrão'),
        content: const Text(
          'Deseja usar as matérias padrão para este dia? '
          'Isso substituirá suas matérias atuais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final calendarService = context.read<CalendarService>();
                _subjects = List.from(calendarService.getDefaultSubjects());
              });
              Navigator.pop(context);
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _save() async {
    final calendarService = context.read<CalendarService>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    await calendarService.saveCustomSubjects(dateStr, _subjects);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matérias salvas com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d/MM/yyyy').format(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Matérias - $formattedDate'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Matérias da Rotina de Estudos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Alterações feitas aqui afetam apenas este dia específico.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (_subjects.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Nenhuma matéria cadastrada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._subjects.asMap().entries.map((entry) {
              final index = entry.key;
              final subject = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(subject.name),
                  subtitle: Text(
                      '${subject.sessions} sess${subject.sessions != 1 ? 'ões' : 'ão'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editSubject(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: AppTheme.dangerColor),
                        onPressed: () => _deleteSubject(index),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),
          Card(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Adicionar Nova Matéria',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Matéria',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.predefinedSubjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject['name'] as String,
                        child: Text('${subject['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSubject = value;
                        if (value != null) {
                          final subject = AppConstants.predefinedSubjects
                              .firstWhere((s) => s['name'] == value);
                          _sessions = subject['sessions'] as int;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _sessions.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Número de Sessões',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _sessions = int.tryParse(value) ?? 1;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addSubject,
                      child: const Text('Adicionar'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetToDefault,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                  ),
                  child: const Text('Restaurar Padrão'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvar Alterações'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditSessionsDialog extends StatefulWidget {
  final String subjectName;
  final int currentSessions;

  const _EditSessionsDialog({
    required this.subjectName,
    required this.currentSessions,
  });

  @override
  State<_EditSessionsDialog> createState() => _EditSessionsDialogState();
}

class _EditSessionsDialogState extends State<_EditSessionsDialog> {
  late int _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = widget.currentSessions;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar ${widget.subjectName}'),
      content: TextFormField(
        initialValue: _sessions.toString(),
        decoration: const InputDecoration(
          labelText: 'Número de Sessões',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          _sessions = int.tryParse(value) ?? 1;
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _sessions),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

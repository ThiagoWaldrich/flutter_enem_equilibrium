import 'package:equilibrium/features/core/services/enhanced_database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../../goals/models/study_topic.dart';
import '../../core/theme/constants.dart';
import '../../core/theme/theme.dart';

class ManageSubjectsWithTopicsScreen extends StatefulWidget {
  final DateTime date;

  const ManageSubjectsWithTopicsScreen({
    super.key,
    required this.date,
  });

  @override
  State<ManageSubjectsWithTopicsScreen> createState() => _ManageSubjectsWithTopicsScreenState();
}

class _ManageSubjectsWithTopicsScreenState extends State<ManageSubjectsWithTopicsScreen> {
  List<SubjectWithTopics> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    
    final db = context.read<EnhancedDatabaseService>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    
    final subjects = await db.getDaySubjects(dateStr);
    final subjectsWithTopics = <SubjectWithTopics>[];
    
    for (final subject in subjects) {
      final topics = await db.getSubjectTopics(subject.id);
      subjectsWithTopics.add(SubjectWithTopics(
        subject: subject,
        topics: topics,
      ));
    }
    
    setState(() {
      _subjects = subjectsWithTopics;
      _isLoading = false;
    });
  }

  void _addSubject() {
    showDialog(
      context: context,
      builder: (context) => _AddSubjectDialog(
        onAdd: (subjectWithTopics) {
          setState(() {
            _subjects.add(subjectWithTopics);
          });
        },
      ),
    );
  }

  void _editSubject(int index) {
    showDialog(
      context: context,
      builder: (context) => _EditSubjectDialog(
        subjectWithTopics: _subjects[index],
        onUpdate: (updated) {
          setState(() {
            _subjects[index] = updated;
          });
        },
      ),
    );
  }

  void _deleteSubject(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Matéria'),
        content: Text('Tem certeza que deseja excluir "${_subjects[index].subject.name}"?'),
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
            child: const Text('Excluir', style: TextStyle(color: AppTheme.dangerColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final db = context.read<EnhancedDatabaseService>();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);
    
    final subjects = _subjects.map((s) => s.subject).toList();
    final topicsBySubject = <String, List<StudyTopic>>{};
    
    for (final s in _subjects) {
      topicsBySubject[s.subject.id] = s.topics;
    }
    
    await db.saveDaySubjectsWithTopics(dateStr, subjects, topicsBySubject);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matérias e tópicos salvos com sucesso!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d/MM/yyyy').format(widget.date);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Gerenciar - $formattedDate')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar - $formattedDate'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addSubject,
            tooltip: 'Adicionar Matéria',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhuma matéria cadastrada',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addSubject,
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar Matéria'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _subjects.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _subjects.removeAt(oldIndex);
                        _subjects.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final subjectWithTopics = _subjects[index];
                      return _SubjectCard(
                        key: ValueKey(subjectWithTopics.subject.id),
                        subjectWithTopics: subjectWithTopics,
                        onEdit: () => _editSubject(index),
                        onDelete: () => _deleteSubject(index),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Salvar Alterações'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectWithTopics {
  final Subject subject;
  final List<StudyTopic> topics;

  SubjectWithTopics({
    required this.subject,
    required this.topics,
  });

  SubjectWithTopics copyWith({
    Subject? subject,
    List<StudyTopic>? topics,
  }) {
    return SubjectWithTopics(
      subject: subject ?? this.subject,
      topics: topics ?? this.topics,
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectWithTopics subjectWithTopics;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    super.key,
    required this.subjectWithTopics,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final subject = subjectWithTopics.subject;
    final topics = subjectWithTopics.topics;
    final color = AppTheme.getSubjectColor(subject.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.book, color: color),
            ),
            title: Text(
              subject.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${subject.sessions} sess${subject.sessions != 1 ? 'ões' : 'ão'} • ${topics.length} tópico${topics.length != 1 ? 's' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.infoColor),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppTheme.dangerColor),
                  onPressed: onDelete,
                ),
                const Icon(Icons.drag_handle, color: Colors.grey),
              ],
            ),
          ),
          if (topics.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics.map((topic) {
                  return Chip(
                    label: Text(
                      '${topic.topic} (${topic.sessions})',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: color.withValues(alpha:0.1),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// ========== DIALOGS ==========
class _AddSubjectDialog extends StatefulWidget {
  final Function(SubjectWithTopics) onAdd;

  const _AddSubjectDialog({required this.onAdd});

  @override
  State<_AddSubjectDialog> createState() => _AddSubjectDialogState();
}

class _AddSubjectDialogState extends State<_AddSubjectDialog> {
  String? _selectedSubject;
  int _sessions = 1;
  final List<TopicEntry> _topics = [];

  void _addTopic() {
    showDialog(
      context: context,
      builder: (context) => _AddTopicDialog(
        onAdd: (topic, sessions) {
          setState(() {
            _topics.add(TopicEntry(topic: topic, sessions: sessions));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Adicionar Matéria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Matéria',
                      border: OutlineInputBorder(),
                    ),
                    items: AppConstants.predefinedSubjects
                        .map((s) => s['name'] as String)
                        .toSet()
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSubject = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _sessions.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Sessões Totais',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _sessions = int.tryParse(value) ?? 1,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tópicos:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addTopic,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar Tópico'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._topics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final topic = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text(topic.topic),
                        subtitle: Text('${topic.sessions} sess${topic.sessions != 1 ? 'ões' : 'ão'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              _topics.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedSubject == null) return;
                    
                    final subject = Subject(
                      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
                      name: _selectedSubject!,
                      sessions: _sessions,
                    );
                    
                    final topics = _topics.map((t) => StudyTopic(
                      id: 'topic_${DateTime.now().millisecondsSinceEpoch}_${_topics.indexOf(t)}',
                      subjectId: subject.id,
                      topic: t.topic,
                      sessions: t.sessions,
                    )).toList();
                    
                    widget.onAdd(SubjectWithTopics(
                      subject: subject,
                      topics: topics,
                    ));
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Adicionar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSubjectDialog extends StatefulWidget {
  final SubjectWithTopics subjectWithTopics;
  final Function(SubjectWithTopics) onUpdate;

  const _EditSubjectDialog({
    required this.subjectWithTopics,
    required this.onUpdate,
  });

  @override
  State<_EditSubjectDialog> createState() => _EditSubjectDialogState();
}

class _EditSubjectDialogState extends State<_EditSubjectDialog> {
  late int _sessions;
  late List<TopicEntry> _topics;

  @override
  void initState() {
    super.initState();
    _sessions = widget.subjectWithTopics.subject.sessions;
    _topics = widget.subjectWithTopics.topics
        .map((t) => TopicEntry(topic: t.topic, sessions: t.sessions))
        .toList();
  }

  void _addTopic() {
    showDialog(
      context: context,
      builder: (context) => _AddTopicDialog(
        onAdd: (topic, sessions) {
          setState(() {
            _topics.add(TopicEntry(topic: topic, sessions: sessions));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.subjectWithTopics.subject.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    initialValue: _sessions.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Sessões Totais',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _sessions = int.tryParse(value) ?? 1,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tópicos:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addTopic,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._topics.asMap().entries.map((entry) {
                    final index = entry.key;
                    final topic = entry.value;
                    return Card(
                      child: ListTile(
                        title: Text(topic.topic),
                        subtitle: Text('${topic.sessions} sess${topic.sessions != 1 ? 'ões' : 'ão'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () {
                            setState(() {
                              _topics.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final subject = widget.subjectWithTopics.subject.copyWith(
                      sessions: _sessions,
                    );
                    
                    final topics = _topics.map((t) => StudyTopic(
                      id: 'topic_${DateTime.now().millisecondsSinceEpoch}_${_topics.indexOf(t)}',
                      subjectId: subject.id,
                      topic: t.topic,
                      sessions: t.sessions,
                    )).toList();
                    
                    widget.onUpdate(SubjectWithTopics(
                      subject: subject,
                      topics: topics,
                    ));
                    
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTopicDialog extends StatefulWidget {
  final Function(String topic, int sessions) onAdd;

  const _AddTopicDialog({required this.onAdd});

  @override
  State<_AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<_AddTopicDialog> {
  final _topicController = TextEditingController();
  int _sessions = 1;

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar Tópico'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Nome do Tópico',
              hintText: 'Ex: Geometria Plana',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Número de Sessões',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) => _sessions = int.tryParse(value) ?? 1,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_topicController.text.isNotEmpty) {
              widget.onAdd(_topicController.text, _sessions);
              Navigator.pop(context);
            }
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class TopicEntry {
  final String topic;
  final int sessions;

  TopicEntry({
    required this.topic,
    required this.sessions,
  });
}
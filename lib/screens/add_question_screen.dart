// lib/screens/add_question_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _correctAnswerController = TextEditingController();

  // Estado
  String? _selectedSubjectId;
  String? _selectedTopicId;
  String? _selectedSourceId;
  String? _selectedYearId;
  File? _selectedImage;
  int _difficultyLevel = 3;

  // Listas
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _years = [];

  bool _isLoading = true;
  bool _loadingTopics = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _subjects = await SupabaseService.getSubjects();
      _sources = await SupabaseService.getSources();
      _years = await SupabaseService.getExamYears();

      // DEBUG: Verificar se há matérias
      if (_subjects.isEmpty) {
        print('⚠️ Nenhuma matéria encontrada');
      } else {
        print('✅ Matérias carregadas: ${_subjects.length}');
        for (var subject in _subjects) {
          print('   - ${subject['name']} (ID: ${subject['id']})');
        }
        
        // DEBUG: Opcional - Rodar diagnóstico
        // await SupabaseService.debugSubjectTopicRelation();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTopics(String? subjectId) async {
    if (subjectId == null) {
      setState(() {
        _topics.clear();
        _selectedTopicId = null;
        _loadingTopics = false;
      });
      return;
    }

    try {
      setState(() => _loadingTopics = true);
      
      print('🔄 Carregando tópicos para matéria ID: $subjectId');
      
      // Encontrar o nome da matéria para debug
      final subject = _subjects.firstWhere(
        (s) => s['id'] == subjectId,
        orElse: () => {'name': 'Desconhecida'},
      );
      print('   Matéria selecionada: ${subject['name']}');

      final topics = await SupabaseService.getTopicsBySubject(subjectId);
      
      setState(() {
        _topics = topics;
        _selectedTopicId = null;
        _loadingTopics = false;
      });
      
      if (_topics.isEmpty) {
        print('ℹ️ Nenhum tópico encontrado para ${subject['name']}');
      } else {
        print('✅ Tópicos carregados: ${_topics.length}');
      }
    } catch (e) {
      print('Erro ao carregar tópicos: $e');
      setState(() {
        _topics = [];
        _selectedTopicId = null;
        _loadingTopics = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma matéria')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        String sourceName = 'custom';
        String year = DateTime.now().year.toString();

        if (_selectedSourceId != null) {
          final selectedSource = _sources.firstWhere(
            (s) => s['id'] == _selectedSourceId,
            orElse: () => {},
          );
          if (selectedSource.isNotEmpty) {
            sourceName = selectedSource['name']
                    ?.toString()
                    .replaceAll(' ', '_') ??
                'custom';
          }
        }

        if (_selectedYearId != null) {
          final selectedYear = _years.firstWhere(
            (y) => y['id'] == _selectedYearId,
            orElse: () => {},
          );
          if (selectedYear.isNotEmpty) {
            year = selectedYear['year']?.toString() ?? year;
          }
        }

        // Número 1 como padrão para nome do arquivo
        imageUrl = await SupabaseService.uploadQuestionImage(
          imageFile: _selectedImage!,
          sourceName: sourceName,
          year: year,
          questionNumber: 1,
        );
      }

      final questionData = {
        'subject_id': _selectedSubjectId,
        'topic_id': _selectedTopicId,
        'source_id': _selectedSourceId,
        'year_id': _selectedYearId,
        'correct_answer': _correctAnswerController.text.toUpperCase(),
        'image_url': imageUrl,
        'difficulty_level': _difficultyLevel,
      };

      await SupabaseService.addQuestion(questionData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Questão adicionada com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // LIMPAR FORMULÁRIO APÓS SALVAR COM SUCESSO
      await Future.delayed(const Duration(milliseconds: 500));
      _resetForm();
      
    } catch (e) {
      print('Erro ao salvar questão: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    print('🧹 Limpando formulário...');
    
    // Limpa controladores
    _correctAnswerController.clear();
    
    // Limpa estado
    setState(() {
      _selectedSubjectId = null;
      _selectedTopicId = null;
      _selectedSourceId = null;
      _selectedYearId = null;
      _selectedImage = null;
      _difficultyLevel = 3;
      _topics.clear();
      _loadingTopics = false;
    });
    
    // Limpa validação do formulário
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
    
    // Força reconstrução
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ Adicionar Questão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _submitQuestion,
            tooltip: 'Salvar questão',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Matéria *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Selecione uma matéria',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ..._subjects.map((subject) {
                          return DropdownMenuItem<String>(
                            value: subject['id'],
                            child: Text(subject['name']),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSubjectId = value;
                          _selectedTopicId = null;
                          _topics.clear();
                        });
                        if (value != null) {
                          _loadTopics(value);
                        }
                      },
                      validator: (value) {
                        if (value == null) return 'Selecione uma matéria';
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedTopicId,
                              isExpanded: true,
                              underline: const SizedBox(),
                              hint: _selectedSubjectId == null
                                  ? const Text(
                                      'Selecione uma matéria primeiro',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  : _loadingTopics
                                      ? const Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Carregando tópicos...',
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        )
                                      : _topics.isEmpty
                                          ? const Text(
                                              'Nenhum tópico disponível',
                                              style: TextStyle(
                                                  color: Colors.grey),
                                            )
                                          : const Text('Selecione um tópico'),
                              items: _buildTopicDropdownItems(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedTopicId = value;
                                });
                              },
                            ),
                          ),
                          if (_loadingTopics)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSourceId,
                            decoration: const InputDecoration(
                              labelText: 'Fonte (opcional)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Selecione uma fonte',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              ..._sources.map((source) {
                                return DropdownMenuItem<String>(
                                  value: source['id'],
                                  child: Text(
                                      '${source['name']} (${source['type']})'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSourceId = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedYearId,
                            decoration: const InputDecoration(
                              labelText: 'Ano (opcional)',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Selecione um ano',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                              ..._years.map((year) {
                                return DropdownMenuItem<String>(
                                  value: year['id'],
                                  child: Text(year['year'].toString()),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedYearId = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _correctAnswerController,
                      decoration: const InputDecoration(
                        labelText: 'Resposta Correta (A, B, C, D, E) *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.check_circle_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a resposta correta';
                        }
                        final upperValue = value.toUpperCase();
                        if (!['A', 'B', 'C', 'D', 'E'].contains(upperValue)) {
                          return 'A resposta deve ser A, B, C, D ou E';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: _difficultyLevel,
                      decoration: const InputDecoration(
                        labelText: 'Dificuldade',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.bar_chart),
                      ),
                      items: [1, 2, 3, 4, 5].map((level) {
                        final labels = [
                          'Muito Fácil',
                          'Fácil',
                          'Médio',
                          'Difícil',
                          'Muito Difícil'
                        ];
                        final colors = [
                          Colors.green,
                          Colors.lightGreen,
                          Colors.amber,
                          Colors.orange,
                          Colors.red
                        ];
                        return DropdownMenuItem<int>(
                          value: level,
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 12, color: colors[level - 1]),
                              const SizedBox(width: 8),
                              Text('$level - ${labels[level - 1]}'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _difficultyLevel = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.image, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Imagem da Questão',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Adicione uma imagem do enunciado, se necessário',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (_selectedImage != null)
                              Column(
                                children: [
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _selectedImage!,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.black54,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 14,
                                                color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _selectedImage = null;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Selecionar Imagem'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[50],
                                      foregroundColor: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _submitQuestion,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(width: 12),
                                Text('Salvando...'),
                              ],
                            )
                          : const Text(
                              'SALVAR QUESTÃO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetForm,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(color: Colors.orange[300]!),
                              foregroundColor: Colors.orange[700],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cleaning_services, size: 20),
                                SizedBox(width: 8),
                                Text('LIMPAR FORMULÁRIO'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: const Text('CANCELAR'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<DropdownMenuItem<String>> _buildTopicDropdownItems() {
    final items = <DropdownMenuItem<String>>[];

    if (_selectedSubjectId == null) {
      return items;
    }

    if (_loadingTopics) {
      return items;
    }

    if (_topics.isEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          value: null,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Nenhum tópico disponível',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    } else {
      items.add(
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Selecione um tópico (opcional)'),
        ),
      );

      items.addAll(
        _topics.map((topic) {
          return DropdownMenuItem<String>(
            value: topic['id'],
            child: Text(topic['name']),
          );
        }),
      );
    }

    return items;
  }

  @override
  void dispose() {
    _correctAnswerController.dispose();
    super.dispose();
  }
}
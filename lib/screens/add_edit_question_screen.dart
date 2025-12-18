// lib/screens/add_edit_question_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class AddEditQuestionScreen extends StatefulWidget {
  final Map<String, dynamic>? questionToEdit;
  
  const AddEditQuestionScreen({
    super.key,
    this.questionToEdit,
  });

  @override
  State<AddEditQuestionScreen> createState() => _AddEditQuestionScreenState();
}

class _AddEditQuestionScreenState extends State<AddEditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _correctAnswerController = TextEditingController();

  // Estado
  String? _selectedSubjectId;
  String? _selectedTopicId;
  String? _selectedSourceId;
  String? _selectedYearId;
  File? _selectedImage;
  File? _selectedAnswerImage;
  int _difficultyLevel = 3;
  
  // Para rastrear se estamos editando
  bool _isEditing = false;
  String? _editingQuestionId;
  
  // URLs das imagens existentes
  String? _existingImageUrl;
  String? _existingAnswerImageUrl;
  
  // Listas
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _sources = [];
  List<Map<String, dynamic>> _years = [];

  bool _isLoading = true;
  bool _loadingTopics = false;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.questionToEdit != null;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [subjects, sources, years] = await Future.wait([
        SupabaseService.getSubjects(),
        SupabaseService.getSources(),
        SupabaseService.getExamYears(),
      ]);

      setState(() {
        _subjects = subjects;
        _sources = sources;
        _years = years;
      });

      // Se estiver editando, carregar dados da questão
      if (_isEditing && widget.questionToEdit != null) {
        await _loadQuestionData(widget.questionToEdit!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadQuestionData(Map<String, dynamic> question) async {
    try {
      _editingQuestionId = question['id'];
      
      // Preencher campos
      _correctAnswerController.text = question['correct_answer']?.toString() ?? '';
      
      // Preencher IDs
      _selectedSubjectId = question['subject_id'];
      _selectedSourceId = question['source_id'];
      _selectedYearId = question['year_id'];
      _selectedTopicId = question['topic_id'];
      _difficultyLevel = question['difficulty_level'] ?? 3;
      
      // Salvar URLs das imagens existentes
      _existingImageUrl = question['image_url'];
      _existingAnswerImageUrl = question['answer_image_url'];
      
      // Carregar tópicos da matéria selecionada
      if (_selectedSubjectId != null) {
        await _loadTopics(_selectedSubjectId!);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('Erro ao carregar dados da questão: $e');
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
      final topics = await SupabaseService.getTopicsBySubject(subjectId);
      
      setState(() {
        _topics = topics;
        _loadingTopics = false;
      });
    } catch (e) {
      print('Erro ao carregar tópicos: $e');
      setState(() {
        _topics = [];
        _selectedTopicId = null;
        _loadingTopics = false;
      });
    }
  }

  Future<void> _pickImage({bool isAnswerImage = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        
        // Verifica se o arquivo existe
        if (await file.exists()) {
          setState(() {
            if (isAnswerImage) {
              _selectedAnswerImage = file;
            } else {
              _selectedImage = file;
            }
          });
        } else {
          _showErrorSnackBar('Arquivo não encontrado');
        }
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao selecionar imagem: ${e.toString()}');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectId == null) {
      _showErrorSnackBar('Selecione uma matéria');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      String? answerImageUrl;

      // Upload da imagem principal (se houver)
      if (_selectedImage != null) {
        print('📤 Fazendo upload de nova imagem...');
        String sourceName = 'custom';
        String year = DateTime.now().year.toString();

        if (_selectedSourceId != null) {
          final selectedSource = _sources.firstWhere(
            (s) => s['id'] == _selectedSourceId,
            orElse: () => {},
          );
          if (selectedSource.isNotEmpty) {
            sourceName = selectedSource['name']?.toString().replaceAll(' ', '_') ?? 'custom';
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

        imageUrl = await SupabaseService.uploadQuestionImage(
          imageFile: _selectedImage!,
          sourceName: sourceName,
          year: year,
          questionNumber: 1,
          isAnswerImage: false,
        );
        print('✅ Nova imagem carregada: $imageUrl');
      } else if (_existingImageUrl != null) {
        // Se não há nova imagem mas há imagem existente, mantém
        imageUrl = _existingImageUrl;
        print('🔄 Mantendo imagem existente: $imageUrl');
      }

      // Upload da imagem da resposta (se houver)
      if (_selectedAnswerImage != null) {
        print('📤 Fazendo upload de nova imagem da resposta...');
        String sourceName = 'custom';
        String year = DateTime.now().year.toString();

        if (_selectedSourceId != null) {
          final selectedSource = _sources.firstWhere(
            (s) => s['id'] == _selectedSourceId,
            orElse: () => {},
          );
          if (selectedSource.isNotEmpty) {
            sourceName = selectedSource['name']?.toString().replaceAll(' ', '_') ?? 'custom';
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

        answerImageUrl = await SupabaseService.uploadQuestionImage(
          imageFile: _selectedAnswerImage!,
          sourceName: sourceName,
          year: year,
          questionNumber: 1,
          isAnswerImage: true,
        );
        print('✅ Nova imagem da resposta carregada: $answerImageUrl');
      } else if (_existingAnswerImageUrl != null) {
        // Se não há nova imagem da resposta mas há imagem existente, mantém
        answerImageUrl = _existingAnswerImageUrl;
        print('🔄 Mantendo imagem da resposta existente: $answerImageUrl');
      }

      final questionData = {
        'subject_id': _selectedSubjectId,
        'topic_id': _selectedTopicId,
        'source_id': _selectedSourceId,
        'year_id': _selectedYearId,
        'correct_answer': _correctAnswerController.text.trim().toUpperCase(),
        'difficulty_level': _difficultyLevel,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Adicionar URLs das imagens apenas se não forem nulas
      if (imageUrl != null && imageUrl.isNotEmpty) {
        questionData['image_url'] = imageUrl;
      }
      if (answerImageUrl != null && answerImageUrl.isNotEmpty) {
        questionData['answer_image_url'] = answerImageUrl;
      }

      print('🎯 Dados finais: $questionData');

      if (_isEditing && _editingQuestionId != null) {
        // Atualizar questão existente
        print('✏️ Atualizando questão ID: $_editingQuestionId');
        await SupabaseService.updateQuestion(_editingQuestionId!, questionData);
        _showSuccessSnackBar('✅ Questão atualizada com sucesso!');
      } else {
        // Adicionar nova questão
        print('➕ Adicionando nova questão');
        await SupabaseService.addQuestion(questionData);
        _showSuccessSnackBar('✅ Questão adicionada com sucesso!');
      }

      // Aguardar um pouco para mostrar o feedback
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Retornar à tela anterior
      if (mounted) {
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('❌ ERRO ao salvar questão: $e');
      
      String errorMessage = 'Erro ao salvar questão';
      if (e.toString().contains('connection')) {
        errorMessage = 'Sem conexão com o servidor. Verifique sua internet.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Tempo esgotado. Tente novamente.';
      } else if (e.toString().contains('storage')) {
        errorMessage = 'Erro ao salvar imagem. Tente novamente.';
      } else {
        errorMessage = 'Erro: ${e.toString().split('\n')[0]}';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetForm() {
    _correctAnswerController.clear();
    
    setState(() {
      _selectedSubjectId = null;
      _selectedTopicId = null;
      _selectedSourceId = null;
      _selectedYearId = null;
      _selectedImage = null;
      _selectedAnswerImage = null;
      _difficultyLevel = 3;
      _topics.clear();
      _loadingTopics = false;
      _existingImageUrl = null;
      _existingAnswerImageUrl = null;
    });
    
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
  }

  Widget _buildImageSection(String title, File? image, String? existingImageUrl, VoidCallback onPick, VoidCallback? onRemove, {bool isAnswerImage = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAnswerImage ? Icons.lightbulb_outline : Icons.image,
                  size: 20,
                  color: isAnswerImage ? Colors.amber : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isAnswerImage 
                ? 'Imagem com a solução/resposta (opcional)'
                : 'Imagem do enunciado da questão (opcional)',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Mostrar imagem selecionada ou existente
            if (image != null || (existingImageUrl != null && existingImageUrl!.isNotEmpty))
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image != null
                        ? Image.file(
                            image,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Erro ao carregar imagem',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Image.network(
                            existingImageUrl!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Erro ao carregar imagem',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.white),
                          onPressed: onRemove,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: onPick,
              icon: Icon(
                isAnswerImage ? Icons.lightbulb : Icons.image,
                color: isAnswerImage ? Colors.amber[700] : Colors.blue[700],
              ),
              label: Text(
                isAnswerImage 
                  ? image != null || (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                    ? 'Alterar Imagem da Resposta'
                    : 'Adicionar Imagem da Resposta'
                  : image != null || (existingImageUrl != null && existingImageUrl!.isNotEmpty)
                    ? 'Alterar Imagem do Enunciado'
                    : 'Selecionar Imagem do Enunciado',
                style: TextStyle(color: isAnswerImage ? Colors.amber[700] : Colors.blue[700]),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAnswerImage ? Colors.amber[50] : Colors.blue[50],
                foregroundColor: isAnswerImage ? Colors.amber[700] : Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '✏️ Editar Questão' : '➕ Adicionar Questão'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveQuestion,
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
                    // Matéria
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
                          child: Text('Selecione uma matéria', style: TextStyle(color: Colors.grey)),
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

                    // Tópico
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
                                  ? const Text('Selecione uma matéria primeiro', style: TextStyle(color: Colors.grey))
                                  : _loadingTopics
                                      ? const Row(
                                          children: [
                                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                            SizedBox(width: 8),
                                            Text('Carregando tópicos...', style: TextStyle(color: Colors.grey)),
                                          ],
                                        )
                                      : _topics.isEmpty
                                          ? const Text('Nenhum tópico disponível', style: TextStyle(color: Colors.grey))
                                          : const Text('Selecione um tópico (opcional)'),
                              items: _buildTopicDropdownItems(),
                              onChanged: (value) {
                                setState(() => _selectedTopicId = value);
                              },
                            ),
                          ),
                          if (_loadingTopics)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Fonte e Ano
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
                                child: Text('Selecione uma fonte', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._sources.map((source) {
                                return DropdownMenuItem<String>(
                                  value: source['id'],
                                  child: Text('${source['name']} (${source['type']})'),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedSourceId = value);
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
                                child: Text('Selecione um ano', style: TextStyle(color: Colors.grey)),
                              ),
                              ..._years.map((year) {
                                return DropdownMenuItem<String>(
                                  value: year['id'],
                                  child: Text(year['year'].toString()),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedYearId = value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Resposta Correta
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

                    // Dificuldade
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
                        final labels = ['Muito Fácil', 'Fácil', 'Médio', 'Difícil', 'Muito Difícil'];
                        final colors = [Colors.green, Colors.lightGreen, Colors.amber, Colors.orange, Colors.red];
                        return DropdownMenuItem<int>(
                          value: level,
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: colors[level - 1]),
                              const SizedBox(width: 8),
                              Text('$level - ${labels[level - 1]}'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _difficultyLevel = value);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // IMAGEM DO ENUNCIADO
                    _buildImageSection(
                      'Imagem do Enunciado',
                      _selectedImage,
                      _existingImageUrl,
                      () => _pickImage(isAnswerImage: false),
                      _selectedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                          ? () {
                              setState(() {
                                _selectedImage = null;
                                _existingImageUrl = null;
                              });
                            }
                          : null,
                      isAnswerImage: false,
                    ),

                    const SizedBox(height: 16),

                    // IMAGEM DA RESPOSTA
                    _buildImageSection(
                      'Imagem da Resposta',
                      _selectedAnswerImage,
                      _existingAnswerImageUrl,
                      () => _pickImage(isAnswerImage: true),
                      _selectedAnswerImage != null || (_existingAnswerImageUrl != null && _existingAnswerImageUrl!.isNotEmpty)
                          ? () {
                              setState(() {
                                _selectedAnswerImage = null;
                                _existingAnswerImageUrl = null;
                              });
                            }
                          : null,
                      isAnswerImage: true,
                    ),

                    const SizedBox(height: 32),

                    // BOTÃO SALVAR
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveQuestion,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(width: 12),
                                Text('Salvando...'),
                              ],
                            )
                          : Text(
                              _isEditing ? 'ATUALIZAR QUESTÃO' : 'SALVAR QUESTÃO',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // BOTÕES LIMPAR E CANCELAR
                    Row(
                      children: [
                        if (!_isEditing)
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
                        if (!_isEditing) const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
              Text('Nenhum tópico disponível', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
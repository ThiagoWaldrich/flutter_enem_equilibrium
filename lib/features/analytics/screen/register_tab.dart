import 'package:equilibrium/features/questions/models/question.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/theme/theme.dart';
import '../../core/utils/subject_data_constants.dart';

class RegisterTab extends StatelessWidget {
  final String? selectedSubject;
  final String? selectedTopic;
  final String? selectedSubtopic;
  final String? selectedYear;
  final String? selectedSource;
  final List<String> availableTopics;
  final List<String> availableSubtopics;
  final TextEditingController topicController;
  final TextEditingController subtopicController;
  final TextEditingController errorDescriptionController;
  final TextEditingController yearController;
  final TextEditingController sourceController;
  final bool contentError;
  final bool attentionError;
  final bool timeError;
  final File? imageFile;
  final String? imageFilePath;
  final bool isEditing;
  final Question? questionToEdit;
  final Function(String?)? onSubjectChanged;
  final Function(String?)? onTopicChanged;
  final Function(String?)? onSubtopicChanged;
  final Function(String?)? onYearChanged;
  final Function(String?)? onSourceChanged;
  final Function(bool)? onContentErrorChanged;
  final Function(bool)? onAttentionErrorChanged;
  final Function(bool)? onTimeErrorChanged;
  final Function()? onPickImage;
  final Function()? onClearImage;
  final Function()? onSaveQuestion;
  final Function()? onClearForm;

  const RegisterTab({
    super.key,
    required this.selectedSubject,
    required this.selectedTopic,
    required this.selectedSubtopic,
    required this.selectedYear,
    required this.selectedSource,
    required this.availableTopics,
    required this.availableSubtopics,
    required this.topicController,
    required this.subtopicController,
    required this.errorDescriptionController,
    required this.yearController,
    required this.sourceController,
    required this.contentError,
    required this.attentionError,
    required this.timeError,
    required this.imageFile,
    required this.imageFilePath,
    required this.isEditing,
    required this.questionToEdit,
    this.onSubjectChanged,
    this.onTopicChanged,
    this.onSubtopicChanged,
    this.onYearChanged,
    this.onSourceChanged,
    this.onContentErrorChanged,
    this.onAttentionErrorChanged,
    this.onTimeErrorChanged,
    this.onPickImage,
    this.onClearImage,
    this.onSaveQuestion,
    this.onClearForm,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit : Icons.add_circle_outline,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Questão' : 'Cadastrar Questão',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Atualize os dados da questão'
                              : 'Registre questões que você errou para análise',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),

              // Campo Matéria
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Matéria *',
                  prefixIcon: Icon(Icons.book),
                  border: OutlineInputBorder(),
                ),
                items: SubjectDataConstants.subjectData.keys
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: onSubjectChanged,
              ),

              const SizedBox(height: 16),

              // Campo Tópico
              DropdownButtonFormField<String>(
                initialValue: selectedTopic,
                decoration: const InputDecoration(
                  labelText: 'Tópico *',
                  prefixIcon: Icon(Icons.topic),
                  border: OutlineInputBorder(),
                  hintText: 'Selecione um tópico...',
                ),
                items: availableTopics
                    .map((topic) => DropdownMenuItem(
                          value: topic,
                          child: Text(topic),
                        ))
                    .toList(),
                onChanged: onTopicChanged,
              ),

              const SizedBox(height: 16),

              // Campo Subtopic
              DropdownButtonFormField<String>(
                initialValue: selectedSubtopic,
                decoration: const InputDecoration(
                  labelText: 'Subtópico',
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  border: OutlineInputBorder(),
                  hintText: 'Selecione um subtópico...',
                ),
                items: availableSubtopics
                    .map((subtopic) => DropdownMenuItem(
                          value: subtopic,
                          child: Text(subtopic),
                        ))
                    .toList(),
                onChanged: onSubtopicChanged,
              ),

              const SizedBox(height: 16),

              // Campos Ano e Fonte lado a lado
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Ano *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        hintText: 'Selecione o ano',
                      ),
                      items: SubjectDataConstants.years
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              ))
                          .toList(),
                      onChanged: onYearChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Fonte',
                        prefixIcon: Icon(Icons.source),
                        border: OutlineInputBorder(),
                        hintText: 'Selecione a fonte',
                      ),
                      items: SubjectDataConstants.sources
                          .map((source) => DropdownMenuItem(
                                value: source,
                                child: Text(source),
                              ))
                          .toList(),
                      onChanged: onSourceChanged,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Campo Análise do Erro
              TextField(
                controller: errorDescriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Análise do Erro',
                  hintText: 'Explique POR QUE você errou e o que aprendeu...',
                  prefixIcon: Icon(Icons.psychology),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // Seção de imagem
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.image,
                            size: 20, color: AppTheme.textSecondary),
                        SizedBox(width: 8),
                        Text(
                          'Imagem da Questão',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (imageFile != null && onClearImage != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              imageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white, size: 20),
                                onPressed: onClearImage,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: onPickImage,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Adicionar Imagem'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tipos de erro
              const Text(
                'Tipo de Erro',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecione um ou mais tipos de erro',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              _ErrorCheckbox(
                label: 'Conteúdo',
                subtitle: 'Não sabia o conteúdo necessário',
                icon: Icons.menu_book,
                value: contentError,
                onChanged: onContentErrorChanged ?? (_) {},
              ),
              const SizedBox(height: 8),
              _ErrorCheckbox(
                label: 'Atenção',
                subtitle: 'Erro de interpretação ou distração',
                icon: Icons.visibility_off,
                value: attentionError,
                onChanged: onAttentionErrorChanged ?? (_) {},
              ),
              const SizedBox(height: 8),
              _ErrorCheckbox(
                label: 'Tempo',
                subtitle: 'Não tive tempo suficiente',
                icon: Icons.access_time,
                value: timeError,
                onChanged: onTimeErrorChanged ?? (_) {},
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onClearForm,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                      child: const Text('Limpar Formulário'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onSaveQuestion,
                      icon: Icon(isEditing ? Icons.update : Icons.check),
                      label: Text(isEditing
                          ? 'Atualizar Questão'
                          : 'Adicionar Questão'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Classe ErrorCheckbox movida para dentro do RegisterTab
class _ErrorCheckbox extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;

  const _ErrorCheckbox({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: value
            ? AppTheme.primaryColor.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppTheme.primaryColor : AppTheme.lightGray,
          width: value ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (val) => onChanged(val ?? false),
        title: Row(
          children: [
            Icon(icon,
                size: 20,
                color: value ? AppTheme.primaryColor : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        subtitle: Text(subtitle,
            style:
                const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';
import '../services/database_service.dart';
import '../models/question.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';
import 'package:flutter/services.dart';
import '../widgets/questions_grid_view.dart';
import 'mind_maps_screen.dart';

class AutodiagnosticoScreen extends StatefulWidget {
  const AutodiagnosticoScreen({super.key});

  @override
  State<AutodiagnosticoScreen> createState() => _AutodiagnosticoScreenState();
}

class _AutodiagnosticoScreenState extends State<AutodiagnosticoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedSubject;
  String? _selectedTopic;
  String? _selectedSubtopic;
  String? _selectedYear;
  String? _selectedSource;

  final List<String> _availableTopics = [];
  final List<String> _availableSubtopics = [];

  final _topicController = TextEditingController();
  final _subtopicController = TextEditingController();
  final _errorDescriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _sourceController = TextEditingController();

  bool _contentError = false;
  bool _attentionError = false;
  bool _timeError = false;

  File? _imageFile;
  String? _imageData;

  List<Question> _questions = [];
  Map<String, int> _subjectStats = {};
  Map<String, int> _yearStats = {};
  Map<String, int> _sourceStats = {};
  Map<String, Map<String, dynamic>> _errorStats = {};
  int _totalQuestions = 0;
  bool _isLoading = false;

  String? _filterSubject;
  String? _filterYear;
  String? _filterSource;
  String? _filterErrorType;

  Question? _questionToEdit;
  bool _isEditing = false;

  // Lista de anos (de 2027 até 1980)
  final List<String> _years =
      List.generate(48, (index) => (2027 - index).toString());

  // Lista de fontes (provas e vestibulares)
  final List<String> _sources = [
    'ENEM',
    'ENEM PPL',
    'ENEM 2ª Aplicação',
    'ENEM Digital',
    'ENEM Reaplicação',
    'ENEM 1ª Aplicação',
    'ENEM 2ª Aplicação (PPL)',
    'ENEM Libras',
    'ENEM para adultos privados de liberdade',
    'FUVEST',
    'UNICAMP',
    'UNESP',
    'UERJ',
    'UFPR',
    'UFRGS',
    'UFRJ',
    'UFMG',
    'UFSM',
    'UFC',
    'UFBA',
    'UNIFESP',
    'ITA',
    'IME',
    'AFA',
    'EFOMM',
    'EsPCEx',
    'Colégio Naval',
    'ESA',
    'EsSA',
    'CN',
    'EPCAR',
    'Fuvest - USP',
    'Vunesp',
    'Comvest - Unicamp',
    'UPE',
    'UEMA',
    'UFPI',
    'UFSC',
    'UFT',
    'UNIR',
    'UFPA',
    'UFMT',
    'UFMS',
    'UFG',
    'UFSCar',
    'UFF',
    'UFV',
    'UFRN',
    'UFCG',
    'UFPB',
    'UFRPE',
    'IF - Instituto Federal',
    'IFSP',
    'IFRJ',
    'IFCE',
    'IFMG',
    'IFSUL',
    'IF Goiano',
    'Cefet',
    'Cefet-MG',
    'Cefet-RJ',
    'Colégio Pedro II',
    'Obmep',
    'OBA',
    'OBF',
    'Simulado Positivo',
    'Simulado Anglo',
    'Simulado Bernoulli',
    'Simulado Poliedro',
    'Simulado Etapa',
    'Simulado Farias Brito',
    'Simulado SAS',
    'Simulado Somos',
    'Prova particular',
    'Livro didático',
    'Apostila',
    'Curso preparatório',
    'Plataforma online',
    'App de estudo',
    'Site educativo',
    'YouTube',
    'Outro'
  ];
  final Map<String, Map<String, List<String>>> _subjectData = {
    'Física': {
      'Mecânica': [
        'Vetores',
        'Cinemática',
        'Dinâmica',
        'Estática',
        'Hidrostática',
        'Trabalho e Energia',
        'Gravitação',
        'Movimento Circular',
        'Impulso e Quantidade de Movimento'
      ],
      'Termologia': [
        'Calorimetria',
        'Termodinâmica',
        'Dilatação Térmica',
        'Gases Ideais',
        'Termometria',
        'Transmissão de Calor'
      ],
      'Óptica': [
        'Reflexão',
        'Refração',
        'Lentes',
        'Espelhos',
        'Óptica da Visão',
        'Instrumentos Ópticos'
      ],
      'Ondulatória': [
        'Efeito Doppler',
        'Ondas Mecânicas',
        'Acústica',
        'Fenômenos Ondulatórios',
        'Cordas Vibrantes',
        'Tubos Sonoros',
        'Espectro Eletromagnético'
      ],
      'Eletricidade': [
        'Eletrostática',
        'Circuitos Elétricos',
        'Eletromagnetismo',
        'Potência Elétrica',
        'Lei de Ohm',
        'Capacitores',
        'Geradores'
      ],
      'Física Moderna': [
        'Relatividade',
        'Física Quântica',
        'Radioatividade',
        'Física Nuclear',
        'Partículas Elementares'
      ]
    },
    'Literatura': {
        'Escolas Literárias Brasileiras':[
          'Modernismo',
          'Realismo/Naturalismo',
          'Romantismo',
          'Barroco',
          'Arcadismo(Neoclassicismo)',
          'Simbolismo',
          'Pré-Modernismo',
          'Parnasianismo'
        ],
        'Vanguardas Europeias':[
          'Futurismo',
          'Cubismo',
          'Expressionismo',
          'Dadaísmo'
        ]
    },
    'Química': {
      'Química Geral': [
        'Estrutura Atômica',
        'Tabela Periódica',
        'Ligações Químicas',
        'Estequiometria',
        'Soluções',
        'Funções Inorgânicas'
      ],
      'Físico-Química': [
        'Termoquímica',
        'Cinética Química',
        'Equilíbrio Químico',
        'Eletroquímica',
        'Propriedades Coligativas'
      ],
      'Química Orgânica': [
        'Funções Orgânicas',
        'Reações Orgânicas',
        'Isomeria',
        'Polímeros',
        'Petróleo e Combustíveis',
        'Bioquímica'
      ],
      'Química Inorgânica': [
        'Funções Inorgânicas',
        'Reações Inorgânicas',
        'Química dos Minerais',
        'Metais e Não-Metais'
      ],
      'Química Ambiental': [
        'Poluição Ambiental',
        'Tratamento de Água',
        'Chuva Ácida',
        'Efeito Estufa',
        'Camada de Ozônio'
      ]
    },
    'Biologia': {
      'Citologia':[
        'Organelas'
      ],
      'Biologia Celular': [
        'Células Procariontes e Eucariontes',
        'Metabolismo Energético',
        'Divisão Celular',
        'Síntese Proteica',
        'Membrana Celular',
        'Organelas Celulares'
      ],
      'Genética': [
        'Leis de Mendel',
        'DNA e RNA',
        'Engenharia Genética',
        'Mutações',
        'Herança Genética',
        'Genética de Populações'
      ],
      'Ecologia': [
        'Cadeias Alimentares',
        'Ciclos Biogeoquímicos',
        'Conservação Ambiental',
        'Biomas',
        'Relações Ecológicas',
        'Sucessão Ecológica'
      ],
      'Fisiologia Humana': [
        'Sistema Digestório',
        'Sistema Circulatório',
        'Sistema Respiratório',
        'Sistema Nervoso',
        'Sistema Endócrino',
        'Sistema Excretor',
        'Sistema Reprodutor',
        'Sistema Locomotor'
      ],
      'Evolução': [
        'Teorias Evolutivas',
        'Evidências da Evolução',
        'Seleção Natural',
        'Especiação',
        'Evolução Humana'
      ],
      'Botânica': [
        'Fisiologia Vegetal',
        'Classificação Vegetal',
        'Reprodução Vegetal',
        'Fotossíntese'
      ],
      'Zoologia': [
        'Classificação Animal',
        'Invertebrados',
        'Vertebrados',
        'Fisiologia Animal',
        'Características Gerais'
      ]
    },
    'Matemática': {
      'Básica':[
        'Porcentagem',
        'Razão e Proporção',
        'Potenciação e Radiciação',
        'Regra de Três',
        'Análise de Gráficos e Tabelas'
      ],
      'Álgebra': [
        'Equações e Inequações',
        'Funções Afim',
        'Funções Quadráticas',
        'Funções Exponenciais',
        'Funções Logarítmicas',
        'Funções Trigonométricas',
        'Sistemas Lineares',
        'Polinômios',
        'Números Complexos',
        'Matrizes e Determinantes',
        'Trigonometría',
        'Logaritmo'
      ],
      'Geometria': [
        'Geometria Plana',
        'Geometria Espacial',
        'Geometria Analítica',
        'Trigonometria',
        'Áreas e Volumes',
        'Geometria Métrica',
        'Sólidos de Revolução',
        'Projeção Ortonogonal'
      ],
      'Aritmética': [
        'Números Naturais e Inteiros',
        'Números Racionais',
        'Números Reais',
        'Sequências e Progressões',
        'PA',
        'PG'
      ],
      'Probabilidade e Estatística': [
        'Estatística Descritiva',
        'Probabilidade',
        'Distribuição Normal',
        'Análise Combinatória',
        'Medidas de Tendência Central',
      ],
      'Matemática Financeira': [
        'Juros Simples',
        'Juros Compostos',
        'Porcentagem',
        'Descontos',
        'Financiamentos'
      ]
    },
    'História': {
      'História Geral': [
        'Pré-História',
        'Antiguidade',
        'Idade Média',
        'Idade Moderna',
        'Idade Contemporânea',
        'Guerras Mundiais',
        'Guerra Fria',
        'Revolução Industrial'
      ],
      'História do Brasil': [
        'Período Colonial',
        'Período Imperial',
        'República Velha',
        'Era Vargas',
        'Ditadura Militar',
        'Redemocratização',
        'Brasil Contemporâneo'
      ],
      'História da América': [
        'América Pré-Colombiana',
        'Colonização da América',
        'Independências Americanas',
        'América Contemporânea'
      ]
    },
    'Geografia': {
      'Geografia Ambiental':[
        'Impactos Ambientais'
      ],
      'Geografia Política':[
        'Globalização',
        'Política'
      ],
      'Geografia Física': [
        'Climatologia',
        'Geomorfologia',
        'Biomas',
        'Hidrografia',
        'Domínios Morfoclimáticos',
        'Geografia dos Solos',
        'Recursos Naturais'
      ],
      'Geografia Humana': [
        'Demografia',
        'Urbanização',
        'Industrialização',
        'Agricultura',
        'Globalização',
        'Demografia Brasileira'
      ],
      'Geografia do Brasil': [
        'Regiões Brasileiras',
        'População Brasileira',
        'Indústria Brasileira',
        'Agropecuária Brasileira',
        'Transportes no Brasil',
        'Energia no Brasil'
      ],
      'Geopolítica': [
        'Organizações Internacionais',
        'Conflitos Mundiais',
        'Relacionamentos Internacionais',
        'Geopolítica do Brasil'
      ]
    },
    'Língua Portuguesa': {
      'Gramática': [
        'Morfologia',
        'Sintaxe',
        'Fonologia',
        'Semântica',
        'Pontuação',
        'Crase',
        'Regência',
        'Concordância'
      ],
      'Interpretação e Análise Textual': [
        'Gêneros Textuais',
        'Estratégias Argumentativas',
        'Coesão e Coerência',
        'Funções da Linguagem',
        'Textos Literários',
        'Textos Não-Literários',
        'Variação Linguística'
      ],
    },
    'Inglês': {
      'Interpretação de Textos': [
        'Textos Jornalísticos',
        'Textos Literários',
        'Textos Acadêmicos',
        'Textos Publicitários',
        'Compreensão de Texto'
      ],
      'Gramática': [
        'Tempos Verbais',
        'Preposições',
        'Artigos',
        'Pronomes',
        'Estruturas Sintáticas',
        'Phrasal Verbs'
      ],
      'Vocabulário': [
        'Sinônimos e Antônimos',
        'Falsos Cognatos',
        'Expressões Idiomáticas',
        'Vocabulário Técnico'
      ]
    },
    'Filosofia': {
      'Temática':[
        'Pensar Filosófico'
      ],
      'Filosofia Clássica': [
        'Pré-Socráticos',
        'Sócrates, Platão, Aristóteles',
        'Helenismo',
        'Filosofia Grega'
      ],
      'Filosofia Medieval': [
        'Patrística',
        'Escolástica',
        'Santo Agostinho',
        'São Tomás de Aquino'
      ],
      'Filosofia Moderna': [
        'Racionalismo (Descartes)',
        'Empirismo (Locke, Hume)',
        'Iluminismo',
        'Utilitarismo',
        'Kant',
        'Idealismo Alemão'
      ],
      'Filosofia Contemporânea': [
        'Marxismo',
        'Existencialismo',
        'Fenomenologia',
        'Filosofia Analítica'
      ],
      'Ética e Filosofia Política': [
        'Teorias Éticas',
        'Justiça Social',
        'Democracia',
        'Direitos Humanos'
      ]
    },
    'Sociologia': {
      'Política, Poder e Estado':[
        'Política'
      ],
      'Trabalho e Estratificação Social':[
        'Trabalho e Produção'
      ],
      'Teorias Sociológicas Clássicas': [
        'Durkheim (Fatos Sociais)',
        'Marx (Luta de Classes)',
        'Weber (Ação Social)',
        'Sociologia Compreensiva'
      ],
      'Sociologia Brasileira': [
        'Formação da Sociedade Brasileira',
        'Desigualdades Sociais',
        'Identidade Nacional'
      ],
      'Cultura e Sociedade': [
        'Diversidade Cultural',
        'Globalização Cultural',
        'Indústria Cultural'
      ],
      'Movimentos Sociais': [
        'Movimentos Urbanos',
        'Movimentos Rurais (MST)',
        'Movimentos Feministas',
        'Movimentos Negros',
        'Movimentos LGBTQIA+',
        'Movimentos Ambientalistas'
      ]
    },
    'Redação': {
      'Redação ENEM': [
        'Competências do ENEM',
        'Estrutura da Dissertação-Argumentativa',
        'Temas Recorrentes',
        'Estratégias Argumentativas',
        'Proposta de Intervenção',
        'Coesão e Coerência',
        'Norma Culta'
      ],
      'Técnicas de Redação': [
        'Introdução',
        'Desenvolvimento',
        'Conclusão',
        'Argumentação',
        'Repertório Sociocultural'
      ]
    }
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _subtopicController.dispose();
    _errorDescriptionController.dispose();
    _yearController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _updateTopics() {
    setState(() {
      _availableTopics.clear();
      _selectedTopic = null;
      _availableSubtopics.clear();
      _selectedSubtopic = null;

      if (_selectedSubject != null &&
          _subjectData.containsKey(_selectedSubject)) {
        _availableTopics.addAll(_subjectData[_selectedSubject]!.keys.toList());
      }
    });
  }

  void _updateSubtopics() {
    setState(() {
      _availableSubtopics.clear();
      _selectedSubtopic = null;

      if (_selectedSubject != null &&
          _selectedTopic != null &&
          _subjectData.containsKey(_selectedSubject) &&
          _subjectData[_selectedSubject]!.containsKey(_selectedTopic)) {
        _availableSubtopics
            .addAll(_subjectData[_selectedSubject]![_selectedTopic]!);
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final databaseService = context.read<DatabaseService>();

    final questions = await databaseService.getQuestions(limit: 1000);
    final stats = await databaseService.getSubjectStats();
    final yearStats = await databaseService.getYearStats();
    final sourceStats = await databaseService.getSourceStats();
    final count = await databaseService.getQuestionCount();

    final errorStats = <String, Map<String, dynamic>>{};
    for (final question in questions) {
      final subject = question.subject;
      if (!errorStats.containsKey(subject)) {
        errorStats[subject] = {
          'total': 0,
          'conteudo': 0,
          'atencao': 0,
          'tempo': 0,
        };
      }
      errorStats[subject]!['total']++;
      if (question.errors['conteudo'] == true) {
        errorStats[subject]!['conteudo']++;
      }
      if (question.errors['atencao'] == true) {
        errorStats[subject]!['atencao']++;
      }
      if (question.errors['tempo'] == true) {
        errorStats[subject]!['tempo']++;
      }
    }

    setState(() {
      _questions = questions;
      _subjectStats = stats;
      _yearStats = yearStats;
      _sourceStats = sourceStats;
      _errorStats = errorStats;
      _totalQuestions = count;
      _isLoading = false;
    });
  }

  Map<String, Map<String, int>> _loadTopicStats() {
    final topicStats = <String, Map<String, int>>{};

    for (final question in _questions) {
      final subject = question.subject;
      final topic = question.topic;

      if (!topicStats.containsKey(subject)) {
        topicStats[subject] = {};
      }

      if (!topicStats[subject]!.containsKey(topic)) {
        topicStats[subject]![topic] = 0;
      }

      topicStats[subject]![topic] = topicStats[subject]![topic]! + 1;
    }

    return topicStats;
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Selecionar Imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        // Verificar o tamanho da imagem (limitar para evitar problemas de memória)
        if (bytes.length > 10 * 1024 * 1024) {
          // 10MB
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'A imagem é muito grande. Por favor, selecione uma imagem menor.'),
                backgroundColor: AppTheme.dangerColor,
              ),
            );
          }
          return;
        }

        setState(() {
          _imageFile = File(image.path);
          _imageData = base64Encode(bytes);
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao acessar a imagem: ${e.message}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _saveQuestion() async {
    if (_selectedSubject == null || _selectedTopic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha Matéria e Tópico!'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    if (_selectedYear == null || _selectedYear!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe o ano da prova!'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final question = Question(
      id: _isEditing
          ? _questionToEdit!.id
          : 'q_${DateTime.now().millisecondsSinceEpoch}',
      subject: _selectedSubject!,
      topic: _selectedTopic!,
      subtopic: _selectedSubtopic,
      year: _selectedYear,
      source: _selectedSource,
      errorDescription: _errorDescriptionController.text.isEmpty
          ? null
          : _errorDescriptionController.text,
      errors: {
        'conteudo': _contentError,
        'atencao': _attentionError,
        'tempo': _timeError,
      },
      image: _imageData != null
          ? QuestionImage(
              data: 'data:image/jpeg;base64,$_imageData',
              name: _imageFile?.path.split('/').last ?? 'image.jpg',
              type: 'image/jpeg',
            )
          : null,
      timestamp: _isEditing
          ? _questionToEdit!.timestamp
          : DateTime.now().toIso8601String(),
    );

    final databaseService = context.read<DatabaseService>();

    if (_isEditing) {
      await databaseService.updateQuestion(question);
    } else {
      await databaseService.insertQuestion(question);
    }

    _clearForm();
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Questão ${_isEditing ? 'atualizada' : 'salva'} com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _clearForm() {
    setState(() {
      _questionToEdit = null;
      _isEditing = false;
      _selectedSubject = null;
      _selectedTopic = null;
      _selectedSubtopic = null;
      _selectedYear = null;
      _selectedSource = null;
      _availableTopics.clear();
      _availableSubtopics.clear();
      _topicController.clear();
      _subtopicController.clear();
      _errorDescriptionController.clear();
      _yearController.clear();
      _sourceController.clear();
      _contentError = false;
      _attentionError = false;
      _timeError = false;
      _imageFile = null;
      _imageData = null;
    });
  }

  Future<void> _editQuestion(Question question) async {
    setState(() {
      _questionToEdit = question;
      _isEditing = true;

      _selectedSubject = question.subject;
      _selectedTopic = question.topic;
      _selectedSubtopic = question.subtopic;
      _selectedYear = question.year;
      _selectedSource = question.source;
      _errorDescriptionController.text = question.errorDescription ?? '';
      _contentError = question.errors['conteudo'] ?? false;
      _attentionError = question.errors['atencao'] ?? false;
      _timeError = question.errors['tempo'] ?? false;

      if (question.image != null) {
        _imageData = question.image!.data.split(',').last;
      }
    });

    _updateTopics();
    _updateSubtopics();

    _tabController.animateTo(0);
  }

  Future<void> _deleteQuestion(Question question) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Questão'),
        content: const Text('Tem certeza que deseja excluir esta questão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final databaseService = context.read<DatabaseService>();
      await databaseService.deleteQuestions([question.id]);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questão excluída com sucesso'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  Future<void> _exportData() async {
    final data = _questions
        .map((q) => {
              'materia': q.subject,
              'topico': q.topic,
              'subtopico': q.subtopic ?? '',
              'ano': q.year ?? '',
              'fonte': q.source ?? '',
              'erro_descricao': q.errorDescription ?? '',
              'erro_conteudo': q.errors['conteudo'] ?? false,
              'erro_atencao': q.errors['atencao'] ?? false,
              'erro_tempo': q.errors['tempo'] ?? false,
              'data': q.timestamp,
            })
        .toList();

    final jsonData = jsonEncode(data);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total de questões: ${_questions.length}'),
            const SizedBox(height: 16),
            const Text(
              'Dados preparados para exportação em formato JSON.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SelectableText(
              jsonData.length > 200
                  ? '${jsonData.substring(0, 200)}...'
                  : jsonData,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  List<Question> _getFilteredQuestions() {
    var filtered = _questions;

    if (_filterSubject != null && _filterSubject!.isNotEmpty) {
      filtered = filtered.where((q) => q.subject == _filterSubject).toList();
    }

    if (_filterYear != null && _filterYear!.isNotEmpty) {
      filtered = filtered.where((q) => q.year == _filterYear).toList();
    }

    if (_filterSource != null && _filterSource!.isNotEmpty) {
      filtered = filtered.where((q) => q.source == _filterSource).toList();
    }

    if (_filterErrorType != null && _filterErrorType!.isNotEmpty) {
      filtered = filtered.where((q) {
        return q.errors[_filterErrorType] == true;
      }).toList();
    }

    return filtered;
  }

  void _showQuestionDetails(Question question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(question.subject),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tópico: ${question.topic}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (question.subtopic != null)
                Text('Subtópico: ${question.subtopic}'),
              if (question.year != null) Text('Ano: ${question.year}'),
              if (question.source != null) Text('Fonte: ${question.source}'),
              const SizedBox(height: 16),
              if (question.errorDescription != null) ...[
                const Text(
                  'Análise do Erro:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(question.errorDescription!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Tipos de Erro:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  if (question.errors['conteudo'] == true)
                    Chip(
                      label: const Text('Conteúdo'),
                      backgroundColor: Colors.red.withOpacity(0.1),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  const SizedBox(width: 8),
                  if (question.errors['atencao'] == true)
                    Chip(
                      label: const Text('Atenção'),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      side: BorderSide(color: Colors.orange.withOpacity(0.3)),
                    ),
                  const SizedBox(width: 8),
                  if (question.errors['tempo'] == true)
                    Chip(
                      label: const Text('Tempo'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                ],
              ),
              if (question.image != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Imagem:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(question.image!.data.split(',').last),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editQuestion(question);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('📊 Autodiagnóstico ENEM'),
        backgroundColor: const Color(0xFF011B3D),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: _exportData,
            tooltip: 'Exportar Dados',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Atualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.add, color: Colors.white),
              text: 'Cadastrar',
            ),
            Tab(
              icon: Icon(Icons.bar_chart, color: Colors.white),
              text: 'Gráficos',
            ),
            Tab(
              icon: Icon(Icons.table_chart, color: Colors.white),
              text: 'Planilha',
            ),
            Tab(
              icon: Icon(Icons.menu_book, color: Colors.white),
              text: 'Caderno',
            ),
            Tab(
              icon: Icon(Icons.lightbulb, color: Colors.white),
              text: 'Mapas',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRegisterTab(),
          _buildChartsTab(),
          _buildDataTab(),
          _buildNotebookTab(),
          const MindMapsScreen(),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditing ? Icons.edit : Icons.add_circle_outline,
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
                          _isEditing ? 'Editar Questão' : 'Cadastrar Questão',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _isEditing
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
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Matéria *',
                  prefixIcon: Icon(Icons.book),
                  border: OutlineInputBorder(),
                ),
                items: _subjectData.keys
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSubject = value);
                  _updateTopics();
                },
              ),

              const SizedBox(height: 16),

              // Campo Tópico
              DropdownButtonFormField<String>(
                value: _selectedTopic,
                decoration: const InputDecoration(
                  labelText: 'Tópico *',
                  prefixIcon: Icon(Icons.topic),
                  border: OutlineInputBorder(),
                  hintText: 'Selecione um tópico...',
                ),
                items: _availableTopics
                    .map((topic) => DropdownMenuItem(
                          value: topic,
                          child: Text(topic),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedTopic = value);
                  _updateSubtopics();
                },
              ),

              const SizedBox(height: 16),

              // Campo Subtopic
              DropdownButtonFormField<String>(
                value: _selectedSubtopic,
                decoration: const InputDecoration(
                  labelText: 'Subtópico',
                  prefixIcon: Icon(Icons.subdirectory_arrow_right),
                  border: OutlineInputBorder(),
                  hintText: 'Selecione um subtópico...',
                ),
                items: _availableSubtopics
                    .map((subtopic) => DropdownMenuItem(
                          value: subtopic,
                          child: Text(subtopic),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSubtopic = value);
                },
              ),

              const SizedBox(height: 16),

              // Campos Ano e Fonte lado a lado
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                        labelText: 'Ano *',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                        hintText: 'Selecione o ano',
                      ),
                      items: _years
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Fonte',
                        prefixIcon: Icon(Icons.source),
                        border: OutlineInputBorder(),
                        hintText: 'Selecione a fonte',
                      ),
                      items: _sources
                          .map((source) => DropdownMenuItem(
                                value: source,
                                child: Text(source),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedSource = value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Campo Análise do Erro
              TextField(
                controller: _errorDescriptionController,
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
                  color: AppTheme.lightGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightGray),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.image,
                            size: 20, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        const Text(
                          'Imagem da Questão',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_imageFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
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
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                    _imageData = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (_imageData != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(_imageData!),
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
                                onPressed: () {
                                  setState(() {
                                    _imageFile = null;
                                    _imageData = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
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
                value: _contentError,
                onChanged: (value) => setState(() => _contentError = value),
              ),
              const SizedBox(height: 8),
              _ErrorCheckbox(
                label: 'Atenção',
                subtitle: 'Erro de interpretação ou distração',
                icon: Icons.visibility_off,
                value: _attentionError,
                onChanged: (value) => setState(() => _attentionError = value),
              ),
              const SizedBox(height: 8),
              _ErrorCheckbox(
                label: 'Tempo',
                subtitle: 'Não tive tempo suficiente',
                icon: Icons.access_time,
                value: _timeError,
                onChanged: (value) => setState(() => _timeError = value),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      child: const Text('Limpar Formulário'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _saveQuestion,
                      icon: Icon(_isEditing ? Icons.update : Icons.check),
                      label: Text(_isEditing
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

  Widget _buildChartsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedStats = _subjectStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topicStats = _loadTopicStats();

    String? selectedChartSubject;
    if (_selectedSubject != null && topicStats.containsKey(_selectedSubject)) {
      selectedChartSubject = _selectedSubject;
    } else if (topicStats.isNotEmpty) {
      selectedChartSubject = topicStats.keys.first;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Cards de resumo
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total de Questões',
                    _totalQuestions.toString(),
                    Icons.quiz,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Matérias',
                    _subjectStats.length.toString(),
                    Icons.book,
                    AppTheme.successColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Estatísticas de erros
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipos de Erros',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildErrorStatCard(
                          'Conteúdo',
                          _countErrorType('conteudo'),
                          Colors.red,
                          Icons.menu_book,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildErrorStatCard(
                          'Atenção',
                          _countErrorType('atencao'),
                          Colors.orange,
                          Icons.visibility_off,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildErrorStatCard(
                          'Tempo',
                          _countErrorType('tempo'),
                          Colors.blue,
                          Icons.access_time,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gráfico de Pizza
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribuição por Matéria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_totalQuestions > 0)
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: sortedStats.take(10).map((entry) {
                            final color = AppTheme.getSubjectColor(entry.key);
                            final percentage = (_totalQuestions > 0
                                    ? (entry.value / _totalQuestions * 100)
                                    : 0)
                                .round();

                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title: '$percentage%',
                              color: color,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text('Nenhum dado disponível'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: sortedStats.take(10).map((entry) {
                      final color = AppTheme.getSubjectColor(entry.key);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.key} (${entry.value})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gráfico de Barras (Tópicos por Matéria) - CORRIGIDO
            if (selectedChartSubject != null &&
                topicStats.containsKey(selectedChartSubject) &&
                topicStats[selectedChartSubject]!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tópicos de $selectedChartSubject',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (topicStats.length > 1)
                          DropdownButton<String>(
                            value: selectedChartSubject,
                            items: topicStats.keys.map((subject) {
                              return DropdownMenuItem(
                                value: subject,
                                child: Text(
                                  subject,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSubject = value;
                                });
                              }
                            },
                            underline: Container(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (topicStats[selectedChartSubject]!.isNotEmpty)
                      SizedBox(
                        height: 350,
                        child: _buildTopicsBarChart(selectedChartSubject!,
                            topicStats[selectedChartSubject]!),
                      )
                    else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Text(
                              'Nenhum tópico cadastrado para esta matéria'),
                        ),
                      ),
                    if (topicStats[selectedChartSubject]!.isNotEmpty)
                      _buildTopicsLegend(selectedChartSubject!,
                          topicStats[selectedChartSubject]!),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Gráfico de anos
            if (_yearStats.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribuição por Ano',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: _buildYearBarChart(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Gráfico de fontes
            if (_sourceStats.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fontes mais frequentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 300,
                      child: _buildSourceBarChart(),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsBarChart(String subject, Map<String, int> topicsData) {
    final topicsEntries = topicsData.entries.toList();
    topicsEntries.sort((a, b) => b.value.compareTo(a.value));

    // Limita a 10 tópicos para melhor visualização
    final topTopics = topicsEntries.take(10).toList();

    // Se não houver dados, mostra mensagem
    if (topTopics.isEmpty) {
      return Center(
        child: Text(
          'Nenhum dado disponível para $subject',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    // Cria grupos de barras
    final barGroups = topTopics.asMap().entries.map((entry) {
      final index = entry.key;
      final topic = entry.value.key;
      final value = entry.value.value;
      final color = AppTheme.getSubjectColor(subject);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: color,
            width: 22,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();

    // Calcula o valor máximo para o eixo Y
    final maxValue = topTopics
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // Aumenta um pouco para dar espaço no topo
    final adjustedMaxValue = maxValue + (maxValue * 0.1);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: adjustedMaxValue,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= 0 && groupIndex < topTopics.length) {
                final topic = topTopics[groupIndex].key;
                final value = topTopics[groupIndex].value;
                return BarTooltipItem(
                  '$topic\n$value questão${value != 1 ? 's' : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          // Configuração do eixo X (bottom)
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < topTopics.length) {
                  final topic = topTopics[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 80,
                      child: Text(
                        _truncateText(topic, 20),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 60,
              interval: 1,
            ),
          ),
          // Configuração do eixo Y (left)
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 1 == 0) {
                  // Mostra apenas valores inteiros
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              interval: _calculateInterval(maxValue),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: _calculateInterval(maxValue),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

// Função auxiliar para truncar texto longo
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

// Função auxiliar para calcular intervalo do eixo Y
  double _calculateInterval(double maxValue) {
    if (maxValue <= 5) return 1;
    if (maxValue <= 10) return 2;
    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    return 50;
  }

  Widget _buildYearBarChart() {
    final yearEntries = _yearStats.entries.toList();
    yearEntries.sort((a, b) => a.key.compareTo(b.key));

    final recentYears = yearEntries.take(10).toList();

    final barGroups = recentYears.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    final double maxValue = recentYears.isNotEmpty
        ? recentYears
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.1
        : 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= 0 && groupIndex < recentYears.length) {
                final year = recentYears[groupIndex].key;
                final value = recentYears[groupIndex].value;
                return BarTooltipItem(
                  '$year\n$value questão${value != 1 ? 's' : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < recentYears.length) {
                  final year = recentYears[index].key;
                  return Text(
                    year,
                    style: const TextStyle(fontSize: 11),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: true),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildSourceBarChart() {
    final sourceEntries = _sourceStats.entries.toList();
    sourceEntries.sort((a, b) => b.value.compareTo(a.value));

    final topSources = sourceEntries.take(10).toList();

    final barGroups = topSources.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: Colors.green,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    final double maxValue = topSources.isNotEmpty
        ? topSources
                .map((e) => e.value)
                .reduce((a, b) => a > b ? a : b)
                .toDouble() *
            1.1
        : 10.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex >= 0 && groupIndex < topSources.length) {
                final source = topSources[groupIndex].key;
                final value = topSources[groupIndex].value;
                return BarTooltipItem(
                  '$source\n$value questão${value != 1 ? 's' : ''}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < topSources.length) {
                  final source = topSources[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 80,
                      child: Text(
                        source.length > 15
                            ? '${source.substring(0, 15)}...'
                            : source,
                        style: const TextStyle(fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 11),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: true),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildTopicsLegend(String subject, Map<String, int> topicsData) {
    final topicsEntries = topicsData.entries.toList();
    topicsEntries.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Top Tópicos:',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: topicsEntries.take(15).map((entry) {
            return Chip(
              label: Text(
                '${entry.key} (${entry.value})',
                style: const TextStyle(fontSize: 11),
              ),
              backgroundColor:
                  AppTheme.getSubjectColor(subject).withOpacity(0.1),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allQuestions = List<Question>.from(_questions);

    List<Question> filteredQuestions = allQuestions;

    if (_filterSubject != null && _filterSubject!.isNotEmpty) {
      filteredQuestions =
          filteredQuestions.where((q) => q.subject == _filterSubject).toList();
    }

    if (_filterYear != null && _filterYear!.isNotEmpty) {
      filteredQuestions =
          filteredQuestions.where((q) => q.year == _filterYear).toList();
    }

    if (_filterSource != null && _filterSource!.isNotEmpty) {
      filteredQuestions =
          filteredQuestions.where((q) => q.source == _filterSource).toList();
    }

    if (_filterErrorType != null && _filterErrorType!.isNotEmpty) {
      filteredQuestions = filteredQuestions.where((q) {
        return q.errors[_filterErrorType] == true;
      }).toList();
    }

    filteredQuestions.sort((a, b) {
      final subjectCompare = a.subject.compareTo(b.subject);
      if (subjectCompare != 0) return subjectCompare;
      return a.topic.compareTo(b.topic);
    });

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Dropdown de Matéria
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String?>(
                    value: _filterSubject,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Filtrar por matéria'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas as matérias'),
                      ),
                      ..._subjectStats.keys
                          .map((subject) => DropdownMenuItem<String?>(
                                value: subject,
                                child: Text(subject),
                              ))
                          .toList(),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filterSubject = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dropdown de Ano
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String?>(
                    value: _filterYear,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Filtrar por ano'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os anos'),
                      ),
                      ..._years
                          .where((year) => _yearStats.containsKey(year))
                          .map((year) => DropdownMenuItem<String?>(
                                value: year,
                                child: Text('$year (${_yearStats[year]})'),
                              ))
                          .toList(),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filterYear = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dropdown de Fonte
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String?>(
                    value: _filterSource,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Filtrar por fonte'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas as fontes'),
                      ),
                      ..._sources
                          .where((source) => _sourceStats.containsKey(source))
                          .map((source) => DropdownMenuItem<String?>(
                                value: source,
                                child:
                                    Text('$source (${_sourceStats[source]})'),
                              ))
                          .toList(),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filterSource = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Dropdown de Tipo de Erro
              Container(
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String?>(
                    value: _filterErrorType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Filtrar por tipo de erro'),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos os erros'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'conteudo',
                        child: Text('Erro de conteúdo'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'atencao',
                        child: Text('Erro de atenção'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'tempo',
                        child: Text('Erro de tempo'),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() {
                        _filterErrorType = value;
                      });
                    },
                  ),
                ),
              ),

              // Botão Limpar
              if (_filterSubject != null ||
                  _filterYear != null ||
                  _filterSource != null ||
                  _filterErrorType != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _filterSubject = null;
                          _filterYear = null;
                          _filterSource = null;
                          _filterErrorType = null;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear,
                                size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Limpar filtros',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Lista de questões
        Expanded(
          child: filteredQuestions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma questão encontrada',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_filterSubject != null ||
                          _filterYear != null ||
                          _filterSource != null ||
                          _filterErrorType != null)
                        Text(
                          'Tente alterar os filtros',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final question = filteredQuestions[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.getSubjectColor(question.subject),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(
                          question.subject,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${question.topic}${question.subtopic != null ? " - ${question.subtopic}" : ""}',
                            ),
                            if (question.year != null ||
                                question.source != null) ...[
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (question.year != null)
                                    Chip(
                                      label: Text(question.year!),
                                      backgroundColor:
                                          Colors.blue.withOpacity(0.1),
                                      side: BorderSide.none,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (question.source != null)
                                    Chip(
                                      label: Text(question.source!),
                                      backgroundColor:
                                          Colors.green.withOpacity(0.1),
                                      side: BorderSide.none,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (question.errors['conteudo'] == true)
                                  _buildErrorBadge('C', Colors.red),
                                if (question.errors['atencao'] == true)
                                  _buildErrorBadge('A', Colors.orange),
                                if (question.errors['tempo'] == true)
                                  _buildErrorBadge('T', Colors.blue),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: AppTheme.infoColor),
                              onPressed: () => _editQuestion(question),
                              tooltip: 'Editar questão',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: AppTheme.dangerColor),
                              onPressed: () => _deleteQuestion(question),
                              tooltip: 'Excluir questão',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showQuestionDetails(question);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNotebookTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma questão cadastrada ainda',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use a aba "Cadastrar" para adicionar questões',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final sortedQuestions = List<Question>.from(_questions);
    sortedQuestions.sort((a, b) {
      final subjectComparison = a.subject.compareTo(b.subject);
      if (subjectComparison != 0) return subjectComparison;
      return a.topic.compareTo(b.topic);
    });

    return QuestionsGridView(questions: sortedQuestions);
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStatCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBadge(String letter, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  int _countErrorType(String errorType) {
    return _questions.where((q) => q.errors[errorType] == true).length;
  }
}

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
            ? AppTheme.primaryColor.withOpacity(0.05)
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
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}

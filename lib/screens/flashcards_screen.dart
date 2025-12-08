import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/enhanced_database_service.dart';
import '../models/flashcard.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('🃏 Flashcards'),
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add), text: 'Criar'),
            Tab(icon: Icon(Icons.school), text: 'Estudar'),
            Tab(icon: Icon(Icons.library_books), text: 'Biblioteca'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CreateFlashcardTab(),
          _StudyFlashcardsTab(),
          _FlashcardLibraryTab(),
        ],
      ),
    );
  }
}

// ========== ABA CRIAR ==========
class _CreateFlashcardTab extends StatefulWidget {
  const _CreateFlashcardTab();

  @override
  State<_CreateFlashcardTab> createState() => _CreateFlashcardTabState();
}

class _CreateFlashcardTabState extends State<_CreateFlashcardTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSubject;
  final _topicController = TextEditingController();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();

  @override
  void dispose() {
    _topicController.dispose();
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  Future<void> _saveFlashcard() async {
    if (!_formKey.currentState!.validate()) return;

    final flashcard = Flashcard(
      id: 'fc_${DateTime.now().millisecondsSinceEpoch}',
      subject: _selectedSubject!,
      topic: _topicController.text,
      front: _frontController.text,
      back: _backController.text,
      createdAt: DateTime.now().toIso8601String(),
    );

    final db = context.read<EnhancedDatabaseService>();
    await db.insertFlashcard(flashcard);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Flashcard criado com sucesso!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      _topicController.clear();
      _frontController.clear();
      _backController.clear();
      setState(() {
        _selectedSubject = null;
      });
    }
  }

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
                color: Colors.white,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.create, color: AppTheme.primaryColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Criar Novo Flashcard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: const InputDecoration(
                    labelText: 'Matéria *',
                    prefixIcon: Icon(Icons.book),
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
                  validator: (value) => value == null ? 'Selecione uma matéria' : null,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Tópico *',
                    prefixIcon: Icon(Icons.topic),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Digite o tópico' : null,
                ),
                
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _frontController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Frente (Pergunta) *',
                    hintText: 'Digite a pergunta ou conceito...',
                    prefixIcon: Icon(Icons.help_outline),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Digite a frente do card' : null,
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _backController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Verso (Resposta) *',
                    hintText: 'Digite a resposta ou explicação...',
                    prefixIcon: Icon(Icons.lightbulb_outline),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Digite o verso do card' : null,
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saveFlashcard,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar Flashcard'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ========== ABA ESTUDAR ==========
class _StudyFlashcardsTab extends StatefulWidget {
  const _StudyFlashcardsTab();

  @override
  State<_StudyFlashcardsTab> createState() => _StudyFlashcardsTabState();
}

class _StudyFlashcardsTabState extends State<_StudyFlashcardsTab> {
  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  Future<void> _loadDueCards() async {
    setState(() => _isLoading = true);
    
    final db = context.read<EnhancedDatabaseService>();
    final cards = await db.getDueFlashcards();
    
    setState(() {
      _dueCards = cards;
      _currentIndex = 0;
      _showAnswer = false;
      _isLoading = false;
    });
  }

  Future<void> _reviewCard(int quality) async {
    if (_currentIndex >= _dueCards.length) return;

    final card = _dueCards[_currentIndex];
    final updated = _calculateNextReview(card, quality);
    
    final db = context.read<EnhancedDatabaseService>();
    await db.updateFlashcard(updated);
    
    if (_currentIndex < _dueCards.length - 1) {
      setState(() {
        _currentIndex++;
        _showAnswer = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  Flashcard _calculateNextReview(Flashcard card, int quality) {
    int newEaseFactor = card.easeFactor;
    int newInterval = card.interval;
    
    if (quality < 3) {
      // Errou - resetar
      newInterval = 1;
      newEaseFactor = (card.easeFactor - 20).clamp(130, 250);
    } else {
      // Acertou
      if (card.reviewCount == 0) {
        newInterval = 1;
      } else if (card.reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (newInterval * newEaseFactor / 100).round();
      }
      
      newEaseFactor = (card.easeFactor + (quality - 3) * 10).clamp(130, 250);
    }
    
    final nextReview = DateTime.now().add(Duration(days: newInterval));
    
    return card.copyWith(
      easeFactor: newEaseFactor,
      interval: newInterval,
      nextReview: nextReview.toIso8601String(),
      reviewCount: card.reviewCount + 1,
      lastReviewedAt: DateTime.now().toIso8601String(),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Parabéns!'),
        content: const Text('Você completou todas as revisões de hoje!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadDueCards();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dueCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[300]),
            const SizedBox(height: 16),
            const Text(
              'Nenhum card para revisar hoje!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Volte amanhã ou crie novos flashcards',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    final card = _dueCards[_currentIndex];

    return Column(
      children: [
        // Progress
        Container(
          padding: const EdgeInsets.all(16),
          color: AppTheme.primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card ${_currentIndex + 1} de ${_dueCards.length}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                '${card.subject} - ${card.topic}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showAnswer = !_showAnswer),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAnswer ? Icons.lightbulb : Icons.help_outline,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _showAnswer ? 'RESPOSTA' : 'PERGUNTA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                _showAnswer ? card.back : card.front,
                                style: const TextStyle(
                                  fontSize: 20,
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (!_showAnswer) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Toque para revelar',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                if (_showAnswer) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Como foi sua resposta?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _ReviewButton(
                          label: 'Errei',
                          icon: Icons.close,
                          color: AppTheme.dangerColor,
                          onPressed: () => _reviewCard(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReviewButton(
                          label: 'Difícil',
                          icon: Icons.sentiment_dissatisfied,
                          color: AppTheme.warningColor,
                          onPressed: () => _reviewCard(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReviewButton(
                          label: 'Fácil',
                          icon: Icons.check,
                          color: AppTheme.successColor,
                          onPressed: () => _reviewCard(5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ReviewButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// ========== ABA BIBLIOTECA ==========
class _FlashcardLibraryTab extends StatefulWidget {
  const _FlashcardLibraryTab();

  @override
  State<_FlashcardLibraryTab> createState() => _FlashcardLibraryTabState();
}

class _FlashcardLibraryTabState extends State<_FlashcardLibraryTab> {
  List<Flashcard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    
    final db = context.read<EnhancedDatabaseService>();
    final cards = await db.getFlashcards();
    
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  Future<void> _deleteCard(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Flashcard'),
        content: const Text('Tem certeza que deseja excluir este flashcard?'),
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
      final db = context.read<EnhancedDatabaseService>();
      await db.deleteFlashcard(id);
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Nenhum flashcard criado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cards.length,
      itemBuilder: (context, index) {
        final card = _cards[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.getSubjectColor(card.subject).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.credit_card,
                color: AppTheme.getSubjectColor(card.subject),
              ),
            ),
            title: Text(
              card.subject,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(card.topic),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PERGUNTA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(card.front),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'RESPOSTA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(card.back),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Revisões: ${card.reviewCount}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.dangerColor),
                          onPressed: () => _deleteCard(card.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
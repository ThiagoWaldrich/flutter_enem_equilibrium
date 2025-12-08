import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../services/database_service.dart';
import '../services/monthly_goals_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Map<String, dynamic>? _currentGoals;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    
    final goalsService = context.read<MonthlyGoalsService>();
    await goalsService.reload();
    
    setState(() {
      _currentGoals = goalsService.currentMonthGoals;
      _isLoading = false;
    });
  }

  void _showGoalGeneratorDialog() {
    showDialog(
      context: context,
      builder: (context) => _GoalGeneratorDialog(
        onGoalsGenerated: () {
          _loadGoals();
        },
      ),
    );
  }

  void _deleteGoals() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Metas'),
        content: const Text('Tem certeza que deseja excluir as metas do mês atual?'),
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
      final goalsService = context.read<MonthlyGoalsService>();
      await goalsService.deleteCurrentMonthGoals();
      _loadGoals();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metas excluídas com sucesso'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: const Text('🎯 Metas Mensais', style: TextStyle(color: Colors.white),),
        actions: [
          if (_currentGoals != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteGoals,
              tooltip: 'Excluir Metas',
              color: Colors.white,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentGoals == null
              ? _buildEmptyState()
              : _buildGoalsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showGoalGeneratorDialog,
        icon: const Icon(Icons.auto_awesome),
        label: Text(_currentGoals == null ? 'Gerar Metas' : 'Regenerar Metas'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma meta definida',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Clique no botão abaixo para gerar suas metas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    final config = _currentGoals!['config'] as Map<String, dynamic>;
    final subjects = _currentGoals!['subjects'] as Map<String, dynamic>;
    
    final monthName = DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now());
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de configuração
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.settings, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Configuração - ${monthName.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildConfigRow('Horas por dia', '${config['hoursPerDay']}h'),
                _buildConfigRow('Sábado', config['includeSaturday'] ? 'Sim' : 'Não'),
                _buildConfigRow('Domingo', config['includeSunday'] ? 'Sim' : 'Não'),
                _buildConfigRow('Total de horas', '${config['totalHours']}h'),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Card de pesos
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pie_chart, color: AppTheme.primaryColor),
                    SizedBox(width: 12),
                    Text(
                      'Distribuição por Área',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildWeightRow('Linguagens', config['weights']['linguagens']),
                _buildWeightRow('Matemática', config['weights']['matematica']),
                _buildWeightRow('Natureza', config['weights']['natureza']),
                _buildWeightRow('Humanas', config['weights']['humanas']),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Metas por matéria
        const Text(
          'Metas por Matéria',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        ...subjects.entries.map((entry) {
          final subject = entry.key;
          final hours = entry.value as num;
          final color = AppTheme.getSubjectColor(subject);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.book, color: color),
              ),
              title: Text(
                subject,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Meta: ${hours.toStringAsFixed(1)} horas'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${hours.toStringAsFixed(0)}h',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
        
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRow(String area, num weight) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              area,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: weight / 10,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 30,
            child: Text(
              weight.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalGeneratorDialog extends StatefulWidget {
  final VoidCallback onGoalsGenerated;

  const _GoalGeneratorDialog({
    required this.onGoalsGenerated,
  });

  @override
  State<_GoalGeneratorDialog> createState() => _GoalGeneratorDialogState();
}

class _GoalGeneratorDialogState extends State<_GoalGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  double _hoursPerDay = 6.0;
  bool _includeSaturday = true;
  bool _includeSunday = false;
  
  final Map<String, int> _weights = {
    'linguagens': 2,
    'matematica': 3,
    'natureza': 3,
    'humanas': 2,
  };
  
  bool _useAutodiagnostico = true;
  bool _isGenerating = false;

  int get _totalWeight => _weights.values.reduce((a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
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
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Gerador de Metas Mensais',
                      style: TextStyle(
                        fontSize: 20,
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
            
            // Content
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Horas por dia
                    const Text(
                      'Quantas horas por dia você vai estudar?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _hoursPerDay,
                            min: 1,
                            max: 12,
                            divisions: 22,
                            label: '${_hoursPerDay.toStringAsFixed(1)}h',
                            onChanged: (value) {
                              setState(() {
                                _hoursPerDay = value;
                              });
                            },
                          ),
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_hoursPerDay.toStringAsFixed(1)}h',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Dias da semana
                    const Text(
                      'Dias de estudo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Incluir sábado'),
                      value: _includeSaturday,
                      onChanged: (value) {
                        setState(() {
                          _includeSaturday = value ?? true;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Incluir domingo'),
                      value: _includeSunday,
                      onChanged: (value) {
                        setState(() {
                          _includeSunday = value ?? false;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Método de distribuição
                    const Text(
                      'Método de distribuição',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      title: const Text('Usar dados do Autodiagnóstico'),
                      subtitle: const Text('Distribui horas baseado nos erros'),
                      value: true,
                      groupValue: _useAutodiagnostico,
                      onChanged: (value) {
                        setState(() {
                          _useAutodiagnostico = value ?? true;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      title: const Text('Usar pesos das áreas'),
                      subtitle: const Text('Distribui horas baseado nos pesos'),
                      value: false,
                      groupValue: _useAutodiagnostico,
                      onChanged: (value) {
                        setState(() {
                          _useAutodiagnostico = value ?? true;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Pesos das áreas
                    if (!_useAutodiagnostico) ...[
                      Row(
                        children: [
                          const Text(
                            'Pesos das áreas (Total: ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$_totalWeight)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildWeightSlider('Linguagens', 'linguagens'),
                      _buildWeightSlider('Matemática', 'matematica'),
                      _buildWeightSlider('Natureza', 'natureza'),
                      _buildWeightSlider('Humanas', 'humanas'),
                    ],
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isGenerating ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generateGoals,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isGenerating ? 'Gerando...' : 'Gerar Metas'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightSlider(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Slider(
              value: _weights[key]!.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: _weights[key].toString(),
              onChanged: (value) {
                setState(() {
                  _weights[key] = value.toInt();
                });
              },
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              _weights[key].toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateGoals() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);

    try {
      final goalsService = context.read<MonthlyGoalsService>();
      
      await goalsService.generateGoals(
        hoursPerDay: _hoursPerDay,
        includeSaturday: _includeSaturday,
        includeSunday: _includeSunday,
        useAutodiagnostico: _useAutodiagnostico,
        weights: _weights,
      );
      
      if (mounted) {
        Navigator.pop(context);
        widget.onGoalsGenerated();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Metas geradas com sucesso!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar metas: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}
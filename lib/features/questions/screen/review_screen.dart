import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/constants.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late TextEditingController _weeklyWorkedController;
  late TextEditingController _weeklyNotWorkedController;
  late TextEditingController _weeklyImproveController;
  late TextEditingController _monthlyWorkedController;
  late TextEditingController _monthlyNotWorkedController;
  late TextEditingController _monthlyImproveController;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  void _loadReview() async {
    final storageService = context.read<StorageService>();
    final review = storageService.getData(AppConstants.keyReview) ?? {
      'weekly': {'worked': '', 'notWorked': '', 'improve': ''},
      'monthly': {'worked': '', 'notWorked': '', 'improve': ''},
    };
    
    _weeklyWorkedController = TextEditingController(
      text: review['weekly']?['worked'] ?? '',
    );
    _weeklyNotWorkedController = TextEditingController(
      text: review['weekly']?['notWorked'] ?? '',
    );
    _weeklyImproveController = TextEditingController(
      text: review['weekly']?['improve'] ?? '',
    );
    _monthlyWorkedController = TextEditingController(
      text: review['monthly']?['worked'] ?? '',
    );
    _monthlyNotWorkedController = TextEditingController(
      text: review['monthly']?['notWorked'] ?? '',
    );
    _monthlyImproveController = TextEditingController(
      text: review['monthly']?['improve'] ?? '',
    );
  }

  @override
  void dispose() {
    _weeklyWorkedController.dispose();
    _weeklyNotWorkedController.dispose();
    _weeklyImproveController.dispose();
    _monthlyWorkedController.dispose();
    _monthlyNotWorkedController.dispose();
    _monthlyImproveController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    final storageService = context.read<StorageService>();
    final review = {
      'weekly': {
        'worked': _weeklyWorkedController.text,
        'notWorked': _weeklyNotWorkedController.text,
        'improve': _weeklyImproveController.text,
      },
      'monthly': {
        'worked': _monthlyWorkedController.text,
        'notWorked': _monthlyNotWorkedController.text,
        'improve': _monthlyImproveController.text,
      },
    };
    
    await storageService.saveData(AppConstants.keyReview, review);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisão salva com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildReviewSection(
    String title,
    TextEditingController workedController,
    TextEditingController notWorkedController,
    TextEditingController improveController,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            const Text('O que funcionou:'),
            const SizedBox(height: 8),
            TextField(
              controller: workedController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text('O que não funcionou:'),
            const SizedBox(height: 8),
            TextField(
              controller: notWorkedController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text('O que melhorar:'),
            const SizedBox(height: 8),
            TextField(
              controller: improveController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
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
        title: const Text('Revisão'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReviewSection(
            'Revisão Semanal',
            _weeklyWorkedController,
            _weeklyNotWorkedController,
            _weeklyImproveController,
          ),
          
          _buildReviewSection(
            'Revisão Mensal',
            _monthlyWorkedController,
            _monthlyNotWorkedController,
            _monthlyImproveController,
          ),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveReview,
              child: const Text('Salvar Revisão'),
            ),
          ),
        ],
      ),
    );
  }
}
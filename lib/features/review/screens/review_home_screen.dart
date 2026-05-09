// lib/features/review/screens/review_home_screen.dart
import 'package:equilibrium/features/questions/models/question.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/priority_calculator_service.dart';
import '../models/priority_item_model.dart';
import '../widgets/priority_card_widget.dart';
import 'pomodoro_screen.dart';

class ReviewHomeScreen extends StatefulWidget {
  const ReviewHomeScreen({super.key});

  @override
  State<ReviewHomeScreen> createState() => _ReviewHomeScreenState();
}

class _ReviewHomeScreenState extends State<ReviewHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.emoji_events), text: 'Prioridades'),
                  Tab(icon: Icon(Icons.timer), text: 'Pomodoro'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrioritiesTab(),
                const PomodoroScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritiesTab() {
    return Consumer<PriorityCalculatorService>(
      builder: (context, service, child) {
        return FutureBuilder<List<PriorityItem>>(
          future: service.getPrioritizedTopics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analisando seus erros...'),
                  ],
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erro: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => service.refresh(),
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }
            
            final items = snapshot.data ?? [];
            
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('Nenhum erro registrado!'),
                    SizedBox(height: 8),
                    Text('Continue estudando para manter o ritmo.'),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isTop3 = index < 3;
                return _buildPriorityCard(item, index, isTop3);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityCard(PriorityItem item, int index, bool isTop3) {
    Color cardColor;
    IconData medalIcon;
    Color medalColor;
    
    if (index == 0) {
      cardColor = const Color(0xFFFFD700);
      medalIcon = Icons.emoji_events;
      medalColor = const Color(0xFFFFB800);
    } else if (index == 1) {
      cardColor = const Color(0xFFC0C0C0);
      medalIcon = Icons.emoji_events;
      medalColor = const Color(0xFFA0A0A0);
    } else if (index == 2) {
      cardColor = const Color(0xFFCD7F32);
      medalIcon = Icons.emoji_events;
      medalColor = const Color(0xFFB87333);
    } else {
      cardColor = Colors.white;
      medalIcon = Icons.error_outline;
      medalColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isTop3
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardColor.withOpacity(0.15),
                  cardColor.withOpacity(0.05),
                ],
              )
            : null,
        color: isTop3 ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3 ? cardColor.withOpacity(0.5) : Colors.grey.shade200,
          width: isTop3 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop3 ? cardColor.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Definir sessão de estudo para: ${item.topic}'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (isTop3)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: medalColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      medalIcon,
                      color: medalColor,
                      size: 24,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.subject,
                        style: TextStyle(
                          fontSize: 11,
                          color: isTop3 ? medalColor : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: item.errorsByType.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getErrorColor(entry.key).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${entry.key.displayName}: ${entry.value}',
                              style: TextStyle(
                                fontSize: 9,
                                color: _getErrorColor(entry.key),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isTop3 ? medalColor.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.totalErrorCount} erros',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTop3 ? medalColor : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getErrorColor(ErrorType type) {
    switch (type) {
      case ErrorType.conteudo:
        return Colors.red;
      case ErrorType.atencao:
        return Colors.orange;
      case ErrorType.tempo:
        return Colors.blue;
    }
  }
}
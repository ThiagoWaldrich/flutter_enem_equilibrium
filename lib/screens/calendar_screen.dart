import 'package:equilibrium/screens/access_logs_screen.dart';
import 'package:equilibrium/screens/flashcards_screen.dart';
import 'package:equilibrium/screens/manage_subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_panel.dart';
import '../widgets/monthly_goals_panel.dart';
import '../utils/theme.dart';
import 'autodiagnostico_screen.dart';
import 'goals_screen.dart';
import 'review_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  final List<String> _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro'
  ];

  bool _isContextReady = false;

  @override
  void initState() {
    super.initState();
    // Usar WidgetsBinding para garantir que o contexto está pronto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isContextReady = true;
        });
        final calendarService =
            Provider.of<CalendarService>(context, listen: false);
        calendarService.updateMonthlyGoals(
            DateFormat('yyyy-MM').format(DateTime.now()) // Mudado para yyyy-MM
            );
      }
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(today.year, today.month);
      _selectedDate = today;
    });
  }

  void _navigateToSubjects() {
    if (_selectedDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManageSubjectsScreen(
            date: _selectedDate!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um dia primeiro'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToAutodiagnostico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AutodiagnosticoScreen(),
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Row(
      children: [
        // Seletor de mês
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth.month - 1,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Colors.black, size: 20),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(_months[index], style: const TextStyle(color: Colors.black)),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, value + 1);
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Seletor de ano
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth.year,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Colors.black, size: 20),
              items: [
                for (int year = DateTime.now().year - 1;
                    year <= DateTime.now().year + 3;
                    year++)
                  year
              ].map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString(), style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonth = DateTime(value, _selectedMonth.month);
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        IconButton(
          icon: const Icon(Icons.flag, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalsScreen(),
              ),
            );
          },
          tooltip: 'Metas Mensais',
        ),
        
        IconButton(
          icon: const Icon(Icons.credit_card, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FlashcardsScreen(),
            ),
          ),
          tooltip: 'Flashcards',
        ),
        
        IconButton(
          icon: const Icon(Icons.analytics, color: Colors.white),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AccessLogsScreen(),
            ),
          ),
          tooltip: 'Logs de Acesso',
        ),

        // Botão Hoje
        IconButton(
          icon: const Icon(Icons.today, color: Colors.white),
          onPressed: _goToToday,
          tooltip: 'Ir para hoje',
        ),

        // Botão Gerenciar Matérias
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _navigateToSubjects,
          tooltip: 'Gerenciar Matérias',
        ),

        const SizedBox(width: 4),

        // Botão Autodiagnóstico
        IconButton(
          icon: const Icon(Icons.assessment, color: Colors.white),
          onPressed: _navigateToAutodiagnostico,
          tooltip: 'Autodiagnóstico',
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Calendário reduzido
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CalendarGrid(
              selectedMonth: _selectedMonth,
              selectedDate: _selectedDate,
              onDateSelected: _selectDate,
              daySize: 40.0,
              spacing: 4.0,
            ),
          ),
        ),

        // Painel do dia ou espaço vazio
        if (_selectedDate != null)
          Expanded(
            flex: 1,
            child: DayPanel(
              selectedDate: _selectedDate!,
              onClose: () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
          )
        else
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Selecione um dia',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Clique em qualquer dia do calendário',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Metas mensais
        const Expanded(
          flex: 1,
          child: MonthlyGoalsPanel(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CalendarGrid(
                    selectedMonth: _selectedMonth,
                    selectedDate: _selectedDate,
                    onDateSelected: _selectDate,
                    daySize: 38.0,
                    spacing: 4.0,
                  ),
                ),
              ),
              const Expanded(
                flex: 1,
                child: MonthlyGoalsPanel(),
              ),
            ],
          ),
        ),
        if (_selectedDate != null)
          SizedBox(
            width: 400,
            child: DayPanel(
              selectedDate: _selectedDate!,
              onClose: () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: CalendarGrid(
            selectedMonth: _selectedMonth,
            selectedDate: _selectedDate,
            onDateSelected: _selectDate,
            daySize: 35.0,
            spacing: 3.0,
          ),
        ),
        if (_selectedDate != null)
          Positioned(
            bottom: 70,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) => Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: DayPanel(
                        selectedDate: _selectedDate!,
                        onClose: () => Navigator.pop(context),
                        scrollController: scrollController,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Ver Dia'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF011B3D),
      appBar: AppBar(
        title: const Text(
          '🎯Equilibrium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white
          ),
        ),
        backgroundColor: const Color(0xFF011B3D),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [_buildAppBarActions()],
      ),
      body: !_isContextReady
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1200) {
                  return _buildDesktopLayout();
                } else if (constraints.maxWidth > 800) {
                  return _buildTabletLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800
          ? BottomNavigationBar(
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.flag),
                  label: 'Metas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.rate_review),
                  label: 'Revisão',
                ),
              ],
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoalsScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ReviewScreen(),
                    ),
                  );
                }
              },
            )
          : null,
    );
  }
}
import 'package:equilibrium/features/subjects/screen/manage_subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../logic/calendar_service.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_panel.dart';
import '../widgets/glass_container.dart';
import '../widgets/month_year_selector.dart'; 
import '../../goals/widgets/monthly_goals_panel.dart';
import '../../questions/screen/autodiagnostico_screen.dart';
import '../../goals/screen/goals_screen.dart';

final backgroundColor = const Color(0xFF011B3D).withValues(alpha: 1.0);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;

  static const List<String> _months = [
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
  static final DateFormat _monthYearFormat = DateFormat('yyyy-MM');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isContextReady = true;
        });
        final calendarService =
            Provider.of<CalendarService>(context, listen: false);
        calendarService
            .updateMonthlyGoals(_monthYearFormat.format(DateTime.now()));
      }
    });
  }

  void _selectDate(DateTime date) {
    if (_selectedDate?.year == date.year &&
        _selectedDate?.month == date.month &&
        _selectedDate?.day == date.day) {
      return;
    }
    setState(() {
      _selectedDate = date;
    });
  }

  void _goToToday() {
    final today = DateTime.now();
    final newMonth = DateTime(today.year, today.month);
    if (_selectedMonth.year != newMonth.year ||
        _selectedMonth.month != newMonth.month ||
        _selectedDate?.day != today.day) {
      setState(() {
        _selectedMonth = newMonth;
        _selectedDate = today;
      });
    }
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
    return _AppBarActionsContainer(
      selectedMonth: _selectedMonth,
      months: _months,
      onTodayPressed: _goToToday,
      onGoalsPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GoalsScreen(),
          ),
        );
      },
      onSchedulePressed: () {
        Navigator.pushNamed(context, '/weekly-schedule');
      },
      onSubjectsPressed: _navigateToSubjects,
      onDiagnosticPressed: _navigateToAutodiagnostico,
      onMonthChanged: (month) {
        setState(() {
          _selectedMonth = DateTime(_selectedMonth.year, month + 1);
        });
      },
      onYearChanged: (year) {
        setState(() {
          _selectedMonth = DateTime(year, _selectedMonth.month);
        });
      },
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: RepaintBoundary(
            child: GlassContainer(
              blur: 4.0,
              opacity: 0.02,
              child: CalendarGrid(
                selectedMonth: _selectedMonth,
                selectedDate: _selectedDate,
                onDateSelected: _selectDate,
                daySize: 40.0,
                spacing: 4.0,
              ),
            ),
          ),
        ),

       
        if (_selectedDate != null)
          Expanded(
            flex: 1,
            child: RepaintBoundary(
              child: GlassContainer(
                blur: 4.0,
                opacity: 0.02,
                margin: const EdgeInsets.only(
                    left: 8, right: 12, top: 12, bottom: 12),
                child: DayPanel(
                  selectedDate: _selectedDate!,
                  onClose: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                ),
              ),
            ),
          )
        else
          const Expanded(
            flex: 1,
            child: RepaintBoundary(
              child: _EmptyDayPanel(),
            ),
          ),

        const Expanded(
          flex: 1,
          child: RepaintBoundary(
            child: GlassContainer(
              blur: 4.0,
              opacity: 0.02,
              margin: EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: MonthlyGoalsPanel(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: RepaintBoundary(
                  child: GlassContainer(
                    blur: 4.0,
                    opacity: 0.02,
                    child: CalendarGrid(
                      selectedMonth: _selectedMonth,
                      selectedDate: _selectedDate,
                      onDateSelected: _selectDate,
                      daySize: 38.0,
                      spacing: 4.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(
                flex: 1,
                child: RepaintBoundary(
                  child: GlassContainer(
                    blur: 4.0,
                    opacity: 0.02,
                    child: MonthlyGoalsPanel(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedDate != null)
          SizedBox(
            width: 400,
            child: RepaintBoundary(
              child: GlassContainer(
                blur: 4.0,
                opacity: 0.02,
                margin: const EdgeInsets.all(12.0),
                child: DayPanel(
                  selectedDate: _selectedDate!,
                  onClose: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(BoxConstraints constraints) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: RepaintBoundary(
            child: GlassContainer(
              blur: 4.0,
              opacity: 0.02,
              child: CalendarGrid(
                selectedMonth: _selectedMonth,
                selectedDate: _selectedDate,
                onDateSelected: _selectDate,
                daySize: 35.0,
                spacing: 3.0,
              ),
            ),
          ),
        ),
        if (_selectedDate != null)
          Positioned(
            bottom: 70,
            right: 16,
            child: FloatingActionButton.extended(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              foregroundColor: Colors.white,
              heroTag: 'dayPanelFAB',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  useRootNavigator: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    expand: false,
                    builder: (context, scrollController) => RepaintBoundary(
                      child: GlassContainer(
                        blur: 6.0,
                        opacity: 0.03,
                        margin: const EdgeInsets.all(16.0),
                        child: DayPanel(
                          selectedDate: _selectedDate!,
                          onClose: () => Navigator.pop(context),
                          scrollController: scrollController,
                        ),
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
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '🎯Equilibrium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [_buildAppBarActions()],
      ),
      body: !_isContextReady
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1200) {
                  return _buildDesktopLayout(constraints);
                } else if (constraints.maxWidth > 800) {
                  return _buildTabletLayout(constraints);
                } else {
                  return _buildMobileLayout(constraints);
                }
              },
            ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF011B3D).withValues(alpha: 0.8),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withValues(alpha: 0.6),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              type: BottomNavigationBarType.fixed,
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
                }
              },
            )
          : null,
    );
  }
}
class _AppBarActionsContainer extends StatelessWidget {
  final DateTime selectedMonth;
  final List<String> months;
  final VoidCallback onTodayPressed;
  final VoidCallback onGoalsPressed;
  final VoidCallback onSchedulePressed;
  final VoidCallback onSubjectsPressed;
  final VoidCallback onDiagnosticPressed;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const _AppBarActionsContainer({
    required this.selectedMonth,
    required this.months,
    required this.onTodayPressed,
    required this.onGoalsPressed,
    required this.onSchedulePressed,
    required this.onSubjectsPressed,
    required this.onDiagnosticPressed,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        MonthYearSelector( 
          selectedMonth: selectedMonth,
          months: months,
          onMonthChanged: onMonthChanged,
          onYearChanged: onYearChanged,
        ),
        
        const SizedBox(width: 8),
        
        _OptimizedIconButton(
          icon: Icons.flag,
          tooltip: 'Metas Mensais',
          onPressed: onGoalsPressed,
        ),
        
        _OptimizedIconButton(
          icon: Icons.today,
          tooltip: 'Ir para hoje',
          onPressed: onTodayPressed,
        ),
        
        _OptimizedIconButton(
          icon: Icons.schedule,
          tooltip: 'Horários Semanais',
          onPressed: onSchedulePressed,
        ),
        
        _OptimizedIconButton(
          icon: Icons.edit,
          tooltip: 'Gerenciar Matérias',
          onPressed: onSubjectsPressed,
        ),
        
        _OptimizedIconButton(
          icon: Icons.assessment,
          tooltip: 'Autodiagnóstico',
          onPressed: onDiagnosticPressed,
        ),
      ],
    );
  }
}

class _OptimizedIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _OptimizedIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 20,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}
class _EmptyDayPanel extends StatelessWidget {
  const _EmptyDayPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecione um dia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clique em qualquer dia do calendário',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
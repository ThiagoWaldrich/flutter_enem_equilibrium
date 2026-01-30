import 'package:equilibrium/features/subjects/screen/manage_subjects_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../logic/calendar_service.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_panel.dart';
import '../../goals/widgets/monthly_goals_panel.dart';
import '../../questions/screen/autodiagnostico_screen.dart';
import '../../goals/screen/goals_screen.dart';
import '../../questions/screen/review_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color color;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(12.0),
    this.borderRadius = 20.0,
    this.blur = 6.0,
    this.opacity = 0.03,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color.withValues(alpha:opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.12),
          width: 0.7,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: RepaintBoundary(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
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
        calendarService.updateMonthlyGoals(
          _monthYearFormat.format(DateTime.now())
        );
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
    return Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        _MonthYearSelector(
          selectedMonth: _selectedMonth,
          months: _months,
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
        ),
        const SizedBox(width: 8),
        _AppBarIconButton(
          icon: Icons.flag,
          tooltip: 'Metas Mensais',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GoalsScreen(),
              ),
            );
          },
        ),

        _AppBarIconButton(
          icon: Icons.today,
          tooltip: 'Ir para hoje',
          onPressed: _goToToday,
        ),

        _AppBarIconButton(
          icon: Icons.schedule,
          tooltip: 'Horários Semanais',
          onPressed: () {
            Navigator.pushNamed(context, '/weekly-schedule');
          },
        ),

        _AppBarIconButton(
          icon: Icons.edit,
          tooltip: 'Gerenciar Matérias',
          onPressed: _navigateToSubjects,
        ),

        _AppBarIconButton(
          icon: Icons.assessment,
          tooltip: 'Autodiagnóstico',
          onPressed: _navigateToAutodiagnostico,
        ),
      ],
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

        // Painel do dia
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

        // Metas mensais
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
              // Calendário
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
              // Metas mensais
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
              backgroundColor: Colors.white.withValues(alpha:0.15),
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
      backgroundColor: const Color(0xFF011B3D),
      appBar: AppBar(
        title: const Text(
          '🎯Equilibrium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF011B3D),
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
          ? _buildBottomNavBar()
          : null,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF011B3D).withValues(alpha:0.8),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withValues(alpha:0.6),
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed, // ✅ Melhor performance
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
    );
  }
}
class _MonthYearSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final List<String> months;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const _MonthYearSelector({
    required this.selectedMonth,
    required this.months,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha:0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonth.month - 1,
              dropdownColor: const Color(0xFF011B3D).withValues(alpha:0.95),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 20,
              ),
              items: List.generate(
                12,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text(
                    months[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              onChanged: (value) {
                if (value != null) {
                  onMonthChanged(value);
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Seletor de ano
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha:0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonth.year,
              dropdownColor: const Color(0xFF011B3D).withValues(alpha:0.95),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 20,
              ),
              items: List.generate(
                5, 
                (index) {
                  final year = DateTime.now().year - 1 + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
              onChanged: (value) {
                if (value != null) {
                  onYearChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIconButton({
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
        color: Colors.white.withValues(alpha:0.02),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: Colors.white.withValues(alpha:0.08),
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
              color: Colors.white.withValues(alpha:0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Selecione um dia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha:0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clique em qualquer dia do calendário',
              style: TextStyle(color: Colors.white.withValues(alpha:0.3)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
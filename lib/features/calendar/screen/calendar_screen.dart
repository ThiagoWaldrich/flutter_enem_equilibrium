import 'package:equilibrium/features/subjects/screen/manage_subjects_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/calendar_service.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_panel.dart';
import '../widgets/glass_container.dart';
import '../widgets/month_year_selector.dart';
import '../../goals/widgets/monthly_goals_panel.dart';
import '../../questions/screen/autodiagnostico_screen.dart';
import '../../goals/screen/goals_screen.dart';

const _backgroundColor = Color(0xFF011B3D);


DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _normalizeMonth(DateTime d) => DateTime(d.year, d.month);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedMonth = _normalizeMonth(DateTime.now());
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      Provider.of<CalendarService>(context, listen: false)
          .updateMonthlyGoals('${now.year}-${now.month.toString().padLeft(2, '0')}');
    });
  }

  void _selectDate(DateTime date) {
    final normalized = _normalizeDate(date);
    if (_selectedDate == normalized) return;
    setState(() => _selectedDate = normalized);
  }

  void _goToToday() {
    final today = _normalizeDate(DateTime.now());
    final todayMonth = _normalizeMonth(today);
    if (_selectedMonth != todayMonth || _selectedDate != today) {
      setState(() {
        _selectedMonth = todayMonth;
        _selectedDate = today;
      });
    }
  }

  void _navigateToSubjects() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um dia primeiro'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageSubjectsScreen(date: _selectedDate!),
      ),
    );
  }

  Widget _buildDesktopLayout() {
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
        Expanded(
          child: RepaintBoundary(
            child: _selectedDate != null
                ? GlassContainer(
                    blur: 4.0,
                    opacity: 0.02,
                    margin:
                        const EdgeInsets.only(left: 8, right: 12, top: 12, bottom: 12),
                    child: DayPanel(
                      selectedDate: _selectedDate!,
                      onClose: () => setState(() => _selectedDate = null),
                    ),
                  )
                : const _EmptyDayPanel(),
          ),
        ),
        const Expanded(
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

  Widget _buildTabletLayout() {
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
                  onClose: () => setState(() => _selectedDate = null),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout() {
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
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              foregroundColor: Colors.white,
              heroTag: 'dayPanelFAB',
              onPressed: () => _showDayPanel(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text('Ver Dia'),
            ),
          ),
      ],
    );
  }

  void _showDayPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => RepaintBoundary(
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isWide = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          '🎯Equilibrium',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: _backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _AppBarActions(
            selectedMonth: _selectedMonth,
            onTodayPressed: _goToToday,
            onGoalsPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
            onSchedulePressed: () => Navigator.pushNamed(context, '/weekly-schedule'),
            onSubjectsPressed: _navigateToSubjects,
            onDiagnosticPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AutodiagnosticoScreen()),
            ),
            onMonthChanged: (m) =>
                setState(() => _selectedMonth = DateTime(_selectedMonth.year, m + 1)),
            onYearChanged: (y) =>
                setState(() => _selectedMonth = DateTime(y, _selectedMonth.month)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (_, constraints) {
          if (constraints.maxWidth > 1200) return _buildDesktopLayout();
          if (constraints.maxWidth > 800) return _buildTabletLayout();
          return _buildMobileLayout();
        },
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              backgroundColor: _backgroundColor,
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withValues(alpha: 0.5),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Metas'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.rate_review), label: 'Revisão'),
              ],
              onTap: (index) {
                if (index == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalsScreen()),
                  );
                }
              },
            ),
    );
  }
}

const _months = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
];

class _AppBarActions extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onTodayPressed;
  final VoidCallback onGoalsPressed;
  final VoidCallback onSchedulePressed;
  final VoidCallback onSubjectsPressed;
  final VoidCallback onDiagnosticPressed;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const _AppBarActions({
    required this.selectedMonth,
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
          months: _months,
          onMonthChanged: onMonthChanged,
          onYearChanged: onYearChanged,
        ),
        const SizedBox(width: 8),
        _IconBtn(Icons.flag, 'Metas Mensais', onGoalsPressed),
        _IconBtn(Icons.today, 'Ir para hoje', onTodayPressed),
        _IconBtn(Icons.schedule, 'Horários Semanais', onSchedulePressed),
        _IconBtn(Icons.edit, 'Gerenciar Matérias', onSubjectsPressed),
        _IconBtn(Icons.assessment, 'Autodiagnóstico', onDiagnosticPressed),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconBtn(this.icon, this.tooltip, this.onPressed);

  @override
  Widget build(BuildContext context) => IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      );
}

class _EmptyDayPanel extends StatelessWidget {
  const _EmptyDayPanel();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
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
                color: Colors.white.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 16),
              Text(
                'Selecione um dia',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clique em qualquer dia do calendário',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
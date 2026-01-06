import 'package:equilibrium/screens/manage_subjects_screen.dart';
import 'package:equilibrium/screens/question_bank_screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/day_panel.dart';
import '../widgets/monthly_goals_panel.dart';
import '../utils/theme.dart';
import 'package:marquee/marquee.dart';
import 'autodiagnostico_screen.dart';
import 'goals_screen.dart';
import 'review_screen.dart';

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
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 0.7,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
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

  // Texto para o letreiro Marquee
  final String _marqueeText = 
    '🚀 Sempre começar o dia com as questões do livro dos assuntos que viu no dia • '
    '📚 Após concluir o capítulo do livro estudado no dia, resolver as listas físicas recebidas • '
    '🎯 Livro, PDFs e Listas físicas devem ser organizadas por prioridade• '
    '⏰ Estude até o limite(se existir), descanse 20 minutos e repita o processo... • '
    '🧠 Questão é diagnóstico, não julgamento • '
    '📊 Meta de 90 questões por dia • '
    '💡 Interleaving: misturar matérias fortalece conexões neurais • '
    '📝 Dia excepcional: 100–120 | Dia ruim que ainda conta: 30–40  • '
    '🎧 Música clássica pode melhorar concentração • '
    '💤 Sono de qualidade consolida aprendizagem • '
    '🏃‍♂️ Exercícios físicos aumentam oxigenação cerebral • '
    '🥗 Alimentação saudável = desempenho acadêmico melhor • '
    '🧘‍♀️ Meditação reduz ansiedade pré-prova • '
    '📅 Planejamento semanal evita procrastinação • '
    '🤝 Estudo em grupo eficaz aumenta compreensão • '
    '🔁 Revisão em 24h retém 80% do conteúdo • '
    '🎯 Quantidade suficiente hoje é vitória. Excesso vira sabotagem. • '
    '📈 Progresso constante > perfeccionismo • '
    '💪 2 redações por semana → padrão ideal • '
    '🌟 Celebre pequenas vitórias no processo • ';

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
            .updateMonthlyGoals(DateFormat('yyyy-MM').format(DateTime.now()));
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

  void _navigateToQuestionBank() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionBankScreen(),
      ),
    );
  }

  void _navigateToAutodiagnostico() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AutodiagnosticoScreen(),
      ),
    );
  }

  Widget _buildMarqueeBanner() {
    return GlassContainer(
      margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      blur: 4.0,
      opacity: 0.02,
      height: 42,
      borderRadius: 12.0,
      child: Marquee(
        text: _marqueeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        blankSpace: 60.0,
        velocity: 40.0,
        pauseAfterRound: const Duration(milliseconds: 800),
        startPadding: 20.0,
        accelerationDuration: const Duration(milliseconds: 800),
        accelerationCurve: Curves.easeInOut,
        decelerationDuration: const Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
        fadingEdgeStartFraction: 0.05,
        fadingEdgeEndFraction: 0.05,
      ),
    );
  }

  Widget _buildAppBarActions() {
    return Row(
      children: [
        // Seletor de mês
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth.month - 1,
              dropdownColor: const Color(0xFF011B3D).withOpacity(0.95),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Colors.white, size: 20),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index,
                  child: Text(_months[index],
                      style: const TextStyle(color: Colors.white)),
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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMonth.year,
              dropdownColor: const Color(0xFF011B3D).withOpacity(0.95),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Colors.white, size: 20),
              items: [
                for (int year = DateTime.now().year - 1;
                    year <= DateTime.now().year + 3;
                    year++)
                  year
              ].map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year.toString(),
                      style: const TextStyle(color: Colors.white)),
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
        // IconButton(
        //   icon: const Icon(Icons.library_books, color: Colors.white),
        //   onPressed: _navigateToQuestionBank,
        //   tooltip: 'Banco de Questões',
        // ),

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
    return Column(
      children: [
        // Letreiro Marquee
        _buildMarqueeBanner(),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Calendário SUPER transparente
              Expanded(
                flex: 2,
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

              // Painel do dia SUPER transparente
              if (_selectedDate != null)
                Expanded(
                  flex: 1,
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
                )
              else
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'Selecione um dia',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Clique em qualquer dia do calendário',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.3)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Metas mensais SUPER transparente
              const Expanded(
                flex: 1,
                child: GlassContainer(
                  blur: 4.0,
                  opacity: 0.02,
                  margin: EdgeInsets.only(right: 12, top: 12, bottom: 12),
                  child: MonthlyGoalsPanel(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Letreiro Marquee
        _buildMarqueeBanner(),
        
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    // Calendário
                    Expanded(
                      flex: 2,
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
                    // Metas mensais
                    const SizedBox(height: 12),
                    const Expanded(
                      flex: 1,
                      child: GlassContainer(
                        blur: 4.0,
                        opacity: 0.02,
                        child: MonthlyGoalsPanel(),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedDate != null)
                SizedBox(
                  width: 400,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Letreiro Marquee (menor em mobile)
        GlassContainer(
          margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          blur: 4.0,
          opacity: 0.02,
          height: 36,
          borderRadius: 10.0,
          child: Marquee(
            text: _marqueeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 40.0,
            velocity: 35.0,
            pauseAfterRound: const Duration(milliseconds: 500),
            startPadding: 15.0,
            accelerationDuration: const Duration(milliseconds: 600),
            accelerationCurve: Curves.easeInOut,
            decelerationDuration: const Duration(milliseconds: 400),
            decelerationCurve: Curves.easeOut,
            fadingEdgeStartFraction: 0.05,
            fadingEdgeEndFraction: 0.05,
          ),
        ),
        
        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
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
              if (_selectedDate != null)
                Positioned(
                  bottom: 70,
                  right: 16,
                  child: FloatingActionButton.extended(
                    backgroundColor: Colors.white.withOpacity(0.15),
                    foregroundColor: Colors.white,
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
                          builder: (context, scrollController) => GlassContainer(
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
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Ver Dia'),
                  ),
                ),
            ],
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
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
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
              backgroundColor: const Color(0xFF011B3D).withOpacity(0.8),
              selectedItemColor: Colors.white,
              unselectedItemColor: Colors.white.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
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
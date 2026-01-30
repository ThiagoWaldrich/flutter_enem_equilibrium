import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/theme.dart';

class YearBarChart extends StatelessWidget {
  final Map<String, int> data;

  const YearBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final recent = entries.take(10).toList();

    final barGroups = recent.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value.toDouble(),
            color: Colors.blue,
            width: 20,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    final maxValue = recent.isNotEmpty
        ? recent.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() * 1.1
        : 10.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Distribuição por Ano', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue,
                minY: 0,
                barGroups: barGroups,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < recent.length) {
                          return Text(recent[index].key, style: const TextStyle(fontSize: 11));
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
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

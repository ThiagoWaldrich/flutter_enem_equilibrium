import 'package:flutter/material.dart';

class MonthYearSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final List<String> months;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const MonthYearSelector({
    super.key,
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
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 9.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonth.month - 1,
              dropdownColor: const Color(0xFF011B3D).withValues(alpha: 0.95),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              borderRadius: BorderRadius.circular(8),
              alignment: AlignmentDirectional.centerStart,
              menuMaxHeight: 330,
              underline: const SizedBox(),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 25,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedMonth.year,
              dropdownColor: const Color(0xFF011B3D).withValues(alpha: 0.95),
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
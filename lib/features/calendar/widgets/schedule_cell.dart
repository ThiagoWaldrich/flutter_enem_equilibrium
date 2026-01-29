import 'dart:ui';

class ScheduleCell {
  final int dayIndex;
  final int timeIndex;
  final String subject;
  final Color color;

  ScheduleCell({
    required this.dayIndex,
    required this.timeIndex,
    required this.subject,
    required this.color,
  });

  ScheduleCell copyWith({
    int? dayIndex,
    int? timeIndex,
    String? subject,
    Color? color,
  }) {
    return ScheduleCell(
      dayIndex: dayIndex ?? this.dayIndex,
      timeIndex: timeIndex ?? this.timeIndex,
      subject: subject ?? this.subject,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayIndex': dayIndex,
      'timeIndex': timeIndex,
      'subject': subject,
      'color': color.toARGB32(),
    };
  }

  factory ScheduleCell.fromMap(Map<String, dynamic> map) {
    return ScheduleCell(
      dayIndex: map['dayIndex'] as int,
      timeIndex: map['timeIndex'] as int,
      subject: map['subject'] as String,
      color: Color(map['color'] as int),
    );
  }
}
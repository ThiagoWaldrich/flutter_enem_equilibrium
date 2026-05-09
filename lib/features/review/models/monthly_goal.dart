class MonthlyGoal {
  int targetMinutes;
  DateTime month;
  
  MonthlyGoal({
    required this.targetMinutes,
    required this.month,
  });
  
  factory MonthlyGoal.fromMap(Map<String, dynamic> map) => MonthlyGoal(
    targetMinutes: map['targetMinutes'] as int,
    month: DateTime.parse(map['month'] as String),
  );
  
  Map<String, dynamic> toMap() => {
    'targetMinutes': targetMinutes,
    'month': month.toIso8601String(),
  };
}
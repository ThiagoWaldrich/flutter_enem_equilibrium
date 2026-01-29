class MonthlyGoal {
  final String subject;
  final int target;
  final int current;

  MonthlyGoal({
    required this.subject,
    required this.target,
    required this.current,
  });

  double get percentage => target > 0 ? (current / target) * 100 : 0;
  bool get isCompleted => current >= target;
  bool get isExceeded => current > target;

  MonthlyGoal copyWith({
    String? subject,
    int? target,
    int? current,
  }) {
    return MonthlyGoal(
      subject: subject ?? this.subject,
      target: target ?? this.target,
      current: current ?? this.current,
    );
  }
}
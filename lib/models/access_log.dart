class AccessLog {
  final String id;
  final String date;
  final int accessCount;
  final String firstAccessTime;
  final String lastAccessTime;

  AccessLog({
    required this.id,
    required this.date,
    required this.accessCount,
    required this.firstAccessTime,
    required this.lastAccessTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'access_count': accessCount,
      'first_access_time': firstAccessTime,
      'last_access_time': lastAccessTime,
    };
  }

  factory AccessLog.fromJson(Map<String, dynamic> json) {
    return AccessLog(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      accessCount: json['access_count'] ?? 0,
      firstAccessTime: json['first_access_time'] ?? '',
      lastAccessTime: json['last_access_time'] ?? '',
    );
  }

  AccessLog copyWith({
    String? id,
    String? date,
    int? accessCount,
    String? firstAccessTime,
    String? lastAccessTime,
  }) {
    return AccessLog(
      id: id ?? this.id,
      date: date ?? this.date,
      accessCount: accessCount ?? this.accessCount,
      firstAccessTime: firstAccessTime ?? this.firstAccessTime,
      lastAccessTime: lastAccessTime ?? this.lastAccessTime,
    );
  }
}
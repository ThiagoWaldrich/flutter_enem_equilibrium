class Flashcard {
  final String id;
  final String subject;
  final String topic;
  final String front;
  final String back;
  final int easeFactor; // 0-5
  final int interval; // dias
  final String? nextReview;
  final int reviewCount;
  final String createdAt;
  final String? lastReviewedAt;

  Flashcard({
    required this.id,
    required this.subject,
    required this.topic,
    required this.front,
    required this.back,
    this.easeFactor = 250, // 2.5 * 100
    this.interval = 1,
    this.nextReview,
    this.reviewCount = 0,
    required this.createdAt,
    this.lastReviewedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'front': front,
      'back': back,
      'ease_factor': easeFactor,
      'interval': interval,
      'next_review': nextReview,
      'review_count': reviewCount,
      'created_at': createdAt,
      'last_reviewed_at': lastReviewedAt,
    };
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      easeFactor: json['ease_factor'] ?? 250,
      interval: json['interval'] ?? 1,
      nextReview: json['next_review'],
      reviewCount: json['review_count'] ?? 0,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      lastReviewedAt: json['last_reviewed_at'],
    );
  }

  Flashcard copyWith({
    String? id,
    String? subject,
    String? topic,
    String? front,
    String? back,
    int? easeFactor,
    int? interval,
    String? nextReview,
    int? reviewCount,
    String? createdAt,
    String? lastReviewedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      front: front ?? this.front,
      back: back ?? this.back,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      nextReview: nextReview ?? this.nextReview,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  bool get isDueForReview {
    if (nextReview == null) return true;
    return DateTime.parse(nextReview!).isBefore(DateTime.now());
  }
}
class MindMap {
  final String id;
  final String subject;
  final String topic;
  final List<MindMapFile> files;
  final DateTime timestamp;

  MindMap({
    required this.id,
    required this.subject,
    required this.topic,
    required this.files,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'files': files.map((f) => f.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MindMap.fromJson(Map<String, dynamic> json) {
    return MindMap(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      files: json['files'] != null
          ? (json['files'] as List).map((f) => MindMapFile.fromJson(f)).toList()
          : [],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  MindMap copyWith({
    String? id,
    String? subject,
    String? topic,
    List<MindMapFile>? files,
    DateTime? timestamp,
  }) {
    return MindMap(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      files: files ?? List.from(this.files),
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMap && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MindMapFile {
  final String name;
  final String type;
  final int size;
  final String filePath;
  final DateTime lastModified;

  MindMapFile({
    required this.name,
    required this.type,
    required this.size,
    required this.filePath,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
      'filePath': filePath,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory MindMapFile.fromJson(Map<String, dynamic> json) {
    return MindMapFile(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      filePath: json['filePath'] ?? '',
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : DateTime.now(),
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapFile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          lastModified == other.lastModified;

  @override
  int get hashCode => Object.hash(name, lastModified);
  bool get isImage => type.toLowerCase().startsWith('image/');
  bool get isPdf => type.toLowerCase() == 'application/pdf';
}

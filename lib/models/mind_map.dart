class MindMap {
  final String id;
  final String subject;
  final String topic;
  final List<MindMapFile> files;
  final String timestamp;

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
      'timestamp': timestamp,
    };
  }

  factory MindMap.fromJson(Map<String, dynamic> json) {
    return MindMap(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      files: json['files'] != null
          ? (json['files'] as List)
              .map((f) => MindMapFile.fromJson(f))
              .toList()
          : [],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  MindMap copyWith({
    String? id,
    String? subject,
    String? topic,
    List<MindMapFile>? files,
    String? timestamp,
  }) {
    return MindMap(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      files: files ?? this.files,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class MindMapFile {
  final String name;
  final String type;
  final int size;
  final String data; // Base64
  final int lastModified;

  MindMapFile({
    required this.name,
    required this.type,
    required this.size,
    required this.data,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'size': size,
      'data': data,
      'lastModified': lastModified,
    };
  }

  factory MindMapFile.fromJson(Map<String, dynamic> json) {
    return MindMapFile(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
      data: json['data'] ?? '',
      lastModified: json['lastModified'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool get isImage => type.startsWith('image/');
  bool get isPdf => type == 'application/pdf';
}
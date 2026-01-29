import 'dart:typed_data';

class QuestionImage {
  final String filePath;
  final String? name;
  final String? type;
  final Uint8List? data;
  final String? url;
  final int? size;

  const QuestionImage({
    required this.filePath,
    this.name,
    this.type,
    this.data,
    this.url,
    this.size,
  });

  bool get isPdf => (type?.toLowerCase() == 'pdf' || filePath.toLowerCase().endsWith('.pdf'));
  bool get isImage => ['png', 'jpg', 'jpeg', 'gif', 'webp']
      .any((ext) => filePath.toLowerCase().endsWith('.$ext'));
  
  bool get hasUrl => url != null && url!.isNotEmpty;

  QuestionImage copyWith({
    String? filePath,
    String? name,
    String? type,
    Uint8List? data,
    String? url,
    int? size,
  }) {
    return QuestionImage(
      filePath: filePath ?? this.filePath,
      name: name ?? this.name,
      type: type ?? this.type,
      data: data ?? this.data,
      url: url ?? this.url,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is QuestionImage &&
            runtimeType == other.runtimeType &&
            filePath == other.filePath;
  }

  @override
  int get hashCode => filePath.hashCode;

  @override
  String toString() {
    return 'QuestionImage(filePath: $filePath)';
  }
}
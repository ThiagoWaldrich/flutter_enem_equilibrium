import 'package:flutter/foundation.dart';
import '../models/mind_map.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class MindMapService extends ChangeNotifier {
  final StorageService _storageService;
  Map<String, MindMap> _mindMaps = {};

  MindMapService(this._storageService) {
    _loadData();
  }

  Future<void> _loadData() async {
    final data = _storageService.getData(AppConstants.keyMindMaps);
    if (data != null && data is Map) {
      _mindMaps = data.map(
        (key, value) => MapEntry(
          key as String,
          MindMap.fromJson(value as Map<String, dynamic>),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final data = _mindMaps.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _storageService.saveData(AppConstants.keyMindMaps, data);
  }

  // Obter mapa mental por subject e topic
  MindMap? getMindMap(String subject, String topic) {
    final key = _getKey(subject, topic);
    return _mindMaps[key];
  }

  // Verificar se tem mapas para um tópico
  bool hasMindMaps(String subject, String topic) {
    final mindMap = getMindMap(subject, topic);
    return mindMap != null && mindMap.files.isNotEmpty;
  }

  // Contar arquivos de um tópico
  int getFileCount(String subject, String topic) {
    final mindMap = getMindMap(subject, topic);
    return mindMap?.files.length ?? 0;
  }

  // Adicionar arquivos a um mapa mental
  Future<void> addFiles(
    String subject,
    String topic,
    List<MindMapFile> files,
  ) async {
    final key = _getKey(subject, topic);
    final existing = _mindMaps[key];

    if (existing != null) {
      _mindMaps[key] = existing.copyWith(
        files: [...existing.files, ...files],
        timestamp: DateTime.now().toIso8601String(),
      );
    } else {
      _mindMaps[key] = MindMap(
        id: key,
        subject: subject,
        topic: topic,
        files: files,
        timestamp: DateTime.now().toIso8601String(),
      );
    }

    await _saveData();
    notifyListeners();
  }

  // Remover um arquivo específico
  Future<void> removeFile(
    String subject,
    String topic,
    int fileIndex,
  ) async {
    final key = _getKey(subject, topic);
    final mindMap = _mindMaps[key];

    if (mindMap != null && fileIndex < mindMap.files.length) {
      final updatedFiles = List<MindMapFile>.from(mindMap.files);
      updatedFiles.removeAt(fileIndex);

      if (updatedFiles.isEmpty) {
        _mindMaps.remove(key);
      } else {
        _mindMaps[key] = mindMap.copyWith(
          files: updatedFiles,
          timestamp: DateTime.now().toIso8601String(),
        );
      }

      await _saveData();
      notifyListeners();
    }
  }

  // Remover todos os arquivos de um tópico
  Future<void> removeAllFiles(String subject, String topic) async {
    final key = _getKey(subject, topic);
    _mindMaps.remove(key);
    await _saveData();
    notifyListeners();
  }

  // Obter estatísticas
  Map<String, int> getStatistics() {
    int totalTopics = _mindMaps.length;
    int totalFiles = 0;

    for (final map in _mindMaps.values) {
      totalFiles += map.files.length;
    }

    return {
      'topics': totalTopics,
      'files': totalFiles,
    };
  }

  // Obter todos os tópicos com mapas de uma matéria
  List<String> getTopicsWithMaps(String subject) {
    return _mindMaps.values
        .where((map) => map.subject == subject)
        .map((map) => map.topic)
        .toList();
  }

  // Chave única para subject + topic
  String _getKey(String subject, String topic) {
    return '$subject-$topic';
  }

  Map<String, MindMap> get allMindMaps => Map.unmodifiable(_mindMaps);
}

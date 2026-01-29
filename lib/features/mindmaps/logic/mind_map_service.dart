import 'package:equilibrium/features/core/services/file_upload_service.dart';
import 'package:equilibrium/features/core/services/storage_service.dart';
import 'package:equilibrium/features/core/theme/constants.dart';
import 'package:flutter/foundation.dart';
import '../models/mind_map.dart';


class MindMapService extends ChangeNotifier {
  final StorageService _storageService;
  bool _isInitialized = false;
  bool _isLoading = false;
  Map<String, MindMap> _mindMaps = {};

  MindMapService(this._storageService);

  bool get isLoading => _isLoading;

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      _isLoading = true;
      notifyListeners();
      await _loadData();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadData() async {
    final data = _storageService.getData(AppConstants.keyMindMaps);
    if (data == null) return;
    if (data is! Map) return;

    final Map<String, MindMap> loadedMaps = {};
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      if (value is! Map) continue;

      try {
        final Map<String, dynamic> jsonMap = value.cast<String, dynamic>();
        final mindMap = MindMap.fromJson(jsonMap);
        loadedMaps[key] = mindMap;
      } catch (e) {
        continue;
      }
    }
    _mindMaps = loadedMaps;
    notifyListeners();
  }

  Future<void> _saveData() async {
    final data = _mindMaps.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await _storageService.saveData(AppConstants.keyMindMaps, data);
  }

  MindMap? getMindMap(String subject, String topic) {
    if (!_isInitialized) return null;
    final key = _getKey(subject, topic);
    return _mindMaps[key];
  }

  bool hasMindMaps(String subject, String topic) {
    if (!_isInitialized) return false;
    final mindMap = getMindMap(subject, topic);
    return mindMap != null && mindMap.files.isNotEmpty;
  }

  int getFileCount(String subject, String topic) {
    if (!_isInitialized) return 0;
    final mindMap = getMindMap(subject, topic);
    return mindMap?.files.length ?? 0;
  }

  Future<void> addFiles(String subject, String topic, List<MindMapFile> files) async {
    await ensureInitialized();
    final key = _getKey(subject, topic);
    final existing = _mindMaps[key];

    if (existing != null) {
      _mindMaps[key] = existing.copyWith(
        files: [...existing.files, ...files],
        timestamp: DateTime.now(),
      );
    } else {
      _mindMaps[key] = MindMap(
        id: key,
        subject: subject,
        topic: topic,
        files: files,
        timestamp: DateTime.now(),
      );
    }
    await _saveData();
    notifyListeners();
  }

  Future<void> removeFile(String subject, String topic, int fileIndex) async {
    await ensureInitialized();
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
          timestamp: DateTime.now(),
        );
      }
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> removeAllFiles(String subject, String topic) async {
    await ensureInitialized();
    final key = _getKey(subject, topic);
    final mindMap = _mindMaps[key];
    
    if (mindMap != null) {
      final uploadService = FileUploadService();
      for (final file in mindMap.files) {
        await uploadService.deletePhysicalFile(file.filePath);
      }
    }
    _mindMaps.remove(key);
    await _saveData();
    notifyListeners();
  }

  Map<String, int> getStatistics() {
    if (!_isInitialized) return {'topics': 0, 'files': 0};
    int totalTopics = _mindMaps.length;
    int totalFiles = 0;
    for (final map in _mindMaps.values) {
      totalFiles += map.files.length;
    }
    return {'topics': totalTopics, 'files': totalFiles};
  }

  List<String> getTopicsWithMaps(String subject) {
    if (!_isInitialized) return [];
    return _mindMaps.values
        .where((map) => map.subject == subject)
        .map((map) => map.topic)
        .toList();
  }

  String _getKey(String subject, String topic) {
    return '$subject-$topic';
  }

  Map<String, MindMap> get allMindMaps => Map.unmodifiable(_mindMaps);
}
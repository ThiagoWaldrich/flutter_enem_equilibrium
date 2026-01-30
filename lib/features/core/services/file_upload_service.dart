import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../mindmaps/models/mind_map.dart';
import 'package:logging/logging.dart';

final _logger = Logger('FileService');

class FileUploadService {
  Future<List<MindMapFile>> prepareFiles(List<File> selectedFiles) async {
    final List<MindMapFile> mindMapFiles = [];
    
    for (final file in selectedFiles) {
      try {
        final mindMapFile = await _prepareSingleFile(file);
        mindMapFiles.add(mindMapFile);
      } catch (e) {
        continue;
      }
    }
    
    return mindMapFiles;
  }
  Future<MindMapFile> _prepareSingleFile(File file) async {
    if (!await file.exists()) {
      throw Exception('Arquivo não existe: ${file.path}');
    }
    
    final fileStat = await file.stat();
    final fileName = file.path.split('/').last;
    final appDir = await getApplicationDocumentsDirectory();
    final mindMapsDir = Directory('${appDir.path}/mindmaps');
    
    if (!await mindMapsDir.exists()) {
      await mindMapsDir.create(recursive: true);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeFileName = '${timestamp}_${fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')}';
    final destinationPath = '${mindMapsDir.path}/$safeFileName';
    
    final savedFile = await file.copy(destinationPath);
    final fileExtension = fileName.split('.').last.toLowerCase();
    final mimeType = _getMimeType(fileExtension);
    
    return MindMapFile(
      name: fileName, 
      type: mimeType,
      size: fileStat.size,
      filePath: savedFile.path,
      lastModified: fileStat.modified,
    );
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
  
Future<void> deletePhysicalFile(String filePath) async {
  try {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e, stackTrace) {
    _logger.severe('Erro ao deletar arquivo', e, stackTrace);
  }
}
  Future<void> cleanupOrphanedFiles(List<String> validFilePaths) async {
    final appDir = await getApplicationDocumentsDirectory();
    final mindMapsDir = Directory('${appDir.path}/mindmaps');
    
    if (await mindMapsDir.exists()) {
      final files = await mindMapsDir.list().toList();
      
      for (final file in files.whereType<File>()) {
        if (!validFilePaths.contains(file.path)) {
          await file.delete();
        }
      }
    }
  }
}
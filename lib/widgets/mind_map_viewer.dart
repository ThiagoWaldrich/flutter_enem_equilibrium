import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/mind_map_service.dart';
import '../utils/theme.dart';

class MindMapViewer extends StatefulWidget {
  final String subject;
  final String topic;

  const MindMapViewer({
    super.key,
    required this.subject,
    required this.topic,
  });

  @override
  State<MindMapViewer> createState() => _MindMapViewerState();
}

class _MindMapViewerState extends State<MindMapViewer> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mindMapService = context.watch<MindMapService>();
    final mindMap = mindMapService.getMindMap(widget.subject, widget.topic);

    if (mindMap == null || mindMap.files.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.topic),
        ),
        body: const Center(
          child: Text('Nenhum mapa encontrado'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topic,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              widget.subject,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteCurrentFile(mindMap.files.length),
            tooltip: 'Excluir Este Mapa',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Carrossel
          PageView.builder(
            controller: _pageController,
            itemCount: mindMap.files.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final file = mindMap.files[index];
              return _buildFileView(file);
            },
          ),

          // Indicador de página
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${mindMap.files.length} - ${mindMap.files[_currentPage].name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          // Botão anterior
          if (mindMap.files.length > 1)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

          // Botão próximo
          if (mindMap.files.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, size: 40, color: Colors.white),
                    onPressed: () {
                      if (_currentPage < mindMap.files.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileView(dynamic file) {
    if (file.isPdf) {
      return _buildPdfView(file);
    } else if (file.isImage) {
      return _buildImageView(file);
    } else {
      return const Center(
        child: Text(
          'Tipo de arquivo não suportado',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
  }

  Widget _buildImageView(dynamic file) {
    try {
      final bytes = base64Decode(file.data);
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 80, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'Erro ao carregar imagem',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Erro ao decodificar imagem',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPdfView(dynamic file) {
    // Para PDF, vamos mostrar uma mensagem informativa
    // Em produção, você pode usar pacotes como flutter_pdfview ou syncfusion_flutter_pdfviewer
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 120,
            color: Colors.red,
          ),
          const SizedBox(height: 24),
          Text(
            file.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Visualização de PDF em desenvolvimento.\nPor enquanto, apenas imagens são suportadas.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Aqui você pode adicionar funcionalidade para abrir em app externo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Funcionalidade em desenvolvimento'),
                ),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Abrir em App Externo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCurrentFile(int totalFiles) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mapa'),
        content: const Text('Tem certeza que deseja excluir este mapa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final mindMapService = context.read<MindMapService>();
      await mindMapService.removeFile(
        widget.subject,
        widget.topic,
        _currentPage,
      );

      if (mounted) {
        // Se era o último arquivo, voltar
        if (totalFiles == 1) {
          Navigator.pop(context);
        } else {
          // Ajustar página se necessário
          if (_currentPage >= totalFiles - 1) {
            _pageController.jumpToPage(_currentPage - 1);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapa excluído com sucesso'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }
}
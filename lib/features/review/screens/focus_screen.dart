import 'dart:async';
import 'package:equilibrium/features/core/theme/theme.dart';
import 'package:equilibrium/features/review/models/study_topic_model.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/services/database_service.dart';  
import '../models/study_topic_model.dart';

enum SoundType { rain, whiteNoise }

class FocusScreen extends StatefulWidget {
  final GroupedTopic topic;
  final Function(int, int) onComplete;

  const FocusScreen({super.key, required this.topic, required this.onComplete});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const int totalSeconds = 60 * 60;
  int _remainingSeconds = totalSeconds;
  bool _isRunning = true;
  Timer? _timer;
  AudioPlayer? _audioPlayer;
  bool _soundEnabled = true;
  SoundType _selectedSound = SoundType.rain;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    if (_soundEnabled) {
      await _playSound();
    }
  }

  Future<void> _playSound() async {
    final assetPath = _selectedSound == SoundType.rain 
        ? 'sounds/rain.mp3' 
        : 'sounds/white_noise.mp3';
    try {
      await _audioPlayer?.setSourceAsset(assetPath);
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer?.setVolume(0.5);
      await _audioPlayer?.resume();
    } catch (e) {
      debugPrint('Erro ao carregar áudio: $e');
    }
  }

  Future<void> _pauseSound() async {
    await _audioPlayer?.pause();
  }

  Future<void> _resumeSound() async {
    if (_soundEnabled) {
      await _audioPlayer?.resume();
    }
  }

  Future<void> _stopSound() async {
    await _audioPlayer?.stop();
  }

  Future<void> _toggleSound() async {
    if (_soundEnabled) {
      await _stopSound();
    } else {
      await _playSound();
    }
    setState(() => _soundEnabled = !_soundEnabled);
  }

  Future<void> _changeSound(SoundType type) async {
    setState(() => _selectedSound = type);
    if (_soundEnabled) {
      await _stopSound();
      await _playSound();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        _finishSession();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _pauseSound();
    setState(() => _isRunning = false);
  }

  void _resumeTimer() {
    _startTimer();
    _resumeSound();
    setState(() => _isRunning = true);
  }

  void _finishSession() {
    _timer?.cancel();
    _stopSound();
    _showQualityDialog();
  }

  void _goBack() {
    _timer?.cancel();
    _stopSound();
    Navigator.pop(context);
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Como foi a sessão?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQualityButton('Muito difícil', 1, Colors.red),
            const SizedBox(height: 8),
            _buildQualityButton('Difícil', 2, Colors.orange),
            const SizedBox(height: 8),
            _buildQualityButton('Boa', 3, Colors.green),
            const SizedBox(height: 8),
            _buildQualityButton('Muito boa', 4, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityButton(String label, int quality, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          final minutesStudied = (totalSeconds - _remainingSeconds) ~/ 60;
          Navigator.pop(context);
          widget.onComplete(quality, minutesStudied);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / totalSeconds;
    final elapsedPercent = ((1 - progress) * 100).round();
    final minutesLeft = _remainingSeconds ~/ 60;
    final secondsLeft = _remainingSeconds % 60;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        tooltip: 'Voltar para revisões',
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _toggleSound,
                      icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, color: Colors.white),
                    ),
                    if (_soundEnabled)
                      PopupMenuButton<SoundType>(
                        onSelected: _changeSound,
                        icon: const Icon(Icons.music_note, color: Colors.white),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: SoundType.rain, child: Text('🌧️ Chuva')),
                          const PopupMenuItem(value: SoundType.whiteNoise, child: Text('🤍 Ruído Branco')),
                        ],
                      ),
                  ],
                ),
                
                const Spacer(),
                
                Column(
                  children: [
                    Text(
                      widget.topic.subject.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.topic.topic,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.topic.subtopics.take(3).map((st) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(st, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.topic.count} questões • ${widget.topic.totalReviewCount} revisões',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$elapsedPercent% completo',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 64),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: _isRunning ? _pauseTimer : _resumeTimer,
                        icon: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: _finishSession,
                        icon: const Icon(Icons.stop, size: 48, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  _isRunning 
                      ? '🔴 Sessão em andamento\nEstude profundamente este tópico.'
                      : '⏸️ Sessão pausada\nVolte quando estiver pronto.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
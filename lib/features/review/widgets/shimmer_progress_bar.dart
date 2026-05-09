import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShimmerProgressBar extends StatefulWidget {
  final double value;
  final double height;
  final double borderRadius;

  const ShimmerProgressBar({
    super.key,
    required this.value,
    this.height = 12,
    this.borderRadius = 16,
  });

  @override
  State<ShimmerProgressBar> createState() => _ShimmerProgressBarState();
}

class _ShimmerProgressBarState extends State<ShimmerProgressBar>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnim;
  late final AnimationController _waveController;
  late final Animation<double> _waveAnim;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _waveController,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shimmerAnim, _waveAnim, _glowAnim]),
      builder: (context, _) {
        return CustomPaint(
          painter: _ShimmerPainter(
            progress: widget.value.clamp(0.0, 1.0),
            shimmerOffset: _shimmerAnim.value,
            wavePhase: _waveAnim.value,
            glowOpacity: _glowAnim.value,
            borderRadius: widget.borderRadius,
          ),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
          ),
        );
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final double shimmerOffset;
  final double wavePhase;
  final double glowOpacity;
  final double borderRadius;

  _ShimmerPainter({
    required this.progress,
    required this.shimmerOffset,
    required this.wavePhase,
    required this.glowOpacity,
    required this.borderRadius,
  });

  static const Color _base = Color(0xFF0A1628);
  static const Color _trackBg = Color(0x33FFFFFF);
  static const Color _deep = Color(0xFF0D3B6E);
  static const Color _mid = Color(0xFF1A7FD4);
  static const Color _bright = Color(0xFF4FC3F7);
  static const Color _cyan = Color(0xFF80DEEA);
  static const Color _shimmerHot = Color(0xFFE0F7FA);
  static const Color _purple = Color(0xFF7C4DFF);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final trackPaint = Paint()..color = _trackBg;
    canvas.drawRRect(rrect, trackPaint);

    if (progress <= 0) return;

    final filled = size.width * progress;
    final filledRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, filled, size.height),
      Radius.circular(borderRadius),
    );

    canvas.save();
    canvas.clipRRect(filledRRect);

    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [_deep, _mid, _bright, _mid, _deep],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, filled, size.height));
    canvas.drawRRect(filledRRect, basePaint);

    _paintWaveLayer(canvas, size, filled, wavePhase, _bright, 0.18);
    _paintWaveLayer(canvas, size, filled, wavePhase + 1.2, _cyan, 0.12);
    _paintWaveLayer(canvas, size, filled, wavePhase + 2.4, _purple, 0.08);

    final shimmerCenter = shimmerOffset * filled;
    final shimmerWidth = filled * 0.45;
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          _shimmerHot.withOpacity(0.0),
          _shimmerHot.withOpacity(0.28 * glowOpacity),
          _shimmerHot.withOpacity(0.55 * glowOpacity),
          _shimmerHot.withOpacity(0.28 * glowOpacity),
          _shimmerHot.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(
        shimmerCenter - shimmerWidth / 2,
        0,
        shimmerWidth,
        size.height,
      ))
      ..blendMode = BlendMode.screen;
    canvas.drawRRect(filledRRect, shimmerPaint);

    final edgePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _cyan.withOpacity(0.6 * glowOpacity),
          _shimmerHot.withOpacity(0.8 * glowOpacity),
          _cyan.withOpacity(0.6 * glowOpacity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, filled, size.height))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(filledRRect, edgePaint);

    canvas.restore();

    if (progress > 0.02) {
      final glowPaint = Paint()
        ..color = _bright.withOpacity(0.20 * glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-2, -2, filled + 4, size.height + 4),
          Radius.circular(borderRadius + 2),
        ),
        glowPaint,
      );
    }
  }

  void _paintWaveLayer(
    Canvas canvas,
    Size size,
    double filled,
    double phase,
    Color color,
    double maxOpacity,
  ) {
    const segments = 40;
    final segW = filled / segments;

    for (int i = 0; i < segments; i++) {
      final t = i / segments;
      final wave = (math.sin(phase + t * 6.0) * 0.5 + 0.5) *
                   (math.sin(phase * 0.7 + t * 3.5) * 0.3 + 0.7);
      final opacity = (wave * maxOpacity).clamp(0.0, 1.0);

      final segPaint = Paint()
        ..color = color.withOpacity(opacity)
        ..blendMode = BlendMode.screen;

      canvas.drawRect(
        Rect.fromLTWH(i * segW, 0, segW + 0.5, size.height),
        segPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) =>
      old.progress != progress ||
      old.shimmerOffset != shimmerOffset ||
      old.wavePhase != wavePhase ||
      old.glowOpacity != glowOpacity;
}
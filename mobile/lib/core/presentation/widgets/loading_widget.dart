import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget de chargement élégant avec animation
/// Utiliser à la place de CircularProgressIndicator pour une meilleure UX
class LoadingWidget extends StatefulWidget {
  final String? message;
  final double size;
  final Color? color;
  final LoadingStyle style;

  const LoadingWidget({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
    this.style = LoadingStyle.spinner,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

enum LoadingStyle {
  spinner, // Spinner rotatif
  dots, // Points qui pulsent
  wave, // Barres en vague
  agricultural, // Icône agricole animée
}

class _LoadingWidgetState extends State<LoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.color ?? Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildLoader(primaryColor),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.5 + (_pulseController.value * 0.5),
                child: Text(
                  widget.message!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLoader(Color color) {
    switch (widget.style) {
      case LoadingStyle.spinner:
        return _buildSpinner(color);
      case LoadingStyle.dots:
        return _buildDots(color);
      case LoadingStyle.wave:
        return _buildWave(color);
      case LoadingStyle.agricultural:
        return _buildAgriculturalLoader(color);
    }
  }

  Widget _buildSpinner(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SpinnerPainter(progress: _controller.value, color: color),
        );
      },
    );
  }

  Widget _buildDots(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            final scale = 0.5 + (math.sin(value * math.pi) * 0.5);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: widget.size / 5,
              height: widget.size / 5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3 + (scale * 0.7)),
                shape: BoxShape.circle,
              ),
              transform: Matrix4.identity()..scale(scale, scale, 1.0),
            );
          },
        );
      }),
    );
  }

  Widget _buildWave(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.1;
            final value = ((_controller.value + delay) % 1.0);
            final height = 0.3 + (math.sin(value * math.pi * 2) * 0.7);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: widget.size / 8,
              height: widget.size * height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(widget.size / 16),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildAgriculturalLoader(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * math.pi,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cercle extérieur (soleil)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
              ),
              // Feuille/plante au centre
              Icon(Icons.eco, size: widget.size * 0.5, color: color),
              // Points autour (gouttes d'eau)
              ...List.generate(6, (index) {
                final angle = (index / 6) * 2 * math.pi;
                final x = math.cos(angle) * (widget.size / 2.5);
                final y = math.sin(angle) * (widget.size / 2.5);
                return Transform.translate(
                  offset: Offset(x, y),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SpinnerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Cercle de fond
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Arc animé
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = math.pi * 1.5;
    final startAngle = progress * math.pi * 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Widget plein écran de chargement avec fond semi-transparent
class FullScreenLoading extends StatelessWidget {
  final String? message;
  final LoadingStyle style;

  const FullScreenLoading({
    super.key,
    this.message,
    this.style = LoadingStyle.agricultural,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: LoadingWidget(
            message: message ?? 'Chargement en cours...',
            size: 60,
            style: style,
          ),
        ),
      ),
    );
  }
}

/// Overlay de chargement pour les actions asynchrones
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final LoadingStyle style;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.style = LoadingStyle.spinner,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: FullScreenLoading(message: message, style: style),
          ),
      ],
    );
  }
}

/// Shimmer effect pour les placeholders de contenu
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({super.key, required this.child, this.isLoading = true});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

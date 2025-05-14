import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class MilestoneCelebration extends StatefulWidget {
  final String milestone;
  final String message;
  final VoidCallback? onComplete;

  const MilestoneCelebration({
    super.key,
    required this.milestone,
    required this.message,
    this.onComplete,
  });

  @override
  State<MilestoneCelebration> createState() => _MilestoneCelebrationState();
}

class _MilestoneCelebrationState extends State<MilestoneCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _confettiController;
  late List<ConfettiParticle> _particles;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _particles = List.generate(50, (index) => ConfettiParticle());

    _controller.forward();
    _confettiController.forward();

    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(seconds: 4), () {
      if (widget.onComplete != null && mounted) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Background blur
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),

              // Confetti
              ...List.generate(_particles.length, (index) {
                return AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    final particle = _particles[index];
                    final progress = _confettiController.value;

                    return Positioned(
                      left: particle.x * size.width,
                      top:
                          particle.y * size.height +
                          (progress * size.height * 1.5),
                      child: Transform.rotate(
                        angle:
                            particle.rotation +
                            (progress * particle.rotationSpeed),
                        child: Container(
                          width: particle.size,
                          height: particle.size,
                          decoration: BoxDecoration(
                            color: particle.color,
                            shape:
                                particle.isCircle
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              // Celebration content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.celebration,
                            size: 80,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            widget.milestone,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.message,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ConfettiParticle {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble() * 0.5 - 0.5;
  final double size = math.Random().nextDouble() * 8 + 4;
  final Color color =
      [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.pink,
      ][math.Random().nextInt(7)];
  final bool isCircle = math.Random().nextBool();
  final double rotation = math.Random().nextDouble() * 2 * math.pi;
  final double rotationSpeed = math.Random().nextDouble() * 4 - 2;
}

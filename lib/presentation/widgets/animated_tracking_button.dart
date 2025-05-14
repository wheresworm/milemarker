import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedTrackingButton extends StatefulWidget {
  final bool isTracking;
  final VoidCallback onPressed;
  final AnimationController animationController;

  const AnimatedTrackingButton({
    super.key,
    required this.isTracking,
    required this.onPressed,
    required this.animationController,
  });

  @override
  State<AnimatedTrackingButton> createState() => _AnimatedTrackingButtonState();
}

class _AnimatedTrackingButtonState extends State<AnimatedTrackingButton> {
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(begin: Colors.blue, end: Colors.red).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeInOut,
      ),
    );

    _iconRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_colorAnimation.value ?? Colors.blue).withOpacity(
                    0.3,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
              backgroundColor: _colorAnimation.value,
              elevation: 8,
              child: RotationTransition(
                turns: _iconRotation,
                child: Icon(
                  widget.isTracking ? Icons.stop : Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Collection of page transitions for consistent navigation animations
/// Following Material Design motion principles

/// Slide transition from right
class SlideRightRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRightRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

/// Slide transition from bottom (for modals/sheets)
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      );
}

/// Fade transition for subtle navigation
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      );
}

/// Scale transition with fade for emphasis
class ScaleFadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScaleFadeRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeOutCubic;

          var scaleTween = Tween(
            begin: 0.9,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(scaleTween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      );
}

/// Shared axis transition (Material Design)
class SharedAxisRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType type;

  SharedAxisRoute({
    required this.page,
    this.type = SharedAxisTransitionType.horizontal,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => page,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           Offset begin;
           switch (type) {
             case SharedAxisTransitionType.horizontal:
               begin = const Offset(30.0, 0.0);
               break;
             case SharedAxisTransitionType.vertical:
               begin = const Offset(0.0, 30.0);
               break;
             case SharedAxisTransitionType.scaled:
               begin = Offset.zero;
               break;
           }

           final slideAnimation = Tween<Offset>(begin: begin, end: Offset.zero)
               .animate(
                 CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
               );

           final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(
               parent: animation,
               curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
             ),
           );

           if (type == SharedAxisTransitionType.scaled) {
             final scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
               CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
             );

             return FadeTransition(
               opacity: fadeAnimation,
               child: ScaleTransition(scale: scaleAnimation, child: child),
             );
           }

           return FadeTransition(
             opacity: fadeAnimation,
             child: SlideTransition(
               position: slideAnimation.drive(
                 Tween<Offset>(
                   begin: Offset(begin.dx / 30, begin.dy / 30),
                   end: Offset.zero,
                 ),
               ),
               child: child,
             ),
           );
         },
         transitionDuration: const Duration(milliseconds: 300),
       );
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// Hero-like transition for element focus
class ExpandRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Rect sourceRect;

  ExpandRoute({required this.page, required this.sourceRect})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      );
}

/// Animated list item wrapper
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 300),
    this.delay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutCubic,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + (delay * index),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Staggered animation for lists
class StaggeredListAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDelay;
  final Curve curve;
  final ScrollController? scrollController;

  const StaggeredListAnimation({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 300),
    this.staggerDelay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutCubic,
    this.scrollController,
  });

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration:
          widget.itemDuration + (widget.staggerDelay * widget.children.length),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        final startInterval =
            index *
            widget.staggerDelay.inMilliseconds /
            _controller.duration!.inMilliseconds;
        final endInterval =
            (startInterval +
                    widget.itemDuration.inMilliseconds /
                        _controller.duration!.inMilliseconds)
                .clamp(0.0, 1.0);

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startInterval.clamp(0.0, 1.0),
            endInterval,
            curve: widget.curve,
          ),
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - animation.value)),
                child: child,
              ),
            );
          },
          child: widget.children[index],
        );
      },
    );
  }
}

/// Pulse animation widget
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

/// Shake animation for errors/attention
class ShakeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final bool animate;
  final VoidCallback? onComplete;

  const ShakeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 10.0,
    this.animate = false,
    this.onComplete,
  });

  @override
  State<ShakeAnimation> createState() => _ShakeAnimationState();
}

class _ShakeAnimationState extends State<ShakeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -widget.offset),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.offset, end: widget.offset),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.offset, end: -widget.offset),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.offset, end: widget.offset),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.offset, end: 0.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.animate) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ShakeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Extension for easy route transitions
extension NavigatorExtensions on NavigatorState {
  Future<T?> pushSlideRight<T>(Widget page) {
    return push(SlideRightRoute<T>(page: page));
  }

  Future<T?> pushSlideUp<T>(Widget page) {
    return push(SlideUpRoute<T>(page: page));
  }

  Future<T?> pushFade<T>(Widget page) {
    return push(FadeRoute<T>(page: page));
  }

  Future<T?> pushScaleFade<T>(Widget page) {
    return push(ScaleFadeRoute<T>(page: page));
  }
}

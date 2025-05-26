// Breathtaking cosmic particle system for spectacular visual effects
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tug/utils/theme/colors.dart';

class CosmicParticles extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final bool animate;
  final List<Color> particleColors;
  final double maxParticleSize;
  final double minParticleSize;
  final double maxSpeed;
  final double particleOpacity;
  final Duration duration;
  final bool connectParticles;
  final bool interactive;
  final bool fadeAtEdges;
  final ParticleEffect effect;

  const CosmicParticles({
    super.key,
    required this.child,
    this.particleCount = 25,
    this.animate = true,
    this.particleColors = const [],
    this.maxParticleSize = 3.0,
    this.minParticleSize = 1.0,
    this.maxSpeed = 0.5,
    this.particleOpacity = 0.6,
    this.duration = const Duration(seconds: 10),
    this.connectParticles = true,
    this.interactive = false,
    this.fadeAtEdges = true,
    this.effect = ParticleEffect.nebula,
  });

  @override
  State<CosmicParticles> createState() => _CosmicParticlesState();
}

class _CosmicParticlesState extends State<CosmicParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  Offset? _pointerPosition;
  
  // Dynamic colors based on theme and effect type
  late List<Color> _effectiveColors;
  
  @override
  void initState() {
    super.initState();
    
    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    
    if (widget.animate) {
      _controller.repeat();
    }
    
    // Initialize particles when we have a size
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeParticles();
    });
  }
  
  @override
  void didUpdateWidget(CosmicParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
    
    if (widget.particleCount != oldWidget.particleCount ||
        widget.effect != oldWidget.effect ||
        widget.particleColors != oldWidget.particleColors) {
      _initializeParticles();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _initializeParticles() {
    if (!mounted) return;
    
    final size = context.size;
    if (size == null) return;
    
    // Determine effective colors based on theme and effect
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (widget.particleColors.isNotEmpty) {
      _effectiveColors = widget.particleColors;
    } else {
      switch (widget.effect) {
        case ParticleEffect.nebula:
          _effectiveColors = [
            TugColors.primaryPurple,
            TugColors.primaryPurpleLight,
            TugColors.info,
            TugColors.success,
          ];
          break;
        case ParticleEffect.cosmic:
          _effectiveColors = [
            TugColors.primaryPurple,
            TugColors.primaryPurpleLight,
            TugColors.info,
            const Color(0xFF6A35FF),
          ];
          break;
        case ParticleEffect.energy:
          _effectiveColors = [
            TugColors.success,
            TugColors.success,
            TugColors.info,
            const Color(0xFF00E5FF),
          ];
          break;
        case ParticleEffect.fire:
          _effectiveColors = [
            TugColors.warning,
            const Color(0xFFFF5722),
            const Color(0xFFFF9800),
            const Color(0xFFFFC107),
          ];
          break;
      }
    }
    
    // Create particles
    final random = math.Random();
    _particles = List.generate(widget.particleCount, (_) {
      final color = _effectiveColors[random.nextInt(_effectiveColors.length)];
      
      return Particle(
        position: Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * widget.maxSpeed * 2,
          (random.nextDouble() - 0.5) * widget.maxSpeed * 2,
        ),
        radius: widget.minParticleSize + random.nextDouble() * (widget.maxParticleSize - widget.minParticleSize),
        color: color.withOpacity(
          widget.particleOpacity * (0.5 + random.nextDouble() * 0.5),
        ),
        glow: 0.5 + random.nextDouble() * 0.8,
        angle: random.nextDouble() * math.pi * 2,
        angularVelocity: (random.nextDouble() - 0.5) * 0.02,
        bounds: Rect.fromLTWH(0, 0, size.width, size.height),
        lifespan: 0.3 + random.nextDouble() * 0.7, // For pulsating
        growDirection: random.nextBool(),
      );
    });
    
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: widget.interactive ? (event) {
        setState(() {
          _pointerPosition = event.localPosition;
        });
      } : null,
      onExit: widget.interactive ? (_) {
        setState(() {
          _pointerPosition = null;
        });
      } : null,
      child: Stack(
        children: [
          // Background child
          widget.child,
          
          // Particle layer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Update particles position
              final size = context.size;
              if (size != null && _particles.isNotEmpty) {
                for (final particle in _particles) {
                  particle.update(
                    bounds: Rect.fromLTWH(0, 0, size.width, size.height),
                    pointerPosition: _pointerPosition,
                    interactive: widget.interactive,
                  );
                }
              }
              
              return CustomPaint(
                size: Size.infinite,
                painter: ParticlesPainter(
                  particles: _particles,
                  connectParticles: widget.connectParticles,
                  fadeAtEdges: widget.fadeAtEdges,
                  bounds: size != null ? Rect.fromLTWH(0, 0, size.width, size.height) : null,
                  effect: widget.effect,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  Color color;
  double glow;
  double angle;
  double angularVelocity;
  Rect bounds;
  double lifespan;
  bool growDirection;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
    required this.glow,
    required this.angle,
    required this.angularVelocity,
    required this.bounds,
    required this.lifespan,
    required this.growDirection,
  });
  
  void update({required Rect bounds, Offset? pointerPosition, bool interactive = false}) {
    // Update position
    position = Offset(
      position.dx + velocity.dx,
      position.dy + velocity.dy,
    );
    
    // Boundary check
    if (position.dx < 0) {
      position = Offset(0, position.dy);
      velocity = Offset(-velocity.dx * 0.5, velocity.dy);
    } else if (position.dx > bounds.width) {
      position = Offset(bounds.width, position.dy);
      velocity = Offset(-velocity.dx * 0.5, velocity.dy);
    }
    
    if (position.dy < 0) {
      position = Offset(position.dx, 0);
      velocity = Offset(velocity.dx, -velocity.dy * 0.5);
    } else if (position.dy > bounds.height) {
      position = Offset(position.dx, bounds.height);
      velocity = Offset(velocity.dx, -velocity.dy * 0.5);
    }
    
    // Apply interactive forces if pointer is near
    if (interactive && pointerPosition != null) {
      final distance = (position - pointerPosition).distance;
      final maxDistance = 100.0;
      
      if (distance < maxDistance) {
        final force = 1.0 - (distance / maxDistance);
        final directionVector = (position - pointerPosition);
        final direction = _normalizeOffset(directionVector);
        
        // Apply repulsive force
        velocity += direction * force * 0.2;
      }
    }
    
    // Add slight randomness for natural motion
    velocity += Offset(
      (math.Random().nextDouble() - 0.5) * 0.05,
      (math.Random().nextDouble() - 0.5) * 0.05,
    );
    
    // Apply drag to prevent excessive speed
    velocity *= 0.98;
    
    // Update rotation
    angle += angularVelocity;
    
    // Pulse effect - expand and contract
    if (growDirection) {
      lifespan += 0.01;
      if (lifespan > 1.0) {
        growDirection = false;
      }
    } else {
      lifespan -= 0.01;
      if (lifespan < 0.3) {
        growDirection = true;
      }
    }
  }
  
  // Get effective radius with pulsation
  double get effectiveRadius => radius * (0.7 + lifespan * 0.3);
  
  // Helper method to normalize an Offset (create a unit vector)
  Offset _normalizeOffset(Offset offset) {
    final distance = offset.distance;
    if (distance == 0) return Offset.zero;
    return offset.scale(1/distance, 1/distance);
  }
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final bool connectParticles;
  final bool fadeAtEdges;
  final Rect? bounds;
  final ParticleEffect effect;
  
  const ParticlesPainter({
    required this.particles,
    required this.connectParticles,
    required this.fadeAtEdges,
    this.bounds,
    required this.effect,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;
    
    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      
      // Draw connections between particles if enabled
      if (connectParticles && bounds != null) {
        for (int j = i + 1; j < particles.length; j++) {
          final other = particles[j];
          final distance = (particle.position - other.position).distance;
          
          // Only connect particles within a certain distance
          final maxDistance = bounds!.width * 0.15;
          if (distance < maxDistance) {
            final opacity = (1 - distance / maxDistance) * 0.3;
            
            // Draw connection line with gradient
            final paint = Paint()
              ..shader = LinearGradient(
                colors: [
                  particle.color.withOpacity(opacity),
                  other.color.withOpacity(opacity),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(Rect.fromPoints(
                Offset(particle.position.dx, particle.position.dy),
                Offset(other.position.dx, other.position.dy),
              ));
              
            final strokeWidth = math.max(1.0, (1 - distance / maxDistance) * 2);
            paint.strokeWidth = strokeWidth;
            
            canvas.drawLine(
              particle.position,
              other.position,
              paint,
            );
          }
        }
      }
      
      // Calculate edge fade if enabled
      double opacityMultiplier = 1.0;
      if (fadeAtEdges && bounds != null) {
        // Calculate distance from edges
        final distanceFromEdgeX = math.min(
          particle.position.dx,
          bounds!.width - particle.position.dx,
        );
        final distanceFromEdgeY = math.min(
          particle.position.dy,
          bounds!.height - particle.position.dy,
        );
        
        // Fade out near edges (within 5% of the edge)
        final edgeFadeDistance = math.min(bounds!.width, bounds!.height) * 0.05;
        
        if (distanceFromEdgeX < edgeFadeDistance || distanceFromEdgeY < edgeFadeDistance) {
          final fadeFactorX = distanceFromEdgeX < edgeFadeDistance
              ? distanceFromEdgeX / edgeFadeDistance
              : 1.0;
          final fadeFactorY = distanceFromEdgeY < edgeFadeDistance
              ? distanceFromEdgeY / edgeFadeDistance
              : 1.0;
          
          opacityMultiplier = math.min(fadeFactorX, fadeFactorY);
        }
      }
      
      // Get effective opacity based on particle lifespan and edge fade
      final effectiveOpacity = particle.color.opacity * particle.lifespan * opacityMultiplier;
      
      // Draw particle
      final particlePaint = Paint()
        ..color = particle.color.withOpacity(effectiveOpacity);
      
      // Different drawing based on effect type
      switch (effect) {
        case ParticleEffect.nebula:
          // Draw glow
          final glowPaint = Paint()
            ..color = particle.color.withOpacity(effectiveOpacity * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
          
          canvas.drawCircle(
            particle.position,
            particle.effectiveRadius * 2.5,
            glowPaint,
          );
          
          // Draw core
          canvas.drawCircle(
            particle.position,
            particle.effectiveRadius,
            particlePaint,
          );
          break;
          
        case ParticleEffect.cosmic:
          // Radial gradient for cosmic star-like particles
          final shader = RadialGradient(
            colors: [
              particle.color.withOpacity(effectiveOpacity),
              particle.color.withOpacity(effectiveOpacity * 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
            radius: 1.0,
          ).createShader(Rect.fromCircle(
            center: particle.position,
            radius: particle.effectiveRadius * 3,
          ));
          
          final starPaint = Paint()
            ..shader = shader;
          
          canvas.drawCircle(
            particle.position,
            particle.effectiveRadius * 3,
            starPaint,
          );
          break;
          
        case ParticleEffect.energy:
          // Draw ring
          final ringPaint = Paint()
            ..color = particle.color.withOpacity(effectiveOpacity * 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = particle.effectiveRadius * 0.5;
          
          canvas.drawCircle(
            particle.position,
            particle.effectiveRadius * 1.5,
            ringPaint,
          );
          
          // Draw core
          canvas.drawCircle(
            particle.position,
            particle.effectiveRadius * 0.8,
            particlePaint,
          );
          break;
          
        case ParticleEffect.fire:
          // Save canvas state
          canvas.save();
          
          // Translate and rotate
          canvas.translate(particle.position.dx, particle.position.dy);
          canvas.rotate(particle.angle);
          
          // Create flame-like path
          final path = Path();
          final flameHeight = particle.effectiveRadius * 3;
          final flameWidth = particle.effectiveRadius * 1.5;
          
          path.moveTo(0, -flameHeight / 2);
          path.quadraticBezierTo(
            flameWidth / 2, 0,
            0, flameHeight / 2,
          );
          path.quadraticBezierTo(
            -flameWidth / 2, 0,
            0, -flameHeight / 2,
          );
          
          // Create gradient for flame
          final flameShader = RadialGradient(
            colors: [
              particle.color.withOpacity(effectiveOpacity),
              particle.color.withOpacity(effectiveOpacity * 0.5),
              particle.color.withOpacity(0),
            ],
            stops: const [0.0, 0.5, 1.0],
            radius: 1.0,
            center: const Alignment(0.0, -0.2),
          ).createShader(Rect.fromCircle(
            center: Offset.zero,
            radius: flameHeight,
          ));
          
          final flamePaint = Paint()
            ..shader = flameShader;
          
          canvas.drawPath(path, flamePaint);
          
          // Restore canvas
          canvas.restore();
          break;
      }
    }
  }
  
  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return true; // Always repaint for animations
  }
}

enum ParticleEffect {
  nebula,  // Soft glowing particles with connections
  cosmic,  // Star-like bright points
  energy,  // Pulsating energy rings
  fire,    // Dynamic flame-like particles
}
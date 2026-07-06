import 'package:flutter/material.dart';
import 'package:pata/screens/home_screen.dart';
import 'package:pata/auth/sign_in_screen.dart';  // ← IMPORTANT
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeLogo;
  late Animation<double> _scaleLogo;
  late Animation<double> _fadeText;
  late Animation<double> _fadeTagline;
  late Animation<Offset> _slideLine;
  late Animation<double> _glowPulse;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );
    
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    
    _scaleLogo = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    
    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.6, curve: Curves.easeOut)),
    );
    
    _fadeTagline = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.75, curve: Curves.easeOut)),
    );
    
    _slideLine = Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.65, 0.95, curve: Curves.easeOut)),
    );
    
    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.5, curve: Curves.easeInOut)),
    );
    
    _controller.forward();
    
    // ✅ Après l'animation, vérifier l'état de connexion
    Future.delayed(const Duration(milliseconds: 3700), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Méthode pour naviguer vers la bonne page après le splash
  void _navigateToNextScreen() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // ✅ Si connecté → HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      // ✅ Si non connecté → SignInScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF008080),
            Color(0xFF00A0A0),
            Color(0xFF002626),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // PARTICULES FLOTTANTES
          ...List.generate(20, (index) {
            final x = (index * 97.3) % size.width;
            final y = (index * 143.7) % size.height;
            final duration = 2.0 + (index % 3) * 1.5;
            
            return _FloatingParticle(
              x: x,
              y: y,
              size: 2 + (index % 4),
              duration: duration,
              opacity: 0.1 + (index % 5) * 0.05,
            );
          }),
          
          // EFFET DE VAGUE
          Center(
            child: AnimatedBuilder(
              animation: _waveAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: 1.0 - _waveAnimation.value,
                  child: Container(
                    width: 200 + _waveAnimation.value * 400,
                    height: 200 + _waveAnimation.value * 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3 * (1 - _waveAnimation.value)),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO AVEC GLOW PULSANT
                FadeTransition(
                  opacity: _fadeLogo,
                  child: ScaleTransition(
                    scale: _scaleLogo,
                    child: AnimatedBuilder(
                      animation: _glowPulse,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.15 * _glowPulse.value),
                                blurRadius: 40 + 20 * _glowPulse.value,
                                spreadRadius: 10 * _glowPulse.value,
                              ),
                            ],
                          ),
                          child: const CustomPaint(
                            size: Size(180, 180),
                            painter: PataLogoPainter(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // TEXTE PATA
                FadeTransition(
                  opacity: _fadeText,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [Colors.white, Colors.white70],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'PATA',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.white24,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // LIGNE + FLÈCHE
                SlideTransition(
                  position: _slideLine,
                  child: const CustomPaint(
                    size: Size(140, 24),
                    painter: ArrowLinePainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PARTICULE FLOTTANTE
// ============================================================
class _FloatingParticle extends StatefulWidget {
  final double x;
  final double y;
  final double size;
  final double duration;
  final double opacity;

  const _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.duration,
    required this.opacity,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.duration.toInt()),
      vsync: this,
    );
    
    _floatAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        final offsetY = math.sin(_floatAnimation.value) * 15;
        final offsetX = math.cos(_floatAnimation.value * 0.7) * 10;
        
        return Positioned(
          left: widget.x + offsetX,
          top: widget.y + offsetY,
          child: Opacity(
            opacity: widget.opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// LOGO PATA PREMIUM
// ============================================================
class PataLogoPainter extends CustomPainter {
  const PataLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Glow derrière le coussinet
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + 15),
          width: size.width * 0.5,
          height: size.height * 0.38,
        ),
        Radius.circular(size.width * 0.13),
      ),
      glowPaint,
    );
    
    // Coussinet central
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + 15),
          width: size.width * 0.48,
          height: size.height * 0.36,
        ),
        Radius.circular(size.width * 0.12),
      ),
      whitePaint,
    );
    
    // Barres avec symboles
    _drawBarWithSymbol(canvas, size, Offset(centerX - 48, centerY - 42), 16, 58, '₣', textPaint);
    _drawBarWithSymbol(canvas, size, Offset(centerX - 20, centerY - 54), 16, 72, '€', textPaint);
    _drawBarWithSymbol(canvas, size, Offset(centerX + 20, centerY - 54), 16, 62, '\$', textPaint);
    _drawBarWithSymbol(canvas, size, Offset(centerX + 48, centerY - 42), 16, 50, '£', textPaint);
    
    // Articulations
    final smallCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX - 48, centerY - 18), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX - 20, centerY - 25), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 20, centerY - 25), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 48, centerY - 18), 7, smallCirclePaint);
    
    // Lignes de croissance
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(centerX - 22, centerY + 5),
      Offset(centerX + 28, centerY - 8),
      linePaint,
    );
    
    canvas.drawLine(
      Offset(centerX - 18, centerY + 18),
      Offset(centerX + 32, centerY + 5),
      linePaint,
    );
    
    canvas.drawCircle(Offset(centerX + 28, centerY - 8), 3, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 32, centerY + 5), 3, smallCirclePaint);
  }
  
  void _drawBarWithSymbol(Canvas canvas, Size size, Offset position, double width, double height, String symbol, TextPainter textPainter) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: width,
        height: height,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(rect, paint);
    
    textPainter.text = TextSpan(
      text: symbol,
      style: const TextStyle(
        color: Color(0xFF008080),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Ligne + flèche
class ArrowLinePainter extends CustomPainter {
  const ArrowLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    for (int i = 0; i < size.width; i += 4) {
      final opacity = 0.3 + (i / size.width) * 0.7;
      final pointPaint = Paint()
        ..color = Colors.white.withOpacity(opacity)
        ..strokeWidth = 1.5;
      
      canvas.drawLine(
        Offset(i.toDouble(), size.height / 2),
        Offset((i + 2).toDouble(), size.height / 2),
        pointPaint,
      );
    }
    
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    const arrowSize = 7.0;
    final path = Path();
    path.moveTo(size.width - 10, size.height / 2 - arrowSize);
    path.lineTo(size.width - 2, size.height / 2);
    path.lineTo(size.width - 10, size.height / 2 + arrowSize);
    path.close();
    
    canvas.drawPath(path, arrowPaint);
    canvas.drawCircle(Offset(3, size.height / 2), 3, arrowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
import 'package:flutter/material.dart';
import 'package:pata/screens/home_screen.dart';

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
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Animation du logo
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    
    _scaleLogo = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)),
    );
    
    // Animation du texte PATA
    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );
    
    // Animation du slogan
    _fadeTagline = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 0.8, curve: Curves.easeOut)),
    );
    
    // Animation de la ligne + flèche
    _slideLine = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 0.95, curve: Curves.easeOut)),
    );
    
    // Animation de pulsation pour les particules
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF008080), // Teal élégant
            Color(0xFF00A0A0), // Teal moyen
            Color(0xFF002626), // Teal profond
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Particules animées en arrière-plan
          ...List.generate(12, (index) {
            return Positioned(
              left: (index * 75.0) % MediaQuery.of(context).size.width,
              top: (index * 120.0) % MediaQuery.of(context).size.height,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.1 + (_pulseAnimation.value * 0.05),
                    child: Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animé
                FadeTransition(
                  opacity: _fadeLogo,
                  child: ScaleTransition(
                    scale: _scaleLogo,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const CustomPaint(
                        size: Size(180, 180),
                        painter: PataLogoPainter(),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Texte PATA stylisé (sans soulignement)
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
                
                // Ligne + flèche animée
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
// LOGO PATA PREMIUM : empreinte + barres + symboles monétaires
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
    
    // === COUSSINET PRINCIPAL ===
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
    
    // === DOIGTS = BARRES AVEC SYMBOLES ===
    _drawBarWithSymbol(canvas, size, Offset(centerX - 48, centerY - 42), 16, 58, '₣', textPaint);
    _drawBarWithSymbol(canvas, size, Offset(centerX - 20, centerY - 54), 16, 72, '€', textPaint);
    _drawBarWithSymbol(canvas, size, Offset(centerX + 20, centerY - 54), 16, 62, '\$', textPaint);
    _drawBarWithSymbol(canvas, size, Offset(centerX + 48, centerY - 42), 16, 50, '£', textPaint);
    
    // === ARTICULATIONS ===
    final smallCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX - 48, centerY - 18), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX - 20, centerY - 25), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 20, centerY - 25), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 48, centerY - 18), 7, smallCirclePaint);
    
    // === LIGNES DE CROISSANCE ===
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
    
    // Petit point sur les lignes de croissance
    canvas.drawCircle(Offset(centerX + 28, centerY - 8), 3, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 32, centerY + 5), 3, smallCirclePaint);
  }
  
  void _drawBarWithSymbol(Canvas canvas, Size size, Offset position, double width, double height, String symbol, TextPainter textPainter) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Barre arrondie
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: width,
        height: height,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(rect, paint);
    
    // Symbole avec ombre
    textPainter.text = TextSpan(
      text: symbol,
      style: const TextStyle(
        color: Color(0xFF008080),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 4,
            color: Colors.white24,
          ),
        ],
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

// Ligne + flèche avec effet premium
class ArrowLinePainter extends CustomPainter {
  const ArrowLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Ligne horizontale avec dégradé (via points fins)
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
    
    // Flèche stylisée
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
    
    // Cercle décoratif au début
    canvas.drawCircle(Offset(3, size.height / 2), 3, arrowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
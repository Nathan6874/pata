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
  late Animation<Offset> _slideLine;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    
    _scaleLogo = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );
    
    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 0.8, curve: Curves.easeOut)),
    );
    
    _slideLine = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeOut)),
    );
    
    _controller.forward();
    
    Future.delayed(const Duration(milliseconds: 2800), () {
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
            Color(0xFF008080),
            Color(0xFF002626),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeLogo,
              child: ScaleTransition(
                scale: _scaleLogo,
                child: const CustomPaint(
                  size: Size(220, 220),
                  painter: PataLogoPainter(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeText,
              child: const Text(
                'PATA',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SlideTransition(
              position: _slideLine,
              child: const CustomPaint(
                size: Size(120, 20),
                painter: ArrowLinePainter(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGO PATA : empreinte de patte + barres de graphique 
// + symboles monétaires (FCFA, $, €)
// ============================================================
class PataLogoPainter extends CustomPainter {
  const PataLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // === COUSSINET PRINCIPAL (forme de patte arrondie) ===
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
    
    // === DOIGTS = BARRES DE GRAPHIQUE AVEC SYMBOLES ===
    // Doigt 1 (haut gauche) - Dollar $
    _drawBarWithSymbol(canvas, size, Offset(centerX - 45, centerY - 40), 14, 55, '\$', textPaint);
    
    // Doigt 2 (haut centre gauche) - Euro €
    _drawBarWithSymbol(canvas, size, Offset(centerX - 18, centerY - 52), 14, 70, '€', textPaint);
    
    // Doigt 3 (haut centre droit) - FCFA ₣
    _drawBarWithSymbol(canvas, size, Offset(centerX + 18, centerY - 52), 14, 60, '₣', textPaint);
    
    // Doigt 4 (haut droit) - Livre £
    _drawBarWithSymbol(canvas, size, Offset(centerX + 45, centerY - 40), 14, 48, '£', textPaint);
    
    // === PETITS RONDS SOUS LES BARRES ===
    final smallCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX - 45, centerY - 18), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX - 18, centerY - 24), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 18, centerY - 24), 7, smallCirclePaint);
    canvas.drawCircle(Offset(centerX + 45, centerY - 18), 7, smallCirclePaint);
    
    // === DÉTAIL : PETITE LIGNE DE CROISSANCE DANS LE COUSSINET ===
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(centerX - 20, centerY + 5),
      Offset(centerX + 25, centerY - 5),
      linePaint,
    );
    
    canvas.drawLine(
      Offset(centerX - 15, centerY + 15),
      Offset(centerX + 30, centerY + 5),
      linePaint,
    );
  }
  
  void _drawBarWithSymbol(Canvas canvas, Size size, Offset position, double width, double height, String symbol, TextPainter textPainter) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Dessiner la barre
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: position,
        width: width,
        height: height,
      ),
      Radius.circular(width / 2),
    );
    canvas.drawRRect(rect, paint);
    
    // Dessiner le symbole monétaire dans la barre
    textPainter.text = TextSpan(
      text: symbol,
      style: const TextStyle(
        color: Color(0xFF008080),
        fontSize: 12,
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

// Ligne + flèche animée
class ArrowLinePainter extends CustomPainter {
  const ArrowLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Ligne horizontale
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width - 12, size.height / 2),
      paint,
    );
    
    // Flèche vers le haut
    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    const arrowSize = 8.0;
    final path = Path();
    path.moveTo(size.width - 12, size.height / 2 - arrowSize);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 12, size.height / 2 + arrowSize);
    path.close();
    
    canvas.drawPath(path, arrowPaint);
    
    // Petit point au début de la ligne
    canvas.drawCircle(Offset(2, size.height / 2), 3, arrowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
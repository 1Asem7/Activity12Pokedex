import 'dart:math';

import 'package:flutter/material.dart';

// ---------------------------------------------------------------
// Pokébola dibujada a mano con CustomPainter
// ---------------------------------------------------------------
class PokeballPainter extends CustomPainter {
  final Color color;
  final bool rellena; // true = pokébola de colores, false = solo contorno

  PokeballPainter({required this.color, this.rellena = false});

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;
    final grosor = radio * 0.12;

    if (rellena) {
      // Mitad de arriba roja
      final pintaRoja = Paint()..color = const Color(0xFFE53935);
      canvas.drawArc(Rect.fromCircle(center: centro, radius: radio), pi, pi,
          true, pintaRoja);
      // Mitad de abajo blanca
      final pintaBlanca = Paint()..color = Colors.white;
      canvas.drawArc(Rect.fromCircle(center: centro, radius: radio), 0, pi,
          true, pintaBlanca);
    }

    final pinta = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;

    // Círculo exterior
    canvas.drawCircle(centro, radio - grosor / 2, pinta);

    // Línea del centro
    final pintaLinea = Paint()
      ..color = color
      ..strokeWidth = grosor;
    canvas.drawLine(Offset(0, centro.dy), Offset(size.width, centro.dy),
        pintaLinea);

    // Botón del centro
    if (rellena) {
      canvas.drawCircle(centro, radio * 0.32, Paint()..color = color);
      canvas.drawCircle(centro, radio * 0.2, Paint()..color = Colors.white);
    } else {
      // Como marca de agua solo dibujamos el aro del botón
      canvas.drawCircle(centro, radio * 0.26, pinta);
    }
  }

  @override
  bool shouldRepaint(covariant PokeballPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.rellena != rellena;
  }
}

// ---------------------------------------------------------------
// Pokébola girando, la usamos como indicador de carga
// ---------------------------------------------------------------
class PokeballCargando extends StatefulWidget {
  final double tamano;

  const PokeballCargando({super.key, this.tamano = 70});

  @override
  State<PokeballCargando> createState() => _PokeballCargandoState();
}

class _PokeballCargandoState extends State<PokeballCargando>
    with SingleTickerProviderStateMixin {
  late AnimationController controlador;

  @override
  void initState() {
    super.initState();
    controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controlador,
      builder: (context, child) {
        // Vuelta completa en cada ciclo
        double giro = controlador.value * 2 * pi;
        return Transform.rotate(
          angle: giro,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.tamano,
        height: widget.tamano,
        child: CustomPaint(
          painter: PokeballPainter(color: const Color(0xFF263238), rellena: true),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Partículas (burbujas) que suben lentamente en el fondo
// ---------------------------------------------------------------
class Particula {
  double x; // posición de 0 a 1
  double y; // posición de 0 a 1
  double tamano;
  double velocidad;
  double fase;

  Particula(this.x, this.y, this.tamano, this.velocidad, this.fase);
}

class ParticulasFondo extends StatefulWidget {
  const ParticulasFondo({super.key});

  @override
  State<ParticulasFondo> createState() => _ParticulasFondoState();
}

class _ParticulasFondoState extends State<ParticulasFondo>
    with SingleTickerProviderStateMixin {
  late AnimationController controlador;
  final List<Particula> particulas = [];

  @override
  void initState() {
    super.initState();
    final random = Random();
    for (int i = 0; i < 28; i++) {
      particulas.add(Particula(
        random.nextDouble(),
        random.nextDouble(),
        3 + random.nextDouble() * 10,
        0.3 + random.nextDouble() * 0.7,
        random.nextDouble() * 2 * pi,
      ));
    }
    controlador = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controlador,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: ParticulasPainter(particulas, controlador.value),
          );
        },
      ),
    );
  }
}

class ParticulasPainter extends CustomPainter {
  final List<Particula> particulas;
  final double tiempo;

  ParticulasPainter(this.particulas, this.tiempo);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particulas) {
      // Suben poco a poco y cuando salen por arriba vuelven a empezar abajo
      double y = (p.y - tiempo * p.velocidad) % 1.0;
      if (y < 0) y = y + 1;
      // Se mueven un poco de lado a lado con seno
      double x = p.x + sin(tiempo * 2 * pi * 2 + p.fase) * 0.02;

      final pinta = Paint()..color = Colors.white.withAlpha(45);
      canvas.drawCircle(
          Offset(x * size.width, y * size.height), p.tamano, pinta);
    }
  }

  @override
  bool shouldRepaint(covariant ParticulasPainter oldDelegate) => true;
}

import 'dart:math';

import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../utils/tipos.dart';

// ---------------------------------------------------------------
// Panel de estadísticas con dos vistas: barras y radar
// ---------------------------------------------------------------
class PanelEstadisticas extends StatefulWidget {
  final Pokemon pokemon;
  final Color colorTipo;

  const PanelEstadisticas({
    super.key,
    required this.pokemon,
    required this.colorTipo,
  });

  @override
  State<PanelEstadisticas> createState() => _PanelEstadisticasState();
}

class _PanelEstadisticasState extends State<PanelEstadisticas> {
  bool verRadar = false;

  @override
  Widget build(BuildContext context) {
    Pokemon pokemon = widget.pokemon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título + selector Barras / Radar
        Row(
          children: [
            const Expanded(
              child: Text(
                'Estadísticas base',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: widget.colorTipo,
                selectedForegroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.bar_chart)),
                ButtonSegment(value: true, icon: Icon(Icons.hexagon_outlined)),
              ],
              selected: {verRadar},
              onSelectionChanged: (valor) {
                setState(() {
                  verRadar = valor.first;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Cambia entre vistas con una animación de desvanecido
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: verRadar
              ? GraficaRadar(
                  key: ValueKey('radar-${pokemon.id}'),
                  pokemon: pokemon,
                  color: widget.colorTipo,
                )
              : Column(
                  key: ValueKey('barras-${pokemon.id}'),
                  children: [
                    for (int i = 0; i < pokemon.estadisticas.length; i++)
                      BarraEstadistica(
                        estadistica: pokemon.estadisticas[i],
                        retraso: i * 90, // cada barra empieza un poco después
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // Total con contador animado
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.colorTipo.withAlpha(30),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.functions, color: widget.colorTipo),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TweenAnimationBuilder<double>(
                key: ValueKey('total-${pokemon.id}'),
                tween: Tween(begin: 0, end: pokemon.totalEstadisticas.toDouble()),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, valor, child) {
                  return Text(
                    valor.toInt().toString(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: widget.colorTipo,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Una barra que se llena animada y cuenta el número desde 0
// ---------------------------------------------------------------
class BarraEstadistica extends StatefulWidget {
  final Estadistica estadistica;
  final int retraso; // milisegundos antes de empezar

  const BarraEstadistica({
    super.key,
    required this.estadistica,
    required this.retraso,
  });

  @override
  State<BarraEstadistica> createState() => _BarraEstadisticaState();
}

class _BarraEstadisticaState extends State<BarraEstadistica>
    with SingleTickerProviderStateMixin {
  late AnimationController controlador;
  late Animation<double> animacion;

  @override
  void initState() {
    super.initState();
    controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    animacion = CurvedAnimation(
      parent: controlador,
      curve: Curves.easeOutBack, // se pasa un poquito y regresa, se ve vivo
    );

    // Esperamos el retraso y luego arrancamos
    Future.delayed(Duration(milliseconds: widget.retraso), () {
      if (mounted) {
        controlador.forward();
      }
    });
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int valor = widget.estadistica.valor;
    Color color = colorPorValor(valor);
    double porcentaje = valor / 255; // 255 es el máximo posible
    if (porcentaje > 1) porcentaje = 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: animacion,
        builder: (context, child) {
          double avance = animacion.value;
          int numero = (valor * avance).round();
          if (numero < 0) numero = 0;
          if (numero > valor) numero = valor;

          return Row(
            children: [
              SizedBox(
                width: 84,
                child: Text(
                  nombreEstadistica(widget.estadistica.nombre),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  numero.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, restricciones) {
                    double anchoTotal = restricciones.maxWidth;
                    double anchoBarra = anchoTotal * porcentaje * avance;
                    if (anchoBarra < 0) anchoBarra = 0;
                    if (anchoBarra > anchoTotal) anchoBarra = anchoTotal;

                    return Stack(
                      children: [
                        // Fondo gris de la barra
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // Barra de color con degradado y brillo
                        Container(
                          height: 12,
                          width: anchoBarra,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withAlpha(170), color],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withAlpha(120),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------
// Gráfica de radar (hexágono) que crece desde el centro
// ---------------------------------------------------------------
class GraficaRadar extends StatelessWidget {
  final Pokemon pokemon;
  final Color color;

  const GraficaRadar({super.key, required this.pokemon, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, avance, child) {
        return AspectRatio(
          aspectRatio: 1.3,
          child: CustomPaint(
            painter: RadarPainter(
              estadisticas: pokemon.estadisticas,
              color: color,
              avance: avance,
            ),
          ),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final List<Estadistica> estadisticas;
  final Color color;
  final double avance;

  RadarPainter({
    required this.estadisticas,
    required this.color,
    required this.avance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int lados = estadisticas.length;
    if (lados < 3) return;

    final centro = Offset(size.width / 2, size.height / 2);
    final radio = min(size.width, size.height) / 2 - 34;
    final angulo = 2 * pi / lados;

    // Punto en el círculo para el lado i (empezando arriba)
    Offset punto(int i, double distancia) {
      double a = -pi / 2 + angulo * i;
      return Offset(
        centro.dx + cos(a) * distancia,
        centro.dy + sin(a) * distancia,
      );
    }

    // 1. Rejilla de hexágonos
    final pintaRejilla = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int nivel = 1; nivel <= 4; nivel++) {
      Path camino = Path();
      for (int i = 0; i < lados; i++) {
        Offset p = punto(i, radio * nivel / 4);
        if (i == 0) {
          camino.moveTo(p.dx, p.dy);
        } else {
          camino.lineTo(p.dx, p.dy);
        }
      }
      camino.close();
      canvas.drawPath(camino, pintaRejilla);
    }

    // Líneas del centro a cada esquina
    for (int i = 0; i < lados; i++) {
      canvas.drawLine(centro, punto(i, radio), pintaRejilla);
    }

    // 2. Polígono con los valores del Pokémon
    Path forma = Path();
    for (int i = 0; i < lados; i++) {
      double valor = estadisticas[i].valor / 180; // 180 para que se vea grande
      if (valor > 1) valor = 1;
      Offset p = punto(i, radio * valor * avance);
      if (i == 0) {
        forma.moveTo(p.dx, p.dy);
      } else {
        forma.lineTo(p.dx, p.dy);
      }
    }
    forma.close();

    canvas.drawPath(forma, Paint()..color = color.withAlpha(90));
    canvas.drawPath(
      forma,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );

    // Puntitos en cada vértice
    for (int i = 0; i < lados; i++) {
      double valor = estadisticas[i].valor / 180;
      if (valor > 1) valor = 1;
      Offset p = punto(i, radio * valor * avance);
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3.5, Paint()..color = color);
    }

    // 3. Etiquetas con nombre y valor
    for (int i = 0; i < lados; i++) {
      Offset p = punto(i, radio + 20);
      final texto = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${nombreEstadistica(estadisticas[i].nombre)}\n',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
            TextSpan(
              text: estadisticas[i].valor.toString(),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      texto.layout();
      texto.paint(
        canvas,
        Offset(p.dx - texto.width / 2, p.dy - texto.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.avance != avance || oldDelegate.color != color;
  }
}

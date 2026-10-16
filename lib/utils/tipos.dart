import 'package:flutter/material.dart';

// Colores, íconos y nombres en español para cada tipo de Pokémon

Color colorPorTipo(String tipo) {
  switch (tipo) {
    case 'grass':
      return const Color(0xFF3FBF8F);
    case 'fire':
      return const Color(0xFFF5634A);
    case 'water':
      return const Color(0xFF4A90E2);
    case 'electric':
      return const Color(0xFFF7C631);
    case 'bug':
      return const Color(0xFF8CB230);
    case 'poison':
      return const Color(0xFF9B59B6);
    case 'ground':
      return const Color(0xFFD4A75A);
    case 'rock':
      return const Color(0xFFB09A4F);
    case 'psychic':
      return const Color(0xFFF0628E);
    case 'ice':
      return const Color(0xFF5FC9D8);
    case 'fighting':
      return const Color(0xFFCE4A3B);
    case 'ghost':
      return const Color(0xFF6C5BA8);
    case 'dragon':
      return const Color(0xFF6A54E8);
    case 'fairy':
      return const Color(0xFFE88FD8);
    case 'dark':
      return const Color(0xFF5A4A42);
    case 'steel':
      return const Color(0xFF8E9CB0);
    case 'flying':
      return const Color(0xFF8BA6F0);
    default:
      return const Color(0xFF9E9E7A); // normal
  }
}

// Un color más oscuro del mismo tipo, para hacer degradados
Color colorOscuro(Color color) {
  final hsl = HSLColor.fromColor(color);
  double nuevaLuz = hsl.lightness - 0.22;
  if (nuevaLuz < 0) nuevaLuz = 0;
  return hsl.withLightness(nuevaLuz).toColor();
}

IconData iconoPorTipo(String tipo) {
  switch (tipo) {
    case 'grass':
      return Icons.eco;
    case 'fire':
      return Icons.local_fire_department;
    case 'water':
      return Icons.water_drop;
    case 'electric':
      return Icons.bolt;
    case 'bug':
      return Icons.bug_report;
    case 'poison':
      return Icons.science;
    case 'ground':
      return Icons.terrain;
    case 'rock':
      return Icons.landscape;
    case 'psychic':
      return Icons.psychology;
    case 'ice':
      return Icons.ac_unit;
    case 'fighting':
      return Icons.sports_mma;
    case 'ghost':
      return Icons.nightlight_round;
    case 'dragon':
      return Icons.cyclone;
    case 'fairy':
      return Icons.auto_awesome;
    case 'dark':
      return Icons.dark_mode;
    case 'steel':
      return Icons.shield;
    case 'flying':
      return Icons.air;
    default:
      return Icons.circle_outlined;
  }
}

String nombreTipo(String tipo) {
  switch (tipo) {
    case 'grass':
      return 'Planta';
    case 'fire':
      return 'Fuego';
    case 'water':
      return 'Agua';
    case 'electric':
      return 'Eléctrico';
    case 'bug':
      return 'Bicho';
    case 'poison':
      return 'Veneno';
    case 'ground':
      return 'Tierra';
    case 'rock':
      return 'Roca';
    case 'psychic':
      return 'Psíquico';
    case 'ice':
      return 'Hielo';
    case 'fighting':
      return 'Lucha';
    case 'ghost':
      return 'Fantasma';
    case 'dragon':
      return 'Dragón';
    case 'fairy':
      return 'Hada';
    case 'dark':
      return 'Siniestro';
    case 'steel':
      return 'Acero';
    case 'flying':
      return 'Volador';
    default:
      return 'Normal';
  }
}

// Nombres cortos de las estadísticas en español
String nombreEstadistica(String nombre) {
  switch (nombre) {
    case 'hp':
      return 'PS';
    case 'attack':
      return 'Ataque';
    case 'defense':
      return 'Defensa';
    case 'special-attack':
      return 'At. Esp.';
    case 'special-defense':
      return 'Def. Esp.';
    case 'speed':
      return 'Velocidad';
    default:
      return nombre;
  }
}

// Color de la barra según qué tan alta es la estadística
Color colorPorValor(int valor) {
  if (valor < 50) return const Color(0xFFEF5350); // rojo
  if (valor < 80) return const Color(0xFFFFA726); // naranja
  if (valor < 100) return const Color(0xFFFFD54F); // amarillo
  if (valor < 130) return const Color(0xFF66BB6A); // verde
  return const Color(0xFF26C6DA); // turquesa (muy alta)
}

// Pone la primera letra en mayúscula y cambia guiones por espacios
String capitalizar(String texto) {
  if (texto.isEmpty) return texto;
  texto = texto.replaceAll('-', ' ');
  return texto[0].toUpperCase() + texto.substring(1);
}

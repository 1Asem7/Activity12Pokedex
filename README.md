# Actividad 12 – Flutter consumiendo una API (Práctica académica 02)

**Alumno:** Emmanuel Alejandro Paredes Ramírez
**Materia:** Programación de Aplicaciones – 5° B
**Profesor:** José Nabor Ramírez Morfín

Pokédex hecha en Flutter que consume la [PokeAPI](https://pokeapi.co/api/v2/pokemon/1/).

## ¿Qué hace?

- Hace la petición de red con **Dio** o con **http** (se cambia con el botón de arriba a la derecha).
- Usa `Future`, `async/await` y `FutureBuilder` para esperar la respuesta.
- Convierte el JSON en un objeto propio de Dart (`Pokemon`, en `lib/models/pokemon.dart`).
- Muestra nombre, número, tipos, imagen, altura, peso, habilidades y estadísticas.
- Permite buscar por nombre o número y avanzar con Anterior / Siguiente.

## Estructura

```
lib/
├── main.dart                     # Pantalla principal y animaciones
├── models/pokemon.dart           # Clase Pokemon, fromJson y datos de especie
├── services/pokemon_service.dart # Peticiones con http y Dio (con caché y timeout)
├── utils/tipos.dart              # Colores, íconos y nombres de tipos en español
└── widgets/
    ├── decoracion.dart           # Pokébola, carga animada y partículas de fondo
    └── estadisticas.dart         # Barras animadas y gráfica de radar
```

## Extras

- Animación al cambiar de Pokémon (desliza, escala y gira según la dirección).
- Fondo con degradado del color del tipo, burbujas y pokébola girando.
- Estadísticas en barras animadas o en gráfica de radar, con total.
- Versión shiny (botón o doble clic en la imagen).
- Descripción y categoría en español (endpoint `pokemon-species`).
- Botón aleatorio, flechas del teclado y deslizar para cambiar.

## Dependencias (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.2
  dio: ^5.7.0
```

## Ejecutar

```bash
flutter pub get
flutter run
```

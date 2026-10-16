import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/pokemon.dart';
import 'services/pokemon_service.dart';
import 'utils/tipos.dart';
import 'widgets/decoracion.dart';
import 'widgets/estadisticas.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokédex API',
      theme: ThemeData(
        colorSchemeSeed: Colors.red,
        useMaterial3: true,
      ),
      home: const PantallaPokedex(),
    );
  }
}

class PantallaPokedex extends StatefulWidget {
  const PantallaPokedex({super.key});

  @override
  State<PantallaPokedex> createState() => _PantallaPokedexState();
}

class _PantallaPokedexState extends State<PantallaPokedex>
    with TickerProviderStateMixin {
  final PokemonService servicio = PokemonService();
  final TextEditingController controladorBusqueda = TextEditingController();

  Pokemon? pokemon; // el Pokémon que se está mostrando
  bool cargando = false;
  String? error;

  int idActual = 1; // empezamos con Bulbasaur (pokemon/1)
  bool usarDio = true; // true = Dio, false = http
  bool shiny = false;
  int direccion = 1; // 1 = siguiente (entra por la derecha), -1 = anterior
  int numeroPeticion = 0; // para ignorar respuestas viejas si el usuario es muy rápido

  // Animaciones que se repiten siempre
  late AnimationController controladorFlotar; // la imagen sube y baja
  late AnimationController controladorGiro; // la pokébola del fondo gira

  @override
  void initState() {
    super.initState();

    controladorFlotar = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    controladorGiro = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // Esperamos a que se dibuje la pantalla y luego hacemos la primera petición
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cargarPokemon(idActual.toString());
    });
  }

  @override
  void dispose() {
    controladorFlotar.dispose();
    controladorGiro.dispose();
    controladorBusqueda.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Petición a la API (con Dio o con http)
  // ---------------------------------------------------------------
  Future<void> cargarPokemon(String idONombre) async {
    numeroPeticion = numeroPeticion + 1;
    int miPeticion = numeroPeticion;

    setState(() {
      cargando = true;
      error = null;
    });

    try {
      Pokemon nuevo;
      if (usarDio) {
        nuevo = await servicio.obtenerConDio(idONombre);
      } else {
        nuevo = await servicio.obtenerConHttp(idONombre);
      }

      // Si mientras tanto se pidió otro Pokémon, ignoramos esta respuesta
      if (!mounted || miPeticion != numeroPeticion) return;

      setState(() {
        pokemon = nuevo;
        idActual = nuevo.id;
        cargando = false;
        shiny = false;
      });
    } catch (e) {
      if (!mounted || miPeticion != numeroPeticion) return;

      String mensaje;
      if (e is TimeoutException) {
        mensaje = 'La petición tardó demasiado, intenta otra vez';
      } else {
        mensaje = e.toString().replaceAll('Exception: ', '');
      }

      setState(() {
        cargando = false;
        error = mensaje;
      });

      // Si ya había un Pokémon en pantalla, avisamos con un SnackBar
      if (pokemon != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
          ),
        );
      }
    }
  }

  void buscar() {
    String texto = controladorBusqueda.text.trim();
    if (texto.isEmpty) return;
    FocusScope.of(context).unfocus();
    direccion = 1;
    cargarPokemon(texto);
  }

  void siguiente() {
    direccion = 1;
    cargarPokemon((idActual + 1).toString());
  }

  void anterior() {
    if (idActual > 1) {
      direccion = -1;
      cargarPokemon((idActual - 1).toString());
    }
  }

  void aleatorio() {
    direccion = 1;
    int numero = Random().nextInt(1025) + 1;
    cargarPokemon(numero.toString());
  }

  void cambiarPaquete() {
    setState(() {
      usarDio = !usarDio;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(usarDio
            ? 'Ahora las peticiones se hacen con Dio'
            : 'Ahora las peticiones se hacen con http'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void cambiarShiny() {
    setState(() {
      shiny = !shiny;
    });
  }

  // ---------------------------------------------------------------
  // Pantalla principal
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    Color colorTipo = Colors.blueGrey;
    if (pokemon != null) {
      colorTipo = colorPorTipo(pokemon!.tipos[0]);
    }
    // Si es shiny le damos un toque dorado al fondo
    Color colorFinal = shiny ? Color.lerp(colorTipo, Colors.amber, 0.35)! : colorTipo;

    // Atajos de teclado (para web): flechas izquierda y derecha
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): siguiente,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): anterior,
      },
      child: Focus(
        autofocus: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorFinal, colorOscuro(colorFinal)],
            ),
          ),
          child: Stack(
            children: [
              // Burbujas del fondo
              const Positioned.fill(child: ParticulasFondo()),

              // Pokébola gigante girando como marca de agua
              Positioned(
                top: -60,
                right: -80,
                child: RotationTransition(
                  turns: controladorGiro,
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: CustomPaint(
                      painter: PokeballPainter(color: Colors.white.withAlpha(35)),
                    ),
                  ),
                ),
              ),

              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: barraSuperior(),
                body: SafeArea(child: cuerpo(colorTipo)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget barraSuperior() {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: PokeballCargandoQuieta(),
          ),
          const SizedBox(width: 10),
          const Text(
            'Pokédex',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Pokémon aleatorio',
          icon: const Icon(Icons.casino),
          onPressed: aleatorio,
        ),
        // Botón para cambiar entre Dio y http
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ActionChip(
            avatar: const Icon(Icons.swap_horiz, size: 18),
            label: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                usarDio ? 'Dio' : 'http',
                key: ValueKey(usarDio),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: cambiarPaquete,
          ),
        ),
      ],
    );
  }

  Widget cuerpo(Color colorTipo) {
    // Primera carga: todavía no hay Pokémon
    if (pokemon == null) {
      if (error != null) {
        return pantallaError();
      }
      return const Center(child: PokeballCargando(tamano: 90));
    }

    // Deslizar con el dedo / mouse para cambiar de Pokémon
    return GestureDetector(
      onHorizontalDragEnd: (detalles) {
        double velocidad = detalles.primaryVelocity ?? 0;
        if (velocidad < -300) {
          siguiente();
        } else if (velocidad > 300) {
          anterior();
        }
      },
      child: LayoutBuilder(
        builder: (context, restricciones) {
          // En pantallas anchas (web) usamos dos columnas
          if (restricciones.maxWidth > 900) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: seccionSuperior(alto: 420),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 24, 24),
                    child: SingleChildScrollView(
                      child: tarjetaInformacion(colorTipo, bordeCompleto: true),
                    ),
                  ),
                ),
              ],
            );
          }

          // En celular todo en una columna
          return SingleChildScrollView(
            child: Column(
              children: [
                seccionSuperior(alto: 260),
                tarjetaInformacion(colorTipo, bordeCompleto: false),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // Parte de arriba: buscador, nombre, tipos e imagen
  // ---------------------------------------------------------------
  Widget seccionSuperior({required double alto}) {
    Pokemon p = pokemon!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Buscador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: controladorBusqueda,
            onSubmitted: (valor) => buscar(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número (ej. pikachu, 25)',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: buscar,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nombre y número (cambian con animación)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            transitionBuilder: (child, animacion) {
              return FadeTransition(
                opacity: animacion,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animacion),
                  child: child,
                ),
              );
            },
            child: Row(
              key: ValueKey('nombre-${p.id}'),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capitalizar(p.nombre),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                      ),
                      if (p.categoria.isNotEmpty)
                        Text(
                          p.categoria,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '#${p.id.toString().padLeft(3, '0')}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tipos con ícono
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (int i = 0; i < p.tipos.length; i++)
                chipTipo(p.tipos[i], i),
              const Spacer(),
              // Botón shiny
              Material(
                color: shiny ? Colors.amber : Colors.white24,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: cambiarShiny,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: shiny ? 1 : 0,
                          duration: const Duration(milliseconds: 600),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: shiny ? Colors.black87 : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Shiny',
                          style: TextStyle(
                            color: shiny ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Imagen con número gigante detrás
        SizedBox(
          height: alto,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Número gigante de fondo
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: FittedBox(
                  key: ValueKey('numero-${p.id}'),
                  child: Text(
                    '#${p.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      fontSize: 150,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withAlpha(40),
                    ),
                  ),
                ),
              ),

              // Brillo circular detrás del Pokémon
              Container(
                width: alto * 0.7,
                height: alto * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withAlpha(110), Colors.white.withAlpha(0)],
                  ),
                ),
              ),

              // La imagen del Pokémon: entra deslizándose y luego flota
              AnimatedBuilder(
                animation: controladorFlotar,
                builder: (context, child) {
                  double movimiento =
                      Curves.easeInOut.transform(controladorFlotar.value);
                  return Transform.translate(
                    offset: Offset(0, -12 + movimiento * 24),
                    child: child,
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 550),
                  transitionBuilder: (child, animacion) {
                    // El que entra viene del lado de la dirección,
                    // el que sale se va hacia el lado contrario
                    bool entra = child.key == llaveImagen();
                    double inicioX = entra ? direccion * 0.9 : -direccion * 0.9;
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(inicioX, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animacion,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: animacion,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.4, end: 1)
                              .animate(CurvedAnimation(
                            parent: animacion,
                            curve: Curves.easeOutBack,
                          )),
                          child: RotationTransition(
                            turns: Tween<double>(
                              begin: direccion * 0.08,
                              end: 0,
                            ).animate(animacion),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    key: llaveImagen(),
                    onDoubleTap: cambiarShiny, // doble clic = shiny
                    child: Image.network(
                      shiny ? p.imagenShiny : p.imagen,
                      height: alto * 0.92,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progreso) {
                        if (progreso == null) return child;
                        return const PokeballCargando(tamano: 50);
                      },
                      errorBuilder: (context, error, stack) => const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              // Pokébola girando encima mientras carga el siguiente
              if (cargando)
                const Positioned(
                  bottom: 10,
                  right: 24,
                  child: PokeballCargando(tamano: 40),
                ),

              // Flechas a los lados
              Positioned(
                left: 4,
                child: botonFlecha(Icons.chevron_left, anterior),
              ),
              Positioned(
                right: 4,
                child: botonFlecha(Icons.chevron_right, siguiente),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ValueKey<String> llaveImagen() {
    return ValueKey('imagen-${pokemon!.id}-$shiny');
  }

  Widget chipTipo(String tipo, int indice) {
    // Cada chip aparece con un pequeño rebote
    return TweenAnimationBuilder<double>(
      key: ValueKey('tipo-${pokemon!.id}-$tipo'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + indice * 150),
      curve: Curves.elasticOut,
      builder: (context, valor, child) {
        return Transform.scale(scale: valor, child: child);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha(90)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconoPorTipo(tipo), size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              nombreTipo(tipo),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget botonFlecha(IconData icono, VoidCallback accion) {
    return Material(
      color: Colors.white.withAlpha(50),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icono, color: Colors.white, size: 30),
        onPressed: cargando ? null : accion,
      ),
    );
  }

  // ---------------------------------------------------------------
  // Tarjeta blanca con descripción, datos, habilidades y stats
  // ---------------------------------------------------------------
  Widget tarjetaInformacion(Color colorTipo, {required bool bordeCompleto}) {
    Pokemon p = pokemon!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: bordeCompleto
            ? BorderRadius.circular(30)
            : const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, animacion) {
          return FadeTransition(
            opacity: animacion,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(animacion),
              child: child,
            ),
          );
        },
        layoutBuilder: (actual, anteriores) {
          // Alineado arriba para que no brinque al cambiar
          return Stack(
            alignment: Alignment.topCenter,
            children: [...anteriores, if (actual != null) actual],
          );
        },
        child: Column(
          key: ValueKey('tarjeta-${p.id}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Descripción en español
            if (p.descripcion.isNotEmpty) ...[
              Text(
                p.descripcion,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Datos básicos
            Row(
              children: [
                datoBasico(Icons.height, 'Altura', '${p.altura / 10} m', colorTipo),
                const SizedBox(width: 10),
                datoBasico(Icons.monitor_weight_outlined, 'Peso',
                    '${p.peso / 10} kg', colorTipo),
                const SizedBox(width: 10),
                datoBasico(Icons.star_outline, 'Exp. base',
                    '${p.experienciaBase}', colorTipo),
              ],
            ),
            const SizedBox(height: 20),

            // Habilidades
            const Text(
              'Habilidades',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (String h in p.habilidades)
                  Chip(
                    avatar: Icon(Icons.flash_on, size: 16, color: colorTipo),
                    label: Text(capitalizar(h)),
                    backgroundColor: colorTipo.withAlpha(30),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            // Estadísticas (barras o radar)
            PanelEstadisticas(pokemon: p, colorTipo: colorTipo),

            const SizedBox(height: 14),
            Center(
              child: Text(
                'Datos obtenidos con ${usarDio ? 'Dio' : 'http'} · pokeapi.co',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget datoBasico(IconData icono, String titulo, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(22),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icono, color: color),
            const SizedBox(height: 6),
            Text(
              valor,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(titulo, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  // Pantalla de error cuando no se pudo cargar nada
  Widget pantallaError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              error ?? 'Ocurrió un error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              onPressed: () => cargarPokemon(idActual.toString()),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// Pokébola pequeña sin animación para el título
class PokeballCargandoQuieta extends StatelessWidget {
  const PokeballCargandoQuieta({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PokeballPainter(color: const Color(0xFF263238), rellena: true),
    );
  }
}

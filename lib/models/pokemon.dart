// Clase personalizada para guardar los datos que nos regresa la PokeAPI

class Estadistica {
  final String nombre;
  final int valor;

  Estadistica({required this.nombre, required this.valor});
}

class Pokemon {
  final int id;
  final String nombre;
  final int altura; // viene en decímetros
  final int peso; // viene en hectogramos
  final int experienciaBase;
  final String imagen;
  final String imagenShiny;
  final String urlEspecie;
  final List<String> tipos;
  final List<String> habilidades;
  final List<Estadistica> estadisticas;

  // Estos dos vienen de otra petición (pokemon-species), por eso no son final
  String descripcion = '';
  String categoria = '';

  Pokemon({
    required this.id,
    required this.nombre,
    required this.altura,
    required this.peso,
    required this.experienciaBase,
    required this.imagen,
    required this.imagenShiny,
    required this.urlEspecie,
    required this.tipos,
    required this.habilidades,
    required this.estadisticas,
  });

  // Suma de todas las estadísticas
  int get totalEstadisticas {
    int total = 0;
    for (var e in estadisticas) {
      total = total + e.valor;
    }
    return total;
  }

  // Convierte el JSON (Map) de la API en un objeto Pokemon
  factory Pokemon.fromJson(Map<String, dynamic> json) {
    // Tipos
    List<String> listaTipos = [];
    for (var t in json['types']) {
      listaTipos.add(t['type']['name']);
    }
    if (listaTipos.isEmpty) {
      listaTipos.add('normal');
    }

    // Habilidades
    List<String> listaHabilidades = [];
    for (var h in json['abilities']) {
      listaHabilidades.add(h['ability']['name']);
    }

    // Estadísticas
    List<Estadistica> listaEstadisticas = [];
    for (var e in json['stats']) {
      listaEstadisticas.add(
        Estadistica(nombre: e['stat']['name'], valor: e['base_stat']),
      );
    }

    // Imágenes: primero intentamos la oficial, si no hay usamos la normal
    String urlImagen = '';
    String urlShiny = '';
    var sprites = json['sprites'];
    var oficial = sprites['other'] != null
        ? sprites['other']['official-artwork']
        : null;

    if (oficial != null && oficial['front_default'] != null) {
      urlImagen = oficial['front_default'];
    } else if (sprites['front_default'] != null) {
      urlImagen = sprites['front_default'];
    }

    if (oficial != null && oficial['front_shiny'] != null) {
      urlShiny = oficial['front_shiny'];
    } else if (sprites['front_shiny'] != null) {
      urlShiny = sprites['front_shiny'];
    } else {
      urlShiny = urlImagen; // si no tiene shiny usamos la normal
    }

    return Pokemon(
      id: json['id'],
      nombre: json['name'],
      altura: json['height'] ?? 0,
      peso: json['weight'] ?? 0,
      experienciaBase: json['base_experience'] ?? 0,
      imagen: urlImagen,
      imagenShiny: urlShiny,
      urlEspecie: json['species'] != null ? json['species']['url'] : '',
      tipos: listaTipos,
      habilidades: listaHabilidades,
      estadisticas: listaEstadisticas,
    );
  }

  // Lee la descripción y la categoría en español del endpoint pokemon-species
  void agregarDatosEspecie(Map<String, dynamic> json) {
    // Descripción (flavor text) en español
    for (var entrada in json['flavor_text_entries']) {
      if (entrada['language']['name'] == 'es') {
        String texto = entrada['flavor_text'];
        // La API trae saltos de línea raros, los quitamos
        texto = texto.replaceAll('\n', ' ').replaceAll('\f', ' ');
        descripcion = texto;
        break;
      }
    }

    // Categoría, por ejemplo "Pokémon Semilla"
    for (var g in json['genera']) {
      if (g['language']['name'] == 'es') {
        categoria = g['genus'];
        break;
      }
    }
  }
}

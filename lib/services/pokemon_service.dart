import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

// Servicio que hace las peticiones de red a la PokeAPI
// Tiene dos formas: con el paquete http y con el paquete Dio
class PokemonService {
  final String urlBase = 'https://pokeapi.co/api/v2/pokemon/';

  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Caché: guardamos los Pokémon que ya descargamos para no pedirlos otra vez
  final Map<String, Pokemon> cache = {};

  String limpiar(String idONombre) {
    return idONombre.toLowerCase().trim().replaceAll(' ', '-');
  }

  // ---------- Opción 1: paquete http ----------
  Future<Pokemon> obtenerConHttp(String idONombre) async {
    String clave = limpiar(idONombre);
    if (cache.containsKey(clave)) {
      return cache[clave]!;
    }

    final url = Uri.parse(urlBase + clave);
    final respuesta =
        await http.get(url).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode == 200) {
      // http regresa un String, hay que convertirlo a Map con jsonDecode
      Map<String, dynamic> datos = jsonDecode(respuesta.body);
      Pokemon pokemon = Pokemon.fromJson(datos);

      // Segunda petición: descripción y categoría en español
      if (pokemon.urlEspecie.isNotEmpty) {
        try {
          final respEspecie = await http
              .get(Uri.parse(pokemon.urlEspecie))
              .timeout(const Duration(seconds: 10));
          if (respEspecie.statusCode == 200) {
            pokemon.agregarDatosEspecie(jsonDecode(respEspecie.body));
          }
        } catch (e) {
          // Si falla no pasa nada, solo no mostramos la descripción
        }
      }

      guardarEnCache(clave, pokemon);
      return pokemon;
    } else if (respuesta.statusCode == 404) {
      throw Exception('No existe ningún Pokémon llamado "$idONombre"');
    } else {
      throw Exception('Error del servidor (código ${respuesta.statusCode})');
    }
  }

  // ---------- Opción 2: paquete Dio ----------
  Future<Pokemon> obtenerConDio(String idONombre) async {
    String clave = limpiar(idONombre);
    if (cache.containsKey(clave)) {
      return cache[clave]!;
    }

    try {
      final respuesta = await dio.get(urlBase + clave);
      // Dio ya regresa el JSON convertido a Map
      Map<String, dynamic> datos = respuesta.data;
      Pokemon pokemon = Pokemon.fromJson(datos);

      // Segunda petición: descripción y categoría en español
      if (pokemon.urlEspecie.isNotEmpty) {
        try {
          final respEspecie = await dio.get(pokemon.urlEspecie);
          pokemon.agregarDatosEspecie(respEspecie.data);
        } catch (e) {
          // Si falla no pasa nada, solo no mostramos la descripción
        }
      }

      guardarEnCache(clave, pokemon);
      return pokemon;
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 404) {
        throw Exception('No existe ningún Pokémon llamado "$idONombre"');
      } else if (e.response != null) {
        throw Exception('Error del servidor (código ${e.response!.statusCode})');
      } else {
        throw Exception('Error de conexión: revisa tu internet');
      }
    }
  }

  // Guardamos por número y por nombre, así funciona buscar "1" o "bulbasaur"
  void guardarEnCache(String clave, Pokemon pokemon) {
    cache[clave] = pokemon;
    cache[pokemon.id.toString()] = pokemon;
    cache[pokemon.nombre] = pokemon;
  }
}

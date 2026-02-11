// services/api_repository.dart
import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/medicion.dart'; // Importa tu modelo

// services/api_repository.dart

class ApiRepository {
  // Cambiamos 'listMediciones' por 'listMiPrimerModeloDeDatos'
  static const String listMedicionesQuery = '''
    query ListMiPrimerModeloDeDatos(\$filter: ModelMiPrimerModeloDeDatosFilterInput, \$limit: Int, \$nextToken: String) {
      listMiPrimerModeloDeDatos(filter: \$filter, limit: \$limit, nextToken: \$nextToken) {
        items {
          id
          timestamp
          Agua
          AguaR
          Diesel
          gLP
        }
        nextToken
      }
    }
  ''';

  Future<List<Medicion>> getMedicionesPorRango(DateTime start, DateTime end) async {
    List<Medicion> allItems = [];
    String? nextToken;

    int startTs = start.millisecondsSinceEpoch ~/ 1000;
    int endTs = end.millisecondsSinceEpoch ~/ 1000;

    try {
      do {
        final request = GraphQLRequest<String>(
          document: listMedicionesQuery,
          variables: {
            // Ajustamos el filtro según el esquema estándar de Amplify
            'filter': {
              'timestamp': { 'between': [startTs, endTs] }
            },
            'limit': 1000,
            'nextToken': nextToken,
          },
        );

        final response = await Amplify.API.query(request: request).response;

        if (response.data == null || response.errors.isNotEmpty) {
          safePrint('Errores de GraphQL: ${response.errors}');
          break;
        }

        final jsonMap = jsonDecode(response.data!);
        // Cambiar aquí también el acceso al mapa
        final listData = jsonMap['listMiPrimerModeloDeDatos'];

        final items = (listData['items'] as List)
            .map((e) => Medicion.fromJson(e))
            .toList();

        allItems.addAll(items);
        nextToken = listData['nextToken'];

      } while (nextToken != null);

      allItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return allItems;
    } catch (e) {
      safePrint('Excepción en la API: $e');
      return [];
    }
  }
}
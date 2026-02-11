// Archivo: mi_primer_model_demo.dart
// Demo Flutter que muestra un botón de demostración por cada función/operación común
// sobre el modelo generado `MiPrimerModelo` por Amplify.
// Ajusta las rutas de import según tu proyecto (models/...).

import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
// Ajusta las rutas si tus archivos generados están en `lib/models/` u otra carpeta
import '../models/ModelProvider.dart';
import '../models/MiPrimerModeloDeDatos.dart';

/// NOTAS IMPORTANTES:
/// - Asegúrate de que Amplify esté configurado y que el plugin DataStore (o API)
///   esté correctamente agregado y configurado en tu proyecto antes de usar
///   este demo (generalmente en main.dart llamando a Amplify.configure(...) ).
/// - Cambia las rutas de import si tus archivos generados están en otro lugar.
/// - Este archivo es una demostración educativa; maneja errores y estados
///   en producción de forma más robusta.

class MiPrimerModeloDemo extends StatefulWidget {
  const MiPrimerModeloDemo({super.key});

  @override
  State<MiPrimerModeloDemo> createState() => _MiPrimerModeloDemoState();
}

class _MiPrimerModeloDemoState extends State<MiPrimerModeloDemo> {
  final List<String> _logs = [];
  bool _busy = false;

  void _log(String s) {
    setState(() {
      _logs.insert(0, "[${DateTime.now().toIso8601String()}] $s");
    });
  }

  Future<void> _safeRun(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } catch (e, st) {
      _log('ERROR: \$e');
      _log(st.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  // 1) CREATE - guarda un nuevo registro en DataStore
  Future<void> _createExample() async {
    await _safeRun(() async {
      final nuevo = MiPrimerModeloDeDatos(
        // id opcional — Amplify generará uno si no lo pasas
        GLP: 123, // campo requerido en el modelo
        Agua: 10,
        Agua_R: 5,
        Diesel: 7,
      );

      await Amplify.DataStore.save(nuevo);
      _log('CREATE -> guardado: $nuevo');
    });
  }

  // 2) READ ALL - consulta todos los registros
  Future<void> _readAll() async {
    await _safeRun(() async {
      final lista = await Amplify.DataStore.query(MiPrimerModeloDeDatos.classType);
      _log('READ ALL -> ${lista.length} elementos encontrados');
      for (var e in lista) {
        _log('  • $e');
      }
    });
  }

  // 3) QUERY BY FIELD - ejemplo: filtrar por GLP (igual a un valor)
  Future<void> _queryByGLP() async {
    await _safeRun(() async {
      // Ejemplo: buscar donde GLP == 123
      final where = MiPrimerModeloDeDatos.GLP_QUERY_FIELD.eq(123);
      final resultado = await Amplify.DataStore.query(MiPrimerModeloDeDatos.classType, where: where);
      _log('QUERY GLP==123 -> ${resultado.length} encontrados');
      for (var r in resultado) {
        _log('  • $r');
      }
    });
  }

  // 4) UPDATE - tomar el primer elemento y actualizarlo
  Future<void> _updateExample() async {
    await _safeRun(() async {
      final todos = await Amplify.DataStore.query(MiPrimerModeloDeDatos.classType);
      if (todos.isEmpty) {
        _log('UPDATE -> no hay elementos para actualizar');
        return;
      }
      final primero = todos.first;
      final actualizado = primero.copyWith(GLP: primero.GLP + 1);
      await Amplify.DataStore.save(actualizado);
      _log('UPDATE -> actualizado: $actualizado');
    });
  }

  // 5) DELETE - borrar el primer elemento
  Future<void> _deleteExample() async {
    await _safeRun(() async {
      final todos = await Amplify.DataStore.query(MiPrimerModeloDeDatos.classType);
      if (todos.isEmpty) {
        _log('DELETE -> no hay elementos para borrar');
        return;
      }
      final primero = todos.first;
      await Amplify.DataStore.delete(primero);
      _log('DELETE -> borrado: ' + primero.id);
    });
  }

  // 6) toJson / fromJson demo
  Future<void> _toFromJsonDemo() async {
    await _safeRun(() async {
      final m = MiPrimerModeloDeDatos(GLP: 42, Agua: 1);
      final json = m.toJson();
      _log('toJson -> $json');

      final reconstruido = MiPrimerModeloDeDatos.fromJson(json);
      _log('fromJson -> $reconstruido');
    });
  }

  // 7) copyWith demo
  Future<void> _copyWithDemo() async {
    await _safeRun(() async {
      final m = MiPrimerModeloDeDatos(GLP: 50, Agua: 2);
      final c = m.copyWith(Agua: 99, GLP: 500);
      _log('copyWith -> original: $m');
      _log('copyWith -> nuevo: $c');
    });
  }


  // 9) modelIdentifier demo (usar el identificador del modelo)
  Future<void> _modelIdentifierDemo() async {
    await _safeRun(() async {
      final m = MiPrimerModeloDeDatos(GLP: 88);
      final id = m.modelIdentifier.serializeAsString();
      _log('modelIdentifier -> ' + id);
    });
  }

  // Pequeña UI con botones para cada demo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo MiPrimerModelo (Amplify)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(onPressed: _busy ? null : _createExample, child: const Text('CREATE')),
                ElevatedButton(onPressed: _busy ? null : _readAll, child: const Text('READ ALL')),
                ElevatedButton(onPressed: _busy ? null : _queryByGLP, child: const Text('QUERY GLP==123')),
                ElevatedButton(onPressed: _busy ? null : _updateExample, child: const Text('UPDATE (first)')),
                ElevatedButton(onPressed: _busy ? null : _deleteExample, child: const Text('DELETE (first)')),
                ElevatedButton(onPressed: _busy ? null : _toFromJsonDemo, child: const Text('toJson / fromJson')),
                ElevatedButton(onPressed: _busy ? null : _copyWithDemo, child: const Text('copyWith')),
                ElevatedButton(onPressed: _busy ? null : _modelIdentifierDemo, child: const Text('modelIdentifier')),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black12,
              child: ListView.builder(
                reverse: false,
                itemCount: _logs.length,
                itemBuilder: (context, i) => Text(_logs[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FIN del archivo demo

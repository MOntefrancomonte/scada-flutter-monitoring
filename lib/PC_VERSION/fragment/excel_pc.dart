// excel_pc.dart (modificado)
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb; // Para detectar si es Web
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';

// Importación condicional para evitar errores en Web
import 'package:universal_html/html.dart' as html;

// Si vas a mantener soporte Desktop/Móvil, mantén estas importaciones.
// Si es SOLO web, puedes borrarlas, pero aquí las dejo comentadas o usadas con guardas.
import 'dart:io' as io;
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';

import '../fragment/excel_UI/excel_report_generator.dart';

class ExcelPackage {

  /// Genera y descarga el Excel (Compatible con Web y Windows)
  Future<void> createExcelDelPanelWindows(GlobalKey<SfDataGridState> key) async {
    try {
      // 1. Extraer datos del DataGrid (Igual que antes)
      final dataGrid = key.currentState!;
      final data = _extractDataFromDataGrid(dataGrid);
      final columnNames = _extractColumnNames(dataGrid);

      // 2. Crear reporte con formato profesional
      final Workbook workbook = ExcelReportGenerator.generateReportFromDataGrid(
        columnNames: columnNames,
        data: data,
        reportTitle: 'REPORTE DE CONSUMOS - SISTEMA DE GESTIÓN',
        dateRange: _getDateRange(data),
      );

      // 3. Obtener los bytes del archivo
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final String fileName = 'Reporte_Consumos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';

      // 4. Lógica bifurcada según la plataforma
      if (kIsWeb) {
        // === LÓGICA WEB ===
        _saveAndDownloadWeb(bytes, fileName);
        print('✅ Descarga iniciada en el navegador: $fileName');
      } else {
        // === LÓGICA DESKTOP (WINDOWS) ===
        // Nota: Solo se ejecutará si NO es web
        await _saveAndOpenWindows(bytes, fileName);
      }

    } catch (e) {
      print('❌ Error al exportar Excel: $e');
      rethrow;
    }
  }

  // ================================
  // MÉTODO ESPECÍFICO PARA WEB
  // ================================
  void _saveAndDownloadWeb(List<int> bytes, String fileName) {
    // Crear un Blob con los datos del Excel
    final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

    // Crear una URL temporal para el Blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Crear un elemento ancla <a> invisible y simular clic
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    // Limpiar memoria
    html.Url.revokeObjectUrl(url);
  }

  // ================================
  // MÉTODO ESPECÍFICO PARA WINDOWS
  // ================================
  Future<void> _saveAndOpenWindows(List<int> bytes, String fileName) async {
    // Verificar compatibilidad con io.Platform de forma segura
    if (!kIsWeb && (io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux)) {
      final String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar Reporte Excel',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (outputPath == null) {
        throw Exception('Guardado cancelado por el usuario');
      }

      final io.File file = io.File(outputPath);
      if (await file.exists()) {
        await file.delete();
      }
      await file.writeAsBytes(bytes, flush: true);

      // Abrir archivo
      OpenFile.open(outputPath);
    }
  }

  // ================================
  // MÉTODOS PRIVADOS AUXILIARES (Sin cambios)
  // ================================

  static List<String> _extractColumnNames(SfDataGridState dataGrid) {
    final columns = dataGrid.widget.columns;
    return columns.map((col) => col.columnName).toList();
  }

  static List<List<dynamic>> _extractDataFromDataGrid(SfDataGridState dataGrid) {
    final List<List<dynamic>> data = [];
    final source = dataGrid.widget.source;

    for (int i = 0; i < source.rows.length; i++) {
      final row = source.rows[i];
      final List<dynamic> rowData = [];
      for (final cell in row.getCells()) {
        rowData.add(cell.value);
      }
      data.add(rowData);
    }
    return data;
  }

  static String _getDateRange(List<List<dynamic>> data) {
    if (data.isEmpty) return 'Sin datos';
    try {
      final firstDate = data.first[0] as DateTime?;
      final lastDate = data.last[0] as DateTime?; // Asumiendo orden ascendente

      if (firstDate != null && lastDate != null) {
        return '${DateFormat('dd/MM/yyyy').format(firstDate)} - ${DateFormat('dd/MM/yyyy').format(lastDate)}';
      }
    } catch (e) {
      print('Error obteniendo rango de fechas: $e');
    }
    return 'Período no especificado';
  }
}
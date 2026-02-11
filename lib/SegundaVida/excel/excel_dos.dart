//excel_dos.dart
// ignore_for_file: camel_case_types
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_datagrid_export/export.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import 'excel_template_engine.dart'; // Tu nuevo archivo

class excel_package {
  Future<void> createExcelDelPanel(GlobalKey<SfDataGridState> key) async {
    // 1. Exportar datos del DataGrid a un Workbook
    final Workbook workbook = key.currentState!.exportToExcelWorkbook();
    final Worksheet sheet = workbook.worksheets[0];
    final int lastRow = sheet.getLastRow();
    final int lastCol = sheet.getLastColumn();
    print("ready");
    // 2. Extraer nombres de cabeceras
    List<String> headers = [];
    for (int c = 1; c <= lastCol; c++) {
      headers.add(sheet.getRangeByIndex(1, c).text ?? 'Col $c');
    }

    // 3. APLICAR LA PLANTILLA PREMIUM (Gráficos, Dashboard y Sumas)
    ExcelTemplateEngine.applyPremiumTemplate(workbook, headers, lastRow, lastCol);

    // 4. Guardar archivo con nombre único (Marca de tiempo)
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final String fileName = "Reporte_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final directory = await getTemporaryDirectory();
    final String fullPath = '${directory.path}/$fileName';

    final File file = File(fullPath);
    await file.writeAsBytes(bytes, flush: true);

    // 5. COMPARTIR (WhatsApp, Email, etc.)
    await Share.shareXFiles(
      [XFile(fullPath)],
      text: 'Adjunto reporte de consumos generado desde la App.',
      subject: 'Reporte de Consumo Excel',
    );
  }
}
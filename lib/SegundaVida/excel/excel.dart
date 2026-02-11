
import 'package:flutter/material.dart';


import 'package:syncfusion_flutter_datagrid_export/export.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

//import 'helper.dart'; // tu helper para guardar y abrir el archivo Excel


//final GlobalKey<SfDataGridState> key = GlobalKey<SfDataGridState>();
class excel_package {
  Future<void> createExcel() async {
// Create a new Excel Document.
    final Workbook workbook = Workbook();
    print("creando documento de excel");
// Accessing worksheet via index.
    final Worksheet sheet = workbook.worksheets[0];
    print("accediendo a worksheet via index");
// Set the text value.
    sheet.getRangeByName('A1').setText('Hello World!');
    print("establecer valores");
// Save and dispose the document.
    final List<int> bytes = workbook.saveSync();
    workbook.dispose();
    print("guardar documento");

// Get external storage directory
    final directory = await getExternalStorageDirectory();
    print(directory);

// Get directory path
    final path = directory?.path;

// Create an empty file to write Excel data
    File file = File('$path/Output.xlsx');
    print('$path/Output.xlsx');

// Write Excel data
    await file.writeAsBytes(bytes, flush: true);
    print("Se ha impreso en el excel");
// Open the Excel document in mobile
    OpenFile.open('$path/Output.xlsx');
    print("abriendo excel ...");
  }
  Future<void> createExcelDelPanel(GlobalKey<SfDataGridState> key) async {
    final Workbook workbook =
    key.currentState!.exportToExcelWorkbook();
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory();
    print(directory);

// Get directory path
    final path = directory?.path;

// Create an empty file to write Excel data
    File file = File('$path/Output.xlsx');
    print('$path/Output.xlsx');

    // Si existe, intenta borrarlo primero para forzar la actualización
    try {
      if (await file.exists()) {
        await file.delete();
        // opcional: espera breve (no siempre necesario)
        // await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      print('No se pudo eliminar archivo anterior: $e');
    }

// Write Excel data
    await file.writeAsBytes(bytes, mode: FileMode.write, flush: true);
    print("Se ha impreso en el excel");

    // Asegurar que la fecha de modificación cambie (opcional)
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {}

// Open the Excel document in mobile
    OpenFile.open('$path/Output.xlsx');
    print("abriendo excel ...");
    //await helper.saveAndLaunchFile(bytes, 'DataGrid.xlsx');
  }
}
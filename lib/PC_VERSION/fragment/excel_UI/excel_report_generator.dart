// excel_report_generator.dart - VERSIÓN CORREGIDA Y MEJORADA
import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_officechart/officechart.dart';

class ExcelReportGenerator {
  // Constantes para nombres de hojas
  static const String dataSheetName = 'Datos Principales';
  static const String statsSheetName = 'Análisis Estadístico';
  static const String summarySheetName = 'Resumen Ejecutivo';
  static const String chartsSheetName = 'Gráficos';
  static const String metadataSheetName = 'Metadatos';

  /// Genera un reporte Excel completo con formato profesional y estadísticas
  static Workbook generateReportFromDataGrid({
    required List<String> columnNames,
    required List<List<dynamic>> data,
    required String reportTitle,
    required String dateRange,
  }) {
    final Workbook workbook = Workbook();

    // ================================
    // 1. HOJA DE DATOS PRINCIPALES
    // ================================
    final Worksheet dataSheet = workbook.worksheets[0];
    dataSheet.name = dataSheetName;
    _createDataSheet(dataSheet, columnNames, data, reportTitle, dateRange);

    // ================================
    // 2. HOJA DE ANÁLISIS ESTADÍSTICO
    // ================================
    final Worksheet statsSheet = workbook.worksheets.add();
    statsSheet.name = statsSheetName;
    _createStatisticsSheet(statsSheet, columnNames, data, reportTitle, dateRange);

    // ================================
    // 3. HOJA DE RESUMEN EJECUTIVO
    // ================================
    final Worksheet summarySheet = workbook.worksheets.add();
    summarySheet.name = summarySheetName;
    _createSummarySheet(summarySheet, columnNames, data, reportTitle, dateRange);

    // ================================
    // 4. HOJA DE GRÁFICOS Y TENDENCIAS
    // ================================
    final Worksheet chartsSheet = workbook.worksheets.add();
    chartsSheet.name = chartsSheetName;
    _createChartsSheet(chartsSheet, columnNames, data, reportTitle);

    // ================================
    // 5. HOJA DE METADATOS
    // ================================
    final Worksheet metadataSheet = workbook.worksheets.add();
    metadataSheet.name = metadataSheetName;
    _createMetadataSheet(metadataSheet, columnNames, data, reportTitle, dateRange);

    return workbook;
  }

  // ================================
  // HOJA DE DATOS PRINCIPALES
  // ================================
  static void _createDataSheet(Worksheet sheet, List<String> columnNames,
      List<List<dynamic>> data, String title, String dateRange) {

    // Encabezado del reporte
    _addReportHeader(sheet, title, dateRange);

    final int dataStartRow = 5;

    // Encabezados de columna con formato profesional
    for (int i = 0; i < columnNames.length; i++) {
      final Range headerCell = sheet.getRangeByIndex(dataStartRow, i + 1);
      headerCell.setText(_formatColumnName(columnNames[i]));
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.backColor = '#1E4B7F';
      headerCell.cellStyle.fontColor = '#FFFFFF';
      headerCell.cellStyle.hAlign = HAlignType.center;
      headerCell.cellStyle.vAlign = VAlignType.center;
      headerCell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      headerCell.cellStyle.borders.all.color = '#FFFFFF';
      headerCell.cellStyle.fontSize = 11;
    }

    // Datos con formato condicional
    for (int row = 0; row < data.length; row++) {
      for (int col = 0; col < columnNames.length; col++) {
        final Range dataCell = sheet.getRangeByIndex(dataStartRow + row + 1, col + 1);
        final dynamic value = data[row][col];

        if (value is DateTime) {
          dataCell.setDateTime(value);
          dataCell.cellStyle.hAlign = HAlignType.center;
          dataCell.numberFormat = 'dd/mm/yyyy hh:mm:ss';
        } else if (value is num) {
          dataCell.setNumber(value.toDouble());
          dataCell.cellStyle.hAlign = HAlignType.right;
          dataCell.numberFormat = '#,##0.00';

          // Color condicional basado en percentiles
          final double val = value.toDouble();
          if (val > 0) {
            if (val > 1000) {
              dataCell.cellStyle.fontColor = '#C00000';
              dataCell.cellStyle.bold = true;
            } else if (val > 500) {
              dataCell.cellStyle.fontColor = '#FFC000';
            }
          }
        } else {
          dataCell.setText(value?.toString() ?? '--');
          dataCell.cellStyle.hAlign = HAlignType.center;
        }

        // Bordes y fondo alternado
        dataCell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        dataCell.cellStyle.borders.all.color = '#D9D9D9';

        if (row % 2 == 0) {
          dataCell.cellStyle.backColor = '#F5F7FA';
        } else {
          dataCell.cellStyle.backColor = '#FFFFFF';
        }
      }
    }

    // Fórmulas de subtotales por columna
    final int totalRow = dataStartRow + data.length + 2;
    final Range totalLabel = sheet.getRangeByIndex(totalRow, 1);
    totalLabel.setText('SUBTOTALES:');
    totalLabel.cellStyle.bold = true;
    totalLabel.cellStyle.fontColor = '#1E4B7F';

    for (int col = 1; col < columnNames.length; col++) {
      if (columnNames[col] != 'timestamp') {
        final String colLetter = _getColumnLetter(col + 1);
        final String range = '$colLetter${dataStartRow + 1}:$colLetter${dataStartRow + data.length}';

        final Range totalCell = sheet.getRangeByIndex(totalRow, col + 1);
        totalCell.setFormula('=SUM($range)');
        totalCell.numberFormat = '#,##0.00';
        totalCell.cellStyle.bold = true;
        totalCell.cellStyle.backColor = '#E7E6E6';
        totalCell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      }
    }

    // Ajustar ancho de columnas
    for (int i = 1; i <= columnNames.length; i++) {
      final Range column = sheet.getRangeByIndex(1, i);
      if (i == 1) {
        column.columnWidth = 20;
      } else {
        column.columnWidth = 15;
      }
    }

    // Agregar filtros
    final Range headerRange = sheet.getRangeByIndex(dataStartRow, 1, dataStartRow, columnNames.length);
    sheet.autoFilters.filterRange = headerRange;

    // Congelar paneles
    sheet.getRangeByIndex(dataStartRow + 1, 1).freezePanes();
  }

  // ================================
  // HOJA DE ANÁLISIS ESTADÍSTICO - CORREGIDA
  // ================================
  static void _createStatisticsSheet(Worksheet sheet, List<String> columnNames,
      List<List<dynamic>> data, String title, String dateRange) {

    _addSheetHeader(sheet, 'ANÁLISIS ESTADÍSTICO DETALLADO', title, dateRange);

    final int startRow = 5;
    final int dataStartRow = 5; // En la hoja de datos
    final int dataCount = data.length;

    // Tabla de estadísticas principales
    final List<String> statsHeaders = [
      'Métrica',
      'Total (Σ)',
      'Promedio (μ)',
      'Mediana',
      'Moda',
      'Mínimo',
      'Máximo',
      'Rango',
      'Desv. Estándar (σ)',
      'Varianza (σ²)',
      'Coef. Variación (%)',
      'Asimetría (Skew)',
      'Curtosis',
      'Percentil 25% (Q1)',
      'Percentil 75% (Q3)',
      'Rango Intercuartil',
      'Registros Válidos'
    ];

    // Encabezados de estadísticas
    for (int i = 0; i < statsHeaders.length; i++) {
      final Range headerCell = sheet.getRangeByIndex(startRow, i + 1);
      headerCell.setText(statsHeaders[i]);
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.backColor = '#2E5984';
      headerCell.cellStyle.fontColor = '#FFFFFF';
      headerCell.cellStyle.borders.all.lineStyle = LineStyle.thin;
      headerCell.cellStyle.borders.all.color = '#FFFFFF';
      headerCell.cellStyle.hAlign = HAlignType.center;
      headerCell.cellStyle.fontSize = 10;
    }

    // CORRECCIÓN: Usar el nombre correcto de la hoja de datos
    final String dataSheetRef = _escapeSheetName(dataSheetName);

    // Estadísticas para cada columna numérica
    for (int col = 1; col < columnNames.length; col++) {
      final String colLetter = _getColumnLetter(col + 1);
      // CORRECCIÓN: Referencia correcta a la hoja "Datos Principales"
      final String dataRange = '$dataSheetRef!$colLetter${dataStartRow + 1}:$colLetter${dataStartRow + dataCount}';

      final int statRow = startRow + 1 + (col - 1);

      // Nombre de la métrica
      sheet.getRangeByIndex(statRow, 1).setText(_formatColumnName(columnNames[col]));
      sheet.getRangeByIndex(statRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(statRow, 1).cellStyle.fontColor = '#1E4B7F';

      // Fórmulas estadísticas CORREGIDAS
      final List<String> formulas = [
        '=SUM($dataRange)',                                    // Total
        '=AVERAGE($dataRange)',                                // Promedio
        '=MEDIAN($dataRange)',                                 // Mediana
        '=MODE.SNGL($dataRange)',                              // Moda (usamos MODE.SNGL que es más compatible)
        '=MIN($dataRange)',                                    // Mínimo
        '=MAX($dataRange)',                                    // Máximo
        '=MAX($dataRange)-MIN($dataRange)',                    // Rango
        '=STDEV.S($dataRange)',                                // Desviación estándar
        '=VAR.S($dataRange)',                                  // Varianza
        '=IFERROR(STDEV.S($dataRange)/AVERAGE($dataRange)*100, 0)', // Coef. Variación
        '=SKEW($dataRange)',                                   // Asimetría
        '=KURT($dataRange)',                                   // Curtosis
        '=PERCENTILE.INC($dataRange, 0.25)',                   // Q1 (usamos PERCENTILE.INC para compatibilidad)
        '=PERCENTILE.INC($dataRange, 0.75)',                   // Q3
        '=PERCENTILE.INC($dataRange, 0.75)-PERCENTILE.INC($dataRange, 0.25)', // IQR
        '=COUNT($dataRange)'                                   // Registros válidos
      ];

      for (int i = 0; i < formulas.length; i++) {
        final Range statCell = sheet.getRangeByIndex(statRow, i + 2);
        statCell.setFormula(formulas[i]);

        // Formato específico por tipo de estadística
        if (i == 0 || i == 1 || i == 2 || i == 3 || i == 4 || i == 5 || i == 6 || i == 7 || i == 8) {
          statCell.numberFormat = '#,##0.00';
        } else if (i == 9) {
          statCell.numberFormat = '0.00"%"';
        } else if (i == 10 || i == 11) {
          statCell.numberFormat = '0.00';
        } else if (i == 12 || i == 13 || i == 14) {
          statCell.numberFormat = '#,##0.00';
        } else if (i == 16) {
          statCell.numberFormat = '#,##0';
        } else {
          statCell.numberFormat = '0.00';
        }

        // Color basado en el valor
        if (i == 1) { // Promedio
          statCell.cellStyle.fontColor = '#00B050';
        } else if (i == 4) { // Mínimo
          statCell.cellStyle.fontColor = '#FF0000';
        } else if (i == 5) { // Máximo
          statCell.cellStyle.fontColor = '#C00000';
          statCell.cellStyle.bold = true;
        }

        statCell.cellStyle.borders.all.lineStyle = LineStyle.thin;
        statCell.cellStyle.borders.all.color = '#D9D9D9';

        if (statRow % 2 == 0) {
          statCell.cellStyle.backColor = '#F5F7FA';
        }
      }
    }

    // Análisis de distribución
    final int distStartRow = startRow + columnNames.length + 3;
    _addDistributionAnalysis(sheet, columnNames, dataStartRow, dataCount, distStartRow);

    // Ajustar anchos de columna
    sheet.getRangeByIndex(1, 1).columnWidth = 25;
    for (int i = 2; i <= statsHeaders.length; i++) {
      sheet.getRangeByIndex(1, i).columnWidth = 15;
    }
  }

  // ================================
  // HOJA DE RESUMEN EJECUTIVO - CORREGIDA
  // ================================
  static void _createSummarySheet(Worksheet sheet, List<String> columnNames,
      List<List<dynamic>> data, String title, String dateRange) {

    _addSheetHeader(sheet, 'RESUMEN EJECUTIVO', title, dateRange);

    final int startRow = 5;
    final int dataStartRow = 5;
    final int dataCount = data.length;

    // CORRECCIÓN: Referencia correcta a la hoja "Análisis Estadístico"
    final String statsSheetRef = _escapeSheetName(statsSheetName);

    // Panel de KPIs principales - FÓRMULAS CORREGIDAS
    final List<Map<String, String>> kpis = [
      {
        'title': 'Consumo Total del Período',
        'formula': '=SUM($statsSheetRef!B${startRow + 1}:B${startRow + columnNames.length - 1})',
        'format': '#,##0.00 "L/kg"'
      },
      {
        'title': 'Consumo Promedio Diario',
        'formula': '=AVERAGE($statsSheetRef!C${startRow + 1}:C${startRow + columnNames.length - 1})',
        'format': '#,##0.00 "L/kg/día"'
      },
      {
        'title': 'Máximo Consumo Registrado',
        'formula': '=MAX($statsSheetRef!F${startRow + 1}:F${startRow + columnNames.length - 1})',
        'format': '#,##0.00 "L/kg"'
      },
      {
        'title': 'Variabilidad Promedio',
        'formula': '=AVERAGE($statsSheetRef!K${startRow + 1}:K${startRow + columnNames.length - 1})',
        'format': '0.00 "%"'
      },
    ];

    for (int i = 0; i < kpis.length; i++) {
      final int row = startRow + i;

      // Título del KPI
      final Range titleCell = sheet.getRangeByIndex(row, 1);
      titleCell.setText(kpis[i]['title']!);
      titleCell.cellStyle.bold = true;
      titleCell.cellStyle.fontSize = 11;

      // Valor del KPI
      final Range valueCell = sheet.getRangeByIndex(row, 2);
      valueCell.setFormula(kpis[i]['formula']!);
      valueCell.numberFormat = kpis[i]['format']!;
      valueCell.cellStyle.fontSize = 12;
      valueCell.cellStyle.bold = true;

      // Color basado en el valor
      if (i == 2) { // Máximo consumo
        valueCell.cellStyle.fontColor = '#C00000';
      } else if (i == 3) { // Variabilidad
        valueCell.cellStyle.fontColor = '#FFC000';
      }

      // Fondo del KPI
      final Range kpiRange = sheet.getRangeByIndex(row, 1, row, 2);
      kpiRange.cellStyle.borders.all.lineStyle = LineStyle.thin;
      kpiRange.cellStyle.borders.all.color = '#D9D9D9';
      kpiRange.cellStyle.backColor = i % 2 == 0 ? '#F5F7FA' : '#FFFFFF';
    }

    // Análisis de tendencia
    final int trendStartRow = startRow + kpis.length + 2;
    _addTrendAnalysis(sheet, columnNames, dataStartRow, dataCount, trendStartRow);

    // Recomendaciones basadas en datos
    final int recoStartRow = trendStartRow + 4;
    _addRecommendations(sheet, recoStartRow);

    // Resumen de alertas y anomalías
    final int alertsStartRow = recoStartRow + 8;
    _addAlertsSummary(sheet, alertsStartRow);

    // Ajustar anchos de columna
    sheet.getRangeByIndex(1, 1).columnWidth = 30;
    sheet.getRangeByIndex(1, 2).columnWidth = 20;
  }

// ================================
// HOJA DE GRÁFICOS - CON GRÁFICOS REALES (CORREGIDO)
// ================================
  static void _createChartsSheet(Worksheet sheet, List<String> columnNames,
      List<List<dynamic>> data, String title) {

    _addSheetHeader(sheet, 'GRÁFICOS Y VISUALIZACIONES', title, '');

    final int startRow = 5;

    // Crear datos para gráficos (resumen estadístico)
    _createChartData(sheet, columnNames, data);

    // Verificar si hay columnas numéricas para gráficos
    bool hasNumericColumns = false;
    for (int i = 1; i < columnNames.length; i++) {
      if (data.isNotEmpty && data[0][i] is num) {
        hasNumericColumns = true;
        break;
      }
    }

    if (hasNumericColumns) {
      // Gráfico de barras para consumo total
      _createBarChart(sheet, columnNames, startRow + 15, 1);

      // Gráfico de líneas para tendencias
      _createLineChart(sheet, columnNames, startRow + 35, 1);

      // Gráfico de pastel para distribución
      _createPieChart(sheet, columnNames, startRow + 15, 10);
    } else {
      final Range noDataCell = sheet.getRangeByIndex(startRow + 1, 1);
      noDataCell.setText('No hay datos numéricos suficientes para generar gráficos.');
      noDataCell.cellStyle.fontColor = '#FF0000';
      noDataCell.cellStyle.bold = true;
      sheet.getRangeByIndex(startRow + 1, 1, startRow + 1, 5).merge();
    }
  }

  // ================================
  // HOJA DE METADATOS
  // ================================
  static void _createMetadataSheet(Worksheet sheet, List<String> columnNames,
      List<List<dynamic>> data, String title, String dateRange) {

    _addSheetHeader(sheet, 'METADATOS DEL REPORTE', title, dateRange);

    final int startRow = 5;
    int currentRow = startRow;

    final List<Map<String, String>> metadata = [
      {'label': 'Fecha de Generación', 'value': DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())},
      {'label': 'Sistema', 'value': 'Sistema de Gestión de Consumos'},
      {'label': 'Versión del Reporte', 'value': '1.0.0'},
      {'label': 'Total de Registros', 'value': data.length.toString()},
      {'label': 'Período Cubierto', 'value': dateRange},
      {'label': 'Métricas Incluidas', 'value': columnNames.where((c) => c != 'timestamp').length.toString()},
      {'label': 'Formato de Datos', 'value': 'Excel XLSX'},
      {'label': 'Codificación', 'value': 'UTF-8'},
    ];

    for (final meta in metadata) {
      final Range labelCell = sheet.getRangeByIndex(currentRow, 1);
      labelCell.setText(meta['label']!);
      labelCell.cellStyle.bold = true;
      labelCell.cellStyle.fontColor = '#1E4B7F';

      final Range valueCell = sheet.getRangeByIndex(currentRow, 2);
      valueCell.setText(meta['value']!);
      valueCell.cellStyle.borders.bottom.lineStyle = LineStyle.thin;
      valueCell.cellStyle.borders.bottom.color = '#D9D9D9';

      currentRow++;
    }

    // Información de las columnas
    currentRow += 2;
    final Range columnsTitle = sheet.getRangeByIndex(currentRow, 1);
    columnsTitle.setText('DESCRIPCIÓN DE COLUMNAS:');
    columnsTitle.cellStyle.bold = true;
    columnsTitle.cellStyle.fontColor = '#2E5984';

    for (final column in columnNames) {
      currentRow++;
      final Range colName = sheet.getRangeByIndex(currentRow, 1);
      colName.setText('• ${_formatColumnName(column)}');
      colName.cellStyle.indent = 1;

      final Range colDesc = sheet.getRangeByIndex(currentRow, 2);
      colDesc.setText(_getColumnDescription(column));
      colDesc.cellStyle.fontColor = '#666666';
      colDesc.cellStyle.fontSize = 10;
    }

    // Ajustar anchos
    sheet.getRangeByIndex(1, 1).columnWidth = 25;
    sheet.getRangeByIndex(1, 2).columnWidth = 40;
  }

  // ================================
  // MÉTODOS AUXILIARES PARA GRÁFICOS
  // ================================

  static void _createChartData(Worksheet sheet, List<String> columnNames, List<List<dynamic>> data) {
    // Crear tabla de resumen para gráficos
    final int dataStartRow = 5;

    // Encabezados
    sheet.getRangeByIndex(dataStartRow, 1).setText('Métrica');
    sheet.getRangeByIndex(dataStartRow, 2).setText('Consumo Total');
    sheet.getRangeByIndex(dataStartRow, 3).setText('Consumo Promedio');
    sheet.getRangeByIndex(dataStartRow, 4).setText('Máximo');
    sheet.getRangeByIndex(dataStartRow, 5).setText('Mínimo');

    // Formato encabezados
    for (int i = 1; i <= 5; i++) {
      final Range header = sheet.getRangeByIndex(dataStartRow, i);
      header.cellStyle.bold = true;
      header.cellStyle.backColor = '#4F81BD';
      header.cellStyle.fontColor = '#FFFFFF';
      header.cellStyle.hAlign = HAlignType.center;
    }

    // Datos para gráficos (usando fórmulas que apuntan a la hoja de análisis estadístico)
    final String statsSheetRef = _escapeSheetName(statsSheetName);

    for (int col = 1; col < columnNames.length; col++) {
      final int dataRow = dataStartRow + col;

      // Nombre de la métrica
      sheet.getRangeByIndex(dataRow, 1).setText(_formatColumnName(columnNames[col]));

      // Fórmulas que apuntan a la hoja de análisis estadístico
      sheet.getRangeByIndex(dataRow, 2).setFormula('=$statsSheetRef!B${dataStartRow + col}'); // Total
      sheet.getRangeByIndex(dataRow, 3).setFormula('=$statsSheetRef!C${dataStartRow + col}'); // Promedio
      sheet.getRangeByIndex(dataRow, 4).setFormula('=$statsSheetRef!F${dataStartRow + col}'); // Máximo
      sheet.getRangeByIndex(dataRow, 5).setFormula('=$statsSheetRef!E${dataStartRow + col}'); // Mínimo

      // Formato
      for (int i = 2; i <= 5; i++) {
        sheet.getRangeByIndex(dataRow, i).numberFormat = '#,##0.00';
      }
    }

    // Ajustar anchos
    for (int i = 1; i <= 5; i++) {
      sheet.getRangeByIndex(1, i).columnWidth = 15;
    }
  }

// ================================
// MÉTODOS CORREGIDOS PARA CREAR GRÁFICOS
// ================================

  static void _createBarChart(Worksheet sheet, List<String> columnNames, int startRow, int startCol) {
    try {
      final ChartCollection charts = ChartCollection(sheet);
      final Chart chart = charts.add();

      // Configurar el tipo de gráfico
      chart.chartType = ExcelChartType.columnClustered3D;
      chart.isSeriesInRows = false;

      // Definir el rango de datos (excluyendo la primera columna que puede ser timestamp)
      int dataStartRow = 6; // Fila donde empiezan los datos (después del encabezado)
      int dataEndRow = 5 + (columnNames.length - 1); // Última fila de datos

      // Usar columnas A (nombres) y B (valores)
      chart.dataRange = sheet.getRangeByIndex(dataStartRow, 1, dataEndRow, 2);

      // Configurar el gráfico
      chart.chartTitle = 'Consumo Total por Métrica';
      chart.hasLegend = true;
      chart.legend?.position = ExcelLegendPosition.bottom;

      // Posicionar el gráfico
      chart.topRow = startRow;
      chart.leftColumn = startCol;
      chart.bottomRow = startRow + 15;
      chart.rightColumn = startCol + 8;

      sheet.charts = charts;
    } catch (e) {
      print('Error al crear gráfico de barras: $e');
    }
  }

  static void _createLineChart(Worksheet sheet, List<String> columnNames, int startRow, int startCol) {
    try {
      final ChartCollection charts = ChartCollection(sheet);
      final Chart chart = charts.add();

      chart.chartType = ExcelChartType.line;
      chart.isSeriesInRows = false;

      int dataStartRow = 6;
      int dataEndRow = 5 + (columnNames.length - 1);

      // Usar columnas A (nombres), B (total) y C (promedio)
      chart.dataRange = sheet.getRangeByIndex(dataStartRow, 1, dataEndRow, 3);

      chart.chartTitle = 'Tendencias de Consumo';
      chart.hasLegend = true;
      chart.legend?.position = ExcelLegendPosition.bottom;

      chart.topRow = startRow;
      chart.leftColumn = startCol;
      chart.bottomRow = startRow + 15;
      chart.rightColumn = startCol + 8;

      sheet.charts = charts;
    } catch (e) {
      print('Error al crear gráfico de líneas: $e');
    }
  }

  static void _createPieChart(Worksheet sheet, List<String> columnNames, int startRow, int startCol) {
    try {
      final ChartCollection charts = ChartCollection(sheet);
      final Chart chart = charts.add();

      chart.chartType = ExcelChartType.pie;
      chart.isSeriesInRows = false;

      int dataStartRow = 6;
      int dataEndRow = 5 + (columnNames.length - 1);

      // Usar columnas A (nombres) y B (valores) para el gráfico de pastel
      chart.dataRange = sheet.getRangeByIndex(dataStartRow, 1, dataEndRow, 2);

      chart.chartTitle = 'Distribución de Consumo';
      chart.hasLegend = true;
      chart.legend?.position = ExcelLegendPosition.right;

      chart.topRow = startRow;
      chart.leftColumn = startCol;
      chart.bottomRow = startRow + 15;
      chart.rightColumn = startCol + 8;

      sheet.charts = charts;
    } catch (e) {
      print('Error al crear gráfico de pastel: $e');
    }
  }

  // ================================
  // MÉTODOS AUXILIARES
  // ================================

  static void _addReportHeader(Worksheet sheet, String title, String dateRange) {
    final Range titleCell = sheet.getRangeByName('A1');
    titleCell.setText(title);
    titleCell.cellStyle.fontSize = 18;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = '#1E4B7F';
    titleCell.cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A1:${_getColumnLetter(5)}1').merge();

    final Range subtitleCell = sheet.getRangeByName('A2');
    subtitleCell.setText('Período de Análisis: $dateRange');
    subtitleCell.cellStyle.fontSize = 12;
    subtitleCell.cellStyle.fontColor = '#666666';
    subtitleCell.cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A2:${_getColumnLetter(5)}2').merge();

    final Range dateCell = sheet.getRangeByName('A3');
    dateCell.setText('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    dateCell.cellStyle.fontSize = 10;
    dateCell.cellStyle.fontColor = '#999999';
    dateCell.cellStyle.hAlign = HAlignType.center;
    sheet.getRangeByName('A3:${_getColumnLetter(5)}3').merge();
  }

  static void _addSheetHeader(Worksheet sheet, String sheetTitle, String mainTitle, String dateRange) {
    final Range titleCell = sheet.getRangeByName('A1');
    titleCell.setText(sheetTitle);
    titleCell.cellStyle.fontSize = 16;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = '#1E4B7F';
    sheet.getRangeByName('A1:E1').merge();

    final Range subtitleCell = sheet.getRangeByName('A2');
    subtitleCell.setText('Reporte: $mainTitle | Período: $dateRange');
    subtitleCell.cellStyle.fontSize = 11;
    subtitleCell.cellStyle.fontColor = '#666666';
    sheet.getRangeByName('A2:E2').merge();
  }

  static void _addDistributionAnalysis(Worksheet sheet, List<String> columnNames,
      int dataStartRow, int dataCount, int startRow) {

    final Range titleCell = sheet.getRangeByIndex(startRow, 1);
    titleCell.setText('ANÁLISIS DE DISTRIBUCIÓN');
    titleCell.cellStyle.fontSize = 12;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = '#1E4B7F';
    sheet.getRangeByIndex(startRow, 1, startRow, 3).merge();

    final List<String> distHeaders = ['Métrica', 'Distribución', 'Evaluación'];

    for (int i = 0; i < distHeaders.length; i++) {
      final Range headerCell = sheet.getRangeByIndex(startRow + 1, i + 1);
      headerCell.setText(distHeaders[i]);
      headerCell.cellStyle.bold = true;
      headerCell.cellStyle.backColor = '#E7E6E6';
    }

    final String dataSheetRef = _escapeSheetName(dataSheetName);

    for (int col = 1; col < columnNames.length; col++) {
      final int row = startRow + 2 + (col - 1);
      final String colLetter = _getColumnLetter(col + 1);
      final String dataRange = '$dataSheetRef!$colLetter${dataStartRow + 1}:$colLetter${dataStartRow + dataCount}';

      sheet.getRangeByIndex(row, 1).setText(_formatColumnName(columnNames[col]));

      // Análisis de distribución
      final Range distCell = sheet.getRangeByIndex(row, 2);
      distCell.setFormula('=IF(SKEW($dataRange)>1,"Positiva",IF(SKEW($dataRange)<-1,"Negativa","Normal"))');

      // Evaluación
      final Range evalCell = sheet.getRangeByIndex(row, 3);
      evalCell.setFormula('=IF(STDEV.S($dataRange)/AVERAGE($dataRange)>0.3,"Alta Variabilidad","Estable")');
    }
  }

  static void _addTrendAnalysis(Worksheet sheet, List<String> columnNames,
      int dataStartRow, int dataCount, int startRow) {

    final Range titleCell = sheet.getRangeByIndex(startRow, 1);
    titleCell.setText('ANÁLISIS DE TENDENCIA');
    titleCell.cellStyle.fontSize = 12;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = '#1E4B7F';
    sheet.getRangeByIndex(startRow, 1, startRow, 3).merge();

    final Range trendInfo = sheet.getRangeByIndex(startRow + 1, 1);
    trendInfo.setText('El análisis de tendencia muestra la dirección general de los datos en el tiempo. Use la hoja de Gráficos para visualizaciones detalladas.');
    trendInfo.cellStyle.fontSize = 10;
    trendInfo.cellStyle.fontColor = '#666666';
    sheet.getRangeByIndex(startRow + 1, 1, startRow + 1, 3).merge();
  }

  static void _addRecommendations(Worksheet sheet, int startRow) {
    final Range titleCell = sheet.getRangeByIndex(startRow, 1);
    titleCell.setText('RECOMENDACIONES BASADAS EN DATOS');
    titleCell.cellStyle.fontSize = 12;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = '#00B050';
    sheet.getRangeByIndex(startRow, 1, startRow, 3).merge();

    final List<String> recommendations = [
      '• Monitorear consumo máximo para evitar picos',
      '• Optimizar recursos con mayor variabilidad',
      '• Establecer alertas para valores atípicos',
      '• Revisar periodicidad de mantenimiento',
      '• Implementar controles de eficiencia',
      '• Analizar correlaciones entre métricas',
      '• Establecer metas de reducción de consumo',
      '• Capacitar al personal en uso eficiente'
    ];

    for (int i = 0; i < recommendations.length; i++) {
      final Range recCell = sheet.getRangeByIndex(startRow + 1 + i, 1);
      recCell.setText(recommendations[i]);
      recCell.cellStyle.fontSize = 10;
      sheet.getRangeByIndex(startRow + 1 + i, 1, startRow + 1 + i, 3).merge();
    }
  }

  static void _addAlertsSummary(Worksheet sheet, int startRow) {
    final Range titleCell = sheet.getRangeByIndex(startRow, 1);
    titleCell.setText('ALERTAS Y ANOMALÍAS DETECTADAS');
    titleCell.cellStyle.fontSize = 12;
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontColor = '#FF0000';
    sheet.getRangeByIndex(startRow, 1, startRow, 3).merge();

    final Range alertInfo = sheet.getRangeByIndex(startRow + 1, 1);
    alertInfo.setText('Se revisaron los datos en busca de valores atípicos y patrones anómalos. Revise los gráficos en la pestaña correspondiente para más detalles.');
    alertInfo.cellStyle.fontSize = 10;
    alertInfo.cellStyle.fontColor = '#666666';
    sheet.getRangeByIndex(startRow + 1, 1, startRow + 1, 3).merge();
  }

  // Método para escapar nombres de hojas con espacios
  static String _escapeSheetName(String sheetName) {
    if (sheetName.contains(' ')) {
      return "'$sheetName'";
    }
    return sheetName;
  }

  static String _getColumnLetter(int columnIndex) {
    String columnLetter = '';
    while (columnIndex > 0) {
      int remainder = columnIndex % 26;
      if (remainder == 0) {
        remainder = 26;
        columnIndex = (columnIndex ~/ 26) - 1;
      } else {
        columnIndex = columnIndex ~/ 26;
      }
      columnLetter = String.fromCharCode(64 + remainder) + columnLetter;
    }
    return columnLetter;
  }

  static String _formatColumnName(String columnName) {
    switch (columnName) {
      case 'timestamp':
        return 'FECHA Y HORA';
      case 'Agua':
        return 'AGUA (L)';
      case 'Diesel':
        return 'DIESEL (L)';
      case 'gLP':
        return 'GLP (kg)';
      case 'AguaR':
        return 'AGUA RECIRCULADA (L)';
      default:
        return columnName.toUpperCase();
    }
  }

  static String _getColumnDescription(String columnName) {
    switch (columnName) {
      case 'timestamp':
        return 'Fecha y hora exacta del registro';
      case 'Agua':
        return 'Consumo de agua en litros (L)';
      case 'Diesel':
        return 'Consumo de diesel en litros (L)';
      case 'gLP':
        return 'Consumo de Gas Licuado de Petróleo en kilogramos (kg)';
      case 'AguaR':
        return 'Consumo de agua recirculada en litros (L)';
      default:
        return 'Columna de datos';
    }
  }
}
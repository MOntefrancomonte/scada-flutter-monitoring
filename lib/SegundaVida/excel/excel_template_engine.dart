import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:syncfusion_officechart/officechart.dart';

class ExcelTemplateEngine {
  static void applyPremiumTemplate(Workbook workbook, List<String> headers, int lastRow, int lastCol) {
    // 1. Reordenar: Crear Dashboard como la PRIMERA pestaña
    final Worksheet dataSheet = workbook.worksheets[0];
    dataSheet.name = "Datos_Detallados";

    final Worksheet dashboard = workbook.worksheets.addWithName("DASHBOARD EJECUTIVO");
    //dashboard.move(0); // Mueve el Dashboard a la posición 1 (índice 0)
    //workbook.worksheets[0].isGridLinesVisible = false; // Estética limpia

    // --- DISEÑO DE CABECERA ---
    _buildHeader(dashboard);

    // --- SECCIÓN DE KPIs Y ESTADÍSTICAS ---
    _buildKPISection(dashboard, dataSheet, headers, lastRow);

    // --- GRÁFICO DE TENDENCIA TEMPORAL ---
    _buildTimeTrendChart(dashboard, dataSheet, lastRow, lastCol);

    // Estilizar la hoja de datos
    _styleDataSheet(dataSheet, lastRow, lastCol);
  }

  static void _buildHeader(Worksheet sheet) {
    final Range titleRange = sheet.getRangeByName('B2:H2');
    titleRange.merge();
    titleRange.setText('ANÁLISIS ESTRATÉGICO DE CONSUMOS');
    titleRange.cellStyle.fontSize = 18;
    titleRange.cellStyle.bold = true;
    titleRange.cellStyle.fontColor = '#FFFFFF';
    titleRange.cellStyle.backColor = '#2C3E50';
    titleRange.cellStyle.hAlign = HAlignType.center;
    titleRange.cellStyle.vAlign = VAlignType.center;

    sheet.getRangeByName('B3').setText('Periodo de Análisis: ${DateTime.now().toString().substring(0,16)}');
    sheet.getRangeByName('B3').cellStyle.italic = true;
  }

  static void _buildKPISection(Worksheet dashboard, Worksheet dataSheet, List<String> headers, int lastRow) {
    int startCol = 2; // Columna B
    int kpiRow = 5;

    // Encabezados de la tabla de indicadores
    final List<String> kpiTitles = ['INDICADOR', 'TOTAL', 'PROMEDIO', 'MÁXIMO', 'MÍNIMO', 'VARIABILIDAD'];
    for (int i = 0; i < kpiTitles.length; i++) {
      final Range r = dashboard.getRangeByIndex(kpiRow, startCol + i);
      r.setText(kpiTitles[i]);
      r.cellStyle.bold = true;
      r.cellStyle.backColor = '#D5D8DC';
    }

    int currentRow = kpiRow + 1;
    for (int i = 0; i < headers.length; i++) {
      String h = headers[i].toLowerCase();
      if (h.contains('agua') || h.contains('glp') || h.contains('diesel')) {
        String colLetter = _getColumnLetter(i + 1);
        String dataRange = "'Datos_Detallados'!\$$colLetter\$2:\$$colLetter\$$lastRow";

        // Nombre del indicador
        dashboard.getRangeByIndex(currentRow, startCol).setText(headers[i].toUpperCase());

        // Fórmulas Estadísticas
        dashboard.getRangeByIndex(currentRow, startCol + 1).setFormula("=SUM($dataRange)");
        dashboard.getRangeByIndex(currentRow, startCol + 2).setFormula("=AVERAGE($dataRange)");
        dashboard.getRangeByIndex(currentRow, startCol + 3).setFormula("=MAX($dataRange)");
        dashboard.getRangeByIndex(currentRow, startCol + 4).setFormula("=MIN($dataRange)");

        // Variabilidad (Desviación Estándar / Dispersión)
        dashboard.getRangeByIndex(currentRow, startCol + 5).setFormula("=STDEV($dataRange)");

        // Formato numérico
        dashboard.getRangeByIndex(currentRow, startCol + 1, currentRow, startCol + 5).numberFormat = '#,##0.00';
        currentRow++;
      }
    }
  }

  static void _buildTimeTrendChart(Worksheet dashboard, Worksheet dataSheet, int lastRow, int lastCol) {
    if (lastRow < 3) return;

    final ChartCollection charts = ChartCollection(dashboard);
    final Chart chart = charts.add();

    // CAMBIO: Gráfico de Líneas para ver el tiempo
    chart.chartType = ExcelChartType.lineMarkers;

    // Suponiendo que la Columna 1 es Fecha/Tiempo y la Columna 2 es el Consumo principal
    chart.dataRange = dataSheet.getRangeByIndex(1, 1, lastRow, 2);
    chart.isSeriesInRows = false;

    // Estética del gráfico
    chart.chartTitle = "Evolución de Consumo y Detección de Picos";
    chart.chartTitleArea.bold = true;
    chart.chartTitleArea.size = 12;

    // Posición
    chart.topRow = 12;
    chart.bottomRow = 30;
    chart.leftColumn = 2;
    chart.rightColumn = 10;

    dashboard.charts = charts;
  }

  static void _styleDataSheet(Worksheet sheet, int lastRow, int lastCol) {
    final Range allData = sheet.getRangeByIndex(1, 1, lastRow, lastCol);
    allData.cellStyle.fontSize = 9;

    final Range header = sheet.getRangeByIndex(1, 1, 1, lastCol);
    header.cellStyle.backColor = '#34495E';
    header.cellStyle.fontColor = '#FFFFFF';

    sheet.getRangeByIndex(1, 1, lastRow, lastCol).autoFitColumns();
  }

  static String _getColumnLetter(int index) {
    return String.fromCharCode(64 + index);
  }
}
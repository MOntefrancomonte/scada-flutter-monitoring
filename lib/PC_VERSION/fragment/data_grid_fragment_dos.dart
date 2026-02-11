// fragments/data_grid_fragment.dart
import 'package:flutter/material.dart';
import 'package:proyectoscada/PC_VERSION/fragment/excel_pc.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';

// Esta clase es útil en Web para permitir arrastrar con mouse
class DesktopScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.mouse,
    PointerDeviceKind.touch,
    PointerDeviceKind.trackpad,
  };
}

class SensorRecord {
  SensorRecord({this.timestamp, this.agua, this.diesel, this.glp, this.aguaR});
  final int? timestamp;
  final num? agua;
  final num? diesel;
  final num? glp;
  final num? aguaR;
}

class SensorDataSource extends DataGridSource {
  SensorDataSource({
    required List<SensorRecord> records,
    required List<String> visibleColumns,
  }) {
    _visibleColumns = visibleColumns;
    records.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));

    _records = records.map<DataGridRow>((r) {
      return DataGridRow(cells: _visibleColumns.map((col) {
        if (col == 'timestamp') {
          final dt = r.timestamp != null ? DateTime.fromMillisecondsSinceEpoch(r.timestamp! * 1000) : null;
          return DataGridCell<DateTime?>(columnName: 'timestamp', value: dt);
        }
        num? val;
        if (col == 'Agua') val = r.agua;
        else if (col == 'Diesel') val = r.diesel;
        else if (col == 'gLP') val = r.glp;
        else if (col == 'AguaR') val = r.aguaR;

        return DataGridCell<num?>(columnName: col, value: val);
      }).toList());
    }).toList();
  }

  late List<String> _visibleColumns;
  late List<DataGridRow> _records;

  @override
  List<DataGridRow> get rows => _records;

  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        final bool isTimestamp = cell.columnName == 'timestamp';

        return Container(
          alignment: isTimestamp ? Alignment.center : Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: isTimestamp
              ? FittedBox(
            fit: BoxFit.scaleDown,
            child: _buildTimestampCell(cell.value as DateTime?),
          )
              : _buildValueCell(cell.value as num?),
        );
      }).toList(),
    );
  }

  Widget _buildTimestampCell(DateTime? dt) {
    if (dt == null) return const Text('--', style: TextStyle(fontSize: 12));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          DateFormat('dd/MM/yyyy').format(dt),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          DateFormat('HH:mm:ss').format(dt),
          style: TextStyle(fontSize: 10, color: Colors.blueGrey[400]),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildValueCell(num? val) {
    if (val == null) return const Text('--', style: TextStyle(fontSize: 14, color: Colors.grey));
    return Text(
      val.toStringAsFixed(1),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class DataGridFragment extends StatefulWidget {
  final List posts;
  final String? selectedSeries;
  final int? startTs;
  final int? endTs;

  const DataGridFragment({
    super.key,
    required this.posts,
    this.selectedSeries,
    this.startTs,
    this.endTs,
  });

  @override
  State<DataGridFragment> createState() => _DataGridFragmentState();
}

class _DataGridFragmentState extends State<DataGridFragment> {
  late final ExcelPackage excel;
  late SensorDataSource _sensorDataSource;
  late List<String> _visibleColumns;
  final GlobalKey<SfDataGridState> _key = GlobalKey<SfDataGridState>();
  bool _debugMode = false;

  @override
  void initState() {
    super.initState();
    _buildDatasource();
    excel = ExcelPackage();
  }

  @override
  void didUpdateWidget(covariant DataGridFragment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.posts != widget.posts ||
        oldWidget.selectedSeries != widget.selectedSeries ||
        oldWidget.startTs != widget.startTs ||
        oldWidget.endTs != widget.endTs) {
      _buildDatasource();
    }
  }

  void _buildDatasource() {
    final allMetricCols = ['Agua', 'Diesel', 'gLP', 'AguaR'];
    if (widget.selectedSeries == null || widget.selectedSeries == 'Todos') {
      _visibleColumns = ['timestamp', ...allMetricCols];
    } else {
      if (allMetricCols.contains(widget.selectedSeries)) {
        _visibleColumns = ['timestamp', widget.selectedSeries!];
      } else {
        _visibleColumns = ['timestamp', ...allMetricCols];
      }
    }

    final records = _buildRecordsFromPosts(widget.posts, widget.startTs, widget.endTs);

    // Debug
    if (_debugMode && records.isNotEmpty) {
      print('=== DEBUG DATAGRID (WEB) ===');
      print('Total registros: ${records.length}');
    }

    _sensorDataSource = SensorDataSource(records: records, visibleColumns: _visibleColumns);
    if (mounted) setState(() {});
  }

  List<SensorRecord> _buildRecordsFromPosts(List posts, int? startTs, int? endTs) {
    // ... [MISMOS MÉTODOS DE EXTRACCIÓN QUE EN TU CÓDIGO ORIGINAL] ...
    // He omitido el código repetitivo aquí para brevedad, pero debes mantener
    // tu lógica de _buildRecordsFromPosts y _safeExtractNumber tal cual estaba.
    // Solo me aseguro de pegar la parte crítica:
    final List<SensorRecord> out = [];

    for (var p in posts) {
      int? ts;
      if (p['timestamp'] != null) {
        if (p['timestamp'] is int) ts = p['timestamp'];
        else if (p['timestamp'] is String) try { ts = int.parse(p['timestamp'].toString()); } catch (_) { ts = null; }
        else if (p['timestamp'] is double) ts = (p['timestamp'] as double).round();
      }

      if (ts != null) {
        if (startTs != null && ts < startTs) continue;
        if (endTs != null && ts > endTs) continue;
      }

      num? agua = _safeExtractNumber(p, 'Agua');
      num? diesel = _safeExtractNumber(p, 'Diesel');
      num? glp = _safeExtractNumber(p, 'gLP');
      num? aguaR = _safeExtractNumber(p, 'AguaR');

      // Fallback
      if (agua == null) agua = _safeExtractNumber(p, 'agua');
      if (diesel == null) diesel = _safeExtractNumber(p, 'diesel');
      if (glp == null) glp = _safeExtractNumber(p, 'glp');
      if (aguaR == null) aguaR = _safeExtractNumber(p, 'aguaR');

      out.add(SensorRecord(timestamp: ts, agua: agua, diesel: diesel, glp: glp, aguaR: aguaR));
    }
    return out;
  }

  num? _safeExtractNumber(Map<String, dynamic> map, String key) {
    try {
      if (map.containsKey(key)) {
        final value = map[key];
        if (value == null) return null;
        if (value is num) return value;
        if (value is String) return num.tryParse(value);
        if (value is int) return value.toDouble();
        if (value is double) return value;
      }
    } catch (e) {
      print('Error extrayendo $key: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No hay datos', style: theme.textTheme.titleMedium),
            // ... [Resto de tu UI de estado vacío]
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ... [TU CÓDIGO DE HEADER IGUAL] ...
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Registros de Consumo (${_sensorDataSource.rows.length} filas)", style: theme.textTheme.titleMedium),
            ],
          ),
        ),

        Expanded(
          child: ScrollConfiguration(
            behavior: DesktopScrollBehavior(), // Esto ayuda al touch scroll en web
            child: SfDataGridTheme(
              data: SfDataGridThemeData(
                headerColor: theme.colorScheme.surfaceVariant.withOpacity(0.7),
                gridLineColor: theme.dividerColor.withOpacity(0.2),
              ),
              child: SfDataGrid(
                key: _key,
                source: _sensorDataSource,
                columnWidthMode: ColumnWidthMode.fill,
                rowHeight: 50.0,
                headerRowHeight: 45.0,
                allowSorting: true,
                // IMPORTANTE: El filtrado puede requerir lógica extra en web para mostrar el menú popup correctamente,
                // pero generalmente funciona bien.
                allowFiltering: true,
                gridLinesVisibility: GridLinesVisibility.horizontal,
                columns: _visibleColumns.map((col) {
                  return GridColumn(
                    columnName: col,
                    width: col == 'timestamp' ? 160.0 : double.nan,
                    label: Container(
                      alignment: col == 'timestamp' ? Alignment.center : Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        _getColumnDisplayName(col),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Footer con botón de exportar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // Simplificado
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Generando Excel...'),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    );

                    await excel.createExcelDelPanelWindows(_key);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Descarga iniciada'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.download_rounded,
                  size: 20, // 🔑 evita que el icono aplaste el texto
                ),
                label: const Text(
                  'Descargar Excel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44), // 🔑 altura suficiente para el texto
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }

  String _getColumnDisplayName(String columnName) {
    // ... [TU SWITCH CASE ORIGINAL] ...
    switch (columnName) {
      case 'timestamp': return 'FECHA/HORA';
      case 'Agua': return 'AGUA (L)';
      case 'Diesel': return 'DIESEL (L)';
      case 'gLP': return 'GLP (kg)';
      case 'AguaR': return 'AGUA RECIRCULADA (L)';
      default: return columnName.toUpperCase();
    }
  }
}
//como parte de la nueva actualizacion
// fragments/data_grid_fragment.dart
import 'package:flutter/material.dart';
import 'package:proyectoscada/SegundaVida/excel/excel.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:intl/intl.dart'; // Recomendado para manejo de fechas y números

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

    // Ordenamiento inicial
    records.sort((a, b) => (a.timestamp ?? 0).compareTo(b.timestamp ?? 0));

    _records = records.map<DataGridRow>((r) {
      return DataGridRow(cells: _visibleColumns.map((col) {
        if (col == 'timestamp') {
          final dt = r.timestamp != null ? DateTime.fromMillisecondsSinceEpoch(r.timestamp! * 1000) : null;
          return DataGridCell<DateTime?>(columnName: 'timestamp', value: dt);
        }
        // Mapeo dinámico de métricas
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
          padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reducir padding lateral
          child: isTimestamp
              ? FittedBox( // <--- ESTO EVITA EL OVERFLOW encogiendo el texto levemente si es necesario
              fit: BoxFit.scaleDown,
              child: _buildTimestampCell(cell.value as DateTime?)
          )
              : _buildValueCell(cell.value as num?),
        );
      }).toList(),
    );
  }

  Widget _buildTimestampCell(DateTime? dt) {
    if (dt == null) return const Text('--');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(DateFormat('dd/MM/yyyy').format(dt),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(DateFormat('HH:mm:ss').format(dt),
            style: TextStyle(fontSize: 11, color: Colors.blueGrey[400])),
      ],
    );
  }

  Widget _buildValueCell(num? val) {
    return Text(
      val?.toStringAsFixed(1) ?? '--',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.5),
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
  late SensorDataSource _sensorDataSource;
  late List<String> _visibleColumns;
  final GlobalKey<SfDataGridState> _key = GlobalKey<SfDataGridState>();

  @override
  void initState() {
    super.initState();
    _buildDatasource();
  }
  @override
  void didUpdateWidget(covariant DataGridFragment oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Verificamos si alguno de los parámetros cambió
    if (oldWidget.posts != widget.posts ||
        oldWidget.selectedSeries != widget.selectedSeries ||
        oldWidget.startTs != widget.startTs ||
        oldWidget.endTs != widget.endTs) {

      // Forzamos la reconstrucción del DataSource con los nuevos datos
      _buildDatasource();
    }
  }
  // ... (Mantenemos tu lógica de _buildDatasource y _buildRecordsFromPosts que es funcional) ...

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
    _sensorDataSource = SensorDataSource(records: records, visibleColumns: _visibleColumns);
    if (mounted) setState(() {});
  }

  List<SensorRecord> _buildRecordsFromPosts(List posts, int? startTs, int? endTs) {
    final List<SensorRecord> out = [];
    for (var p in posts) {
      int? ts;
      try {
        ts = p.timestamp is int ? p.timestamp : int.parse(p.timestamp.toString());
      } catch (_) { ts = null; }

      if (ts != null) {
        if (startTs != null && ts < startTs) continue;
        if (endTs != null && ts > endTs) continue;
      }

      num? agua, diesel, glp, aguaR;
      try { agua = (p.Agua ?? p.agua) as num?; } catch (_) {}
      try { diesel = (p.Diesel ?? p.diesel) as num?; } catch (_) {}
      try { glp = (p.gLP ?? p.glp) as num?; } catch (_) {}
      try { aguaR = (p.AguaR ?? p.aguaR) as num?; } catch (_) {}

      out.add(SensorRecord(timestamp: ts, agua: agua, diesel: diesel, glp: glp, aguaR: aguaR));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: SfDataGridTheme(
            data: SfDataGridThemeData(
              headerColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              gridLineColor: theme.dividerColor.withOpacity(0.1),
              selectionColor: theme.colorScheme.primary.withOpacity(0.1),
              headerHoverColor: theme.colorScheme.primary.withOpacity(0.05),
            ),
            child: SfDataGrid(
              horizontalScrollPhysics: const NeverScrollableScrollPhysics(),
              key: _key,
              source: _sensorDataSource,
              columnWidthMode: ColumnWidthMode.fill,
              rowHeight: 65.0,
              headerRowHeight: 50.0,
              allowSorting: true,
              gridLinesVisibility: GridLinesVisibility.horizontal,
              headerGridLinesVisibility: GridLinesVisibility.none,
              columns: _visibleColumns.map((col) {
                return GridColumn(
                  columnName: col,
                  label: Container(
                    alignment: col == 'timestamp' ? Alignment.center : Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      col == 'timestamp' ? 'FECHA' : col.toUpperCase(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.2
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // Footer estilizado como barra de acciones
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.2))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Registros: ${_sensorDataSource.rows.length}",
                  style: theme.textTheme.bodySmall),
              ElevatedButton.icon(
                onPressed: () async { await excel_package().createExcelDelPanel(_key); /* tu lógica de excel */
                print("Exportando...");
                  },
                icon: const Icon(Icons.file_download_outlined, size: 20),
                label: const Text("EXPORTAR EXCEL"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

            ],
          ),
        ),
      ],
    );
  }
}
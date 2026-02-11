//añadido como parte de la nueva actualizacion
// widgets/sensor_data_source.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../models/MiPrimerModeloDeDatos.dart';

class SensorDataSource extends DataGridSource {
  List<DataGridRow> _sensorData = [];

  SensorDataSource({required List<MiPrimerModeloDeDatos> sensorList}) {
    _sensorData = sensorList.map<DataGridRow>((e) => DataGridRow(cells: [
      DataGridCell<String>(columnName: 'id', value: e.id),
      DataGridCell<int>(columnName: 'Agua', value: e.Agua),
      DataGridCell<int>(columnName: 'Diesel', value: e.Diesel),
      DataGridCell<int>(columnName: 'AguaR', value: e.AguaR),
      DataGridCell<int>(columnName: 'gLP', value: e.gLP),
    ])).toList();
  }

  @override
  List<DataGridRow> get rows => _sensorData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8.0),
          child: Text(e.value.toString()),
        );
      }).toList(),
    );
  }
}
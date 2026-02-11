import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class ChartFragment extends StatefulWidget {
  final List<dynamic> data;
  final String? selectedMeter;
  final bool showMultipleSeries;

  const ChartFragment({
    super.key,
    required this.data,
    this.selectedMeter,
    this.showMultipleSeries = true,
  });

  @override
  State<ChartFragment> createState() => _ChartFragmentState();
}

class _ChartFragmentState extends State<ChartFragment> {
  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableSelectionZooming: true,
      selectionRectBorderColor: Colors.red,
      selectionRectBorderWidth: 1,
      selectionRectColor: Colors.black54,
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.visible,
      ),
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      lineColor: Colors.grey,
      lineWidth: 1,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Colors.black87,
        textStyle: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        borderColor: Colors.transparent,
        borderWidth: 0,
      )
      ,
    );
  }

  List<ChartData> _prepareChartData() {
    if (widget.data.isEmpty) return [];

    return widget.data.map<ChartData>((item) {
      final timestamp = item['timestamp'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

      return ChartData(
        date: date,
        agua: (item['Agua'] ?? 0).toDouble(),
        diesel: (item['Diesel'] ?? 0).toDouble(),
        glp: (item['gLP'] ?? 0).toDouble(),
        aguaR: (item['AguaR'] ?? 0).toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartData = _prepareChartData();

    if (chartData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos para graficar',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 300,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado del gráfico
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Consumos ${widget.selectedMeter ?? 'Totales'}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_in),
                      onPressed: () {
                        _zoomPanBehavior.zoomIn();
                      },
                      tooltip: 'Zoom in',
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_out),
                      onPressed: () {
                        _zoomPanBehavior.zoomOut();
                      },
                      tooltip: 'Zoom out',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        _zoomPanBehavior.reset();
                      },
                      tooltip: 'Reset zoom',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Gráfico principal
          Expanded(
            child: SfCartesianChart(
              palette: [
                Colors.blue.shade700,
                Colors.brown.shade600,
                Colors.orange.shade700,
                Colors.lightBlueAccent.shade700,
              ],
              primaryXAxis: DateTimeAxis(
                title: AxisTitle(text: 'Fecha'),
                dateFormat: DateFormat('dd/MM HH:mm'),
                intervalType: DateTimeIntervalType.hours,
                majorGridLines: const MajorGridLines(width: 0),
                edgeLabelPlacement: EdgeLabelPlacement.shift,
              ),
              primaryYAxis: NumericAxis(
                title: AxisTitle(text: 'Consumo'),
                labelFormat: '{value}',
                majorGridLines: const MajorGridLines(width: 1),
              ),
              zoomPanBehavior: _zoomPanBehavior,
              trackballBehavior: _trackballBehavior,
              tooltipBehavior: TooltipBehavior(enable: true),
              legend: Legend(
                isVisible: widget.showMultipleSeries,
                position: LegendPosition.top,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              series: _buildSeries(chartData),
            ),
          ),
          // Leyenda y controles
          if (widget.showMultipleSeries) ...[
            const SizedBox(height: 16),
            _buildSeriesSelector(context),
          ],
        ],
      ),
    );
  }

  List<LineSeries<ChartData, DateTime>> _buildSeries(List<ChartData> chartData) {
    final series = <LineSeries<ChartData, DateTime>>[];

    if (widget.showMultipleSeries) {
      series.addAll([
        LineSeries<ChartData, DateTime>(
          name: 'Agua',
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.agua,
          markerSettings: const MarkerSettings(isVisible: true),
          enableTooltip: true,
        ),
        LineSeries<ChartData, DateTime>(
          name: 'Diesel',
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.diesel,
          markerSettings: const MarkerSettings(isVisible: true),
          enableTooltip: true,
        ),
        LineSeries<ChartData, DateTime>(
          name: 'GLP',
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.glp,
          markerSettings: const MarkerSettings(isVisible: true),
          enableTooltip: true,
        ),
        LineSeries<ChartData, DateTime>(
          name: 'AguaR',
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.aguaR,
          markerSettings: const MarkerSettings(isVisible: true),
          enableTooltip: true,
        ),
      ]);
    } else if (widget.selectedMeter != null) {
      final seriesName = widget.selectedMeter!;
      series.add(
        LineSeries<ChartData, DateTime>(
          name: seriesName,
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) {
            switch (seriesName) {
              case 'Agua': return data.agua;
              case 'Diesel': return data.diesel;
              case 'gLP': return data.glp;
              case 'AguaR': return data.aguaR;
              default: return data.agua;
            }
          },
          markerSettings: const MarkerSettings(isVisible: true),
          enableTooltip: true,
        ),
      );
    }

    return series;
  }

  Widget _buildSeriesSelector(BuildContext context) {
    final theme = Theme.of(context);
    //final seriesList = ['Agua', 'Diesel', 'gLP', 'AguaR'];
    final seriesList = [];
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: seriesList.map((series) {
        final isSelected = widget.selectedMeter == series;
        final color = _getColorForSeries(series);

        return ChoiceChip(
          label: Text(series),
          selected: isSelected,
          onSelected: (selected) {
            // Lógica para filtrar por serie individual
          },
          backgroundColor: color.withOpacity(0.1),
          selectedColor: color.withOpacity(0.3),
          labelStyle: TextStyle(
            color: isSelected ? color : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          avatar: CircleAvatar(
            backgroundColor: color,
            radius: 8,
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForSeries(String series) {
    switch (series) {
      case 'Agua': return Colors.blue.shade700;
      case 'Diesel': return Colors.brown.shade600;
      case 'gLP': return Colors.orange.shade700;
      case 'AguaR': return Colors.lightBlueAccent.shade700;
      default: return Colors.green.shade700;
    }
  }
}

class ChartData {
  final DateTime date;
  final double agua;
  final double diesel;
  final double glp;
  final double aguaR;

  ChartData({
    required this.date,
    required this.agua,
    required this.diesel,
    required this.glp,
    required this.aguaR,
  });
}
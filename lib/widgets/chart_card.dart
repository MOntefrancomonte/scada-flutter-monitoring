// lib/widgets/chart_card.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../models/sales_data.dart';

class ChartCard extends StatelessWidget {
  final List<SalesData> data;
  final double height;

  const ChartCard({required this.data, required this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Theme.of(context).colorScheme.inversePrimary.withOpacity(0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Gráfico: directamente muestra los datos
            SizedBox(
              height: height - 32, // Ajustar espacio según lo necesites
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                title: ChartTitle(text: 'Consumos totales'),
                legend: Legend(isVisible: true),
                series: <CartesianSeries<SalesData, String>>[
                  LineSeries<SalesData, String>(
                    dataSource: data,
                    xValueMapper: (SalesData s, _) => s.year,
                    yValueMapper: (SalesData s, _) => s.sales,
                    name: 'Ventas',
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    enableTooltip: true,
                  ),
                ],
              ),
            ),
            //Positioned(child: CustomDateRangePicker()),
          ],
        ),
      ),
    );
  }
}

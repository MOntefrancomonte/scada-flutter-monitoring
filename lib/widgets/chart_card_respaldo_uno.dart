// lib/widgets/chart_card.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import '../models/sales_data.dart';

class ChartCard extends StatefulWidget {
  final List<SalesData> data;
  final double height;

  const ChartCard({required this.data, required this.height, super.key});

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> with SingleTickerProviderStateMixin {
  late SfRangeValues _selectedRange;
  late TabController _tabController;

  // 0 = Todas, 1..4 = Semana 1..4
  int _selectedWeekTab = 0;

  @override
  void initState() {
    super.initState();
    // inicio mostrando todo el dataset
    _selectedRange = SfRangeValues(0.0, (widget.data.length - 1).toDouble());
    //_tabController = TabController(length: 5, vsync: this);
    //_tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) return; // respondemos solo cuando cambian explícitamente
    final idx = _tabController.index;
    setState(() {
      _selectedWeekTab = idx;
      if (_selectedWeekTab == 0) {
        // Todas: restaurar a la porción actual completa (no tocamos nada)
        // dejamos _selectedRange como está
      } else {
        // calcular subrango correspondiente a la semana seleccionada,
        // tomando como base la porción actualmente visible en _selectedRange
        final startIndex = _selectedRange.start.round().clamp(0, widget.data.length - 1);
        final endIndex = _selectedRange.end.round().clamp(0, widget.data.length - 1);
        final lenVisible = (endIndex - startIndex + 1).clamp(1, widget.data.length);
        // dividir en 4 partes (semana i = floor(i*len/4) .. floor((i+1)*len/4)-1)
        final w = _selectedWeekTab - 1; // 0..3
        final partStartOffset = (w * lenVisible / 4).floor();
        final partEndOffset = (((w + 1) * lenVisible / 4).floor()) - 1;
        int newStart = startIndex + partStartOffset;
        int newEnd = startIndex + partEndOffset;
        // Corrección para el caso de la última semana que puede quedar fuera por roundings
        if (w == 3) newEnd = endIndex;
        // Asegurar límites
        newStart = newStart.clamp(0, widget.data.length - 1);
        newEnd = newEnd.clamp(newStart, widget.data.length - 1);
        _selectedRange = SfRangeValues(newStart.toDouble(), newEnd.toDouble());
      }
    });
  }

  // Si el usuario mueve el selector manualmente, regresamos la pestaña a "Todas"
  void _onRangeChanged(SfRangeValues values) {
    setState(() {
      _selectedRange = SfRangeValues(values.start, values.end);
      if (_selectedWeekTab != 0) {
        _selectedWeekTab = 0;
        // forzamos que la TabBar muestre "Todas" (sin animación compleja)
        _tabController.animateTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int startIndex = _selectedRange.start.round().clamp(0, widget.data.length - 1);
    final int endIndex = _selectedRange.end.round().clamp(0, widget.data.length - 1);

    final visibleData = widget.data.sublist(startIndex, endIndex + 1);

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
            // TabBar superior para seleccionar semanas
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Todas'),
                  Tab(text: 'Semana 1'),
                  Tab(text: 'Semana 2'),
                  Tab(text: 'Semana 3'),
                  Tab(text: 'Semana 4'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // RangeSelector: min/max en índices (0 .. n-1)
            // Usamos key para forzar reconstrucción cuando cambian los valores programáticamente
            SfRangeSelector(
              key: ValueKey('${_selectedRange.start}-${_selectedRange.end}'),
              min: 0.0,
              max: (widget.data.length - 1).toDouble(),
              showTicks: true,
              showLabels: true,
              interval: 1,
              // inicializamos con el rango seleccionado en estado
              initialValues: _selectedRange,
              //showTooltip: true,
              onChanged: _onRangeChanged,
              child: SizedBox(
                height: widget.height - 120, // ajustar si quieres más/menos espacio
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  title: ChartTitle(text: 'Consumos totales'),
                  legend: Legend(isVisible: true),
                  series: <CartesianSeries<SalesData, String>>[
                    LineSeries<SalesData, String>(
                      dataSource: visibleData,
                      xValueMapper: (SalesData s, _) => s.year,
                      yValueMapper: (SalesData s, _) => s.sales,
                      name: 'Ventas',
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                      enableTooltip: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Gráfico: toma visibleData calculado arriba

          ],
        ),
      ),
    );
  }
}

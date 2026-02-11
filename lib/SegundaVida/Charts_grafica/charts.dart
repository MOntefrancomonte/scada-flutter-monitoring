// charts.dart - Versión corregida del algoritmo LTTB

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartFragment extends StatelessWidget {
  final List<dynamic> posts;
  final String? selectedSeries;
  final int? startTs;
  final int? endTs;

  static final _dataCache = <String, List<ChartData>>{};

  const ChartFragment({
    super.key,
    required this.posts,
    this.selectedSeries,
    this.startTs,
    this.endTs,
  });

  int? _toMilliseconds(dynamic ts) {
    if (ts == null) return null;
    try {
      final n = ts is int ? ts : int.parse(ts.toString());
      return n < 100000000000 ? n * 1000 : n;
    } catch (e) {
      debugPrint('Error parsing timestamp $ts: $e');
      return null;
    }
  }

  // ALGORITMO LTTB CORREGIDO - Versión robusta
  List<ChartData> _downsampleData(List<ChartData> data, int threshold) {
    if (data.length <= threshold || threshold <= 2) {
      return data;
    }

    final downsampled = List<ChartData>.filled(threshold, data[0]);
    int sampledIndex = 0;

    // Tamaño de cada bucket (excluyendo primer y último punto)
    final double bucketSize = (data.length - 2) / (threshold - 2).toDouble();

    // Agregar primer punto
    downsampled[sampledIndex++] = data[0];

    for (int i = 0; i < threshold - 2; i++) {
      // Rango del bucket actual
      final bucketStart = ((i + 0) * bucketSize + 1).floor();
      final bucketEnd = ((i + 1) * bucketSize + 1).floor();

      // Asegurar que los índices están dentro del rango
      final safeBucketStart = bucketStart.clamp(0, data.length - 1);
      final safeBucketEnd = bucketEnd.clamp(0, data.length - 1);

      if (safeBucketStart >= safeBucketEnd) {
        continue;
      }

      // Calcular punto promedio del siguiente bucket
      final nextBucketStart = ((i + 1) * bucketSize + 1).floor();
      final nextBucketEnd = ((i + 2) * bucketSize + 1).floor();

      final safeNextBucketStart = nextBucketStart.clamp(0, data.length - 1);
      final safeNextBucketEnd = nextBucketEnd.clamp(0, data.length - 1);

      if (safeNextBucketStart >= safeNextBucketEnd) {
        continue;
      }

      double nextAvgX = 0, nextAvgY = 0;
      int nextCount = 0;

      for (int j = safeNextBucketStart; j < safeNextBucketEnd && j < data.length; j++) {
        nextAvgX += data[j].x.millisecondsSinceEpoch.toDouble();
        nextAvgY += data[j].y.toDouble();
        nextCount++;
      }

      if (nextCount == 0) {
        continue;
      }

      nextAvgX /= nextCount;
      nextAvgY /= nextCount;

      // Encontrar punto en el bucket actual con mayor área del triángulo
      double maxArea = -1;
      ChartData? maxPoint;

      for (int j = safeBucketStart; j < safeBucketEnd && j < data.length; j++) {
        // Área del triángulo formado por:
        // - Punto anterior seleccionado (downsampled[sampledIndex-1])
        // - Punto actual (data[j])
        // - Punto promedio del siguiente bucket
        final area = _calculateTriangleArea(
            downsampled[sampledIndex - 1],
            data[j],
            ChartData(DateTime.fromMillisecondsSinceEpoch(nextAvgX.toInt()), nextAvgY)
        );

        if (area > maxArea) {
          maxArea = area;
          maxPoint = data[j];
        }
      }

      if (maxPoint != null) {
        downsampled[sampledIndex++] = maxPoint;
      }
    }

    // Agregar último punto
    if (sampledIndex < threshold) {
      downsampled[sampledIndex] = data[data.length - 1];
    }

    return downsampled.sublist(0, sampledIndex + 1);
  }

  double _calculateTriangleArea(ChartData a, ChartData b, ChartData c) {
    return ((a.x.millisecondsSinceEpoch - c.x.millisecondsSinceEpoch) *
        (b.y - a.y) -
        (a.x.millisecondsSinceEpoch - b.x.millisecondsSinceEpoch) *
            (c.y - a.y))
        .abs()
        .toDouble() /
        2.0;
  }

  // ALTERNATIVA SIMPLE - Downsampling uniforme (más seguro)
  List<ChartData> _simpleDownsample(List<ChartData> data, int threshold) {
    if (data.length <= threshold) return data;

    final step = (data.length / threshold).ceil();
    final result = <ChartData>[];

    for (int i = 0; i < data.length; i += step) {
      result.add(data[i]);
    }

    // Asegurar que tenemos el último punto
    if (result.last.x != data.last.x) {
      result.add(data.last);
    }

    return result;
  }

  int _calculateDynamicThreshold(List<ChartData> data, DateTime? minDate, DateTime? maxDate) {
    if (minDate == null || maxDate == null || data.isEmpty) return 2000;

    final duration = maxDate.difference(minDate);
    final totalPoints = data.length;

    // Limitar el número máximo de puntos para mejor rendimiento
    const int maxPoints = 5000;

    if (totalPoints <= maxPoints) return totalPoints;

    // Reducir según la duración
    if (duration.inDays > 365) return 500;
    if (duration.inDays > 30) return 1000;
    if (duration.inDays > 7) return 2000;
    if (duration.inDays > 1) return 3000;
    return maxPoints;
  }

  List<ChartData> _getCachedOrProcessData(String cacheKey, List<dynamic> posts, String type,
      DateTime? minDate, DateTime? maxDate) {
    final specificKey = '$cacheKey-$type';

    if (_dataCache.containsKey(specificKey)) {
      final cachedData = _dataCache[specificKey]!;
      final threshold = _calculateDynamicThreshold(cachedData, minDate, maxDate);

      // Usar downsampling simple para evitar errores
      return _simpleDownsample(cachedData, threshold);
    }

    final data = _processData(posts, type);
    _dataCache[specificKey] = data;

    // Limpiar cache
    if (_dataCache.length > 30) {
      _dataCache.remove(_dataCache.keys.first);
    }

    final threshold = _calculateDynamicThreshold(data, minDate, maxDate);
    return _simpleDownsample(data, threshold);
  }

  List<ChartData> _processData(List<dynamic> posts, String type) {
    final data = <ChartData>[];

    for (var p in posts) {
      final tsMs = _toMilliseconds(p.timestamp);
      if (tsMs == null) continue;

      final dt = DateTime.fromMillisecondsSinceEpoch(tsMs).toLocal();
      num val = 0;

      switch (type) {
        case 'Agua': val = (p.Agua ?? 0); break;
        case 'Diesel': val = (p.Diesel ?? 0); break;
        case 'gLP': val = (p.gLP ?? 0); break;
        case 'AguaR': val = (p.AguaR ?? 0); break;
      }

      data.add(ChartData(dt, val));
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar por rango temporal
    final startMs = _toMilliseconds(startTs);
    final endMs = _toMilliseconds(endTs);

    List<dynamic> filteredPosts = posts;
    if (startMs != null || endMs != null) {
      filteredPosts = posts.where((p) {
        final tsMs = _toMilliseconds(p.timestamp);
        if (tsMs == null) return false;
        if (startMs != null && tsMs < startMs) return false;
        if (endMs != null && tsMs > endMs) return false;
        return true;
      }).toList();
    }

    // 2. Ordenar
    final sorted = List<dynamic>.from(filteredPosts);
    sorted.sort((a, b) {
      final aMs = _toMilliseconds(a.timestamp);
      final bMs = _toMilliseconds(b.timestamp);
      return (aMs ?? 0).compareTo(bMs ?? 0);
    });

    // 3. Calcular fechas límite
    DateTime? minDate, maxDate;

    if (startMs != null) minDate = DateTime.fromMillisecondsSinceEpoch(startMs).toLocal();
    if (endMs != null) maxDate = DateTime.fromMillisecondsSinceEpoch(endMs).toLocal();

    if ((minDate == null || maxDate == null) && sorted.isNotEmpty) {
      // Encontrar primer y último timestamp válido
      DateTime? firstDate, lastDate;

      for (var p in sorted) {
        final tsMs = _toMilliseconds(p.timestamp);
        if (tsMs != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(tsMs).toLocal();
          if (firstDate == null || dt.isBefore(firstDate)) {
            firstDate = dt;
          }
          if (lastDate == null || dt.isAfter(lastDate)) {
            lastDate = dt;
          }
        }
      }

      minDate ??= firstDate;
      maxDate ??= lastDate;
    }

    // 4. Generar clave de cache
    final cacheKey = sorted.isNotEmpty
        ? '${sorted.length}-${startMs ?? "0"}-${endMs ?? "0"}'
        : 'empty';

    // 5. Obtener datos con downsampling seguro
    final aguaData = _getCachedOrProcessData(cacheKey, sorted, 'Agua', minDate, maxDate);
    final dieselData = _getCachedOrProcessData(cacheKey, sorted, 'Diesel', minDate, maxDate);
    final glpData = _getCachedOrProcessData(cacheKey, sorted, 'gLP', minDate, maxDate);
    final aguarData = _getCachedOrProcessData(cacheKey, sorted, 'AguaR', minDate, maxDate);

    // 6. Configurar intervalo del eje X
    DateTimeIntervalType intervalType = DateTimeIntervalType.days;
    num interval = 1;

    if (minDate != null && maxDate != null) {
      final diff = maxDate.difference(minDate);
      if (diff.inDays >= 365) {
        intervalType = DateTimeIntervalType.months;
        interval = 3;
      } else if (diff.inDays >= 30) {
        intervalType = DateTimeIntervalType.days;
        interval = 7;
      } else if (diff.inDays >= 7) {
        intervalType = DateTimeIntervalType.days;
        interval = 1;
      } else if (diff.inHours >= 24) {
        intervalType = DateTimeIntervalType.hours;
        interval = 6;
      } else {
        intervalType = DateTimeIntervalType.hours;
        interval = 1;
      }
    }

    // 7. Construir series
    final series = <CartesianSeries<ChartData, DateTime>>[];
    final showAll = selectedSeries == null;

    void addIfNeeded(String name, List<ChartData> data, Color color) {
      if (data.isNotEmpty) {
        series.add(AreaSeries<ChartData, DateTime>(
          name: name,
          dataSource: data,
          xValueMapper: (d, _) => d.x,
          yValueMapper: (d, _) => d.y,
          enableTooltip: true,
          markerSettings: MarkerSettings(
            isVisible: data.length <= 100,
            shape: DataMarkerType.circle,
            width: 4,
            height: 4,
          ),
          color: color.withOpacity(0.3),
          borderColor: color,
          borderWidth: 1,
          animationDuration: 0,
        ));
      }
    }

    if (showAll || selectedSeries == 'Agua') {
      addIfNeeded('Agua', aguaData, Colors.blue);
    }
    if (showAll || selectedSeries == 'Diesel') {
      addIfNeeded('Diesel', dieselData, Colors.red);
    }
    if (showAll || selectedSeries == 'gLP') {
      addIfNeeded('GLP', glpData, Colors.green);
    }
    if (showAll || selectedSeries == 'AguaR') {
      addIfNeeded('AguaR', aguarData, Colors.purple);
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SfCartesianChart(
          backgroundColor: Colors.white,
          title: ChartTitle(
              text: selectedSeries == null
                  ? 'Series Agua / Diesel / gLP / AguaR'
                  : 'Serie: $selectedSeries'
          ),
          legend: Legend(
              isVisible: true,
              overflowMode: LegendItemOverflowMode.wrap,
              position: LegendPosition.bottom
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            shouldAlwaysShow: false,
          ),
          trackballBehavior: TrackballBehavior(
            enable: series.length <= 4,
            activationMode: ActivationMode.singleTap,
            tooltipSettings: const InteractiveTooltip(
              enable: true,
              format: 'point.x : point.y',
            ),
          ),
          zoomPanBehavior: ZoomPanBehavior(
            enablePanning: true,
            enablePinching: true,
            zoomMode: ZoomMode.x,
          ),
          primaryXAxis: DateTimeAxis(
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            minimum: minDate,
            maximum: maxDate,
            intervalType: intervalType,
            interval: interval.toDouble(),
          ),
          primaryYAxis: NumericAxis(
            labelFormat: '{value}',
            //numberFormat: '#,###',
          ),
          series: series,
        ),
      ),
    );
  }
}

class ChartData {
  final DateTime x;
  final num y;
  ChartData(this.x, this.y);
}
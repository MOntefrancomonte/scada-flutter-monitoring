import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/AWSServicios/theme_cubit.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';
import '../fragment/data_grid_fragment_dos.dart';
import '../fragment/chart_fragment.dart';
import '../widgets/meter_selector.dart';
import '../widgets/date_range_selector.dart';
import '../models/api_repository.dart';
import '../models/medicion.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  String? _selectedMeter = 'Todos';
  DateTimeRange? _selectedDateRange;
  List<dynamic> _currentData = [];
  Timer? _refreshTimer;
  final ApiRepository _apiRepo = ApiRepository();
  bool _isLoading = false;
  bool _isLiveView = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
    _startLiveUpdateTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startLiveUpdateTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (_isLiveView) {
        print("Actualizando datos en tiempo real...");
        _loadTodayData();
      }
    });
  }

  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    try {
      final datos = await _apiRepo.getMedicionesPorRango(startOfDay, now);

      if (mounted) {
        setState(() {
          _currentData = datos.map((m) => m.toMap()).toList();
          _isLiveView = true;
          _isLoading = false;
          _selectedDateRange = null;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistoricalData(DateTimeRange range) async {
    setState(() {
      _isLoading = true;
      _isLiveView = false;
      _selectedDateRange = range;
    });

    try {
      final datos = await _apiRepo.getMedicionesPorRango(
          range.start,
          range.end.add(const Duration(hours: 23, minutes: 59))
      );

      if (mounted) {
        setState(() {
          _currentData = datos.map((m) => m.toMap()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos históricos: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onDateRangeSelected(DateTimeRange? range) {
    if (range == null) {
      _loadTodayData();
    } else {
      _loadHistoricalData(range);
    }
  }

  void _onMeterSelected(String? meter) {
    setState(() {
      _selectedMeter = meter;
    });
    context.read<ThemeCubit>().setThemeForMeter(meter ?? 'Todos');
  }

  List<dynamic> _getFilteredData() {
    return _currentData;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Gestión de Consumos - Kubiec'),
        actions: [
          // Indicador de carga
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Abrir configuración
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20), // Tamaño ligeramente menor para discreción
            tooltip: 'Cerrar Sesión',
            onPressed: () {
            _showLogoutDialog(context);
          },
          )
        ],
      ),
      body: Row(
        children: [
          // Panel lateral de navegación (fijo)
          Container(
            width: 80,
            color: theme.colorScheme.surface,
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.none,
              leading: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 24,
                    child: const Icon(Icons.account_circle, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usuario',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart),
                  label: Text('Gráficos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.table_chart),
                  label: Text('Datos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history),
                  label: Text('Historial'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.analytics),
                  label: Text('Reportes'),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Contenido principal (desplazable)
          Expanded(
            child: _isLoading && _currentData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              // SOLUCIÓN: Añadimos SingleChildScrollView aquí
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filtros superiores (fijos en la parte superior)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: MeterSelector(
                                selectedMeter: _selectedMeter,
                                onMeterSelected: _onMeterSelected,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: DateRangeSelector(
                                onDateRangeSelected: _onDateRangeSelected,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  if (_selectedDateRange == null) {
                                    _loadTodayData();
                                  } else {
                                    _loadHistoricalData(_selectedDateRange!);
                                  }
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Panel de estadísticas (solo en dashboard)
                    if (_selectedIndex == 0 && _currentData.isNotEmpty) ...[
                      _buildStatsPanel(theme, filteredData),
                      const SizedBox(height: 16),
                    ],

                    // Contenido principal
                    Card(
                      elevation: 2,
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: _currentData.isEmpty
                            ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.data_usage,
                                  size: 60,
                                  color: theme.colorScheme.outline.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isLoading ? 'Cargando datos...' : 'No hay datos disponibles',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                if (!_isLoading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _selectedDateRange == null
                                          ? 'No hay datos para hoy'
                                          : 'No hay datos en el rango seleccionado',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.outline.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                            : Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildContent(
                            context: context,
                            data: filteredData,
                            selectedMeter: _selectedMeter,
                            selectedIndex: _selectedIndex,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estado del sistema (solo se muestra si hay datos)
                    if (_currentData.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_currentData.length} registros cargados',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (_isLiveView)
                              Row(
                                children: [
                                  Icon(Icons.circle, size: 10, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text('Modo tiempo real', style: theme.textTheme.bodySmall),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(ThemeData theme, List<dynamic> data) {
    if (data.isEmpty) return const SizedBox();

    // Calcular estadísticas básicas
    double sumAgua = 0;
    double sumDiesel = 0;
    double sumGlp = 0;
    double sumAguaR = 0;

    for (var item in data) {
      sumAgua += (item['Agua'] ?? 0).toDouble();
      sumDiesel += (item['Diesel'] ?? 0).toDouble();
      sumGlp += (item['gLP'] ?? 0).toDouble();
      sumAguaR += (item['AguaR'] ?? 0).toDouble();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(width: 4),
          _StatCard(
            title: 'Agua',
            value: sumAgua.toStringAsFixed(1),
            unit: 'L',
            color: Colors.blue.shade700,
            icon: Icons.water_drop,
            count: data.length,
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Diesel',
            value: sumDiesel.toStringAsFixed(1),
            unit: 'L',
            color: Colors.brown.shade600,
            icon: Icons.local_gas_station,
            count: data.length,
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'GLP',
            value: sumGlp.toStringAsFixed(1),
            unit: 'kg',
            color: Colors.orange.shade700,
            icon: Icons.propane_tank,
            count: data.length,
          ),
          const SizedBox(width: 12),
          _StatCard(
            title: 'Agua Recirculada',
            value: sumAguaR.toStringAsFixed(1),
            unit: 'L',
            color: Colors.lightBlueAccent.shade700,
            icon: Icons.recycling,
            count: data.length,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required List<dynamic> data,
    required String? selectedMeter,
    required int selectedIndex,
  }) {
    switch (selectedIndex) {
      case 0: // Dashboard
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 600, // Altura mínima para el dashboard
          ),
          child: Column(
            children: [
              // Título del dashboard
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Resumen de Consumos',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Gráfico con altura fija pero scrollable internamente si es necesario
              Container(
                height: 350,
                child: ChartFragment(
                  data: data,
                  selectedMeter: selectedMeter,
                  showMultipleSeries: selectedMeter == null || selectedMeter == 'Todos',
                ),
              ),
              const SizedBox(height: 24),

              // Tabla con altura fija pero scrollable
              Container(
                height: 400,
                child: DataGridFragment(
                  posts: data,
                  selectedSeries: selectedMeter,
                ),
              ),
            ],
          ),
        );

      case 1: // Gráficos
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 500,
          ),
          child: ChartFragment(
            data: data,
            selectedMeter: selectedMeter,
            showMultipleSeries: selectedMeter == null || selectedMeter == 'Todos',
          ),
        );

    case 2: // Tabla de datos - CORREGIDO AQUÍ
        return Container(
        height: 600, // Altura fija para que se muestre correctamente
        child: DataGridFragment(
        posts: data,
        selectedSeries: selectedMeter,
        ),

        );

      case 3: // Historial
        return Container(
          height: 400,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Módulo de Historial',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                ),
                SizedBox(height: 8),
                Text(
                  'Próximamente...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      case 4: // Reportes
        return Container(
          height: 400,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Generador de Reportes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                ),
                SizedBox(height: 8),
                Text(
                  'Próximamente...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );

      default:
        return const Center(child: Text('Seleccione una opción'));
    }
  }
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que deseas salir?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Invocamos la lógica del Cubit que configuraste
              context.read<AuthCubit>().logout();
            },
            child: const Text("Salir", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final int count;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Text(
                    '$count reg.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
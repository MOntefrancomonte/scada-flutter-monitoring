import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/AWSServicios/theme_cubit.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';

// Importaciones de tus fragmentos y widgets
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
  // --- 1. CONTROLADORES DE SCROLL Y KEYS ---
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _kpiKey = GlobalKey();
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _tableKey = GlobalKey();

  // Evita conflicto entre el scroll manual y el click en el menú
  bool _isAutoScrolling = false;

  // --- 2. VARIABLES DE ESTADO ORIGINALES ---
  int _selectedIndex = 0;
  String? _selectedMeter = 'Todos';
  DateTimeRange? _selectedDateRange;
  List<dynamic> _currentData = []; // Usamos dynamic o Medicion según tu modelo
  Timer? _refreshTimer;
  final ApiRepository _apiRepo = ApiRepository();
  bool _isLoading = false;
  // bool _isLiveView = true; // (Opcional si la usas)

  @override
  void initState() {
    super.initState();
    // Carga inicial de datos
    _loadTodayData();
    _startLiveUpdateTimer();

    // Agregamos el listener para detectar dónde está el usuario
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // --- 3. LÓGICA DE DETECCIÓN DE SCROLL (SCROLLSPY) ---
  void _onScroll() {
    if (_isAutoScrolling) return; // No cambiar selección si estamos navegando por click

    // Obtenemos las cajas de renderizado de cada sección
    final kpiBox = _kpiKey.currentContext?.findRenderObject() as RenderBox?;
    final chartBox = _chartKey.currentContext?.findRenderObject() as RenderBox?;
    final tableBox = _tableKey.currentContext?.findRenderObject() as RenderBox?;

    if (kpiBox == null || chartBox == null || tableBox == null) return;

    // Calculamos la posición Y relativa a la ventana
    final kpiOffset = kpiBox.localToGlobal(Offset.zero).dy;
    final chartOffset = chartBox.localToGlobal(Offset.zero).dy;
    final tableOffset = tableBox.localToGlobal(Offset.zero).dy;

    // Punto de corte (ej. 200 pixeles desde arriba)
    const double threshold = 300;

    int newIndex = _selectedIndex;

    // Lógica inversa: verificamos de abajo hacia arriba
    if (tableOffset < threshold) {
      newIndex = 2; // Datos
    } else if (chartOffset < threshold) {
      newIndex = 1; // Gráficas
    } else {
      newIndex = 0; // Resumen
    }

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  // --- 4. LÓGICA DE NAVEGACIÓN MANUAL (CLICK) ---
  Future<void> _scrollToIndex(int index) async {
    setState(() {
      _selectedIndex = index;
      _isAutoScrolling = true; // Bloqueamos el listener temporalmente
    });

    GlobalKey targetKey;
    switch (index) {
      case 0: targetKey = _kpiKey; break;
      case 1: targetKey = _chartKey; break;
      case 2: targetKey = _tableKey; break;
      default: targetKey = _kpiKey;
    }

    if (targetKey.currentContext != null) {
      await Scrollable.ensureVisible(
        targetKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.0, // Alinear al top
      );
    }

    // Pequeña espera para desbloquear el listener
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _isAutoScrolling = false;
    });
  }

  // --- 5. TUS FUNCIONES DE CARGA DE DATOS (MANTENIDAS) ---
  Future<void> _loadTodayData() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final start = _selectedDateRange?.start ?? DateTime(now.year, now.month, now.day);
      final end = _selectedDateRange?.end ?? now;

      // Obtenemos la lista de objetos Medicion
      final List<Medicion> rawData = await _apiRepo.getMedicionesPorRango(start, end);

      if (mounted) {
        setState(() {
          // CORRECCIÓN: Convertimos los objetos Medicion a Mapas (JSON)
          // Esto soluciona el error de "Tried calling: []"
          _currentData = rawData.map((m) => m.toMap()).toList();
        });
      }
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLiveUpdateTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // Solo actualiza si es vista en vivo (hoy)
      if (_selectedDateRange == null) {
        _loadTodayData();
      }
    });
  }

  // --- UI PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // BARRA LATERAL (MENU)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _scrollToIndex, // Usamos nuestra función de scroll
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 20),
              child: Image.asset('assets/icons/app/logo.png', width: 40, errorBuilder: (c,o,s) => const Icon(Icons.bolt)),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Resumen'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: Text('Gráficas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.table_chart_outlined),
                selectedIcon: Icon(Icons.table_chart),
                label: Text('Datos'),
              ),
            ],
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthCubit>().logout(),
                    tooltip: 'Cerrar Sesión',
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // CONTENIDO PRINCIPAL SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ==========================================
                  // SECCIÓN 1: RESUMEN Y KPIs
                  // ==========================================
                  Container(
                    key: _kpiKey, // Key para scroll
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con Selectores
                        _buildHeaderControls(),
                        const SizedBox(height: 24),

                        // Tarjetas de KPI (Reconstruidas basadas en tu código original)
                        _isLoading
                            ? const Center(child: LinearProgressIndicator())
                            : _buildKpiCards(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 40),

                  // ==========================================
                  // SECCIÓN 2: GRÁFICAS
                  // ==========================================
                  Container(
                    key: _chartKey, // Key para scroll
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Análisis Gráfico", style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 450, // Altura fija para evitar conflictos de scroll
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ChartFragment(
                                data: _currentData,
                                selectedMeter: _selectedMeter,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 40),

                  // ==========================================
                  // SECCIÓN 3: TABLA DE DATOS
                  // ==========================================
                  Container(
                    key: _tableKey, // Key para scroll
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Registro Detallado", style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        // Envolvemos DataGrid en un Container con altura definida
                        // para que el scroll principal funcione bien
                        SizedBox(
                          height: 600,
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: DataGridFragment(
                                posts: _currentData,
                                selectedSeries: _selectedMeter,
                              ),

                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Espacio final para que la tabla pueda subir lo suficiente
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildHeaderControls() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: [
        MeterSelector(
          selectedMeter: _selectedMeter,
          onMeterSelected: (val) => setState(() => _selectedMeter = val),
        ),
        DateRangeSelector(
          initialRange: _selectedDateRange,
          onDateRangeSelected: (val) {
            setState(() => _selectedDateRange = val);
            _loadTodayData();
          },
        ),
      ],
    );
  }

  // Reconstrucción básica de tus KPIs basada en lo que suele haber en estos dashboards
  Widget _buildKpiCards() {
    double totalAgua = 0;
    double totalDiesel = 0;
    double totalGLP = 0;

    for (var item in _currentData) {
      // Verificamos si es un Mapa (que es lo que acabamos de convertir)
      if (item is Map<String, dynamic>) {
        totalAgua += (item['Agua'] ?? 0).toDouble();
        totalDiesel += (item['Diesel'] ?? 0).toDouble();
        totalGLP += (item['gLP'] ?? 0).toDouble(); // Ojo con la mayúscula/minúscula de gLP
      }
      // Por si acaso sigue llegando como objeto en algún flujo
      else if (item is Medicion) {
        totalAgua += item.agua;
        totalDiesel += item.diesel;
        totalGLP += item.glp;
      }
    }

    final showAll = _selectedMeter == 'Todos';

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        if (showAll || _selectedMeter == 'Agua')
          _buildKpiCard('Agua', totalAgua.toStringAsFixed(1), 'L', Colors.blue, Icons.water_drop),
        if (showAll || _selectedMeter == 'Diesel')
          _buildKpiCard('Diesel', totalDiesel.toStringAsFixed(1), 'L', Colors.brown, Icons.local_gas_station),
        if (showAll || _selectedMeter == 'gLP')
          _buildKpiCard('GLP', totalGLP.toStringAsFixed(1), 'kg', Colors.orange, Icons.propane),
      ],
    );
  }

  Widget _buildKpiCard(String title, String value, String unit, Color color, IconData icon) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 2,
        surfaceTintColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("Total", style: TextStyle(fontSize: 10, color: color)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
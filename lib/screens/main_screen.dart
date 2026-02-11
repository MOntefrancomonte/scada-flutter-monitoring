import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/Control_Usuario/auth_cubit_dos.dart';
import 'package:proyectoscada/SegundaVida/Charts_grafica/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import '../AWSServicios/post_cubit.dart';
import '../AWSServicios/theme_cubit.dart';
import '../widgets/sliding_card.dart';
import '../widgets/Data_picker.dart';
import '../fragments/data_grid_fragment.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with AutomaticKeepAliveClientMixin {
  static const List<String> _options = ['Todos', 'Agua', 'Diesel', 'gLP', 'AguaR'];
  final PageController _cardPageController = PageController(viewportFraction: 0.78);
  String _selected = 'Todos';

  final fecha_Ahora = DateTime.now();
  late int? _startTs;
  late int? _endTs;

  // Cache para evitar reconstrucciones
  List? _cachedPosts;
  String? _cachedKey;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startTs = DateTime(fecha_Ahora.year, fecha_Ahora.month, fecha_Ahora.day)
        .millisecondsSinceEpoch ~/ 1000;
    _endTs = DateTime(fecha_Ahora.year, fecha_Ahora.month, fecha_Ahora.day, 23, 59, 59)
        .millisecondsSinceEpoch ~/ 1000;

    // Cargar datos iniciales por rango
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostCubit>().getPostsByDateRange(
        startTimestamp: _startTs!,
        endTimestamp: _endTs!,
      );

      // Iniciar actualización solo del último valor
      context.read<PostCubit>().startAutoRefresh(interval: const Duration(seconds: 5));
    });
  }

  @override
  void dispose() {
    _cardPageController.dispose();
    context.read<PostCubit>().stopAutoRefresh();
    super.dispose();
  }

  void _onCardPageChanged(int index) {
    final key = _options[index];
    setState(() => _selected = key);
    context.read<ThemeCubit>().setThemeForMeter(key);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necesario para AutomaticKeepAliveClientMixin

    return BlocConsumer<PostCubit, PostState>(
      // Solo reconstruir cuando cambian los datos relevantes
      buildWhen: (previous, current) {
        if (current is ListPostsSuccess && previous is ListPostsSuccess) {
          // No reconstruir si solo cambió latestPost y ya tenemos datos
          return current.posts.length != previous.posts.length;
        }
        return true;
      },
      listener: (context, state) {
        // Manejar errores sin reconstruir
        if (state is ListPostsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.exception}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is LoadingPosts && _cachedPosts == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Usar datos del estado o cache
        final posts = state is ListPostsSuccess ? state.posts : (_cachedPosts ?? []);
        final latest = state is ListPostsSuccess ? state.latestPost : null;

        // Actualizar cache
        if (state is ListPostsSuccess) {
          _cachedPosts = posts;
        }

        return Scaffold(
          appBar: _buildAppBar(context),
          body: Column(
            children: [
              const SizedBox(height: 10),

              // Tarjetas con datos en tiempo real (solo se actualiza latest)
              _buildCardsSection(latest),

              _buildPageIndicators(context),

              _buildDateFilterButton(context),

              const SizedBox(height: 10),

              // Vistas con datos completos (se actualiza solo cuando cambia el rango)
              _buildDataViews(posts),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Visualizador de Medidores'),
      centerTitle: true,
      elevation: 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.5),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<PostCubit>().getPostsByDateRange(
            startTimestamp: _startTs!,
            endTimestamp: _endTs!,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, size: 20),
          tooltip: 'Cerrar Sesión',
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildCardsSection(dynamic latest) {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _cardPageController,
        itemCount: _options.length,
        onPageChanged: _onCardPageChanged,
        itemBuilder: (context, index) {
          final key = _options[index];

          // Valores para la tarjeta
          double value = 0;
          String unit = '';
          IconData icon = Icons.layers;
          Color iconColor = Colors.grey;

          if (latest != null) {
            if (key == 'Agua') {
              value = (latest.Agua ?? 0).toDouble();
              unit = 'L';
              icon = Icons.water_drop;
              iconColor = Colors.blue;
            } else if (key == 'Diesel') {
              value = (latest.Diesel ?? 0).toDouble();
              unit = 'L';
              icon = Icons.local_gas_station;
              iconColor = Colors.brown;
            } else if (key == 'gLP') {
              value = (latest.gLP ?? 0).toDouble();
              unit = 'kg';
              icon = Icons.local_fire_department;
              iconColor = Colors.orange;
            } else if (key == 'AguaR') {
              value = (latest.AguaR ?? 0).toDouble();
              unit = 'L';
              icon = Icons.water;
              iconColor = Colors.blueAccent.shade400;
            } else if (key == 'Todos') {
              iconColor = Colors.green;
            }
          }

          return GestureDetector(
            onTap: () {
              _cardPageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut
              );
              setState(() => _selected = key);
              context.read<ThemeCubit>().setThemeForMeter(key);
            },
            child: AnimatedScale(
              scale: _selected == key ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _selected == key ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 300),
                child: SlidingCard(
                  title: key,
                  subtitle: key == 'Todos'
                      ? 'Vista General'
                      : 'Valor: ${value.toStringAsFixed(0)} $unit',
                  icon: icon,
                  iconColor: iconColor,
                  isSelected: _selected == key,
                  gauge: key == 'Todos' ? null : _buildGauge(key, value, unit, iconColor),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGauge(String key, double value, String unit, Color iconColor) {
    return SfRadialGauge(
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: 200,
          showTicks: false,
          showLabels: false,
          axisLineStyle: AxisLineStyle(thickness: 0.14 * 100),
          pointers: <GaugePointer>[
            RangePointer(
                value: value,
                width: 0.14 * 100,
                color: iconColor.withOpacity(0.95)
            ),
            NeedlePointer(
                value: value,
                needleLength: 0.58,
                needleEndWidth: 4,
                knobStyle: const KnobStyle(knobRadius: 0.06)
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(
                        '${value.toStringAsFixed(0)} $unit',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: iconColor)
                    ),
                  ],
                ),
                angle: 90,
                positionFactor: 0.6
            )
          ],
        )
      ],
    );
  }

  Widget _buildPageIndicators(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_options.length, (i) {
            final active = _selected == _options[i];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDateFilterButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => CustomDateRangePicker(
                onAccept: (range, start, end) {
                  Navigator.pop(context);
                  setState(() {
                    _startTs = start;
                    _endTs = end;
                  });

                  // Cargar datos del nuevo rango
                  context.read<PostCubit>().getPostsByDateRange(
                    startTimestamp: start,
                    endTimestamp: end,
                  );
                },
              ),
            );
          },
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: const Text('Filtrar por Fecha', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDataViews(List posts) {
    // Crear key única basada en datos relevantes
    final currentKey = '${posts.length}-$_selected-$_startTs-$_endTs';

    return Expanded(
      child: PageView(
        children: [
          _buildHomeIntro(),
          // Vista 1: Lista (con cache)
         // if (currentKey != _cachedKey || _cachedKey == null)
         //   _buildListView(posts)
         // else
         //   Container(), // Mantener vista anterior si no cambió

          // Vista 2: Gráfica (con key para cache)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChartFragment(
              key: ValueKey(currentKey),
              posts: posts,
              selectedSeries: _selected == 'Todos' ? null : _selected,
              startTs: _startTs,
              endTs: _endTs,
            ),
          ),

          // Vista 3: Tabla
          Card(
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DataGridFragment(
                key: ValueKey(currentKey),
                posts: posts,
                selectedSeries: _selected == 'Todos' ? null : _selected,
                startTs: _startTs,
                endTs: _endTs,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List posts) {
    return ListView.builder(
      key: ValueKey(posts.length),
      itemCount: posts.length,
      itemBuilder: (c, i) {
        final post = posts[i];
        return ListTile(
          title: Text("ID: ${post.id}"),
          subtitle: Text("Agua: ${post.Agua}"),
        );
      },
    );
  }
}

Widget _buildHomeIntro() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade200,
              ),
              child: const Icon(Icons.image, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Monitorea tus recursos en tiempo real',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Consulta de forma rápida y visual el consumo de agua, diésel y gas. Usa las tarjetas superiores para navegar entre medidores.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),

  );
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
              context.read<AuthCubit>().logout();
            },
            child: const Text("Salir", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}


//////////////xd


// lib/widgets/floating_card_list.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/selection_provider.dart';

class FloatingCardList extends ConsumerStatefulWidget {
  const FloatingCardList({super.key});

  @override
  ConsumerState<FloatingCardList> createState() => _FloatingCardListState();
}

class _FloatingCardListState extends ConsumerState<FloatingCardList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  final int _itemsCount = 4; // controla cuántas tarjetas mostramos

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    // Staggered intervals por item
    _fadeAnims = List.generate(_itemsCount, (i) {
      final start = i * 0.08;
      final end = (i * 0.08) + 0.6;
      return CurvedAnimation(parent: _controller, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut));
    });

    _slideAnims = List.generate(_itemsCount, (i) {
      final start = i * 0.08;
      final end = (i * 0.08) + 0.6;
      return Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOut)));
    });

    // iniciar animación al montar
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth = MediaQuery.of(context).size.width * 0.75;
    final selectedIndex = ref.watch(selectedCardProvider);
    print('se imprime en toda la pantalla');

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 50),
      itemCount: _itemsCount,
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;

        // Decide el widget concreto por índice (index 0 = tarjeta flotante grande)
        Widget child;
        if (index == 0) {
          //print('el index es: $index');
          child = _FloatingCard(width: itemWidth, isSelected: isSelected);
        } else {
          child = _SmallCard(title: 'Tarjeta ${index + 1}',value:343.0, isSelected: isSelected, isOpen: true);
        }

        // Envolver en transiciones staggered
        return GestureDetector(
          onTap: () {
            ref.read(selectedCardProvider.notifier).state = index;
            print('el index es: $index');
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FadeTransition(
              opacity: _fadeAnims[index],
              child: SlideTransition(
                position: _slideAnims[index],
                child: AnimatedScale(
                  scale: isSelected ? 1.03 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final double width;
  final bool isSelected;
  const _FloatingCard({required this.width, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(math.pi / 4),
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isSelected ? 0.30 : 0.18), blurRadius: isSelected ? 18 : 12, offset: const Offset(0, 8)),
        ],
        border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Tarjeta Flotante', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Contenido de la tarjeta flotante.'),
      ]),
    );
  }
}

class _SmallCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final double value;
  final bool isOpen;

  const _SmallCard({
    required this.title,
    required this.value,
    required this.isOpen,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.inversePrimary.withOpacity(0.6),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: GradientRotation(math.pi / 4),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: isSelected ? 14 : 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Ícono a la izquierda
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.water_drop,
              color: Colors.blue.shade400,
              size: 48,
            ),
          ),

          // Contenido principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Número grande
                Text(
                  value.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                // Icono + "litros"
                Row(
                  children: [
                    Icon(
                      Icons.water,
                      size: 20,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'litros',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Estado: Abierto / Cerrado
                Text(
                  isOpen ? 'Abierto' : 'Cerrado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
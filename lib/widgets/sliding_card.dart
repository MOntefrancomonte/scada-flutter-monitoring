//parte de la nueva actualizacion
// lib/widgets/sliding_card.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tarjeta deslizante personalizada para mostrar métricas individuales
/// con soporte para medidores (gauges) radiales.
class SlidingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? gauge;
  final bool isSelected;

  const SlidingCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.gauge,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            iconColor.withOpacity(0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          transform: const GradientRotation(math.pi / 6),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 6),
          ),
        ],
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Icono circular
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Textos (Título y Subtítulo)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall
                ),
              ],
            ),
          ),

          // Espacio para el Gauge (si se proporciona)
          if (gauge != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              height: 120,
              child: gauge,
            ),
          ]
        ],
      ),
    );
  }
}
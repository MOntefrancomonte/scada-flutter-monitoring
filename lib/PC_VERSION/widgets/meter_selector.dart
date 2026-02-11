import 'package:flutter/material.dart';
import 'package:proyectoscada/AWSServicios/theme_cubit.dart';
//import '../PC_VERSION/cubits/theme_cubit.dart';

class MeterSelector extends StatelessWidget {
  final String? selectedMeter;
  final ValueChanged<String?> onMeterSelected;

  const MeterSelector({
    super.key,
    this.selectedMeter,
    required this.onMeterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final meters = ['Todos', 'Agua', 'AguaR', 'Diesel', 'gLP'];
    
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Seleccionar Medidor',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: meters.map((meter) {
                final isSelected = selectedMeter == meter;
                final color = ThemeCubit.colorForKey(meter);
                
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(meter),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onMeterSelected(meter);
                    }
                  },
                  selectedColor: color.withOpacity(0.2),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? color : Colors.grey[300]!,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

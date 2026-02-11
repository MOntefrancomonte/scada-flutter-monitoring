import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateRangeSelector extends StatefulWidget {
  final ValueChanged<DateTimeRange?> onDateRangeSelected;
  final DateTimeRange? initialRange;

  const DateRangeSelector({
    super.key,
    required this.onDateRangeSelected,
    this.initialRange,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialRange = _selectedRange ?? DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialRange,
      currentDate: DateTime.now(),
      saveText: 'Aplicar',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
      helpText: 'Seleccionar Rango de Fechas',
      errorFormatText: 'Formato inválido',
      errorInvalidText: 'Rango inválido',
      errorInvalidRangeText: 'Rango no válido',
      fieldStartLabelText: 'Fecha inicio',
      fieldEndLabelText: 'Fecha fin',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedRange = newRange;
      });
      widget.onDateRangeSelected(newRange);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedRange = null;
    });
    widget.onDateRangeSelected(null);
  }

  String _formatDateRange() {
    if (_selectedRange == null) {
      return 'Todo el período';
    }
    
    final format = DateFormat('dd/MM/yyyy');
    return '${format.format(_selectedRange!.start)} - ${format.format(_selectedRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Rango de Fechas',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _formatDateRange(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                if (_selectedRange != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                    tooltip: 'Limpiar selección',
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
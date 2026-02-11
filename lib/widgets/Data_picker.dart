// lib/widgets/CustomDateRangePicker.dart


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

/// Widget que replica las principales características del ejemplo "GettingStartedDatePicker"
/// pero en un componente reutilizable y compacto que retorna el rango seleccionado
/// mediante la callback `onAccept(String)`.
class CustomDateRangePicker extends StatefulWidget {
  final Function(String range, int startTimestamp, int endTimestamp) onAccept;
  final PickerDateRange? initialRange;

  const CustomDateRangePicker({
    super.key,
    required this.onAccept,
    this.initialRange,
  });

  @override
  _CustomDateRangePickerState createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  final DateRangePickerController _controller = DateRangePickerController();

  // Propiedades similares al ejemplo "getting started"
  final DateRangePickerSelectionMode _selectionMode = DateRangePickerSelectionMode.extendableRange;
  final ExtendableRangeSelectionDirection _selectionDirection = ExtendableRangeSelectionDirection.both;

  final bool _showTrailingAndLeadingDates = false;
  final bool _enablePastDates = true;
  final bool _enableSwipingSelection = true;
  final bool _enableViewNavigation = true;
  final bool _showActionButtons = true;
  final bool _showWeekNumber = false;
  final bool _showTodayButton = true;

  String _range = '';

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador con valores por defecto (similares al ejemplo)
    _controller.view = DateRangePickerView.month;
    _controller.displayDate = DateTime.now();

    // Si llega un rango inicial, usarlo; si no, usar un rango por defecto.
    if (widget.initialRange != null) {
      _controller.selectedRange = widget.initialRange;
      _range = _formatPickerRange(widget.initialRange!);
    } else {
      final PickerDateRange defaultRange = PickerDateRange(
        DateTime.now().subtract(const Duration(days: 4)),
        DateTime.now().add(const Duration(days: 3)),
      );
      _controller.selectedRange = defaultRange;
      _range = _formatPickerRange(defaultRange);
    }
  }

  String _formatPickerRange(PickerDateRange r) {
    final DateFormat f = DateFormat('dd/MM/yyyy');
    final String start = f.format(r.startDate!);
    final String end = f.format(r.endDate ?? r.startDate!);
    return '$start - $end';
  }

  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _range = _formatPickerRange(args.value);
      } else if (args.value is DateTime) {
        final DateFormat f = DateFormat('dd/MM/yyyy');
        _range = f.format(args.value);
      } else if (args.value is List<DateTime>) {
        // si es lista de fechas, tomar el menor y mayor
        final List<DateTime> list = args.value.cast<DateTime>();
        list.sort();
        final DateFormat f = DateFormat('dd/MM/yyyy');
        _range = '${f.format(list.first)} - ${f.format(list.last)}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: rango seleccionado y botón de hoy
            Row(
              children: [
                Expanded(
                  child: Text(
                    _range.isEmpty ? 'Seleccione un rango' : _range,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (_showTodayButton)
                  TextButton(
                    onPressed: () {
                      _controller.displayDate = DateTime.now();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ir a hoy'),
                          duration: Duration(milliseconds: 400),
                        ),
                      );
                    },
                    child: const Text('Hoy'),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // DateRangePicker
            SizedBox(
              height: 660,
              child: SfDateRangePicker(
                controller: _controller,
    selectionMode: DateRangePickerSelectionMode.range,
                extendableRangeSelectionDirection: _selectionDirection,
                enablePastDates: _enablePastDates,
                allowViewNavigation: _enableViewNavigation,
                showActionButtons: _showActionButtons,
                showTodayButton: _showTodayButton,
                enableMultiView: true,
                navigationDirection: DateRangePickerNavigationDirection.vertical,
                navigationMode: DateRangePickerNavigationMode.scroll,
                headerStyle: DateRangePickerHeaderStyle(
                backgroundColor: Colors.green.shade100,
                textAlign: TextAlign.center,
                textStyle: TextStyle(
                fontStyle: FontStyle.normal,
                fontSize: 25,
                letterSpacing: 5,
                color: Colors.black87.withGreen(70),
                  )
                ),


                monthViewSettings: DateRangePickerMonthViewSettings(
                  enableSwipeSelection: _enableSwipingSelection,
                  showTrailingAndLeadingDates: _showTrailingAndLeadingDates,
                  showWeekNumber: _showWeekNumber,
                ),
                //headerStyle: DateRangePickerHeaderStyle(
                //  textAlign: TextAlign.left,
                //),
                ////////SELECCIONO LAS FECHAS MAXIMAS
                minDate: DateTime.now().subtract(const Duration(days: 730)),
                maxDate: DateTime.now().add(const Duration(days: 730)),
                onSelectionChanged: _onSelectionChanged,

                onCancel: () {
                  // cerrar el diálogo si está en uno
                  Navigator.of(context, rootNavigator: true).maybePop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selección cancelada'), duration: Duration(milliseconds: 600)),
                  );
                },
                onSubmit: (Object? val) {
                  if (val is PickerDateRange) {
                    final start = val.startDate!;
                    final end = val.endDate ?? val.startDate!;

                    // 🔹 Convertimos a segundos desde epoch
                    final int startTimestamp = start.millisecondsSinceEpoch ~/ 1000;
                    final int endTimestamp = end.millisecondsSinceEpoch ~/ 1000;

                    final String formattedRange = _formatPickerRange(val);

                    widget.onAccept(formattedRange, startTimestamp, endTimestamp);
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Selección confirmada'), duration: Duration(milliseconds: 600)),
                  );
                },


              ),
            ),

            const SizedBox(height: 12),


          ],
        ),
      ),
    );
  }
}


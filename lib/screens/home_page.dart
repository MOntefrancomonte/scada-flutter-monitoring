// lib/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectoscada/widgets/Boton.dart';
import 'package:proyectoscada/widgets/Data_picker.dart';

import '../models/sales_data.dart';
import '../providers/counter_provider.dart';
import '../widgets/chart_card.dart';
import '../widgets/floating_card_list.dart';

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key});

  final List<SalesData> _data = const [
    SalesData('Enero', 89),
    SalesData('Febrero', 28),
    SalesData('Marzo', 34),
    SalesData('Abril', 66),
    SalesData('Mayo', 40),
    SalesData('Junio', 56),
    SalesData('Julio', 34),
    SalesData('Agosto', 34),
    SalesData('Septiembre', 56),
    SalesData('Octubre', 25),
    SalesData('Noviembre', 97),
    SalesData('Diciembre', 20)
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // dimensiones responsivas
    final screenH = MediaQuery.of(context).size.height;
    final appBarHeight = screenH * 0.25;
    final cardHeight = 200.0;
    final chartHeight = screenH * 0.38;
    final overlap = screenH * 0.10; // 10% de la pantalla como solapamiento

    final listTop = appBarHeight - (cardHeight / 2);
    final chartTop = 320.0;
    final stackHeight = chartTop + chartHeight + 24;
    String selectedRange = "";
    //locale: const Locale('zh');
    return Scaffold(
      body: SingleChildScrollView(
        child: SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // AppBar simulado
              Container(
                height: appBarHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                padding: const EdgeInsets.only(top: 40, left: 20),
                alignment: Alignment.centerLeft,
              ),

              // Chart dentro del Stack para permitir superposición
              Positioned(
                top: chartTop,
                left: 0,
                right: 0,

                //height: 100,
                child: ChartCard(data: _data, height: chartHeight),
              ),

              // Lista horizontal con tarjeta flotante
              Positioned(
                top: listTop,
                left: 0,
                right: 0,
                child: SizedBox(
                  width: 10,
                  height: cardHeight,
                  child: const FloatingCardList(),
                ),
              ),
              Positioned(
                top: 280,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ajusta la alineación si es necesario
                  children: [
                    IconTextButton(
                      text: "Indicar Fecha",
                      icon: Icons.add,
                      onPressed: () {
                        // Mostrar el CustomDateRangePicker al presionar el botón
                        showDialog(
                          context: context,
                          builder: (context) {
                            return CustomDateRangePicker(
                              onAccept: (range) {
                                // Setea el rango de fechas y cierra el diálogo
                                //setState(() {
                                  //selectedRange = range;
                                //});
                              },
                            );
                          },
                        );
                      },
                    ),
                    IconTextButton(
                      text: "Exportar excel",
                      icon: Icons.pageview,
                      onPressed: () {
                        // Responde al evento del botón
                      },
                    ),
                  ],
                ),
              ),


              //Padding(
                //padding: const EdgeInsets.all(16.0),
                //child: CustomDateRangePicker(),

              //),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider).increment(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

}

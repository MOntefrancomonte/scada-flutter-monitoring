import 'package:flutter/material.dart';

class DescripcionKubiec extends StatelessWidget {
  const DescripcionKubiec({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Kubiec!!",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Nuestra aplicación ha sido desarrollada para centralizar, registrar y analizar "
                  "de forma eficiente las principales variables operativas de la empresa Kubiec. "
                  "Esta vista permite analizar tendencias de forma visual y un registro de las mismas variables "
                  "compatibles con plataformas como Excel de Microsoft.\n\n"
                  "Puedes añadir aquí más texto descriptivo sin problemas de tamaño.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _buildChartPlaceholder(Icons.insert_chart_outlined),
            const SizedBox(height: 20),
            _buildChartPlaceholder(Icons.bar_chart),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(IconData icon) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}

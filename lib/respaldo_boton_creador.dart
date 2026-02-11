import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:proyectoscada/AWSServicios/post_cubit.dart';
import 'package:proyectoscada/AWSServicios/post_cubit.dart'; // Asegúrate de importar correctamente tu Cubit

Widget buildGuardarButton(BuildContext context) {
  return ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white, // ← solo cambia el color del texto e ícono
      textStyle: const TextStyle(
        fontSize: 18, // tamaño de letra
        fontWeight: FontWeight.bold, // grosor de letra
      ),
    ),
    onPressed: () async {
      await context.read<PostCubit>().createPost(
        Agua: 1000,
        AguaR: 933,
        Diesel: 788,
        gLP: 165,
      );
    },
    icon: const Icon(Icons.save),
    label: const Text('crear fecha debug'),
  );
}

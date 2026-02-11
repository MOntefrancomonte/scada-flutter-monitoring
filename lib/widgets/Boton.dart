import 'package:flutter/material.dart';

// Widget personalizado para el ElevatedButton con un ícono y texto
class IconTextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  // Constructor
  const IconTextButton({super.key, 
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onVoicePressed;

  const CustomFAB({
    super.key,
    required this.onScanPressed,
    required this.onVoicePressed,
  });

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon: Icons.menu,
      activeIcon: Icons.close,
      backgroundColor: Colors.green.shade700,
      foregroundColor: Colors.white,
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      animatedIconTheme: const IconThemeData(size: 28.0),
      buttonSize: const Size(60, 60),
      spacing: 10,
      spaceBetweenChildren: 12,
      childrenButtonSize: const Size(56, 56),
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        SpeedDialChild(
          child: const Icon(Icons.document_scanner, color: Colors.white, size: 26),
          backgroundColor: Colors.blue.shade700,
          onTap: onScanPressed,
          label: 'Escanear documento',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelBackgroundColor: Colors.blue.shade700,
        ),
        SpeedDialChild(
          child: const Icon(Icons.mic, color: Colors.white, size: 26),
          backgroundColor: Colors.deepOrange.shade600,
          onTap: onVoicePressed,
          label: 'Registro por voz',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelBackgroundColor: Colors.deepOrange.shade600,
        ),
      ],
    );
  }
}

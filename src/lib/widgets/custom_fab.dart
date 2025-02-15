import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onVoicePressed;

  const CustomFAB({
    Key? key,
    required this.onScanPressed,
    required this.onVoicePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpeedDial(
      icon:
          Icons.add, // Ícono principal (puedes usar Icons.menu si lo prefieres)
      activeIcon: Icons.close,
      backgroundColor: const Color(0xFF228B22), // Color de fondo del FAB
      foregroundColor: Colors.white, // Color del ícono principal
      overlayColor: Colors.black,
      overlayOpacity: 0.3,
      animatedIconTheme: const IconThemeData(size: 28.0),
      buttonSize: const Size(60, 60),
      spacing: 10,
      spaceBetweenChildren: 12,
      childrenButtonSize: const Size(56, 56),
      elevation: 8.0,
      shape: const CircleBorder(),
      children: [
        SpeedDialChild(
          child:
              const Icon(Icons.document_scanner, color: Colors.white, size: 26),
          backgroundColor: const Color(0xFF228B22),
          onTap: onScanPressed,
          label: 'Escanear documento',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelBackgroundColor: const Color(0xFF228B22),
        ),
        SpeedDialChild(
          child: const Icon(Icons.mic, color: Colors.white, size: 26),
          backgroundColor: const Color(0xFF228B22),
          onTap: onVoicePressed,
          label: 'Registro por voz',
          labelStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          labelBackgroundColor: const Color(0xFF228B22),
        ),
      ],
    );
  }
}

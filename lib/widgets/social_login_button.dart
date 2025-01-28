import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String logoPath;
  final VoidCallback onTap;

  const SocialLoginButton({
    Key? key,
    required this.logoPath,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white, // Fondo blanco para resaltar el logo
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            logoPath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

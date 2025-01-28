import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextEditingController? controller; // Agregar el parámetro controller
  final String? Function(String?)? validator; // Agregar el parámetro validator

  const CustomTextField({
    Key? key,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.controller, // Aceptar el controller
    this.validator, // Aceptar el validator
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 17),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF6F6F6F),
              letterSpacing: 0.32,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextFormField(
            controller: controller, // Pasar el controller al TextFormField
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: const Color(0xFF888888),
              letterSpacing: 0.3,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF888888),
                letterSpacing: 0.3,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 16,
              ),
              border: InputBorder.none,
            ),
            validator: validator, // Pasar el validator al TextFormField
          ),
        ),
      ],
    );
  }
}
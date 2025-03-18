import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para usar TextInputFormatter
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http; // Para hacer solicitudes HTTP
import 'dart:convert'; // Para manejar JSON

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String _cardType = 'unknown';

  Future<void> _processPayment() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Crear el PaymentIntent en el backend
        final response = await http.post(
          Uri.parse('https://smartwallet-g4hadr0j.b4a.run/create-payment-intent'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'amount': 5000, // 50€ en centavos (Stripe usa centavos)
            'currency': 'eur', // Moneda (euros)
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          final clientSecret = jsonResponse['clientSecret'];

          // Inicializar el PaymentSheet de Stripe
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Smart Wallet',
              style: ThemeMode.light,
              appearance: PaymentSheetAppearance(
                colors: PaymentSheetAppearanceColors(
                  primary: Colors.green,
                  background: Colors.white,
                  componentBackground: Colors.grey[200]!,
                  componentDivider: Colors.grey[400]!,
                  primaryText: Colors.black,
                  secondaryText: Colors.grey[800]!,
                ),
              ),
            ),
          );

          // Mostrar el formulario de pago de Stripe
          await Stripe.instance.presentPaymentSheet();

          // Éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago exitoso')),
          );
        } else {
          throw Exception('Error al crear el PaymentIntent: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en el pago: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _detectCardType(String input) {
    if (input.startsWith('4')) {
      setState(() {
        _cardType = 'visa';
      });
    } else if (input.startsWith('5')) {
      setState(() {
        _cardType = 'mastercard';
      });
    } else {
      setState(() {
        _cardType = 'unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago de Suscripción'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.white],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Suscripción',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Paga 50€/mes',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre en la tarjeta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el nombre en la tarjeta';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico (opcional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cardNumberController,
                        decoration: InputDecoration(
                          labelText: 'Número de tarjeta',
                          border: const OutlineInputBorder(),
                          prefixIcon: _cardType == 'visa'
                              ? Image.asset('assets/visa.png', width: 24)
                              : _cardType == 'mastercard'
                                  ? Image.asset('assets/mastercard.png', width: 24)
                                  : const Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 19, // Límite de 19 dígitos
                        onChanged: _detectCardType,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el número de tarjeta';
                          }
                          if (value.length < 13 || value.length > 19) {
                            return 'El número de tarjeta debe tener entre 13 y 19 dígitos';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Solo se permiten números';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _expiryDateController,
                        decoration: const InputDecoration(
                          labelText: 'MM/AA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 5, // Límite de 5 caracteres (MM/AA)
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ExpiryDateFormatter(), // Formateador personalizado
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa la fecha de expiración';
                          }
                          if (value.length != 5) {
                            return 'Formato inválido (MM/AA)';
                          }
                          final parts = value.split('/');
                          final month = int.tryParse(parts[0]);
                          final year = int.tryParse(parts[1]);

                          if (month == null || month < 1 || month > 12) {
                            return 'Mes inválido (1-12)';
                          }

                          final currentYear = DateTime.now().year % 100;
                          if (year == null || year < currentYear) {
                            return 'Año inválido';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cvcController,
                        decoration: const InputDecoration(
                          labelText: 'CVC',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4, // Límite de 4 dígitos
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, ingresa el CVC';
                          }
                          if (value.length < 3 || value.length > 4) {
                            return 'El CVC debe tener 3 o 4 dígitos';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Solo se permiten números';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Comprar 50 €',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// Formateador personalizado para la fecha de expiración
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    // Si el texto tiene más de 2 caracteres, agregamos el separador "/"
    if (newText.length >= 2) {
      final month = newText.substring(0, 2);
      final year = newText.length > 2 ? newText.substring(2) : '';
      return TextEditingValue(
        text: '$month/${year.length > 2 ? year.substring(0, 2) : year}',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    }

    return newValue;
  }
}
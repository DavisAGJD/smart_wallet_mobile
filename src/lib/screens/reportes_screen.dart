import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Importa aquí tu ApiServiceReportes si lo requieres
// import '../services/api_service_reportes.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({Key? key}) : super(key: key);

  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  bool _isCreating = false;

  /// Ejemplo de método para crear reporte
  Future<void> _crearReporte() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No se encontró el token. Inicia sesión.')),
      );
      return;
    }

    if (_tituloCtrl.text.trim().isEmpty ||
        _descripcionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Aquí llamarías a tu servicio de reportes, por ejemplo:
      // final apiService = ApiServiceReportes();
      // await apiService.crearReporte(token, {
      //   'titulo': _tituloCtrl.text.trim(),
      //   'descripcion': _descripcionCtrl.text.trim(),
      // });

      // Simulamos una espera
      await Future.delayed(const Duration(seconds: 1));

      // Éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte creado exitosamente')),
      );

      // Limpia campos
      _tituloCtrl.clear();
      _descripcionCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear reporte: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo verde para la parte superior
      backgroundColor: const Color(0xFF228B22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        title: const Text(
          'Reportes',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Contenedor con un título o cualquier otra información
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              'Crea un nuevo reporte',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Sección blanca con bordes redondeados que contiene el formulario
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _tituloCtrl,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descripcionCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCreating ? null : _crearReporte,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF228B22),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isCreating
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Crear Reporte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

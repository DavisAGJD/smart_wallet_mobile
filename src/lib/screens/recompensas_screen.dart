import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service_recompensas.dart';

class RecompensasScreen extends StatefulWidget {
  const RecompensasScreen({Key? key}) : super(key: key);

  @override
  _RecompensasScreenState createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends State<RecompensasScreen> {
  int _puntosUsuario = 0;
  bool _isLoading = false;
  bool _firstLoad = true;

  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && mounted && !_firstLoad) {
        _loadPuntos();
      }
      _firstLoad = false;
    });
    _loadPuntos();
  }

  @override
  void dispose() {
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPuntos() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        throw Exception('No se encontró token o userId en el dispositivo');
      }

      final api = ApiServiceRecompensas();
      final puntos = await api.getPuntosUsuario(token, userId);

      setState(() => _puntosUsuario = puntos);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener puntos: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _canjearPremium() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        throw Exception('No se encontró token o userId en el dispositivo');
      }

      final api = ApiServiceRecompensas();
      await api.canjearRecompensaPremium(token, userId);

      // Descontamos 100 puntos localmente
      setState(() => _puntosUsuario -= 100);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Recompensa canjeada exitosamente!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al canjear recompensa: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Progreso para la barra
    final double progressValue =
        (_puntosUsuario >= 100) ? 1.0 : _puntosUsuario / 100.0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF228B22),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Recompensas',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        // Eliminamos la franja verde de abajo. Todo el body será un Container blanco o gris claro
        body: Container(
          color: Colors.grey.shade100,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Encabezado con los puntos disponibles
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Tus Recompensas',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Puntos disponibles: $_puntosUsuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tarjeta de Recompensa Premium
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Título con ícono
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber[700],
                                    size: 28,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Recompensa Premium',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Imagen o ícono
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/premium-12TzW-Zx.jpg',
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Descripción
                              Text(
                                'Cambia tu suscripción a Premium por 2 días.\n¡Disfruta de beneficios exclusivos!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Puntos requeridos
                              Text(
                                'Puntos requeridos: 100',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Barra de progreso
                              LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_puntosUsuario < 100)
                                Text(
                                  'Te faltan ${100 - _puntosUsuario} puntos para canjear.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                )
                              else
                                const Text(
                                  '¡Ya puedes canjear!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              // Botón de canje
                              ElevatedButton(
                                onPressed: _puntosUsuario >= 100
                                    ? _canjearPremium
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Canjear Recompensa Premium',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Si quieres más recompensas, agrégalas aquí
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

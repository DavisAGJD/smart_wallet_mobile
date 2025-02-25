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

    // Configurar el FocusNode para refrescar datos al volver a la pantalla
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      // Si recupera el foco y no es la primera vez, recarga puntos
      if (_focusNode.hasFocus && mounted && !_firstLoad) {
        _loadPuntos();
      }
      _firstLoad = false;
    });

    // Carga inicial de puntos
    _loadPuntos();
  }

  @override
  void dispose() {
    _focusNode.removeListener(() {});
    _focusNode.dispose();
    super.dispose();
  }

  /// Obtiene el token y userId de SharedPreferences, llama al servicio para traer los puntos
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

  /// Llama a la API para canjear la recompensa Premium
  Future<void> _canjearPremium() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('No se encontró token. Inicia sesión nuevamente.');
      }

      final api = ApiServiceRecompensas();
      await api.canjearRecompensaPremium(token);

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
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF228B22), // Fondo verde
        appBar: AppBar(
          backgroundColor: const Color(0xFF228B22),
          title: const Text(
            'Recompensas',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // Sección superior: título, puntos, etc.
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Tus Recompensas',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Puntos disponibles: $_puntosUsuario',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            // Contenedor blanco con bordes redondeados
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Título de la recompensa
                          const Text(
                            'Canjear Premium (100 pts)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Botón para canjear
                          ElevatedButton(
                            onPressed:
                                _puntosUsuario >= 100 ? _canjearPremium : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF228B22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Canjear Recompensa Premium'),
                          ),
                          const SizedBox(height: 16),
                          // Aquí puedes agregar más "tarjetas" si ofreces más recompensas
                          // ...
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

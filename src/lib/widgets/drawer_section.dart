import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/first_screen.dart';
import '../screens/reportes_screen.dart';
import '../screens/recompensas_screen.dart';
import '../screens/payment_screen.dart';
import '../services/api_service_profile.dart';
import '../screens/gastos_screen.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({Key? key}) : super(key: key);

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  String _userName = '';
  String _userEmail = '';
  String? _profileImageUrl;
  final ApiServiceProfile apiService = ApiServiceProfile();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Cargar la información real del usuario desde el backend
  Future<void> _loadUserProfile() async {
    final userId = await apiService.getUserId();
    if (userId == null || userId.isEmpty) {
      print("Error: no se encontró el ID del usuario.");
      return;
    }
    try {
      final data = await apiService.getUserProfile(userId: userId);
      setState(() {
        _userName = data['nombre_usuario'] ?? '';
        _userEmail = data['email'] ?? '';
        _profileImageUrl = data['image'];
      });
    } catch (e) {
      print("Error al cargar perfil: $e");
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    // Navega al onboarding y elimina todas las rutas previas
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const FirstScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(context),
          _buildMenuItems(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.green[800],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 30,
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: _profileImageUrl == null
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green[800],
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            _userName.isNotEmpty ? _userName : 'Usuario',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _userEmail.isNotEmpty ? _userEmail : 'email@example.com',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return Column(
      children: [
        // Reportes
        ListTile(
          leading: const Icon(Icons.assignment),
          title: const Text('Reportes'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportesScreen(),
              ),
            );
          },
        ),
        // Recompensas
        ListTile(
          leading: const Icon(Icons.card_giftcard),
          title: const Text('Recompensas'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecompensasScreen(),
              ),
            );
          },
        ),
        // Método de Pago
        ListTile(
          leading: const Icon(Icons.payment),
          title: const Text('Método de Pago'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/payment');
          },
        ),
        // Historial -> GastosScreen
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historial'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GastosScreen(),
              ),
            );
          },
        ),
        const Divider(),
        // Cerrar sesión
        ListTile(
          leading: const Icon(Icons.exit_to_app),
          title: const Text('Cerrar Sesión'),
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}

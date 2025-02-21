// widgets/custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    Navigator.pushReplacementNamed(context, '/login');
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
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.green[800],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Juan Pérez',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'juan@example.com',
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
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Inicio'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: const Text('Estadísticas'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/stats');
          },
        ),
        ListTile(
          leading: const Icon(Icons.savings),
          title: const Text('Metas'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/goals');
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Historial'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/history');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Configuración'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.exit_to_app),
          title: const Text('Cerrar Sesión'),
          onTap: () => _logout(context),
        ),
      ],
    );
  }
}

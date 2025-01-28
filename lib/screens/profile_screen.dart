import 'package:flutter/material.dart';
import '../services/api_service_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Controladores de texto
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Llaves de formularios (una para cada pestaña)
  final _personalFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  // Controlador del TabBar
  late TabController _tabController;

  // Servicio API
  final ApiServiceProfile _apiService = ApiServiceProfile();

  // Indicador de carga
  bool _isLoading = false;

  // Color principal verde intenso
  final Color primaryGreen = const Color(0xFF228B22);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Actualizar información personal
  Future<void> _updatePersonalInfo() async {
    if (_personalFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _apiService.updateUser(
          usuarioId: '123', // Reemplaza con el ID real de tu usuario
          name: _nameController.text,
          username: _usernameController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Información personal actualizada con éxito')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la información personal: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // Actualizar configuración de cuenta
  Future<void> _updateAccountSettings() async {
    if (_accountFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _apiService.updateUser(
          usuarioId: '123', // Reemplaza con el ID real de tu usuario
          email: _emailController.text,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de cuenta actualizada con éxito')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la cuenta: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Pestaña de Información Personal
  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _personalFormKey,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con un ligero degradado verde
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryGreen,
                        primaryGreen.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Editar Información Personal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person, color: Colors.grey),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryGreen),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre de Usuario',
                    prefixIcon: Icon(Icons.alternate_email, color: Colors.grey),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryGreen),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePersonalInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white, // Texto en blanco
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Pestaña de Configuración de Cuenta
  Widget _buildAccountSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _accountFormKey,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título con un ligero degradado verde
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryGreen,
                        primaryGreen.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Configuración de Cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryGreen),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo';
                    }
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value)) {
                      return 'Por favor ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryGreen),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAccountSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white, // Texto en blanco
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Guardar Cambios',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo con un tono suave de verde (usando el color principal con opacidad)
      backgroundColor: primaryGreen.withOpacity(0.05),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            automaticallyImplyLeading: true,
            // FlexibleSpace con degradado verde
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen,
                      primaryGreen.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(height: 60), // Espaciado para evitar el choque
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            title: const Text(
              'Perfil',
              style: TextStyle(color: Colors.white),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                // Mismo degradado verde para un efecto uniforme
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen,
                      primaryGreen.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Personal'),
                    Tab(text: 'Cuenta'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPersonalInfoTab(),
            _buildAccountSettingsTab(),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service_profile.dart'; // Asegúrate de que la ruta sea correcta

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _incomeController = TextEditingController();
  final _emailController = TextEditingController();

  // Controladores para campos de solo lectura
  final _subscriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  final _personalFormKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();

  late TabController _tabController;

  bool _isLoading = false;
  File? _imageFile; // Imagen seleccionada localmente
  String? _profileImageUrl; // URL de la imagen guardada en la BD

  final Color primaryGreen = const Color(0xFF228B22);
  final Color accentColor = const Color(0xFF32CD32);

  // Instancia del servicio API
  final ApiServiceProfile apiService = ApiServiceProfile();

  // Controlador para la contraseña en configuración de cuenta
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile(); // Cargar información del usuario al iniciar la pantalla
  }

  // Método para cargar la información del usuario desde el backend
  Future<void> _loadUserProfile() async {
    final userId = await apiService.getUserId();
    if (userId == null || userId.isEmpty) {
      print("Error: no se encontró el ID del usuario en el token.");
      return;
    }
    try {
      final data = await apiService.getUserProfile(userId: userId);
      setState(() {
        // Se asume que la API retorna las llaves: image, nombre_completo (o nombre_usuario),
        // tipo_suscripcion, ingresos y puntos.
        _profileImageUrl = data['image'];
        _nameController.text =
            data['nombre_completo'] ?? data['nombre_usuario'] ?? '';
        _subscriptionController.text = data['tipo_suscripcion'] ?? 'Gratis';
        _incomeController.text = data['ingresos']?.toString() ?? '0';
        _pointsController.text = (data['puntos'] ?? 0).toString();
        _emailController.text = data['email'] ?? '';
      });
    } catch (e) {
      print("Error al cargar perfil: $e");
    }
  }

  // Seleccionar imagen desde la galería
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Actualizar información personal, incluyendo la imagen e ingresos
  Future<void> _updatePersonalInfo() async {
    if (_personalFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = await apiService.getUserId();
        if (userId == null || userId.isEmpty) {
          throw Exception("No se encontró el ID de usuario.");
        }

        // Se envían solo los campos que se hayan modificado, incluyendo ingresos.
        await apiService.updateUser(
          usuarioId: userId,
          name: _nameController.text,
          income: _incomeController.text,
        );

        if (_imageFile != null) {
          await apiService.updateUserImage(
              usuarioId: userId, image: _imageFile!);
          // Actualizar la URL de la imagen luego de actualizarla en el backend
          await _loadUserProfile();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Actualizar configuración de cuenta
  Future<void> _updateAccountSettings() async {
    if (_accountFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = await apiService.getUserId();
        if (userId == null || userId.isEmpty) {
          throw Exception("No se encontró el ID de usuario.");
        }

        await apiService.updateUser(
          usuarioId: userId,
          email: _emailController.text,
          password: _passwordController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de cuenta actualizada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _incomeController.dispose();
    _emailController.dispose();
    _subscriptionController.dispose();
    _pointsController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            automaticallyImplyLeading: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null) as ImageProvider<Object>?,
                          child:
                              (_imageFile == null && _profileImageUrl == null)
                                  ? Icon(Icons.person,
                                      size: 60, color: primaryGreen)
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Perfil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryGreen,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  indicatorColor: primaryGreen,
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

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _personalFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Campo para Nombre Completo (editable)
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: Icon(Icons.person, color: primaryGreen),
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
                    // Campo de solo lectura para Tipo de Suscripción
                    TextFormField(
                      controller: _subscriptionController,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Suscripción',
                        prefixIcon: Icon(Icons.star, color: primaryGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryGreen),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    // Campo editable para Ingresos
                    TextFormField(
                      controller: _incomeController,
                      decoration: InputDecoration(
                        labelText: 'Ingresos',
                        prefixIcon:
                            Icon(Icons.attach_money, color: primaryGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryGreen),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tus ingresos';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ingresa un valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Campo de solo lectura para Puntos
                    TextFormField(
                      controller: _pointsController,
                      decoration: InputDecoration(
                        labelText: 'Puntos',
                        prefixIcon: Icon(Icons.score, color: primaryGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryGreen),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      readOnly: true,
                    ),
                  ],
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Cambios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _accountFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuración de Cuenta',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.email, color: primaryGreen),
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
                        prefixIcon:
                            Icon(Icons.lock_outline, color: primaryGreen),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryGreen),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Cambios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

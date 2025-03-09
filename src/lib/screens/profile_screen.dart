import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service_profile.dart'; // Ajusta la ruta según tu proyecto

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controladores de texto
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Para la validación de formulario
  final _formKey = GlobalKey<FormState>();

  // Manejo de estado de carga
  bool _isLoading = false;

  // Manejo de imagen local y URL
  File? _imageFile;
  String? _profileImageUrl;

  // Colores (usa tu color verde "gordo" aquí)
  final Color primaryGreen = const Color(0xFF228B22);
  final Color accentColor = const Color(0xFF32CD32);

  // Servicio de API
  final ApiServiceProfile apiService = ApiServiceProfile();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Cargar información del usuario
  Future<void> _loadUserProfile() async {
    final userId = await apiService.getUserId();
    if (userId == null || userId.isEmpty) {
      print("Error: no se encontró el ID del usuario en el token.");
      return;
    }
    try {
      final data = await apiService.getUserProfile(userId: userId);
      setState(() {
        _profileImageUrl = data['image'];
        _nameController.text = data['nombre_usuario'] ?? '';
        _usernameController.text = data['username'] ?? '';
        _emailController.text = data['email'] ?? '';
      });
    } catch (e) {
      print("Error al cargar perfil: $e");
    }
  }

  // Seleccionar imagen desde galería
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Actualizar información (incluyendo la imagen si se seleccionó)
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = await apiService.getUserId();
        if (userId == null || userId.isEmpty) {
          throw Exception("No se encontró el ID de usuario.");
        }

        // Actualiza los datos de texto
        await apiService.updateUser(
          usuarioId: userId,
          name: _nameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );

        // Si hay nueva imagen local, súbela
        if (_imageFile != null) {
          await apiService.updateUserImage(
              usuarioId: userId, image: _imageFile!);
          // Refrescamos la URL de la imagen
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

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo blanco
      backgroundColor: Colors.white,
      // AppBar con fondo verde y letras en blanco
      appBar: AppBar(
        backgroundColor: primaryGreen,
        title: const Text(
          'Editar Datos Personales',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar centrado
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : null) as ImageProvider<Object>?,
                      child: (_imageFile == null && _profileImageUrl == null)
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: primaryGreen,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Campo Nombre Completo
              _buildTextField(
                controller: _nameController,
                label: 'Nombre Completo',
                hint: 'Ingresa tu nombre completo',
                icon: Icons.person,
                validatorMsg: 'Por favor ingresa tu nombre',
              ),
              const SizedBox(height: 16),

              // Campo Nombre de Usuario
              _buildTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                hint: 'Ej: @mi_usuario',
                icon: Icons.alternate_email,
              ),
              const SizedBox(height: 16),

              // Campo Correo
              _buildTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                hint: 'ejemplo@correo.com',
                icon: Icons.email,
                validatorMsg: 'Por favor ingresa un correo válido',
                emailValidator: true,
              ),
              const SizedBox(height: 16),

              // Campo Contraseña
              _buildTextField(
                controller: _passwordController,
                label: 'Nueva Contraseña',
                hint: 'Déjalo en blanco si no deseas cambiarla',
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),

              // Botón de guardar cambios
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para crear campos de texto con estilo similar
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? validatorMsg,
    bool isPassword = false,
    bool emailValidator = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etiqueta encima del TextField, en negrita
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryGreen),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            // Borde al enfocar
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primaryGreen),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          validator: (value) {
            if (validatorMsg != null && (value == null || value.isEmpty)) {
              return validatorMsg;
            }
            if (emailValidator && value != null && value.isNotEmpty) {
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Correo inválido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}

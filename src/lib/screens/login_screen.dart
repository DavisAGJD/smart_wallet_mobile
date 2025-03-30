import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service_login.dart';
import '../widgets/social_login_button.dart';
import 'singup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiServiceLogin _apiService = ApiServiceLogin();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // La función loginUsuario ahora retorna el token
        String token = await _apiService.loginUsuario(
          _emailController.text,
          _passwordController.text,
        );

        // Aunque en el servicio ya guardas el token, aquí lo aseguramos
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Navega a MainScreen, que contiene la navbar
        Navigator.pushReplacementNamed(context, '/main');
      } catch (e) {
        // Se muestra un mensaje de error genérico para contraseña incorrecta
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Contraseña incorrecta, por favor inténtalo de nuevo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se obtienen las dimensiones de la pantalla
    final Size size = MediaQuery.of(context).size;
    final double screenWidth = size.width;
    final double screenHeight = size.height;

    // Valores proporcionales basados en la pantalla
    final double containerPadding =
        screenWidth * 0.06; // Ej: ~24 en un ancho de 400
    final double logoHeight = screenHeight * 0.15; // Ajusta según necesidad
    final double verticalSpacing = screenHeight * 0.04;
    final double titleFontSize = screenWidth * 0.06;
    final double subtitleFontSize = screenWidth * 0.035;
    final double buttonFontSize = screenWidth * 0.04;
    final double dividerHorizontalPadding = screenWidth * 0.04;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(containerPadding),
                    // Se limita el ancho máximo para pantallas grandes
                    constraints: BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Image.asset(
                            'assets/logo.png',
                            height: logoHeight,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: verticalSpacing),
                          // Título
                          Text(
                            'Bienvenido de vuelta',
                            style: GoogleFonts.poppins(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          // Subtítulo
                          Text(
                            'Inicia sesión para continuar',
                            style: GoogleFonts.poppins(
                              fontSize: subtitleFontSize,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          // Campo de email
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'ej: jon.smith@email.com',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: verticalSpacing * 0.5),
                          // Campo de contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: verticalSpacing * 0.5),
                          // Botón para "Olvidaste tu contraseña"
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: GoogleFonts.poppins(
                                  color: Colors.green,
                                  fontSize: subtitleFontSize,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing * 0.5),
                          // Botón de iniciar sesión
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              'Iniciar sesión',
                              style: GoogleFonts.poppins(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          // Línea divisoria con texto
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[400])),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: dividerHorizontalPadding),
                                child: Text(
                                  'O continúa con',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: subtitleFontSize,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[400])),
                            ],
                          ),
                          SizedBox(height: verticalSpacing * 0.8),
                          // Botón de login social: Se elimina el de Google
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SocialLoginButton(
                                logoPath: 'assets/facebook_logo.png',
                                onTap: () => print('Login con Facebook'),
                              ),
                            ],
                          ),
                          SizedBox(height: verticalSpacing),
                          // Opción para registrarse
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿No tienes cuenta? ',
                                style: GoogleFonts.poppins(
                                  fontSize: subtitleFontSize,
                                  color: Colors.grey[700],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SignUpScreen()),
                                  );
                                },
                                child: Text(
                                  'Regístrate',
                                  style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

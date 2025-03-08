import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
// Asegúrate de importar tus servicios y modelos reales:
// import 'package:smart_wallet/services/api_service_metas.dart';
// import 'package:smart_wallet/services/api_service_profile.dart';
// import 'package:smart_wallet/services/api_service_update_amount.dart';

class MetasAddAmountModal extends StatefulWidget {
  const MetasAddAmountModal({super.key});

  @override
  _MetasAddAmountModalState createState() => _MetasAddAmountModalState();
}

class _MetasAddAmountModalState extends State<MetasAddAmountModal> {
  final _formKey = GlobalKey<FormState>();

  // Servicio simulado, reemplaza por el real
  // final ApiServiceGetMetas _getMetas = ApiServiceGetMetas();

  bool isLoading = true;
  bool isSaving = false;

  List<Meta> metas = [];
  String? selectedMetaId;
  String? selectedFuente;

  TextEditingController montoController = TextEditingController();
  TextEditingController descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMetas();
  }

  Future<void> _fetchMetas() async {
    try {
      // final metasList = await _getMetas.getMetasWithCategories();
      // Simulación de datos; reemplaza por tu servicio real
      await Future.delayed(const Duration(seconds: 1));
      final metasList = [
        Meta(metaId: 1, nombreMeta: "Comprar moto", categoriaNombre: "Logro"),
        Meta(
            metaId: 2,
            nombreMeta: "Viaje a la playa",
            categoriaNombre: "Viaje"),
      ];

      setState(() {
        metas = metasList;
        if (metas.isNotEmpty) {
          selectedMetaId = metas.first.metaId.toString();
        }
        isLoading = false;
      });
    } catch (e) {
      print("Error al cargar metas: $e");
      setState(() => isLoading = false);
      _showErrorModal('Error al cargar metas: $e');
    }
  }

  void _showErrorModal(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateMetaAmount() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedMetaId == null) {
      _showErrorModal('Selecciona una meta');
      return;
    }

    setState(() => isSaving = true);

    try {
      final metaId = int.parse(selectedMetaId!);
      final monto = double.parse(montoController.text);

      // Ejemplo de obtención de presupuesto; reemplaza por tu servicio real
      // final ApiServiceProfile profileService = ApiServiceProfile();
      // final userId = await profileService.getUserId();
      // if (userId == null) {
      //   _showErrorModal("Usuario no autenticado");
      //   setState(() => isSaving = false);
      //   return;
      // }
      // final dataProfile = await profileService.getUserProfile(userId: userId);
      // final presupuestoValue = dataProfile['ingresos'];
      // if (presupuestoValue == null) {
      //   _showErrorModal('No se pudo obtener tu presupuesto.');
      //   setState(() => isSaving = false);
      //   return;
      // }
      // final presupuesto = presupuestoValue is double
      //     ? presupuestoValue
      //     : double.tryParse(presupuestoValue.toString()) ?? 0.0;

      // Simulación de presupuesto
      final presupuesto = 10000.0;
      if (presupuesto == 0.0) {
        _showErrorModal('Presupuesto no válido.');
        setState(() => isSaving = false);
        return;
      }

      final maxAllowed = presupuesto * 0.20;
      if (monto > maxAllowed) {
        _showErrorModal(
          "El monto ingresado (\$${monto.toStringAsFixed(2)}) supera el 20% "
          "de tu presupuesto (máximo permitido: \$${maxAllowed.toStringAsFixed(2)}). "
          "Ingresa un monto menor.",
        );
        setState(() => isSaving = false);
        return;
      }

      // Actualizar la meta con el nuevo monto.
      // Ejemplo: await ApiServiceUpdateAmount().updateAmount(metaId, monto);

      // También podrías guardar la fuente y descripción en tu backend.
      // Ejemplo:
      // await ApiServiceUpdateAmount().updateAmountWithDetails(
      //   metaId: metaId,
      //   monto: monto,
      //   fuente: selectedFuente,
      //   descripcion: descripcionController.text,
      // );

      _showSuccessSnackbar('Monto actualizado correctamente');
      Navigator.of(context).pop();
    } on FormatException {
      _showErrorModal('Formato de monto inválido');
    } catch (e) {
      print("Error al actualizar: $e");
      _showErrorModal('Error al actualizar: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ícono destacado (CircleAvatar) como en el primer modal
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.greenAccent.withOpacity(0.2),
                child: const Icon(Icons.flag, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 15),
              Text(
                'Agregar Monto',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // SELECCIÓN DE META
                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      DropdownButtonFormField2<String>(
                        decoration: _buildInputDecoration(label: 'Meta'),
                        value: selectedMetaId,
                        items: metas
                            .map(
                              (meta) => DropdownMenuItem<String>(
                                value: meta.metaId.toString(),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getCategoryIcon(meta.categoriaNombre),
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 10),
                                    Text(meta.nombreMeta),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (String? newValue) {
                          setState(() => selectedMetaId = newValue);
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona una meta' : null,
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        buttonStyleData: ButtonStyleData(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                        ),
                      ),
                    const SizedBox(height: 20),
                    // FUENTE DEL INGRESO
                    DropdownButtonFormField2<String>(
                      decoration:
                          _buildInputDecoration(label: 'Fuente del ingreso'),
                      hint: const Text('Selecciona la fuente'),
                      value: selectedFuente,
                      items: [
                        'Sueldo',
                        'Regalo',
                        'Venta de algo',
                        'Freelance',
                        'Otro',
                      ].map((fuente) {
                        return DropdownMenuItem<String>(
                          value: fuente,
                          child: Text(fuente),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() => selectedFuente = value);
                      },
                      validator: (value) =>
                          value == null ? 'Selecciona la fuente' : null,
                    ),
                    const SizedBox(height: 20),
                    // DESCRIPCIÓN (opcional)
                    TextFormField(
                      controller: descripcionController,
                      decoration: _buildInputDecoration(
                        label: 'Descripción (opcional)',
                        icon: Icons.note,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    // MONTO A AGREGAR
                    TextFormField(
                      controller: montoController,
                      decoration: _buildInputDecoration(
                        label: 'Monto a agregar',
                        icon: Icons.monetization_on,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isEmpty) return 'Requerido';
                        final amount = double.tryParse(value);
                        if (amount == null) return 'Número inválido';
                        if (amount <= 0) return 'El monto debe ser positivo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // BOTÓN GUARDAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : _updateMetaAmount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
      {required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: Colors.grey[600]) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'ahorro':
        return Icons.savings;
      case 'viaje':
        return Icons.flight;
      case 'emprendimiento':
        return Icons.business;
      case 'proyecto':
        return Icons.assignment;
      case 'caridad':
        return Icons.volunteer_activism;
      case 'logro':
        return Icons.emoji_events;
      case 'medio ambiente':
        return Icons.eco;
      case 'seguridad':
        return Icons.security;
      case 'estrella':
        return Icons.star;
      default:
        return Icons.more_horiz;
    }
  }
}

// Ejemplo de modelo Meta (ajusta según tu proyecto real)
class Meta {
  final int metaId;
  final String nombreMeta;
  final String categoriaNombre;

  Meta({
    required this.metaId,
    required this.nombreMeta,
    required this.categoriaNombre,
  });
}

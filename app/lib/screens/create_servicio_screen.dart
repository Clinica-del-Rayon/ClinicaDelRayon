import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/database_service.dart';
import '../models/orden.dart';

class CreateServicioScreen extends StatefulWidget {
  const CreateServicioScreen({super.key});

  @override
  State<CreateServicioScreen> createState() => _CreateServicioScreenState();
}

class _CreateServicioScreenState extends State<CreateServicioScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _costoEstimadoController = TextEditingController();
  final _precioEstimadoController = TextEditingController();
  final _duracionEstimadaController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _costoEstimadoController.dispose();
    _precioEstimadoController.dispose();
    _duracionEstimadaController.dispose();
    super.dispose();
  }

  Future<void> _createServicio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Generar ID único para el servicio
      final String servicioId = FirebaseDatabase.instance.ref().child('servicios').push().key!;

      final servicio = Servicio(
        id: servicioId,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        costoEstimado: _costoEstimadoController.text.trim().isEmpty
            ? null
            : double.tryParse(_costoEstimadoController.text.trim()),
        precioEstimado: _precioEstimadoController.text.trim().isEmpty
            ? null
            : double.tryParse(_precioEstimadoController.text.trim()),
        duracionEstimada: _duracionEstimadaController.text.trim().isEmpty
            ? null
            : int.tryParse(_duracionEstimadaController.text.trim()),
      );

      await _dbService.createServicio(servicio);

      if (mounted) {
        Navigator.of(context).pop(true); // Volver con resultado exitoso

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Servicio "${servicio.nombre}" creado exitosamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: const [
                  Icon(Icons.error, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Text('Error al crear servicio: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1E88E5);
    final Color backgroundColor = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey[700], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Crear Servicio',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Ícono decorativo
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.miscellaneous_services,
                            size: 50,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Nombre del servicio
                      _buildModernTextField(
                        controller: _nombreController,
                        label: 'Nombre del Servicio',
                        hint: 'Ej: Lavado Premium, Pulido',
                        icon: Icons.label_outline,
                        required: true,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor ingresa el nombre del servicio';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Descripción
                      _buildModernTextField(
                        controller: _descripcionController,
                        label: 'Descripción',
                        hint: 'Describe el servicio',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      SizedBox(height: 20),

                      // Costo Estimado
                      _buildModernTextField(
                        controller: _costoEstimadoController,
                        label: 'Costo Estimado',
                        hint: 'Costo de aplicación',
                        icon: Icons.attach_money_outlined,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final costo = double.tryParse(value.trim());
                            if (costo == null || costo < 0) {
                              return 'Ingresa un costo válido';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Precio Estimado (Venta)
                      _buildModernTextField(
                        controller: _precioEstimadoController,
                        label: 'Precio de Venta',
                        hint: 'Precio al cliente',
                        icon: Icons.sell_outlined,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final precio = double.tryParse(value.trim());
                            if (precio == null || precio < 0) {
                              return 'Ingresa un precio válido';
                            }

                            // Validar que el precio sea mayor al costo
                            final costoText = _costoEstimadoController.text.trim();
                            if (costoText.isNotEmpty) {
                              final costo = double.tryParse(costoText);
                              if (costo != null && precio <= costo) {
                                return 'El precio debe ser mayor al costo';
                              }
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),

                      // Duración Estimada
                      _buildModernTextField(
                        controller: _duracionEstimadaController,
                        label: 'Duración Estimada',
                        hint: 'Ej: 2, 4, 8',
                        icon: Icons.schedule_outlined,
                        suffix: 'hrs',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final horas = int.tryParse(value.trim());
                            if (horas == null || horas <= 0) {
                              return 'Ingresa una duración válida mayor a 0';
                            }
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 32),

                      // Botón de crear
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createServicio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Crear Servicio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: 16),

                      // Nota informativa
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: primaryColor, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Los precios y duraciones son estimados. Podrás ajustarlos para cada orden específica.',
                                style: TextStyle(fontSize: 13, color: Colors.blueGrey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              suffixText: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            maxLines: maxLines,
            textCapitalization: textCapitalization,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
          ),
        ),
      ],
    );
  }
}


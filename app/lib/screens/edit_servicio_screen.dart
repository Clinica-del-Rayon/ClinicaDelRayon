import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/orden.dart';

class EditServicioScreen extends StatefulWidget {
  final Servicio servicio;

  const EditServicioScreen({super.key, required this.servicio});

  @override
  State<EditServicioScreen> createState() => _EditServicioScreenState();
}

class _EditServicioScreenState extends State<EditServicioScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _costoEstimadoController;
  late TextEditingController _precioEstimadoController;
  late TextEditingController _duracionEstimadaController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.servicio.nombre);
    _descripcionController = TextEditingController(text: widget.servicio.descripcion ?? '');
    _costoEstimadoController = TextEditingController(
      text: widget.servicio.costoEstimado?.toStringAsFixed(2) ?? '',
    );
    _precioEstimadoController = TextEditingController(
      text: widget.servicio.precioEstimado?.toStringAsFixed(2) ?? '',
    );
    _duracionEstimadaController = TextEditingController(
      text: widget.servicio.duracionEstimada?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _costoEstimadoController.dispose();
    _precioEstimadoController.dispose();
    _duracionEstimadaController.dispose();
    super.dispose();
  }

  Future<void> _updateServicio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        'costo_estimado': _costoEstimadoController.text.trim().isEmpty
            ? null
            : double.tryParse(_costoEstimadoController.text.trim()),
        'precio_estimado': _precioEstimadoController.text.trim().isEmpty
            ? null
            : double.tryParse(_precioEstimadoController.text.trim()),
        'duracion_estimada': _duracionEstimadaController.text.trim().isEmpty
            ? null
            : int.tryParse(_duracionEstimadaController.text.trim()),
      };

      await _dbService.updateServicio(widget.servicio.id, updates);

      if (mounted) {
        Navigator.of(context).pop(true); // Volver con resultado exitoso

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Servicio actualizado exitosamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
              content: Text('Error al actualizar servicio: ${e.toString()}'),
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
                    'Editar Servicio',
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
                            Icons.edit_rounded,
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
                        hint: 'Nombre del servicio',
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

                      // Botón de actualizar
                      ElevatedButton(
                        onPressed: _isLoading ? null : _updateServicio,
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
                                'Actualizar Servicio',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/solicitud.dart';
import '../../services/database_service.dart';
import 'package:firebase_database/firebase_database.dart';

class AceptarSolicitudDialog extends StatefulWidget {
  final Solicitud solicitud;

  const AceptarSolicitudDialog({super.key, required this.solicitud});

  @override
  State<AceptarSolicitudDialog> createState() => _AceptarSolicitudDialogState();
}

class _AceptarSolicitudDialogState extends State<AceptarSolicitudDialog> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _duracionController = TextEditingController();

  DateTime? _fechaSeleccionada;
  bool _usarFechaDeseada = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fechaSeleccionada = widget.solicitud.fechaDeseada;
  }

  @override
  void dispose() {
    _duracionController.dispose();
    super.dispose();
  }

  Future<void> _selectFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? now,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1E88E5),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaSeleccionada = picked;
        _usarFechaDeseada = false;
      });
    }
  }

  Future<void> _aceptar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final duracion = int.parse(_duracionController.text.trim());

      if (_usarFechaDeseada) {
        // Aceptar con la fecha deseada por el cliente
        await _dbService.aceptarSolicitud(
          widget.solicitud.id,
          widget.solicitud.fechaDeseada,
          duracion,
        );
      } else {
        // Proponer nueva fecha
        final nuevaPropuesta = PropuestaFecha(
          id: FirebaseDatabase.instance.ref().child('propuestas').push().key!,
          fechaPropuesta: _fechaSeleccionada!,
          duracionEstimadaHoras: duracion,
          propuestaPor: 'admin',
          fechaCreacion: DateTime.now(),
        );

        await _dbService.agregarPropuestaFecha(
          widget.solicitud.id,
          nuevaPropuesta,
        );

        // Mantener estado EN_REVISION con la nueva propuesta
        await _dbService.updateSolicitud(widget.solicitud.id, {
          'estado': 'EN_REVISION',
        });
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(_usarFechaDeseada
                    ? 'Solicitud aceptada exitosamente'
                    : 'Propuesta enviada al cliente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Aceptar Solicitud',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Información de la solicitud
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha solicitada por el cliente:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${widget.solicitud.fechaDeseada.day}/${widget.solicitud.fechaDeseada.month}/${widget.solicitud.fechaDeseada.year}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Opción: Usar fecha deseada
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _usarFechaDeseada ? primaryColor : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<bool>(
                  title: Text('Aceptar con esta fecha'),
                  subtitle: Text('La fecha propuesta por el cliente'),
                  value: true,
                  groupValue: _usarFechaDeseada,
                  onChanged: (value) {
                    setState(() {
                      _usarFechaDeseada = true;
                      _fechaSeleccionada = widget.solicitud.fechaDeseada;
                    });
                  },
                  activeColor: primaryColor,
                ),
              ),
              SizedBox(height: 12),

              // Opción: Proponer otra fecha
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: !_usarFechaDeseada ? primaryColor : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      title: Text('Proponer otra fecha'),
                      subtitle: Text('Sugerir una fecha alternativa'),
                      value: false,
                      groupValue: _usarFechaDeseada,
                      onChanged: (value) {
                        setState(() {
                          _usarFechaDeseada = false;
                        });
                      },
                      activeColor: primaryColor,
                    ),
                    if (!_usarFechaDeseada) ...[
                      Divider(height: 1),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: InkWell(
                          onTap: _selectFecha,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today,
                                    color: primaryColor, size: 20),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _fechaSeleccionada != null
                                        ? '${_fechaSeleccionada!.day}/${_fechaSeleccionada!.month}/${_fechaSeleccionada!.year}'
                                        : 'Seleccionar fecha',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios,
                                    color: primaryColor, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Duración estimada
              TextFormField(
                controller: _duracionController,
                decoration: InputDecoration(
                  labelText: 'Duración Estimada (horas) *',
                  hintText: 'Ej: 4, 8, 12',
                  prefixIcon: Icon(Icons.schedule),
                  suffixText: 'hrs',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la duración estimada';
                  }
                  final horas = int.tryParse(value.trim());
                  if (horas == null || horas <= 0) {
                    return 'Debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _aceptar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              _usarFechaDeseada ? 'Aceptar' : 'Proponer Fecha',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


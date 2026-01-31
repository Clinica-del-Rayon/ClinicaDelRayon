import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/database_service.dart';
import '../../models/solicitud.dart';
import '../../models/vehiculo.dart';
import '../../models/usuario.dart';
import '../../widgets/modern_text_field.dart';
import '../../widgets/modern_multi_selector.dart';

class CreateSolicitudScreen extends StatefulWidget {
  final Cliente cliente;

  const CreateSolicitudScreen({super.key, required this.cliente});

  @override
  State<CreateSolicitudScreen> createState() => _CreateSolicitudScreenState();
}

class _CreateSolicitudScreenState extends State<CreateSolicitudScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();

  bool _isLoading = false;
  Vehiculo? _vehiculoSeleccionado;
  DateTime? _fechaDeseada;
  List<Vehiculo> _vehiculosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadVehiculos() async {
    try {
      final vehiculos = await _dbService.getVehiculosByCliente(widget.cliente.uid);
      setState(() {
        _vehiculosDisponibles = vehiculos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar vehículos: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _selectVehiculo() async {
    if (_vehiculosDisponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No tienes vehículos registrados'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Registrar',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/create-vehiculo',
                arguments: {
                  'clienteId': widget.cliente.uid,
                  'clienteNombre': widget.cliente.nombres,
                },
              );
            },
          ),
        ),
      );
      return;
    }

    final selected = await Navigator.push<List<Vehiculo>>(
      context,
      MaterialPageRoute(
        builder: (context) => ModernMultiSelector<Vehiculo>(
          title: 'Seleccionar Vehículo',
          items: _vehiculosDisponibles,
          selectedItems: _vehiculoSeleccionado != null ? [_vehiculoSeleccionado!] : [],
          getItemTitle: (v) => '${v.marca} ${v.modelo}',
          getItemSubtitle: (v) => '${v.placa} • ${v.generacion}',
          getItemImage: (v) => v.fotosUrls.isNotEmpty ? v.fotosUrls.first : null,
          defaultIcon: Icons.directions_car,
          onSelectionChanged: (items) {},
          multiSelect: false,
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _vehiculoSeleccionado = selected.first;
      });
    }
  }

  Future<void> _selectFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaDeseada ?? now.add(Duration(days: 1)),
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
        _fechaDeseada = picked;
      });
    }
  }

  Future<void> _createSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    if (_vehiculoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona un vehículo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_fechaDeseada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona una fecha'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final solicitudId = FirebaseDatabase.instance.ref().child('solicitudes').push().key!;

      // Crear propuesta inicial del cliente
      final propuestaInicial = PropuestaFecha(
        id: FirebaseDatabase.instance.ref().child('propuestas').push().key!,
        fechaPropuesta: _fechaDeseada!,
        propuestaPor: 'cliente',
        fechaCreacion: DateTime.now(),
      );

      final solicitud = Solicitud(
        id: solicitudId,
        clienteId: widget.cliente.uid,
        vehiculoId: _vehiculoSeleccionado!.id ?? '',
        fechaCreacion: DateTime.now(),
        fechaDeseada: _fechaDeseada!,
        observaciones: _observacionesController.text.trim(),
        historialPropuestas: [propuestaInicial],
      );

      await _dbService.createSolicitud(solicitud);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Solicitud creada exitosamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: Colors.blueGrey[700], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Nueva Solicitud',
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
                            Icons.schedule_send_rounded,
                            size: 50,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Selector de vehículo
                      Text(
                        'Vehículo *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildVehiculoSelector(primaryColor),
                      SizedBox(height: 20),

                      // Selector de fecha
                      Text(
                        'Fecha Deseada *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildFechaSelector(primaryColor),
                      SizedBox(height: 20),

                      // Observaciones
                      ModernTextField(
                        controller: _observacionesController,
                        label: 'Observaciones',
                        hint: 'Describe qué necesita tu vehículo',
                        icon: Icons.notes_outlined,
                        required: true,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor describe lo que necesitas';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 32),

                      // Botón de crear
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createSolicitud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
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
                                'Enviar Solicitud',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: 16),

                      // Nota informativa
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: primaryColor, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'El administrador revisará tu solicitud y te confirmará la fecha. Puedes ver el estado en la sección de Solicitudes.',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.blueGrey[700]),
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

  Widget _buildVehiculoSelector(Color primaryColor) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _selectVehiculo,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.directions_car, color: Colors.grey[400], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: _vehiculoSeleccionado != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_vehiculoSeleccionado!.marca} ${_vehiculoSeleccionado!.modelo}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '${_vehiculoSeleccionado!.placa} • ${_vehiculoSeleccionado!.generacion}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Seleccionar vehículo',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFechaSelector(Color primaryColor) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _selectFecha,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: Colors.grey[400], size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: _fechaDeseada != null
                      ? Text(
                          '${_fechaDeseada!.day}/${_fechaDeseada!.month}/${_fechaDeseada!.year}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        )
                      : Text(
                          'Seleccionar fecha',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.grey[400], size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


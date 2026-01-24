import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../models/vehiculo.dart';
import '../../models/orden.dart';
import '../../services/database_service.dart';
import '../../providers/provider_state.dart';

class ClienteReservasScreen extends StatefulWidget {
  const ClienteReservasScreen({super.key});

  @override
  State<ClienteReservasScreen> createState() => _ClienteReservasScreenState();
}

class _ClienteReservasScreenState extends State<ClienteReservasScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<Vehiculo> _vehiculos = [];
  List<Servicio> _servicios = [];

  Vehiculo? _selectedVehiculo;
  List<Servicio> _selectedServicios = [];
  DateTime? _selectedDate;
  TextEditingController _observacionesController = TextEditingController();

  // Modern Color Palette
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final usuario = Provider.of<ProviderState>(context, listen: false).currentUserData as Cliente;
      final vehiculos = await _dbService.getVehiculosByClienteId(usuario.uid);
      final servicios = await _dbService.getAllServicios();

      setState(() {
        _vehiculos = vehiculos;
        _servicios = servicios;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.blueGrey[800]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createReserva() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehiculo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona un vehículo'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedServicios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona al menos un servicio'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuario = Provider.of<ProviderState>(context, listen: false).currentUserData as Cliente;

      // Generate unique ID for the order
      final ordenId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create DetalleOrden for each selected service
      final detalles = _selectedServicios.map((servicio) {
        final detalleId = '${ordenId}_${servicio.id}';
        return DetalleOrden(
          id: detalleId,
          servicioId: servicio.id,
          servicioNombre: servicio.nombre,
          precio: servicio.precioEstimado ?? 0.0,
          estadoItem: EstadoServicio.PENDIENTE,
          progreso: 0,
        );
      }).toList();

      // Create orden
      final orden = Orden(
        id: ordenId,
        clienteId: usuario.uid,
        vehiculoId: _selectedVehiculo!.id!,
        estado: EstadoOrden.EN_COTIZACION,
        fechaCreacion: DateTime.now(),
        fechaPromesa: _selectedDate,
        detalles: detalles,
      );

      await _dbService.createOrden(orden);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reserva creada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear reserva: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Minimalist Custom AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[700]),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Nueva Reserva',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading && _vehiculos.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Select Vehicle
                            _buildSectionTitle('Selecciona tu vehículo'),
                            SizedBox(height: 12),
                            _buildVehiculoSelector(),
                            SizedBox(height: 24),

                            // Select Services
                            _buildSectionTitle('Selecciona los servicios'),
                            SizedBox(height: 12),
                            _buildServiciosSelector(),
                            SizedBox(height: 24),

                            // Select Date
                            _buildSectionTitle('Fecha preferida (opcional)'),
                            SizedBox(height: 12),
                            _buildDateSelector(),
                            SizedBox(height: 24),

                            // Observations
                            _buildSectionTitle('Observaciones (opcional)'),
                            SizedBox(height: 12),
                            _buildObservacionesField(),
                            SizedBox(height: 24),

                            // Summary
                            if (_selectedServicios.isNotEmpty) ...[
                              _buildSummary(),
                              SizedBox(height: 24),
                            ],

                            // Create Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _createReserva,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Crear Reserva',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildVehiculoSelector() {
    if (_vehiculos.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700]),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No tienes vehículos registrados. Contacta con un administrador.',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: _vehiculos.map((vehiculo) {
          final isSelected = _selectedVehiculo?.id == vehiculo.id;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedVehiculo = vehiculo;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_car_filled_rounded,
                      color: isSelected ? _primaryColor : Colors.grey[400],
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehiculo.placa,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? _primaryColor : Colors.blueGrey[800],
                            ),
                          ),
                          Text(
                            '${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.generacion}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: _primaryColor, size: 24),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiciosSelector() {
    if (_servicios.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No hay servicios disponibles',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: _servicios.map((servicio) {
          final isSelected = _selectedServicios.any((s) => s.id == servicio.id);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServicios.removeWhere((s) => s.id == servicio.id);
                  } else {
                    _selectedServicios.add(servicio);
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? _primaryColor.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedServicios.add(servicio);
                          } else {
                            _selectedServicios.removeWhere((s) => s.id == servicio.id);
                          }
                        });
                      },
                      activeColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio.nombre,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                          if (servicio.descripcion != null && servicio.descripcion!.isNotEmpty)
                            Text(
                              servicio.descripcion!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '\$${(servicio.precioEstimado ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: _primaryColor),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? _formatFecha(_selectedDate!)
                    : 'Seleccionar fecha',
                style: TextStyle(
                  fontSize: 15,
                  color: _selectedDate != null ? Colors.blueGrey[800] : Colors.grey[600],
                  fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildObservacionesField() {
    return TextFormField(
      controller: _observacionesController,
      maxLines: 4,
      decoration: InputDecoration(
        hintText: 'Agrega cualquier observación o detalle especial...',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final total = _selectedServicios.fold<double>(
      0.0,
      (sum, servicio) => sum + (servicio.precioEstimado ?? 0.0),
    );

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          Divider(height: 24),
          ...(_selectedServicios.map((servicio) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    servicio.nombre,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
                Text(
                  '\$${(servicio.precioEstimado ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ))),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}


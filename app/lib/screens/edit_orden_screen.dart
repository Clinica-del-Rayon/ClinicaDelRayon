import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/orden.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../widgets/searchable_dropdown.dart';

class EditOrdenScreen extends StatefulWidget {
  final Orden orden;

  const EditOrdenScreen({super.key, required this.orden});

  @override
  State<EditOrdenScreen> createState() => _EditOrdenScreenState();
}

class _EditOrdenScreenState extends State<EditOrdenScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();

  late Orden _ordenActual;
  late EstadoOrden _estadoSeleccionado;
  DateTime? _fechaPromesa;

  Cliente? _clienteSeleccionado;
  Vehiculo? _vehiculoSeleccionado;

  List<Cliente> _todosClientes = [];
  List<Vehiculo> _vehiculosDelCliente = [];

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _ordenActual = widget.orden;
    _estadoSeleccionado = widget.orden.estado;
    _fechaPromesa = widget.orden.fechaPromesa;
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final cliente = await _dbService.getUsuario(_ordenActual.clienteId) as Cliente?;
      final vehiculo = await _dbService.getVehiculo(_ordenActual.vehiculoId);
      final clientes = await _dbService.getAllClientes();

      // Cargar vehículos del cliente actual
      List<Vehiculo> vehiculos = [];
      if (cliente != null) {
        vehiculos = await _dbService.getVehiculosByClienteId(cliente.uid);
      }

      setState(() {
        _clienteSeleccionado = cliente;
        _vehiculoSeleccionado = vehiculo;
        _todosClientes = clientes;
        _vehiculosDelCliente = vehiculos;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarVehiculosDelCliente(String clienteId) async {
    try {
      final vehiculos = await _dbService.getVehiculosByClienteId(clienteId);
      setState(() {
        _vehiculosDelCliente = vehiculos;
        _vehiculoSeleccionado = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar vehículos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _puedeEditarDatosOrden() {
    return _estadoSeleccionado == EstadoOrden.EN_COTIZACION ||
           _estadoSeleccionado == EstadoOrden.COTIZACION_RESERVA;
  }

  Future<void> _seleccionarFechaPromesa() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaPromesa ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaPromesa = picked;
      });
    }
  }

  Future<void> _cambiarEstadoOrden() async {
    final nuevoEstado = await showDialog<EstadoOrden>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EstadoOrden.values.map((estado) {
            return RadioListTile<EstadoOrden>(
              title: Text(estado.displayName),
              value: estado,
              groupValue: _estadoSeleccionado,
              onChanged: (value) {
                Navigator.pop(context, value);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (nuevoEstado != null && nuevoEstado != _estadoSeleccionado) {
      setState(() {
        _estadoSeleccionado = nuevoEstado;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que haya cliente y vehículo seleccionados
    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_vehiculoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un vehículo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ordenActualizada = _ordenActual.copyWith(
        estado: _estadoSeleccionado,
        fechaPromesa: _fechaPromesa,
        clienteId: _clienteSeleccionado!.uid,
        vehiculoId: _vehiculoSeleccionado!.id!,
      );

      await _dbService.updateOrden(_ordenActual.id, ordenActualizada.toJson());

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getEstadoColor(EstadoOrden estado) {
    switch (estado) {
      case EstadoOrden.EN_COTIZACION:
        return Colors.orange;
      case EstadoOrden.COTIZACION_RESERVA:
        return Colors.amber;
      case EstadoOrden.EN_PROCESO:
        return Colors.blue;
      case EstadoOrden.FINALIZADO:
        return Colors.green;
      case EstadoOrden.ENTREGADO:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Orden #${_ordenActual.id.substring(0, 8)}'),
        backgroundColor: Colors.teal,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estado de la orden
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado de la Orden',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _cambiarEstadoOrden,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(_estadoSeleccionado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getEstadoColor(_estadoSeleccionado)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: _getEstadoColor(_estadoSeleccionado),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _estadoSeleccionado.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getEstadoColor(_estadoSeleccionado),
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca para cambiar el estado',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progreso total
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progreso Total',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _ordenActual.calcularProgresoPromedio() / 100,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getEstadoColor(_estadoSeleccionado),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_ordenActual.calcularProgresoPromedio()}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Información básica (solo editable en cotización)
              if (_puedeEditarDatosOrden()) ...[
                const Text(
                  'Información de la Orden',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SearchableDropdown<Cliente>(
                  value: _clienteSeleccionado,
                  items: _todosClientes,
                  itemLabel: (cliente) => '${cliente.nombres} ${cliente.apellidos}',
                  labelText: 'Cliente',
                  prefixIcon: Icons.person,
                  onChanged: (cliente) {
                    setState(() {
                      _clienteSeleccionado = cliente;
                      if (cliente != null) {
                        _cargarVehiculosDelCliente(cliente.uid);
                      } else {
                        _vehiculosDelCliente = [];
                        _vehiculoSeleccionado = null;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Selecciona un cliente';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SearchableDropdown<Vehiculo>(
                  value: _vehiculoSeleccionado,
                  items: _vehiculosDelCliente,
                  itemLabel: (vehiculo) => '${vehiculo.placa} - ${vehiculo.marca} ${vehiculo.modelo}',
                  labelText: 'Vehículo',
                  prefixIcon: Icons.directions_car,
                  enabled: _clienteSeleccionado != null,
                  onChanged: (vehiculo) {
                    setState(() {
                      _vehiculoSeleccionado = vehiculo;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Selecciona un vehículo';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Fecha promesa (editable en cotización o en proceso)
              const Text(
                'Fecha Promesa de Entrega',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _fechaPromesa == null
                      ? 'Sin fecha promesa'
                      : 'Fecha: ${_fechaPromesa!.day}/${_fechaPromesa!.month}/${_fechaPromesa!.year}',
                ),
                leading: const Icon(Icons.calendar_today),
                trailing: _fechaPromesa != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: (_puedeEditarDatosOrden() || _estadoSeleccionado == EstadoOrden.EN_PROCESO)
                            ? () {
                                setState(() {
                                  _fechaPromesa = null;
                                });
                              }
                            : null,
                      )
                    : null,
                onTap: (_puedeEditarDatosOrden() || _estadoSeleccionado == EstadoOrden.EN_PROCESO)
                    ? _seleccionarFechaPromesa
                    : null,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar cambios
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _guardarCambios,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Guardar Cambios',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
}


import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/orden.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../widgets/fotos_servicio_selector.dart';
import '../widgets/searchable_dropdown.dart';

class CreateOrdenScreen extends StatefulWidget {
  const CreateOrdenScreen({super.key});

  @override
  State<CreateOrdenScreen> createState() => _CreateOrdenScreenState();
}

class _CreateOrdenScreenState extends State<CreateOrdenScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  Cliente? _clienteSeleccionado;
  Vehiculo? _vehiculoSeleccionado;
  DateTime? _fechaPromesa;

  List<Cliente> _clientes = [];
  List<Vehiculo> _vehiculosDelCliente = [];
  List<Servicio> _todosServicios = [];
  List<DetalleOrden> _serviciosSeleccionados = [];
  Map<String, List<XFile>> _fotosServiciosLocales = {}; // Mapa de servicioId -> fotos locales

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final clientes = await _dbService.getAllClientes();
      final servicios = await _dbService.getAllServicios();

      setState(() {
        _clientes = clientes;
        _todosServicios = servicios;
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

  void _mostrarDialogoPrecioServicio(Servicio servicio) {
    final precioController = TextEditingController(
      text: servicio.precioEstimado?.toStringAsFixed(2) ?? '0',
    );
    final observacionesController = TextEditingController();
    List<XFile> fotosServicio = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Agregar: ${servicio.nombre}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (servicio.descripcion != null) ...[
                      Text(
                        servicio.descripcion!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Precio base: \$${servicio.precioEstimado?.toStringAsFixed(2) ?? '0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: precioController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Precio específico para esta orden',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: observacionesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (Opcional)',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FotosServicioSelector(
                      titulo: 'Fotos del servicio (Opcional)',
                      onFotosSeleccionadas: (fotos) {
                        setDialogState(() {
                          fotosServicio = fotos;
                        });
                      },
                      maxFotos: 5,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final precio = double.tryParse(precioController.text);
                  if (precio != null && precio > 0) {
                    _agregarServicio(
                      servicio,
                      precio,
                      observacionesController.text.trim().isEmpty
                          ? null
                          : observacionesController.text.trim(),
                      fotosServicio,
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingresa un precio válido'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _agregarServicio(Servicio servicio, double precio, String? observaciones, List<XFile> fotos) {
    final detalleId = DateTime.now().millisecondsSinceEpoch.toString();
    final detalle = DetalleOrden(
      id: detalleId,
      servicioId: servicio.id,
      servicioNombre: servicio.nombre,
      precio: precio,
      estadoItem: EstadoServicio.PENDIENTE,
      progreso: 0,
      observacionesTecnicas: observaciones,
    );

    setState(() {
      _serviciosSeleccionados.add(detalle);
      if (fotos.isNotEmpty) {
        _fotosServiciosLocales[detalleId] = fotos;
      }
    });
  }

  void _removerServicio(int index) {
    final detalleId = _serviciosSeleccionados[index].id;
    setState(() {
      _serviciosSeleccionados.removeAt(index);
      _fotosServiciosLocales.remove(detalleId);
    });
  }

  double _calcularTotal() {
    return _serviciosSeleccionados.fold(0.0, (sum, detalle) => sum + detalle.precio);
  }

  Future<void> _seleccionarFechaPromesa() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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

  Future<void> _crearOrden() async {
    if (!_formKey.currentState!.validate()) return;

    if (_clienteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cliente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_vehiculoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un vehículo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_serviciosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un servicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Verificar si el vehículo ya tiene órdenes activas
      final tieneOrdenesActivas = await _dbService.vehiculoTieneOrdenesActivas(_vehiculoSeleccionado!.id!);
      if (tieneOrdenesActivas) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este vehículo ya tiene una orden activa. No se puede crear otra hasta que se entregue.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Generar ID único para la orden
      final String ordenId = FirebaseDatabase.instance.ref().child('ordenes').push().key!;

      // Subir fotos de servicios y actualizar detalles
      List<DetalleOrden> detallesConFotos = [];
      for (var detalle in _serviciosSeleccionados) {
        List<String> fotosUrls = [];

        // Si este servicio tiene fotos locales, subirlas
        if (_fotosServiciosLocales.containsKey(detalle.id)) {
          final fotos = _fotosServiciosLocales[detalle.id]!;
          for (int i = 0; i < fotos.length; i++) {
            try {
              final url = await _storageService.uploadServicePhoto(
                ordenId,
                detalle.id,
                fotos[i],
                i,
              );
              fotosUrls.add(url);
            } catch (e) {
              print('Error al subir foto $i del servicio ${detalle.servicioNombre}: $e');
            }
          }
        }

        // Crear detalle con las URLs de las fotos
        detallesConFotos.add(detalle.copyWith(fotosIniciales: fotosUrls));
      }

      final orden = Orden(
        id: ordenId,
        clienteId: _clienteSeleccionado!.uid,
        vehiculoId: _vehiculoSeleccionado!.id!,
        fechaCreacion: DateTime.now(),
        fechaPromesa: _fechaPromesa,
        estado: EstadoOrden.EN_COTIZACION,
        detalles: detallesConFotos,
      );

      await _dbService.createOrden(orden);

      if (mounted) {
        Navigator.of(context).pop(); // Volver a la lista de órdenes

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Orden #${ordenId.substring(0, 8)} creada exitosamente'),
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
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Text('Error al crear orden: ${e.toString()}'),
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
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Orden'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono y título
              const Center(
                child: Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nueva Orden de Trabajo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Selector de Cliente
              const Text(
                '1. Selecciona el Cliente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SearchableDropdown<Cliente>(
                value: _clienteSeleccionado,
                items: _clientes,
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
              const SizedBox(height: 24),

              // Selector de Vehículo
              const Text(
                '2. Selecciona el Vehículo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
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

              // Selector de Servicios
              const Text(
                '3. Agrega Servicios',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Lista de servicios disponibles
              Card(
                elevation: 2,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text(
                        'Servicios Disponibles',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${_todosServicios.length} servicios en catálogo'),
                      leading: const Icon(Icons.build_circle, color: Colors.teal),
                    ),
                    const Divider(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todosServicios.length,
                      itemBuilder: (context, index) {
                        final servicio = _todosServicios[index];
                        final yaSeleccionado = _serviciosSeleccionados
                            .any((d) => d.servicioId == servicio.id);

                        return CheckboxListTile(
                          title: Text(servicio.nombre),
                          subtitle: Text(
                            'Precio base: \$${servicio.precioEstimado?.toStringAsFixed(2) ?? '0'}',
                          ),
                          value: yaSeleccionado,
                          activeColor: Colors.teal,
                          onChanged: (selected) {
                            if (selected!) {
                              _mostrarDialogoPrecioServicio(servicio);
                            } else {
                              final index = _serviciosSeleccionados.indexWhere(
                                (d) => d.servicioId == servicio.id,
                              );
                              if (index != -1) {
                                _removerServicio(index);
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de servicios seleccionados
              if (_serviciosSeleccionados.isNotEmpty) ...[
                Card(
                  elevation: 2,
                  color: Colors.teal[50],
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Servicios Agregados',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${_serviciosSeleccionados.length} servicio(s)'),
                        leading: const Icon(Icons.check_circle, color: Colors.teal),
                      ),
                      const Divider(height: 1),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _serviciosSeleccionados.length,
                        itemBuilder: (context, index) {
                          final detalle = _serviciosSeleccionados[index];
                          return ListTile(
                            title: Text(detalle.servicioNombre),
                            subtitle: detalle.observacionesTecnicas != null
                                ? Text(detalle.observacionesTecnicas!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${detalle.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removerServicio(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_calcularTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Fecha promesa
              const Text(
                '4. Fecha Promesa de Entrega (Opcional)',
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
                        onPressed: () {
                          setState(() {
                            _fechaPromesa = null;
                          });
                        },
                      )
                    : null,
                onTap: _seleccionarFechaPromesa,
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              const SizedBox(height: 32),

              // Botón crear orden
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearOrden,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Crear Orden',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Nota informativa
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La orden se creará en estado "En Cotización". Podrás actualizar el estado y asignar trabajadores después.',
                        style: TextStyle(fontSize: 13, color: Colors.blue[900]),
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
}


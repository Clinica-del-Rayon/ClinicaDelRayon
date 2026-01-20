import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/orden.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../screens/create_orden_screen.dart';
import '../screens/orden_details_screen.dart';

class OrdenesManagementScreen extends StatefulWidget {
  const OrdenesManagementScreen({super.key});

  @override
  State<OrdenesManagementScreen> createState() => _OrdenesManagementScreenState();
}

class _OrdenesManagementScreenState extends State<OrdenesManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  EstadoOrden? _filtroEstado;

  Map<String, Cliente> _clientesMap = {};
  Map<String, Vehiculo> _vehiculosMap = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosAdicionales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosAdicionales() async {
    try {
      // Cargar clientes
      final clientes = await _dbService.getAllClientes();
      final clientesMap = <String, Cliente>{};
      for (var cliente in clientes) {
        clientesMap[cliente.uid] = cliente;
      }

      // Cargar vehículos
      final vehiculos = await _dbService.getAllVehiculos();
      final vehiculosMap = <String, Vehiculo>{};
      for (var vehiculo in vehiculos) {
        if (vehiculo.id != null) {
          vehiculosMap[vehiculo.id!] = vehiculo;
        }
      }

      setState(() {
        _clientesMap = clientesMap;
        _vehiculosMap = vehiculosMap;
      });
    } catch (e) {
      print('Error cargando datos: $e');
    }
  }

  Future<void> _eliminarOrden(Orden orden) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar la orden #${orden.id}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteOrden(orden.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Orden #${orden.id} eliminada exitosamente'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar orden: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo de búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar orden...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filtro por estado
                DropdownButtonFormField<EstadoOrden?>(
                  value: _filtroEstado,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.filter_list),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...EstadoOrden.values.map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado.displayName),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // Lista de órdenes
          Expanded(
            child: StreamBuilder<List<Orden>>(
              stream: _dbService.getOrdenesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final ordenes = snapshot.data ?? [];

                // Filtrar órdenes
                final ordenesFiltradas = ordenes.where((orden) {
                  // Filtro por búsqueda
                  if (_searchQuery.isNotEmpty) {
                    final cliente = _clientesMap[orden.clienteId];
                    final vehiculo = _vehiculosMap[orden.vehiculoId];
                    final nombreCliente = cliente != null
                        ? '${cliente.nombres} ${cliente.apellidos}'.toLowerCase()
                        : '';
                    final placaVehiculo = vehiculo?.placa.toLowerCase() ?? '';

                    if (!orden.id.toLowerCase().contains(_searchQuery) &&
                        !nombreCliente.contains(_searchQuery) &&
                        !placaVehiculo.contains(_searchQuery)) {
                      return false;
                    }
                  }

                  // Filtro por estado
                  if (_filtroEstado != null && orden.estado != _filtroEstado) {
                    return false;
                  }

                  return true;
                }).toList();

                // Ordenar por fecha (más reciente primero)
                ordenesFiltradas.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

                if (ordenesFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _filtroEstado == null
                              ? 'No hay órdenes registradas'
                              : 'No se encontraron órdenes',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty && _filtroEstado == null
                              ? 'Presiona el botón + para crear una orden'
                              : 'Intenta con otros filtros',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ordenesFiltradas.length,
                  itemBuilder: (context, index) {
                    final orden = ordenesFiltradas[index];
                    final cliente = _clientesMap[orden.clienteId];
                    final vehiculo = _vehiculosMap[orden.vehiculoId];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrdenDetailsScreen(
                                ordenInicial: orden,
                                cliente: cliente,
                                vehiculo: vehiculo,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado con ID y estado
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Orden #${orden.id.substring(0, 8)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getEstadoColor(orden.estado).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getEstadoColor(orden.estado),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      orden.estado.displayName,
                                      style: TextStyle(
                                        color: _getEstadoColor(orden.estado),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Información del cliente
                              if (cliente != null)
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${cliente.nombres} ${cliente.apellidos}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6),

                              // Información del vehículo
                              if (vehiculo != null)
                                Row(
                                  children: [
                                    Icon(
                                      vehiculo.tipoVehiculo == TipoVehiculo.CARRO
                                          ? Icons.directions_car
                                          : Icons.two_wheeler,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${vehiculo.placa} - ${vehiculo.marca} ${vehiculo.modelo}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6),

                              // Cantidad de servicios
                              Row(
                                children: [
                                  const Icon(Icons.build, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${orden.detalles.length} servicio(s)',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Footer con total y botones
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Total
                                  Text(
                                    'Total: \$${orden.calcularTotal().toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),

                                  // Botón eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _eliminarOrden(orden),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOrdenScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}


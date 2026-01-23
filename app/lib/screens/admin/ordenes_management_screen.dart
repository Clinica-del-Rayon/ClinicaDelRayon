import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/orden.dart';
import '../../models/usuario.dart';
import '../../models/vehiculo.dart';
import '../create_orden_screen.dart';
import '../orden_details_screen.dart';

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

  // Colores (Personalizar al gusto)
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

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
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey[700], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Gestión Órdenes',
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

            // Search & Filter Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar orden...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<EstadoOrden?>(
                          value: _filtroEstado,
                          isExpanded: true,
                          hint: Text('Estado', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Todos')),
                            ...EstadoOrden.values.map((estado) => DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado.displayName, style: TextStyle(fontSize: 13)),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroEstado = value;
                            });
                          },
                        ),
                      ),
                    ),
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
                    return Center(child: CircularProgressIndicator(color: _primaryColor));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
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
                          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty && _filtroEstado == null
                                ? 'No hay órdenes registradas'
                                : 'No se encontraron órdenes',
                            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
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
                      return _buildOrdenCard(orden);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateOrdenScreen(),
            ),
          );
        },
        backgroundColor: _primaryColor,
        elevation: 4,
         icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nueva Orden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOrdenCard(Orden orden) {
    final cliente = _clientesMap[orden.clienteId];
    final vehiculo = _vehiculosMap[orden.vehiculoId];
    final statusColor = _getEstadoColor(orden.estado);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Orden #${orden.id.substring(0, 8)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        orden.estado.displayName,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: Colors.grey[100]),
                
                // Body: Client and Vehicle
                if (cliente != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person_rounded, size: 16, color: Colors.blueGrey[400]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${cliente.nombres} ${cliente.apellidos}',
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                if (vehiculo != null) ...[
                  Row(
                    children: [
                      Icon(
                        vehiculo.tipoVehiculo == TipoVehiculo.CARRO
                            ? Icons.directions_car_filled_rounded
                            : Icons.two_wheeler_rounded,
                        size: 16,
                        color: Colors.blueGrey[400],
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${vehiculo.placa} - ${vehiculo.marca} ${vehiculo.modelo}',
                          style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
                
                // Services count
                Row(
                  children: [
                    Icon(Icons.checklist_rtl_rounded, size: 16, color: Colors.blueGrey[400]),
                    SizedBox(width: 8),
                    Text(
                      '${orden.detalles.length} servicios',
                      style: TextStyle(fontSize: 13, color: Colors.blueGrey[500]),
                    ),
                  ],
                ),

                SizedBox(height: 16),
                
                // Footer: Total and Delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${orden.calcularTotal().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 22),
                      constraints: BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _eliminarOrden(orden),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


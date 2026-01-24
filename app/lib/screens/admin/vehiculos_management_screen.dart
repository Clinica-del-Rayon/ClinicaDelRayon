import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/vehiculo.dart';
import '../../models/usuario.dart';

class VehiculosManagementScreen extends StatefulWidget {
  const VehiculosManagementScreen({super.key});

  @override
  State<VehiculosManagementScreen> createState() => _VehiculosManagementScreenState();
}

class _VehiculosManagementScreenState extends State<VehiculosManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Vehiculo> _allVehiculos = [];
  List<Vehiculo> _filteredVehiculos = [];
  Map<String, Cliente> _clientesMap = {}; // Para mostrar nombres de clientes
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterVehiculos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar vehículos y clientes en paralelo
      final vehiculos = await _dbService.getAllVehiculos();
      final clientes = await _dbService.getAllClientes();

      // Crear mapa de clientes para acceso rápido
      _clientesMap = {for (var c in clientes) c.uid: c};

      _allVehiculos = vehiculos;
      _filterVehiculos();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar vehículos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterVehiculos() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredVehiculos = _allVehiculos.where((vehiculo) {
        if (query.isEmpty) {
          return true;
        }

        final placa = vehiculo.placa.toLowerCase();
        final marca = vehiculo.marca.toLowerCase();
        final modelo = vehiculo.modelo.toLowerCase();

        // Buscar también por nombre de clientes asociados
        final nombresClientes = vehiculo.clienteIds
            .map((id) => _clientesMap[id])
            .where((c) => c != null)
            .map((c) => '${c!.nombres} ${c.apellidos}'.toLowerCase())
            .join(' ');

        return placa.contains(query) ||
               marca.contains(query) ||
               modelo.contains(query) ||
               nombresClientes.contains(query);
      }).toList();
    });
  }

  Future<void> _eliminarVehiculo(Vehiculo vehiculo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text('¿Eliminar Vehículo?'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el vehículo ${vehiculo.placa}?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _dbService.deleteVehiculo(vehiculo.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehículo eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar vehículo: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
                    'Gestión Vehículos',
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

            // Search Bar (Clean Floating Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                    hintText: 'Buscar por placa, marca, modelo...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            // Lista de vehículos
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primaryColor))
                  : _filteredVehiculos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[300]),
                              SizedBox(height: 16),
                              Text(
                                'No se encontraron vehículos',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 80),
                          itemCount: _filteredVehiculos.length,
                          itemBuilder: (context, index) {
                            return _buildVehiculoCard(_filteredVehiculos[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/select-clientes-vehiculo').then((_) => _loadData());
        },
        backgroundColor: _primaryColor,
        elevation: 4,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Vehículo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildVehiculoCard(Vehiculo vehiculo) {
    // Obtener nombres de clientes asociados
    final nombresClientes = vehiculo.clienteIds
        .map((id) => _clientesMap[id])
        .where((c) => c != null)
        .map((c) => '${c!.nombres} ${c.apellidos}')
        .join(', ');

    final tipoIcon = vehiculo.tipoVehiculo == TipoVehiculo.CARRO
        ? Icons.directions_car_filled
        : Icons.two_wheeler;

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
          onTap: () async {
            await Navigator.pushNamed(
              context,
              '/vehiculo-details',
              arguments: vehiculo.id,
            );
            // Recargar después de ver detalles (por si se editó)
            _loadData();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icono o foto del vehículo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: vehiculo.fotosUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            vehiculo.fotosUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(tipoIcon, size: 28, color: _primaryColor);
                            },
                          ),
                        )
                      : Icon(tipoIcon, size: 28, color: _primaryColor),
                ),
                SizedBox(width: 16),
                
                // Información del vehículo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehiculo.placa,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${vehiculo.marca} ${vehiculo.modelo}',
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey[600]),
                      ),
                      SizedBox(height: 2),
                      Text(
                        nombresClientes.isNotEmpty ? nombresClientes : 'Sin cliente asignado',
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                
                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: Colors.blueGrey[300], size: 20),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/edit-vehiculo',
                          arguments: vehiculo,
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 20),
                      onPressed: () => _eliminarVehiculo(vehiculo),
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


import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/vehiculo.dart';
import '../models/usuario.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículos'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por placa, marca, modelo o cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
            ),
          ),

          // Lista de vehículos
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredVehiculos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron vehículos',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredVehiculos.length,
                        itemBuilder: (context, index) {
                          return _buildVehiculoCard(_filteredVehiculos[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/select-clientes-vehiculo').then((_) => _loadData());
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildVehiculoCard(Vehiculo vehiculo) {
    // Obtener nombres de clientes asociados
    final nombresClientes = vehiculo.clienteIds
        .map((id) => _clientesMap[id])
        .where((c) => c != null)
        .map((c) => '${c!.nombres} ${c!.apellidos}')
        .join(', ');

    final tipoIcon = vehiculo.tipoVehiculo == TipoVehiculo.CARRO
        ? Icons.directions_car
        : Icons.two_wheeler;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navegar a detalles del vehículo
          Navigator.pushNamed(
            context,
            '/vehiculo-details',
            arguments: {
              'vehiculo': vehiculo,
              'clientes': _clientesMap,
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Icono o foto del vehículo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: vehiculo.fotosUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          vehiculo.fotosUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(tipoIcon, size: 30, color: Colors.blue);
                          },
                        ),
                      )
                    : Icon(tipoIcon, size: 30, color: Colors.blue),
              ),
              SizedBox(width: 12),
              // Información del vehículo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehiculo.placa,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${vehiculo.marca} ${vehiculo.modelo} (${vehiculo.generacion})',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      nombresClientes.isNotEmpty ? nombresClientes : 'Sin clientes',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                    icon: Icon(Icons.edit, color: Colors.blue),
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
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarVehiculo(vehiculo),
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


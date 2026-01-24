import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../models/vehiculo.dart';
import '../../services/database_service.dart';
import '../../providers/provider_state.dart';

class ClienteVehiculosScreen extends StatefulWidget {
  const ClienteVehiculosScreen({super.key});

  @override
  State<ClienteVehiculosScreen> createState() => _ClienteVehiculosScreenState();
}

class _ClienteVehiculosScreenState extends State<ClienteVehiculosScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Vehiculo> _vehiculos = [];
  bool _isLoading = false;

  // Modern Color Palette
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadVehiculos();
  }

  Future<void> _loadVehiculos() async {
    setState(() => _isLoading = true);
    try {
      final usuario = Provider.of<ProviderState>(context, listen: false).currentUserData as Cliente;
      final vehiculos = await _dbService.getVehiculosByClienteId(usuario.uid);
      setState(() {
        _vehiculos = vehiculos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar vehículos: ${e.toString()}'),
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
    final usuario = Provider.of<ProviderState>(context).currentUserData as Cliente;

    return Scaffold(
      backgroundColor: _backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/create-vehiculo',
            arguments: {
              'clienteId': usuario.uid,
              'clienteNombre': '${usuario.nombres} ${usuario.apellidos}',
            },
          );
          // Recargar si se creó exitosamente
          if (result == true) {
            _loadVehiculos();
          }
        },
        backgroundColor: _primaryColor,
        icon: Icon(Icons.add),
        label: Text('Nuevo Vehículo'),
      ),
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
                    'Mis Vehículos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: _primaryColor),
                    onPressed: _loadVehiculos,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                      ),
                    )
                  : _vehiculos.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadVehiculos,
                          color: _primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24.0),
                            itemCount: _vehiculos.length,
                            itemBuilder: (context, index) {
                              return _buildVehiculoCard(_vehiculos[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No tienes vehículos registrados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Contacta con un administrador para\nregistrar tu vehículo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculoCard(Vehiculo vehiculo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
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
            _loadVehiculos();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Vehicle Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    size: 32,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(width: 16),

                // Vehicle Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehiculo.placa,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${vehiculo.marca} ${vehiculo.modelo}',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Año ${vehiculo.generacion}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


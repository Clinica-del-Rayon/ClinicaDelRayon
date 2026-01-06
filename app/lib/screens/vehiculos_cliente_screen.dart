import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/database_service.dart';
import '../models/vehiculo.dart';

class VehiculosClienteScreen extends StatefulWidget {
  final String clienteId;
  final String clienteNombre;

  const VehiculosClienteScreen({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  State<VehiculosClienteScreen> createState() => _VehiculosClienteScreenState();
}

class _VehiculosClienteScreenState extends State<VehiculosClienteScreen> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehículos de ${widget.clienteNombre}'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<Vehiculo>>(
        stream: _dbService.vehiculosByClienteStream(widget.clienteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final vehiculos = snapshot.data ?? [];

          if (vehiculos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay vehículos registrados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'para este cliente',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navegarACrearVehiculo(),
                    icon: Icon(Icons.add),
                    label: Text('Registrar Primer Vehículo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehiculos.length,
            itemBuilder: (context, index) {
              return _buildVehiculoCard(vehiculos[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarACrearVehiculo(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Crear Vehículo'),
      ),
    );
  }

  void _navegarACrearVehiculo() {
    Navigator.pushNamed(
      context,
      '/create-vehiculo',
      arguments: {
        'clienteId': widget.clienteId,
        'clienteNombre': widget.clienteNombre,
      },
    );
  }

  Widget _buildVehiculoCard(Vehiculo vehiculo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imágenes del vehículo
          if (vehiculo.fotosUrls.isNotEmpty)
            SizedBox(
              height: 200,
              child: PageView.builder(
                itemCount: vehiculo.fotosUrls.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: vehiculo.fotosUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.error, size: 50),
                    ),
                  );
                },
              ),
            )
          else
            Container(
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car, size: 60, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Sin fotos', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

          // Información del vehículo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vehiculo.descripcion,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildTipoChip(vehiculo.tipoVehiculo),
                  ],
                ),
                SizedBox(height: 12),
                _buildInfoRow(Icons.pin, 'Placa', vehiculo.placa),
                SizedBox(height: 8),
                _buildInfoRow(Icons.palette, 'Color', vehiculo.color),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo_library, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '${vehiculo.fotosUrls.length} foto(s)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    if (!vehiculo.tieneFotosSuficientes) ...[
                      SizedBox(width: 8),
                      Icon(Icons.warning, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Mínimo 3 fotos',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTipoChip(TipoVehiculo tipo) {
    final color = tipo == TipoVehiculo.CARRO ? Colors.blue : Colors.orange;
    final icon = tipo == TipoVehiculo.CARRO
        ? Icons.directions_car
        : Icons.two_wheeler;

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        tipo.displayName,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}


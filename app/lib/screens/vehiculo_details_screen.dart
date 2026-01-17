import 'package:flutter/material.dart';
import '../models/vehiculo.dart';
import '../models/usuario.dart';

class VehiculoDetailsScreen extends StatelessWidget {
  const VehiculoDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Vehiculo vehiculo = args['vehiculo'];
    final Map<String, Cliente> clientesMap = args['clientes'];

    final tipoIcon = vehiculo.tipoVehiculo == TipoVehiculo.CARRO
        ? Icons.directions_car
        : Icons.two_wheeler;

    return Scaffold(
      appBar: AppBar(
        title: Text(vehiculo.placa),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-vehiculo',
                arguments: vehiculo,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galería de fotos
            if (vehiculo.fotosUrls.isNotEmpty)
              Container(
                height: 250,
                child: PageView.builder(
                  itemCount: vehiculo.fotosUrls.length,
                  itemBuilder: (context, index) {
                    return Container(
                      color: Colors.grey[200],
                      child: Image.network(
                        vehiculo.fotosUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(tipoIcon, size: 80, color: Colors.grey),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                color: Colors.grey[200],
                child: Center(
                  child: Icon(tipoIcon, size: 80, color: Colors.grey),
                ),
              ),

            // Indicador de fotos
            if (vehiculo.fotosUrls.length > 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    vehiculo.fotosUrls.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

            // Información del vehículo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placa y tipo
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          vehiculo.placa,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tipoIcon, size: 20, color: Colors.blue.shade900),
                            SizedBox(width: 4),
                            Text(
                              vehiculo.tipoVehiculo.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Información del vehículo
                  _buildSectionTitle('Información del Vehículo'),
                  _buildInfoCard([
                    _buildInfoRow(Icons.branding_watermark, 'Marca', vehiculo.marca),
                    _buildInfoRow(Icons.category, 'Modelo', vehiculo.modelo),
                    _buildInfoRow(Icons.calendar_today, 'Año', vehiculo.generacion.toString()),
                    _buildInfoRow(Icons.palette, 'Color', vehiculo.color),
                  ]),

                  SizedBox(height: 24),

                  // Clientes asociados
                  _buildSectionTitle('Clientes Asociados (${vehiculo.clienteIds.length})'),
                  ...vehiculo.clienteIds.map((clienteId) {
                    final cliente = clientesMap[clienteId];
                    if (cliente == null) {
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text('Cliente no encontrado'),
                          subtitle: Text('ID: $clienteId'),
                        ),
                      );
                    }

                    return Card(
                      elevation: 2,
                      margin: EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          backgroundImage: cliente.fotoPerfil != null
                              ? NetworkImage(cliente.fotoPerfil!)
                              : null,
                          child: cliente.fotoPerfil == null
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        title: Text(
                          '${cliente.nombres} ${cliente.apellidos}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cliente.correo),
                            Text('${cliente.tipoDocumento.name}: ${cliente.numeroDocumento}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // Navegar a detalles del cliente
                          Navigator.pushNamed(
                            context,
                            '/user-details',
                            arguments: cliente,
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 15),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class ClienteHomeScreen extends StatelessWidget {
  final Cliente usuario;
  final AuthService authService;

  const ClienteHomeScreen({
    super.key,
    required this.usuario,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue,
                  backgroundImage: usuario.fotoPerfil != null
                      ? NetworkImage(usuario.fotoPerfil!)
                      : null,
                  child: usuario.fotoPerfil == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Bienvenido!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${usuario.nombres} ${usuario.apellidos}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  usuario.correo,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Cliente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildInfoRow('Tipo de documento:', usuario.tipoDocumento.name),
                        _buildInfoRow('Documento:', usuario.numeroDocumento),
                        _buildInfoRow('Teléfono:', usuario.telefono),
                        _buildInfoRow('Dirección:', usuario.direccion),
                        _buildInfoRow('Calificación:', '${usuario.calificacion.toStringAsFixed(1)} ⭐'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navegar a solicitar servicio
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función próximamente disponible')),
                    );
                  },
                  icon: const Icon(Icons.car_repair),
                  label: const Text('Solicitar Servicio'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}


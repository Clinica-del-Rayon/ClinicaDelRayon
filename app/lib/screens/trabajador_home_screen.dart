import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class TrabajadorHomeScreen extends StatelessWidget {
  final Trabajador usuario;
  final AuthService authService;

  const TrabajadorHomeScreen({
    super.key,
    required this.usuario,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Trabajador'),
        backgroundColor: Colors.orange,
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
                  backgroundColor: Colors.orange,
                  backgroundImage: usuario.fotoPerfil != null
                      ? NetworkImage(usuario.fotoPerfil!)
                      : null,
                  child: usuario.fotoPerfil == null
                      ? const Icon(Icons.engineering, size: 50, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Bienvenido Trabajador!',
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
                if (usuario.area != null)
                  Text(
                    usuario.area!,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
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
                          'Información del Trabajador',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        _buildInfoRow('Documento:', '${usuario.tipoDocumento.name} ${usuario.numeroDocumento}'),
                        _buildInfoRow('Correo:', usuario.correo),
                        _buildInfoRow('Teléfono:', usuario.telefono),
                        if (usuario.area != null)
                          _buildInfoRow('Área:', usuario.area!),
                        if (usuario.sueldo != null)
                          _buildInfoRow('Sueldo:', '\$${usuario.sueldo!.toStringAsFixed(2)}'),
                        if (usuario.estadoDisponibilidad != null)
                          _buildInfoRow('Estado:', usuario.estadoDisponibilidad! ? 'Disponible ✅' : 'No disponible ❌'),
                        _buildInfoRow('Calificación:', '${usuario.calificacion.toStringAsFixed(1)} ⭐'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Ver órdenes asignadas
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función próximamente disponible')),
                    );
                  },
                  icon: const Icon(Icons.assignment),
                  label: const Text('Ver Órdenes Asignadas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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


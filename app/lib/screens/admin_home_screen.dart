import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class AdminHomeScreen extends StatelessWidget {
  final Usuario usuario;
  final AuthService authService;

  const AdminHomeScreen({
    super.key,
    required this.usuario,
    required this.authService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio - Administrador'),
        backgroundColor: Colors.red,
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
                const Icon(
                  Icons.admin_panel_settings,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Bienvenido Administrador!',
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
                const SizedBox(height: 32),

                // Botón Crear Usuario (con selector de tipo)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/select-account-type');
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Crear Usuario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(280, 50),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón Editar Usuarios
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/edit-users');
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar Usuarios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(280, 50),
                  ),
                ),
                const SizedBox(height: 16),

                // Botón Registrar Vehículos
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/clientes-list');
                  },
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Registrar Vehículos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(280, 50),
                  ),
                ),
                const SizedBox(height: 24),

                // Botones secundarios
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Ver lista de trabajadores
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función próximamente disponible')),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Ver Trabajadores'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(280, 50),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Ver lista de clientes
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Función próximamente disponible')),
                    );
                  },
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Ver Clientes'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    minimumSize: const Size(280, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


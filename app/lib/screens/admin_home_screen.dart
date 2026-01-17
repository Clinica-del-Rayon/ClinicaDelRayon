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

                // Botón Usuarios
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/usuarios-management');
                  },
                  icon: const Icon(Icons.people, size: 32),
                  label: const Text('Usuarios', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                    minimumSize: const Size(280, 70),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Vehículos
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/vehiculos-management');
                  },
                  icon: const Icon(Icons.directions_car, size: 32),
                  label: const Text('Vehículos', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                    minimumSize: const Size(280, 70),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Servicios
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/servicios-management');
                  },
                  icon: const Icon(Icons.miscellaneous_services, size: 32),
                  label: const Text('Servicios', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                    minimumSize: const Size(280, 70),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Órdenes
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/ordenes-management');
                  },
                  icon: const Icon(Icons.receipt_long, size: 32),
                  label: const Text('Órdenes', style: TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 24,
                    ),
                    minimumSize: const Size(280, 70),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


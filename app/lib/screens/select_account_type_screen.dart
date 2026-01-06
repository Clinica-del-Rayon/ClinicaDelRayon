import 'package:flutter/material.dart';
import '../models/usuario.dart';

class SelectAccountTypeScreen extends StatelessWidget {
  const SelectAccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Usuario'),
        backgroundColor: Colors.red,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.person_add,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                '¿Qué tipo de cuenta deseas crear?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),

              // Botón Cliente
              _buildAccountTypeButton(
                context,
                icon: Icons.person,
                title: 'Cliente',
                subtitle: 'Usuario que solicita servicios',
                color: Colors.blue,
                rol: RolUsuario.CLIENTE,
              ),
              const SizedBox(height: 16),

              // Botón Trabajador
              _buildAccountTypeButton(
                context,
                icon: Icons.engineering,
                title: 'Trabajador',
                subtitle: 'Mecánico, pintor, etc.',
                color: Colors.orange,
                rol: RolUsuario.TRABAJADOR,
              ),
              const SizedBox(height: 16),

              // Botón Admin
              _buildAccountTypeButton(
                context,
                icon: Icons.admin_panel_settings,
                title: 'Administrador',
                subtitle: 'Control total del sistema',
                color: Colors.red,
                rol: RolUsuario.ADMIN,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTypeButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required RolUsuario rol,
  }) {
    return ElevatedButton(
      onPressed: () {
        // Navegar a la pantalla de creación correspondiente
        String route;
        switch (rol) {
          case RolUsuario.CLIENTE:
            route = '/create-cliente';
            break;
          case RolUsuario.TRABAJADOR:
            route = '/create-trabajador';
            break;
          case RolUsuario.ADMIN:
            route = '/create-admin';
            break;
        }

        Navigator.pushNamed(context, route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white),
        ],
      ),
    );
  }
}


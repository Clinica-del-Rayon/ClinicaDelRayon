import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart' as models;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return FutureBuilder<models.Usuario?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final usuario = snapshot.data;

        if (usuario == null) {
          return const Scaffold(
            body: Center(
              child: Text('No se encontraron datos del usuario'),
            ),
          );
        }

        // Mostrar pantalla según el rol
        switch (usuario.rol) {
          case models.RolUsuario.CLIENTE:
            return _ClienteHomeScreen(usuario: usuario as models.Cliente, authService: authService);
          case models.RolUsuario.TRABAJADOR:
            return _TrabajadorHomeScreen(usuario: usuario as models.Trabajador, authService: authService);
          case models.RolUsuario.ADMIN:
            return _AdminHomeScreen(usuario: usuario, authService: authService);
        }
      },
    );
  }
}

// Pantalla para clientes
class _ClienteHomeScreen extends StatelessWidget {
  final models.Cliente usuario;
  final AuthService authService;

  const _ClienteHomeScreen({
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

// Pantalla para trabajadores
class _TrabajadorHomeScreen extends StatelessWidget {
  final models.Trabajador usuario;
  final AuthService authService;

  const _TrabajadorHomeScreen({
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
                Text(
                  usuario.area,
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
                        _buildInfoRow('Área:', usuario.area),
                        _buildInfoRow('Sueldo:', '\$${usuario.sueldo.toStringAsFixed(2)}'),
                        _buildInfoRow('Estado:', usuario.estadoDisponibilidad ? 'Disponible ✅' : 'No disponible ❌'),
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

// Pantalla para administradores
class _AdminHomeScreen extends StatelessWidget {
  final models.Usuario usuario;
  final AuthService authService;

  const _AdminHomeScreen({
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
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/register-trabajador');
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Crear Nuevo Trabajador'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


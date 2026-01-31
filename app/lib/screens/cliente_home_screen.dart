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
    // Consistent Colors matching Admin Design
    final Color primaryBlue = const Color(0xFF1E88E5);
    final Color backgroundColor = const Color(0xFFF5F7FA);
    final Color darkText = const Color(0xFF263238);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.logout_rounded, color: Colors.grey[400]),
                    onPressed: () async => await authService.signOut(),
                  ),
                ],
              ),
            ),

            // Profile Header (Avatar + Text)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Large Avatar
                  CircleAvatar(
                    key: ValueKey(usuario.fotoPerfil ?? 'no-photo'), // Fuerza actualización
                    radius: 35,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: usuario.fotoPerfil != null
                        ? NetworkImage(usuario.fotoPerfil!)
                        : null,
                    child: usuario.fotoPerfil == null
                        ? Text(
                            usuario.nombres.isNotEmpty ? usuario.nombres[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),

                  SizedBox(width: 20),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola,',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          usuario.nombres.split(' ')[0], // First name
                          style: TextStyle(
                            fontSize: 32,
                            color: darkText,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '¿Qué deseas hacer hoy?',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Grid de Opciones
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.count(
                  physics: BouncingScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.0, // Ajustado para dar más altura
                  children: [
                    _buildClientCard(
                      context,
                      title: 'Solicitudes',
                      subtitle: 'Nueva solicitud',
                      icon: Icons.schedule_send_rounded,
                      color: primaryBlue,
                      route: '/cliente-solicitudes',
                    ),
                    _buildClientCard(
                      context,
                      title: 'Mis Datos',
                      subtitle: 'Editar perfil',
                      icon: Icons.person_outline_rounded,
                      color: Colors.teal[600]!,
                      route: '/cliente-editar-datos',
                    ),
                    _buildClientCard(
                      context,
                      title: 'Mis Vehículos',
                      subtitle: 'Ver vehículos',
                      icon: Icons.directions_car_filled_rounded,
                      color: Colors.orange[700]!,
                      route: '/cliente-vehiculos',
                    ),
                    _buildClientCard(
                      context,
                      title: 'Mis Órdenes',
                      subtitle: 'Estado de órdenes',
                      icon: Icons.assignment_outlined,
                      color: Colors.purple[600]!,
                      route: '/cliente-ordenes',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required String route,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            if (route == '/cliente-solicitudes') {
              Navigator.pushNamed(
                context,
                route,
                arguments: {'cliente': usuario},
              );
            } else {
              Navigator.pushNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[400],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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


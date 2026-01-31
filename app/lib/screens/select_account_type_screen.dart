import 'package:flutter/material.dart';
import '../models/usuario.dart';

class SelectAccountTypeScreen extends StatelessWidget {
  const SelectAccountTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1E88E5);
    final Color backgroundColor = const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey[700], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Crear Usuario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),

                    // Ícono decorativo
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.person_add_rounded,
                          size: 60,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),

                    Text(
                      '¿Qué tipo de cuenta\ndeseas crear?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Selecciona el rol del nuevo usuario',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 48),

                    // Tarjetas de selección
                    _buildModernAccountCard(
                      context,
                      icon: Icons.person_outline_rounded,
                      title: 'Cliente',
                      subtitle: 'Usuario que solicita servicios',
                      color: Colors.blue[600]!,
                      rol: RolUsuario.CLIENTE,
                    ),
                    SizedBox(height: 16),

                    _buildModernAccountCard(
                      context,
                      icon: Icons.engineering_outlined,
                      title: 'Trabajador',
                      subtitle: 'Mecánico, técnico o pintor',
                      color: Colors.orange[600]!,
                      rol: RolUsuario.TRABAJADOR,
                    ),
                    SizedBox(height: 16),

                    _buildModernAccountCard(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Administrador',
                      subtitle: 'Control total del sistema',
                      color: Colors.red[600]!,
                      rol: RolUsuario.ADMIN,
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

  Widget _buildModernAccountCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required RolUsuario rol,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
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


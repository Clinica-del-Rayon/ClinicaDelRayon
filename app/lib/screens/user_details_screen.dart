import 'package:flutter/material.dart';
import '../models/usuario.dart';

class UserDetailsScreen extends StatelessWidget {
  const UserDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = ModalRoute.of(context)!.settings.arguments as Usuario;

    Color roleColor;
    IconData roleIcon;
    String roleText;

    switch (usuario.rol) {
      case RolUsuario.ADMIN:
        roleColor = Colors.red;
        roleIcon = Icons.admin_panel_settings;
        roleText = 'Administrador';
        break;
      case RolUsuario.TRABAJADOR:
        roleColor = Colors.orange;
        roleIcon = Icons.engineering;
        roleText = 'Trabajador';
        break;
      case RolUsuario.CLIENTE:
        roleColor = Colors.blue;
        roleIcon = Icons.person;
        roleText = 'Cliente';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Usuario'),
        backgroundColor: roleColor,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-user',
                arguments: usuario,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con foto y nombre
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: roleColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: usuario.fotoPerfil != null
                        ? NetworkImage(usuario.fotoPerfil!)
                        : null,
                    child: usuario.fotoPerfil == null
                        ? Icon(roleIcon, size: 60, color: roleColor)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${usuario.nombres} ${usuario.apellidos}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Información detallada
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información personal
                  _buildSectionTitle('Información Personal'),
                  _buildInfoCard([
                    _buildInfoRow(Icons.badge, 'Documento', '${usuario.tipoDocumento.name} ${usuario.numeroDocumento}'),
                    _buildInfoRow(Icons.email, 'Correo', usuario.correo),
                    _buildInfoRow(Icons.phone, 'Teléfono', usuario.telefono),
                    _buildInfoRow(Icons.star, 'Calificación', '${usuario.calificacion.toStringAsFixed(1)} ⭐'),
                  ]),

                  // Información específica según el rol
                  if (usuario is Cliente) ...[
                    SizedBox(height: 24),
                    _buildSectionTitle('Información del Cliente'),
                    _buildInfoCard([
                      _buildInfoRow(Icons.home, 'Dirección', (usuario as Cliente).direccion),
                      _buildInfoRow(Icons.calendar_today, 'Fecha de Registro',
                        _formatDate((usuario as Cliente).fechaRegistro)),
                    ]),
                  ],

                  if (usuario is Trabajador) ...[
                    SizedBox(height: 24),
                    _buildSectionTitle('Información Laboral'),
                    _buildInfoCard([
                      if ((usuario as Trabajador).area != null)
                        _buildInfoRow(Icons.work, 'Área', (usuario as Trabajador).area!),
                      if ((usuario as Trabajador).sueldo != null)
                        _buildInfoRow(Icons.attach_money, 'Sueldo', '\$${(usuario as Trabajador).sueldo!.toStringAsFixed(2)}'),
                      if ((usuario as Trabajador).estadoDisponibilidad != null)
                        _buildInfoRow(Icons.check_circle, 'Estado',
                          (usuario as Trabajador).estadoDisponibilidad! ? 'Disponible ✅' : 'No disponible ❌'),
                    ]),
                  ],
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
          Icon(icon, size: 24, color: Colors.purple),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}


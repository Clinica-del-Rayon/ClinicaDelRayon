import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../../services/database_service.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late Usuario _usuario;
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();

  // Colors
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize user from arguments if not already set (to prevent overwrite on rebuilds if we want persistance, 
    // but here we want to load initial arg. We'll handle updates via _refreshUser)
    // Note: If we want to strictly respect the argument only entering, we can check a flag. 
    // But simplest is to grab it. *However*, since we update _usuario locally, we should be careful.
    // Actually, best pattern: grab arg once.
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Usuario;
      // Only set if not set yet, OR if we rely on this being the *initial* state.
      // We'll rely on _usuario being the source of truth.
      _usuario = args; 
    } catch (_) {}
  }

  Future<void> _refreshUser() async {
    setState(() => _isLoading = true);
    try {
      final updatedUser = await _dbService.getUsuario(_usuario.uid);
      if (updatedUser != null) {
        setState(() => _usuario = updatedUser);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar datos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color roleColor;
    String roleText;

    switch (_usuario.rol) {
      case RolUsuario.ADMIN:
        roleColor = Colors.redAccent;
        roleText = 'Administrador';
        break;
      case RolUsuario.TRABAJADOR:
        roleColor = Colors.orange;
        roleText = 'Trabajador';
        break;
      case RolUsuario.CLIENTE:
        roleColor = Colors.green;
        roleText = 'Cliente';
        break;
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey[700]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(Icons.edit_rounded, color: _primaryColor, size: 20),
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/edit-user',
                arguments: _usuario,
              );
              if (result == true) {
                _refreshUser();
              }
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _primaryColor))
        : SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                // Minimalist Header
                Center(
                  child: Column(
                    children: [
                      Hero(
                        tag: 'avatar_${_usuario.uid}',
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage: _usuario.fotoPerfil != null
                              ? NetworkImage(_usuario.fotoPerfil!)
                              : null,
                          child: _usuario.fotoPerfil == null
                              ? Text(
                                  _usuario.nombres.isNotEmpty ? _usuario.nombres[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                )
                              : null,
                          // Add shadow
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '${_usuario.nombres} ${_usuario.apellidos}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[900],
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleText.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40),

                // Info Sections
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Información Personal'),
                      _buildInfoCard([
                        _buildInfoRow(Icons.badge_outlined, 'Documento', '${_usuario.tipoDocumento.name} ${_usuario.numeroDocumento}'),
                        _buildInfoRow(Icons.email_outlined, 'Correo', _usuario.correo),
                        _buildInfoRow(Icons.phone_outlined, 'Teléfono', _usuario.telefono),
                        _buildInfoRow(Icons.star_outline_rounded, 'Calificación', '${_usuario.calificacion.toStringAsFixed(1)} ⭐'),
                      ]),

                      if (_usuario is Cliente) ...[
                        SizedBox(height: 24),
                        _buildSectionTitle('Datos de Cliente'),
                        _buildInfoCard([
                          _buildInfoRow(Icons.location_on_outlined, 'Dirección', (_usuario as Cliente).direccion),
                          _buildInfoRow(Icons.calendar_today_outlined, 'Registro',
                            _formatDate((_usuario as Cliente).fechaRegistro)),
                        ]),
                      ],

                      if (_usuario is Trabajador) ...[
                        SizedBox(height: 24),
                        _buildSectionTitle('Datos de Trabajador'),
                        _buildInfoCard([
                          if ((_usuario as Trabajador).area != null)
                            _buildInfoRow(Icons.work_outline, 'Área', (_usuario as Trabajador).area!),
                          if ((_usuario as Trabajador).sueldo != null)
                            _buildInfoRow(Icons.attach_money, 'Sueldo', '\$${(_usuario as Trabajador).sueldo!.toStringAsFixed(2)}'),
                          if ((_usuario as Trabajador).estadoDisponibilidad != null)
                            _buildInfoRow(Icons.check_circle_outline, 'Disponibilidad',
                              (_usuario as Trabajador).estadoDisponibilidad! ? 'Disponible' : 'No disponible',
                              color: (_usuario as Trabajador).estadoDisponibilidad! ? Colors.green : Colors.red),
                        ]),
                      ],
                      SizedBox(height: 40),
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
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blueGrey[400],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? _primaryColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color ?? _primaryColor),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[300],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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


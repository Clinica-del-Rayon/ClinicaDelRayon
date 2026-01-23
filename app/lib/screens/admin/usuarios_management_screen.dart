import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart'; // Keep if AuthService is used elsewhere, otherwise remove.
import '../../models/usuario.dart';
import '../../providers/provider_state.dart';

class UsuariosManagementScreen extends StatefulWidget {
  const UsuariosManagementScreen({super.key});

  @override
  State<UsuariosManagementScreen> createState() => _UsuariosManagementScreenState();
}

class _UsuariosManagementScreenState extends State<UsuariosManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService(); // Keep if AuthService is used elsewhere, otherwise remove.
  final TextEditingController _searchController = TextEditingController();

  // _allUsers and _filteredUsers are now managed by ProviderState and calculated in build
  bool _isLoading = false; // Initial state, will be set to true by _refreshUsers
  RolUsuario? _filtroRol; // null = todos

  // Modern Color Palette
  final Color _primaryColor = const Color(0xFF1E88E5); // Matches Admin Screen
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshUsers(); // Initial load using the provider
    });
    _searchController.addListener(() => setState(() {})); // Rebuild to filter on search text change
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    setState(() => _isLoading = true);
    await Provider.of<ProviderState>(context, listen: false).fetchAllUsers();
    setState(() => _isLoading = false);
  }

  Future<void> _confirmDelete(Usuario user) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('¿Eliminar Usuario?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${user.nombres} ${user.apellidos}?\n\nEsta acción no se puede deshacer.',
          style: TextStyle(color: Colors.grey[800]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _dbService.deleteUsuario(user.uid); // Use _dbService directly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario eliminado exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshUsers(); // Refresh users after deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el provider
    final provider = Provider.of<ProviderState>(context);
    
    // Si la lista del provider cambió (y no estamos buscando/filtrando activamente), 
    // podríamos querer actualizar _filteredUsers. 
    // Una forma simple es llamar a _filterUsers() al inicio del build si no hay busqueda,
    // o usar un Consumer. Pero aquí, como _filterUsers actualiza el state local, 
    // lo mejor es recalcular el filtrado cuando el provider notifica.
    // Sin embargo, setState dentro de build es malo.
    // Estrategia: Usar directamente la lista del provider para calcular filtrado en el build 
    // O usar un useEffect/listen.
    // Para simplificar: Calculamos la lista filtrada "on the fly" en el build o usamos un listener.
    // Vamos a calcularla aquí para asegurar consistencia inmediata.
    
    final allUsers = provider.allUsers;
    final query = _searchController.text.toLowerCase();
    
    final usersToShow = allUsers.where((user) {
        final matchesSearch = 
            user.nombres.toLowerCase().contains(query) ||
            user.apellidos.toLowerCase().contains(query) ||
            user.numeroDocumento.toLowerCase().contains(query) || // Ensure document number is also searched
            user.correo.toLowerCase().contains(query); // Also search by email
        
        final matchesRol = _filtroRol == null || user.rol == _filtroRol;

        return matchesSearch && matchesRol;
    }).toList();


    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Minimalist Custom AppBar
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
                    'Gestión Usuarios',
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

            // Search & Filter Area (Clean Floating Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}), // Rebuild para filtrar
                        decoration: InputDecoration(
                          hintText: 'Buscar...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RolUsuario?>(
                          value: _filtroRol,
                          hint: Text('Rol', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
                          items: [
                            DropdownMenuItem(value: null, child: Text('Todos')),
                            DropdownMenuItem(value: RolUsuario.ADMIN, child: Text('Admin')),
                            DropdownMenuItem(value: RolUsuario.TRABAJADOR, child: Text('Trabajador')),
                            DropdownMenuItem(value: RolUsuario.CLIENTE, child: Text('Cliente')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _filtroRol = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primaryColor))
                  : usersToShow.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                              SizedBox(height: 16),
                              Text(
                                'No se encontraron usuarios',
                                style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 80),
                          itemCount: usersToShow.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(usersToShow[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/select-account-type').then((_) => _refreshUsers());
        },
        backgroundColor: _primaryColor,
        elevation: 4,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Usuario', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUserCard(Usuario user) {
    Color roleColor;
    String roleText;

    switch (user.rol) {
      case RolUsuario.ADMIN:
        roleColor = Colors.redAccent;
        roleText = 'Admin';
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

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
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
            Navigator.pushNamed(
              context,
              '/user-details',
              arguments: user,
            ).then((_) => _refreshUsers());
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${user.uid}',
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: user.fotoPerfil != null
                        ? NetworkImage(user.fotoPerfil!)
                        : null,
                    child: user.fotoPerfil == null
                        ? Text(
                            user.nombres.isNotEmpty ? user.nombres[0].toUpperCase() : '?',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey[400]),
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.nombres} ${user.apellidos}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        user.correo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roleText,
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: Colors.grey[400]), // Botón de eliminar
                  onPressed: () => _confirmDelete(user),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


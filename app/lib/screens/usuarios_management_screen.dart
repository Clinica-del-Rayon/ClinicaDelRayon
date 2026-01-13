import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class UsuariosManagementScreen extends StatefulWidget {
  const UsuariosManagementScreen({super.key});

  @override
  State<UsuariosManagementScreen> createState() => _UsuariosManagementScreenState();
}

class _UsuariosManagementScreenState extends State<UsuariosManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<Usuario> _allUsers = [];
  List<Usuario> _filteredUsers = [];
  bool _isLoading = true;
  RolUsuario? _filtroRol; // null = todos

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _isLoading = true);

    try {
      final clientes = await _dbService.getAllClientes();
      final trabajadores = await _dbService.getAllTrabajadores();

      _allUsers = [...clientes, ...trabajadores];
      _filterUsers();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar usuarios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Filtro por rol
        if (_filtroRol != null && user.rol != _filtroRol) {
          return false;
        }

        // Filtro por búsqueda
        if (query.isEmpty) {
          return true;
        }

        final nombreCompleto = '${user.nombres} ${user.apellidos}'.toLowerCase();
        final documento = user.numeroDocumento.toLowerCase();
        final correo = user.correo.toLowerCase();

        return nombreCompleto.contains(query) ||
               documento.contains(query) ||
               correo.contains(query);
      }).toList();
    });
  }

  Future<void> _eliminarUsuario(Usuario usuario) async {
    // Confirmar eliminación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 30),
            SizedBox(width: 10),
            Text('¿Eliminar Usuario?'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${usuario.nombres} ${usuario.apellidos}?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // TODO: Implementar eliminación de usuario en AuthService y DatabaseService
      await _dbService.deleteUsuario(usuario.uid);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      _loadAllUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar usuario: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Barra de búsqueda y filtro
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Barra de búsqueda
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, documento o correo...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Filtro por rol
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<RolUsuario?>(
                    value: _filtroRol,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    hint: Text('Rol', style: TextStyle(fontSize: 14)),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: RolUsuario.ADMIN, child: Text('Admin')),
                      DropdownMenuItem(value: RolUsuario.TRABAJADOR, child: Text('Trabajador')),
                      DropdownMenuItem(value: RolUsuario.CLIENTE, child: Text('Cliente')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroRol = value;
                        _filterUsers();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No se encontraron usuarios',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_filteredUsers[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/select-account-type').then((_) => _loadAllUsers());
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildUserCard(Usuario usuario) {
    Color roleColor;
    IconData roleIcon;
    String roleText;

    switch (usuario.rol) {
      case RolUsuario.ADMIN:
        roleColor = Colors.red;
        roleIcon = Icons.admin_panel_settings;
        roleText = 'ADMIN';
        break;
      case RolUsuario.TRABAJADOR:
        roleColor = Colors.orange;
        roleIcon = Icons.engineering;
        roleText = 'TRABAJADOR';
        break;
      case RolUsuario.CLIENTE:
        roleColor = Colors.blue;
        roleIcon = Icons.person;
        roleText = 'CLIENTE';
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navegar a detalles del usuario
          Navigator.pushNamed(
            context,
            '/user-details',
            arguments: usuario,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar con foto de perfil o icono
              CircleAvatar(
                radius: 30,
                backgroundColor: roleColor,
                backgroundImage: usuario.fotoPerfil != null
                    ? NetworkImage(usuario.fotoPerfil!)
                    : null,
                child: usuario.fotoPerfil == null
                    ? Icon(roleIcon, color: Colors.white, size: 30)
                    : null,
              ),
              SizedBox(width: 12),
              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${usuario.nombres} ${usuario.apellidos}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            roleText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            usuario.correo,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${usuario.tipoDocumento.name}: ${usuario.numeroDocumento}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.purple),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/edit-user',
                        arguments: usuario,
                      );
                      if (result == true) {
                        _loadAllUsers();
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _eliminarUsuario(usuario),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


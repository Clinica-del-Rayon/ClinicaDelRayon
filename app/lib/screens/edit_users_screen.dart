import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/usuario.dart';

class EditUsersScreen extends StatefulWidget {
  const EditUsersScreen({super.key});

  @override
  State<EditUsersScreen> createState() => _EditUsersScreenState();
}

class _EditUsersScreenState extends State<EditUsersScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Usuario> _allUsers = [];
  List<Usuario> _filteredUsers = [];
  bool _isLoading = true;

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
      // Cargar todos los usuarios de todos los roles
      final clientes = await _dbService.getAllClientes();
      final trabajadores = await _dbService.getAllTrabajadores();

      _allUsers = [...clientes, ...trabajadores];
      _filteredUsers = _allUsers;

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
        final nombreCompleto = '${user.nombres} ${user.apellidos}'.toLowerCase();
        final documento = user.numeroDocumento.toLowerCase();
        final correo = user.correo.toLowerCase();

        return nombreCompleto.contains(query) ||
               documento.contains(query) ||
               correo.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuarios'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, documento o correo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Lista de usuarios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No hay usuarios registrados'
                                  : 'No se encontraron usuarios',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllUsers,
                        child: ListView.builder(
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final usuario = _filteredUsers[index];
                            return _buildUserCard(usuario);
                          },
                        ),
                      ),
          ),
        ],
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor,
          child: Icon(roleIcon, color: Colors.white),
        ),
        title: Text(
          '${usuario.nombres} ${usuario.apellidos}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    roleText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    usuario.correo,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${usuario.tipoDocumento.name}: ${usuario.numeroDocumento}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: const Icon(Icons.edit, color: Colors.purple),
        onTap: () {
          // Navegar a pantalla de edición según el rol
          Navigator.pushNamed(
            context,
            '/edit-user',
            arguments: usuario,
          );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/usuario.dart';

class ClientesListScreen extends StatefulWidget {
  const ClientesListScreen({super.key});

  @override
  State<ClientesListScreen> createState() => _ClientesListScreenState();
}

class _ClientesListScreenState extends State<ClientesListScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Cliente> _todosClientes = [];
  List<Cliente> _clientesFiltrados = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);

    try {
      final clientes = await _dbService.getAllClientes();
      setState(() {
        _todosClientes = clientes;
        _clientesFiltrados = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filtrarClientes(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();

      if (_searchQuery.isEmpty) {
        _clientesFiltrados = _todosClientes;
      } else {
        _clientesFiltrados = _todosClientes.where((cliente) {
          final nombreCompleto =
              '${cliente.nombres} ${cliente.apellidos}'.toLowerCase();
          final documento = cliente.numeroDocumento.toLowerCase();

          return nombreCompleto.contains(_searchQuery) ||
              documento.contains(_searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Cliente'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Buscador
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarClientes,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o documento...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarClientes('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // Lista de clientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clientesFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay clientes registrados'
                                  : 'No se encontraron clientes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargarClientes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _clientesFiltrados.length,
                          itemBuilder: (context, index) {
                            final cliente = _clientesFiltrados[index];
                            return _buildClienteCard(cliente);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard(Cliente cliente) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          backgroundImage: cliente.fotoPerfil != null
              ? NetworkImage(cliente.fotoPerfil!)
              : null,
          child: cliente.fotoPerfil == null
              ? Text(
                  cliente.nombres[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          '${cliente.nombres} ${cliente.apellidos}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('${cliente.tipoDocumento.name}: ${cliente.numeroDocumento}'),
              ],
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.home, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cliente.direccion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar a pantalla de vehículos del cliente
          Navigator.pushNamed(
            context,
            '/vehiculos-cliente',
            arguments: {
              'clienteId': cliente.uid,
              'clienteNombre': '${cliente.nombres} ${cliente.apellidos}',
            },
          );
        },
      ),
    );
  }
}


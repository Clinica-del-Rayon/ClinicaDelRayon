import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/usuario.dart';

class SelectClientesVehiculoScreen extends StatefulWidget {
  const SelectClientesVehiculoScreen({super.key});

  @override
  State<SelectClientesVehiculoScreen> createState() => _SelectClientesVehiculoScreenState();
}

class _SelectClientesVehiculoScreenState extends State<SelectClientesVehiculoScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Cliente> _todosClientes = [];
  List<String> _clientesSeleccionados = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    try {
      final clientes = await _dbService.getAllClientes();
      setState(() {
        _todosClientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar clientes: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleCliente(String clienteId) {
    setState(() {
      if (_clientesSeleccionados.contains(clienteId)) {
        _clientesSeleccionados.remove(clienteId);
      } else {
        _clientesSeleccionados.add(clienteId);
      }
    });
  }

  void _continuar() {
    if (_clientesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes seleccionar al menos un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navegar a crear vehículo con los clientes seleccionados
    Navigator.pushNamed(
      context,
      '/create-vehiculo-multi',
      arguments: _clientesSeleccionados,
    ).then((_) {
      // Volver a la pantalla anterior cuando termine
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Clientes'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con instrucciones
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona los clientes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Puedes seleccionar uno o más clientes para este vehículo',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${_clientesSeleccionados.length} cliente(s) seleccionado(s)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _clientesSeleccionados.isEmpty
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de clientes
                Expanded(
                  child: _todosClientes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay clientes registrados',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _todosClientes.length,
                          itemBuilder: (context, index) {
                            final cliente = _todosClientes[index];
                            final isSelected = _clientesSeleccionados.contains(cliente.uid);

                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              elevation: isSelected ? 4 : 1,
                              color: isSelected ? Colors.blue.shade50 : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isSelected,
                                onChanged: (_) => _toggleCliente(cliente.uid),
                                secondary: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  backgroundImage: cliente.fotoPerfil != null
                                      ? NetworkImage(cliente.fotoPerfil!)
                                      : null,
                                  child: cliente.fotoPerfil == null
                                      ? Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                title: Text(
                                  '${cliente.nombres} ${cliente.apellidos}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(cliente.correo),
                                    Text(
                                      '${cliente.tipoDocumento.name}: ${cliente.numeroDocumento}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Botón continuar
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _continuar,
                    icon: Icon(Icons.arrow_forward),
                    label: Text(
                      'Continuar con ${_clientesSeleccionados.length} cliente(s)',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}


import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/orden.dart';
import '../servicio_details_screen.dart';
import '../create_servicio_screen.dart';
import '../edit_servicio_screen.dart';

class ServiciosManagementScreen extends StatefulWidget {
  const ServiciosManagementScreen({super.key});

  @override
  State<ServiciosManagementScreen> createState() => _ServiciosManagementScreenState();
}

class _ServiciosManagementScreenState extends State<ServiciosManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteServicio(String id, String nombre) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el servicio "$nombre"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _dbService.deleteServicio(id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Servicio "$nombre" eliminado exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar servicio: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Colores (Personalizar al gusto)
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
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
                    'Gestión Servicios',
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

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                  decoration: InputDecoration(
                    hintText: 'Buscar servicio...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
            ),

            // Lista de servicios
            Expanded(
              child: StreamBuilder<List<Servicio>>(
                stream: _dbService.getServiciosStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: _primaryColor));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)),
                    );
                  }

                  final servicios = snapshot.data ?? [];

                  // Filtrar servicios según búsqueda
                  final serviciosFiltrados = servicios.where((servicio) {
                    final nombre = servicio.nombre.toLowerCase();
                    final descripcion = (servicio.descripcion ?? '').toLowerCase();
                    return nombre.contains(_searchQuery) || descripcion.contains(_searchQuery);
                  }).toList();

                  if (serviciosFiltrados.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.miscellaneous_services_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No hay servicios registrados'
                                : 'No se encontraron servicios',
                            style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 80),
                    itemCount: serviciosFiltrados.length,
                    itemBuilder: (context, index) {
                      final servicio = serviciosFiltrados[index];
                      return _buildServicioCard(servicio);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateServicioScreen(),
            ),
          );
        },
        backgroundColor: _primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Servicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildServicioCard(Servicio servicio) {
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServicioDetailsScreen(servicio: servicio),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.miscellaneous_services_rounded, color: _primaryColor, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicio.nombre,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      if (servicio.descripcion != null && servicio.descripcion!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          servicio.descripcion!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                      SizedBox(height: 8),
                      Row(
                        children: [
                          if (servicio.precioEstimado != null) ...[
                            Icon(Icons.attach_money_rounded, size: 14, color: Colors.green[600]),
                            Text(
                              '${servicio.precioEstimado!.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          if (servicio.duracionEstimada != null) ...[
                            Icon(Icons.schedule_rounded, size: 14, color: Colors.blueGrey[400]),
                            SizedBox(width: 4),
                            Text(
                              '${servicio.duracionEstimada!} ${servicio.duracionEstimada! == 1 ? 'hr' : 'hrs'}',
                              style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded, color: Colors.blueGrey[300], size: 20),
                      onPressed: () async {
                         await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditServicioScreen(servicio: servicio),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 20),
                      onPressed: () => _deleteServicio(servicio.id, servicio.nombre),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


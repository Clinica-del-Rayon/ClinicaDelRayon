import 'package:flutter/material.dart';
import '../models/orden.dart';
import '../models/usuario.dart';
import '../models/vehiculo.dart';
import '../services/database_service.dart';
import 'edit_orden_screen.dart';
import 'avances_servicio_screen.dart';

class OrdenDetailsScreen extends StatefulWidget {
  final Orden ordenInicial;
  final Cliente? cliente;
  final Vehiculo? vehiculo;

  const OrdenDetailsScreen({
    super.key,
    required this.ordenInicial,
    this.cliente,
    this.vehiculo,
  });

  @override
  State<OrdenDetailsScreen> createState() => _OrdenDetailsScreenState();
}

class _OrdenDetailsScreenState extends State<OrdenDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Orden orden;
  Cliente? cliente;
  Vehiculo? vehiculo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    orden = widget.ordenInicial;
    cliente = widget.cliente;
    vehiculo = widget.vehiculo;
  }

  Future<void> _recargarOrden() async {
    setState(() => _isLoading = true);
    try {
      final ordenActualizada = await _dbService.getOrden(orden.id);
      if (ordenActualizada != null && mounted) {
        setState(() {
          orden = ordenActualizada;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getEstadoColor(EstadoOrden estado) {
    switch (estado) {
      case EstadoOrden.EN_COTIZACION:
        return Colors.orange;
      case EstadoOrden.COTIZACION_RESERVA:
        return Colors.amber;
      case EstadoOrden.EN_PROCESO:
        return Colors.blue;
      case EstadoOrden.FINALIZADO:
        return Colors.green;
      case EstadoOrden.ENTREGADO:
        return Colors.grey;
    }
  }

  Color _getEstadoServicioColor(EstadoServicio estado) {
    switch (estado) {
      case EstadoServicio.PENDIENTE:
        return Colors.orange;
      case EstadoServicio.TRABAJANDO:
        return Colors.blue;
      case EstadoServicio.LISTO:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orden #${orden.id.substring(0, 8)}'),
        backgroundColor: Colors.teal,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditOrdenScreen(orden: orden),
                  ),
                );
                // Recargar si hubo cambios
                if (resultado == true) {
                  await _recargarOrden();
                }
              },
              tooltip: 'Editar Orden',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getEstadoColor(orden.estado).withOpacity(0.1),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: _getEstadoColor(orden.estado),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Orden #${orden.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(orden.estado),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      orden.estado.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del Cliente
                  const Text(
                    'Cliente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (cliente != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  backgroundImage: cliente!.fotoPerfil != null
                                      ? NetworkImage(cliente!.fotoPerfil!)
                                      : null,
                                  child: cliente!.fotoPerfil == null
                                      ? const Icon(Icons.person, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${cliente!.nombres} ${cliente!.apellidos}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        cliente!.correo,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      Text(
                                        cliente!.telefono,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Información del Vehículo
                  const Text(
                    'Vehículo',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (vehiculo != null)
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              vehiculo!.tipoVehiculo == TipoVehiculo.CARRO
                                  ? Icons.directions_car
                                  : Icons.two_wheeler,
                              size: 48,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehiculo!.placa,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${vehiculo!.marca} ${vehiculo!.modelo}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  if (vehiculo!.generacion != null)
                                    Text(
                                      'Generación: ${vehiculo!.generacion}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  if (vehiculo!.color != null)
                                    Text(
                                      'Color: ${vehiculo!.color}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Fechas
                  const Text(
                    'Fechas',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey),
                              const SizedBox(width: 12),
                              const Text('Creación: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${orden.fechaCreacion.day}/${orden.fechaCreacion.month}/${orden.fechaCreacion.year}',
                              ),
                            ],
                          ),
                          if (orden.fechaPromesa != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.event_available, color: Colors.blue),
                                const SizedBox(width: 12),
                                const Text('Promesa: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  '${orden.fechaPromesa!.day}/${orden.fechaPromesa!.month}/${orden.fechaPromesa!.year}',
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progreso Total
                  const Text(
                    'Progreso Total',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 3,
                    color: Colors.teal.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '${orden.calcularProgresoPromedio()}%',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: orden.calcularProgresoPromedio() / 100,
                            minHeight: 12,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Progreso promedio de todos los servicios',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Servicios
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Servicios',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${orden.detalles.length} servicio(s)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Lista de servicios
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orden.detalles.length,
                    itemBuilder: (context, index) {
                      final detalle = orden.detalles[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nombre y estado del servicio
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      detalle.servicioNombre,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getEstadoServicioColor(detalle.estadoItem)
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getEstadoServicioColor(detalle.estadoItem),
                                      ),
                                    ),
                                    child: Text(
                                      detalle.estadoItem.displayName,
                                      style: TextStyle(
                                        color: _getEstadoServicioColor(detalle.estadoItem),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Progreso
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: detalle.progreso / 100,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getEstadoServicioColor(detalle.estadoItem),
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${detalle.progreso}%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Precio
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Precio:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '\$${detalle.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),

                              // Observaciones
                              if (detalle.observacionesTecnicas != null &&
                                  detalle.observacionesTecnicas!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Observaciones:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  detalle.observacionesTecnicas!,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],

                              // Fotos iniciales
                              if (detalle.fotosIniciales.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 8),
                                const Text(
                                  'Fotos iniciales:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: detalle.fotosIniciales.length,
                                    itemBuilder: (context, fotoIndex) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            detalle.fotosIniciales[fotoIndex],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.broken_image),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              // Botón de avances
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AvancesServicioScreen(
                                          orden: orden,
                                          detalle: detalle,
                                          detalleIndex: index,
                                        ),
                                      ),
                                    );
                                    // Recargar orden después de ver/agregar avances
                                    await _recargarOrden();
                                  },
                                  icon: const Icon(Icons.history),
                                  label: Text('Ver Avances (${detalle.avances.length})'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Total
                  Card(
                    elevation: 3,
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${orden.calcularTotal().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


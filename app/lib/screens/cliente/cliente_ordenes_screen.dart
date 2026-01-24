import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/usuario.dart';
import '../../models/orden.dart';
import '../../services/database_service.dart';
import '../../providers/provider_state.dart';

class ClienteOrdenesScreen extends StatefulWidget {
  const ClienteOrdenesScreen({super.key});

  @override
  State<ClienteOrdenesScreen> createState() => _ClienteOrdenesScreenState();
}

class _ClienteOrdenesScreenState extends State<ClienteOrdenesScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Orden> _ordenes = [];
  bool _isLoading = false;

  // Modern Color Palette
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadOrdenes();
  }

  Future<void> _loadOrdenes() async {
    setState(() => _isLoading = true);
    try {
      final usuario = Provider.of<ProviderState>(context, listen: false).currentUserData as Cliente;
      final ordenes = await _dbService.getOrdenesByCliente(usuario.uid);

      // Sort by creation date (most recent first)
      ordenes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      setState(() {
        _ordenes = ordenes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar órdenes: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getEstadoColor(EstadoOrden estado) {
    switch (estado) {
      case EstadoOrden.EN_COTIZACION:
      case EstadoOrden.COTIZACION_RESERVA:
        return Colors.orange[700]!;
      case EstadoOrden.EN_PROCESO:
        return Colors.blue[700]!;
      case EstadoOrden.FINALIZADO:
      case EstadoOrden.ENTREGADO:
        return Colors.green[700]!;
    }
  }

  String _getEstadoTexto(EstadoOrden estado) {
    switch (estado) {
      case EstadoOrden.EN_COTIZACION:
        return 'En Cotización';
      case EstadoOrden.COTIZACION_RESERVA:
        return 'Cotización Reserva';
      case EstadoOrden.EN_PROCESO:
        return 'En Proceso';
      case EstadoOrden.FINALIZADO:
        return 'Finalizado';
      case EstadoOrden.ENTREGADO:
        return 'Entregado';
    }
  }

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
                    icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[700]),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Mis Órdenes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: _primaryColor),
                    onPressed: _loadOrdenes,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                      ),
                    )
                  : _ordenes.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadOrdenes,
                          color: _primaryColor,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(24.0),
                            itemCount: _ordenes.length,
                            itemBuilder: (context, index) {
                              return _buildOrdenCard(_ordenes[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          SizedBox(height: 16),
          Text(
            'No tienes órdenes',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tus órdenes de servicio aparecerán aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenCard(Orden orden) {
    final estadoColor = _getEstadoColor(orden.estado);
    final estadoTexto = _getEstadoTexto(orden.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            // Cargar datos completos antes de navegar
            final vehiculo = await _dbService.getVehiculo(orden.vehiculoId);
            final usuario = Provider.of<ProviderState>(context, listen: false).currentUserData as Cliente;

            await Navigator.pushNamed(
              context,
              '/orden-details',
              arguments: {
                'orden': orden,
                'cliente': usuario,
                'vehiculo': vehiculo,
              },
            );
            _loadOrdenes(); // Recargar después de ver detalles
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Orden ID + Estado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Orden #${orden.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        estadoTexto,
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Fecha
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      _formatFecha(orden.fechaCreacion),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Servicios Count
                Row(
                  children: [
                    Icon(Icons.build_outlined, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      '${orden.detalles.length} servicio${orden.detalles.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Total
                Row(
                  children: [
                    Icon(Icons.attach_money_outlined, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'Total: \$${(orden.total ?? orden.calcularTotal()).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),

                // Progress Bar (only for EN_PROCESO)
                if (orden.estado == EstadoOrden.EN_PROCESO) ...[
                  SizedBox(height: 12),
                  _buildProgressIndicator(orden),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(Orden orden) {
    // Use the built-in method from Orden model
    final progress = orden.calcularProgresoPromedio() / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}

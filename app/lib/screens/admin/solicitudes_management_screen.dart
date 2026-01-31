import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/solicitud.dart';
import '../../models/vehiculo.dart';
import '../../models/usuario.dart';
import '../../widgets/aceptar_solicitud_dialog.dart';
import '../../widgets/rechazar_solicitud_dialog.dart';
import '../common/solicitud_details_screen.dart';

class SolicitudesManagementScreen extends StatefulWidget {
  const SolicitudesManagementScreen({super.key});

  @override
  State<SolicitudesManagementScreen> createState() =>
      _SolicitudesManagementScreenState();
}

class _SolicitudesManagementScreenState
    extends State<SolicitudesManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final Color primaryColor = const Color(0xFF1E88E5);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  String _filtroEstado = 'TODOS'; // TODOS, EN_REVISION, ACEPTADA, RECHAZADA

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: Colors.blueGrey[700], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solicitudes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  // Botón de calendario
                  IconButton(
                    icon: Icon(Icons.calendar_month_rounded,
                        color: primaryColor, size: 28),
                    onPressed: () {
                      // TODO: Navegar a calendario de solicitudes
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calendario en desarrollo'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFiltroChip('TODOS'),
                    SizedBox(width: 8),
                    _buildFiltroChip('EN_REVISION'),
                    SizedBox(width: 8),
                    _buildFiltroChip('ACEPTADA'),
                    SizedBox(width: 8),
                    _buildFiltroChip('RECHAZADA'),
                  ],
                ),
              ),
            ),

            // Lista de solicitudes
            Expanded(
              child: StreamBuilder<List<Solicitud>>(
                stream: _dbService.getSolicitudesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red)),
                    );
                  }

                  var solicitudes = snapshot.data ?? [];

                  // Aplicar filtro
                  if (_filtroEstado != 'TODOS') {
                    solicitudes = solicitudes
                        .where((s) => s.estado.name == _filtroEstado)
                        .toList();
                  }

                  if (solicitudes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 80, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'No hay solicitudes',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Ordenar: en revisión primero, luego por fecha
                  solicitudes.sort((a, b) {
                    if (a.estado == EstadoSolicitud.EN_REVISION &&
                        b.estado != EstadoSolicitud.EN_REVISION) {
                      return -1;
                    }
                    if (b.estado == EstadoSolicitud.EN_REVISION &&
                        a.estado != EstadoSolicitud.EN_REVISION) {
                      return 1;
                    }
                    return b.fechaCreacion.compareTo(a.fechaCreacion);
                  });

                  return ListView.builder(
                    padding: EdgeInsets.all(24),
                    itemCount: solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = solicitudes[index];
                      return _buildSolicitudCard(solicitud);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String filtro) {
    final isSelected = _filtroEstado == filtro;
    return FilterChip(
      label: Text(filtro),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroEstado = filtro;
        });
      },
      selectedColor: primaryColor.withValues(alpha: 0.2),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildSolicitudCard(Solicitud solicitud) {
    Color estadoColor;
    IconData estadoIcon;

    switch (solicitud.estado) {
      case EstadoSolicitud.EN_REVISION:
        estadoColor = Colors.orange[600]!;
        estadoIcon = Icons.schedule;
        break;
      case EstadoSolicitud.ACEPTADA:
        estadoColor = Colors.green[600]!;
        estadoIcon = Icons.check_circle;
        break;
      case EstadoSolicitud.RECHAZADA:
        estadoColor = Colors.red[600]!;
        estadoIcon = Icons.cancel;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: solicitud.estado == EstadoSolicitud.EN_REVISION
            ? Border.all(color: estadoColor.withValues(alpha: 0.3), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
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
                builder: (context) => SolicitudDetailsScreen(
                  solicitud: solicitud,
                  esCliente: false,
                ),
              ),
            );
          },
          onLongPress: () {
            _showGestionarDialog(solicitud);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estadoIcon, size: 16, color: estadoColor),
                          SizedBox(width: 6),
                          Text(
                            solicitud.estado.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: estadoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${solicitud.fechaCreacion.day}/${solicitud.fechaCreacion.month}/${solicitud.fechaCreacion.year}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Cliente
                FutureBuilder<Usuario?>(
                  future: _dbService.getUsuario(solicitud.clienteId),
                  builder: (context, snapshot) {
                    final cliente = snapshot.data;
                    return Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[400]),
                        SizedBox(width: 8),
                        Text(
                          cliente?.nombres ?? 'Cliente',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey[800],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 8),

                // Vehículo
                FutureBuilder<Vehiculo?>(
                  future: _dbService.getVehiculo(solicitud.vehiculoId),
                  builder: (context, snapshot) {
                    final vehiculo = snapshot.data;
                    return Row(
                      children: [
                        Icon(Icons.directions_car, size: 16, color: Colors.grey[400]),
                        SizedBox(width: 8),
                        Text(
                          vehiculo != null
                              ? '${vehiculo.marca} ${vehiculo.modelo} - ${vehiculo.placa}'
                              : 'Vehículo',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 8),

                // Fecha
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                    SizedBox(width: 8),
                    Text(
                      'Fecha deseada: ${solicitud.fechaDeseada.day}/${solicitud.fechaDeseada.month}/${solicitud.fechaDeseada.year}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Observaciones
                Text(
                  solicitud.observaciones,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGestionarDialog(Solicitud solicitud) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Gestionar Solicitud',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: 24),
            if (solicitud.estado == EstadoSolicitud.EN_REVISION) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AceptarSolicitudDialog(
                      solicitud: solicitud,
                    ),
                  );
                },
                icon: Icon(Icons.check_circle),
                label: Text('Aceptar Solicitud'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => RechazarSolicitudDialog(
                      solicitud: solicitud,
                    ),
                  );
                },
                icon: Icon(Icons.cancel),
                label: Text('Rechazar Solicitud'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Esta solicitud ya fue ${solicitud.estado.displayName.toLowerCase()}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


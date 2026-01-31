import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/solicitud.dart';
import '../../models/vehiculo.dart';
import '../../models/usuario.dart';
import 'create_solicitud_screen.dart';
import '../common/solicitud_details_screen.dart';

class ClienteSolicitudesScreen extends StatefulWidget {
  final Cliente cliente;

  const ClienteSolicitudesScreen({super.key, required this.cliente});

  @override
  State<ClienteSolicitudesScreen> createState() => _ClienteSolicitudesScreenState();
}

class _ClienteSolicitudesScreenState extends State<ClienteSolicitudesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final Color primaryColor = const Color(0xFF1E88E5);
  final Color backgroundColor = const Color(0xFFF5F7FA);

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
                  Text(
                    'Mis Solicitudes',
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

            // Lista de solicitudes
            Expanded(
              child: StreamBuilder<List<Solicitud>>(
                stream: _dbService.getSolicitudesByClienteStream(widget.cliente.uid),
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

                  final solicitudes = snapshot.data ?? [];

                  if (solicitudes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule_send_outlined,
                              size: 80, color: Colors.grey[300]),
                          SizedBox(height: 16),
                          Text(
                            'No tienes solicitudes',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Crea una nueva solicitud',
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Ordenar por fecha de creación (más reciente primero)
                  solicitudes.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSolicitudScreen(cliente: widget.cliente),
            ),
          );
        },
        backgroundColor: primaryColor,
        elevation: 4,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('Nueva Solicitud',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  esCliente: true,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estado
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
                              ? '${vehiculo.marca} ${vehiculo.modelo}'
                              : 'Vehículo',
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

                // Fecha
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                    SizedBox(width: 8),
                    Text(
                      solicitud.fechaAceptada != null
                          ? 'Fecha confirmada: ${solicitud.fechaAceptada!.day}/${solicitud.fechaAceptada!.month}/${solicitud.fechaAceptada!.year}'
                          : 'Fecha deseada: ${solicitud.fechaDeseada.day}/${solicitud.fechaDeseada.month}/${solicitud.fechaDeseada.year}',
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

                // Indicador de propuesta pendiente
                if (solicitud.tienePropuestaAdminPendiente)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notification_important,
                              size: 16, color: primaryColor),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nueva propuesta de fecha del administrador',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


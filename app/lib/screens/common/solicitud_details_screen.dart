import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../models/vehiculo.dart';
import '../../models/usuario.dart';
import '../../services/database_service.dart';
import '../../widgets/aceptar_solicitud_dialog.dart';
import '../../widgets/rechazar_solicitud_dialog.dart';
import 'package:firebase_database/firebase_database.dart';

class SolicitudDetailsScreen extends StatefulWidget {
  final Solicitud solicitud;
  final bool esCliente;

  const SolicitudDetailsScreen({
    super.key,
    required this.solicitud,
    this.esCliente = false,
  });

  @override
  State<SolicitudDetailsScreen> createState() => _SolicitudDetailsScreenState();
}

class _SolicitudDetailsScreenState extends State<SolicitudDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final Color primaryColor = const Color(0xFF1E88E5);
  final Color backgroundColor = const Color(0xFFF5F7FA);

  Future<void> _aceptarPropuestaAdmin() async {
    final ultimaPropuesta = widget.solicitud.ultimaPropuesta;
    if (ultimaPropuesta == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Aceptar Propuesta'),
        content: Text(
          '¿Deseas aceptar la fecha propuesta: ${ultimaPropuesta.fechaPropuesta.day}/${ultimaPropuesta.fechaPropuesta.month}/${ultimaPropuesta.fechaPropuesta.year}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbService.aceptarSolicitud(
          widget.solicitud.id,
          ultimaPropuesta.fechaPropuesta,
          ultimaPropuesta.duracionEstimadaHoras ?? 4,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Propuesta aceptada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _proponerOtraFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      try {
        final nuevaPropuesta = PropuestaFecha(
          id: FirebaseDatabase.instance.ref().child('propuestas').push().key!,
          fechaPropuesta: picked,
          propuestaPor: 'cliente',
          fechaCreacion: DateTime.now(),
        );

        await _dbService.agregarPropuestaFecha(
          widget.solicitud.id,
          nuevaPropuesta,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nueva propuesta enviada al administrador'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color estadoColor;
    IconData estadoIcon;

    switch (widget.solicitud.estado) {
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
                      'Detalle de Solicitud',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Estado
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: estadoColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(estadoIcon, color: estadoColor, size: 32),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estado',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: estadoColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  widget.solicitud.estado.displayName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: estadoColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Información del vehículo
                    _buildInfoCard(
                      'Vehículo',
                      Icons.directions_car,
                      FutureBuilder<Vehiculo?>(
                        future: _dbService.getVehiculo(widget.solicitud.vehiculoId),
                        builder: (context, snapshot) {
                          final vehiculo = snapshot.data;
                          if (vehiculo == null) {
                            return Text('Cargando...');
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${vehiculo.marca} ${vehiculo.modelo}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey[800],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Placa: ${vehiculo.placa}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Año: ${vehiculo.generacion}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),

                    // Observaciones
                    _buildInfoCard(
                      'Observaciones del Cliente',
                      Icons.notes,
                      Text(
                        widget.solicitud.observaciones,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.blueGrey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Fecha final (si está aceptada)
                    if (widget.solicitud.fechaAceptada != null)
                      _buildInfoCard(
                        'Fecha Confirmada',
                        Icons.event_available,
                        Text(
                          '${widget.solicitud.fechaAceptada!.day}/${widget.solicitud.fechaAceptada!.month}/${widget.solicitud.fechaAceptada!.year}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    SizedBox(height: 16),

                    // Motivo de rechazo (si está rechazada)
                    if (widget.solicitud.motivoRechazo != null)
                      _buildInfoCard(
                        'Motivo del Rechazo',
                        Icons.info_outline,
                        Text(
                          widget.solicitud.motivoRechazo!,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.red[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                    SizedBox(height: 24),

                    // Timeline de propuestas
                    Text(
                      'Historial de Negociación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildTimeline(),

                    // Botones de acción para el cliente
                    if (widget.esCliente &&
                        widget.solicitud.estado == EstadoSolicitud.EN_REVISION &&
                        widget.solicitud.tienePropuestaAdminPendiente) ...[
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _aceptarPropuestaAdmin,
                        icon: Icon(Icons.check_circle),
                        label: Text('Aceptar Propuesta del Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _proponerOtraFecha,
                        icon: Icon(Icons.calendar_month),
                        label: Text('Proponer Otra Fecha'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Widget content) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final propuestas = widget.solicitud.historialPropuestas.reversed.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: propuestas.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 60),
        itemBuilder: (context, index) {
          final propuesta = propuestas[index];
          final esCliente = propuesta.propuestaPor == 'cliente';
          final color = esCliente ? Colors.blue[600]! : Colors.orange[600]!;

          return Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    esCliente ? Icons.person : Icons.admin_panel_settings,
                    color: color,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esCliente ? 'Propuesta del Cliente' : 'Propuesta del Admin',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                          SizedBox(width: 6),
                          Text(
                            '${propuesta.fechaPropuesta.day}/${propuesta.fechaPropuesta.month}/${propuesta.fechaPropuesta.year}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                        ],
                      ),
                      if (propuesta.duracionEstimadaHoras != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                            SizedBox(width: 6),
                            Text(
                              '${propuesta.duracionEstimadaHoras} horas estimadas',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        '${propuesta.fechaCreacion.day}/${propuesta.fechaCreacion.month}/${propuesta.fechaCreacion.year} ${propuesta.fechaCreacion.hour}:${propuesta.fechaCreacion.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      if (propuesta.observaciones != null) ...[
                        SizedBox(height: 8),
                        Text(
                          propuesta.observaciones!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


/// Enumeración para el estado de la solicitud
enum EstadoSolicitud {
  EN_REVISION,
  ACEPTADA,
  RECHAZADA;

  String toJson() => name;

  static EstadoSolicitud fromJson(String json) {
    return EstadoSolicitud.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EstadoSolicitud.EN_REVISION,
    );
  }

  String get displayName {
    switch (this) {
      case EstadoSolicitud.EN_REVISION:
        return 'En Revisión';
      case EstadoSolicitud.ACEPTADA:
        return 'Aceptada';
      case EstadoSolicitud.RECHAZADA:
        return 'Rechazada';
    }
  }
}

/// Clase para representar propuestas de fecha
class PropuestaFecha {
  final String id;
  final DateTime fechaPropuesta;
  final int? duracionEstimadaHoras; // Duración estimada de la revisión
  final String propuestaPor; // 'cliente' o 'admin'
  final DateTime fechaCreacion;
  final String? observaciones;

  PropuestaFecha({
    required this.id,
    required this.fechaPropuesta,
    this.duracionEstimadaHoras,
    required this.propuestaPor,
    required this.fechaCreacion,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha_propuesta': fechaPropuesta.toIso8601String(),
      'duracion_estimada_horas': duracionEstimadaHoras,
      'propuesta_por': propuestaPor,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'observaciones': observaciones,
    };
  }

  factory PropuestaFecha.fromJson(Map<dynamic, dynamic> json) {
    return PropuestaFecha(
      id: json['id'] as String? ?? '',
      fechaPropuesta: json['fecha_propuesta'] != null
          ? DateTime.parse(json['fecha_propuesta'] as String)
          : DateTime.now(),
      duracionEstimadaHoras: json['duracion_estimada_horas'] as int?,
      propuestaPor: json['propuesta_por'] as String? ?? 'cliente',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : DateTime.now(),
      observaciones: json['observaciones'] as String?,
    );
  }
}

/// Clase Solicitud - Solicitud de revisión/servicio del cliente
class Solicitud {
  final String id; // ID único de la solicitud
  final String clienteId; // UID del cliente que solicita
  final String vehiculoId; // ID del vehículo
  final DateTime fechaCreacion; // Fecha de creación de la solicitud
  final DateTime fechaDeseada; // Fecha inicial propuesta por el cliente
  final DateTime? fechaAceptada; // Fecha finalmente acordada
  final int? duracionEstimadaHoras; // Duración estimada final
  final String observaciones; // Lo que necesita el cliente
  final EstadoSolicitud estado; // Estado de la solicitud
  final List<PropuestaFecha> historialPropuestas; // Historial de negociación de fechas
  final String? motivoRechazo; // Razón del rechazo si aplica
  final String? ordenId; // ID de la orden creada si es aceptada

  Solicitud({
    required this.id,
    required this.clienteId,
    required this.vehiculoId,
    required this.fechaCreacion,
    required this.fechaDeseada,
    this.fechaAceptada,
    this.duracionEstimadaHoras,
    required this.observaciones,
    this.estado = EstadoSolicitud.EN_REVISION,
    this.historialPropuestas = const [],
    this.motivoRechazo,
    this.ordenId,
  });

  /// Convertir a Map para guardar en Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'vehiculo_id': vehiculoId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_deseada': fechaDeseada.toIso8601String(),
      'fecha_aceptada': fechaAceptada?.toIso8601String(),
      'duracion_estimada_horas': duracionEstimadaHoras,
      'observaciones': observaciones,
      'estado': estado.toJson(),
      'historial_propuestas': historialPropuestas.map((p) => p.toJson()).toList(),
      'motivo_rechazo': motivoRechazo,
      'orden_id': ordenId,
    };
  }

  /// Crear desde Map de Firebase
  factory Solicitud.fromJson(Map<dynamic, dynamic> json) {
    return Solicitud(
      id: json['id'] as String? ?? '',
      clienteId: json['cliente_id'] as String? ?? '',
      vehiculoId: json['vehiculo_id'] as String? ?? '',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : DateTime.now(),
      fechaDeseada: json['fecha_deseada'] != null
          ? DateTime.parse(json['fecha_deseada'] as String)
          : DateTime.now(),
      fechaAceptada: json['fecha_aceptada'] != null
          ? DateTime.parse(json['fecha_aceptada'] as String)
          : null,
      duracionEstimadaHoras: json['duracion_estimada_horas'] as int?,
      observaciones: json['observaciones'] as String? ?? '',
      estado: EstadoSolicitud.fromJson(json['estado'] as String? ?? 'EN_REVISION'),
      historialPropuestas: (json['historial_propuestas'] as List<dynamic>?)
              ?.map((p) => PropuestaFecha.fromJson(p as Map<dynamic, dynamic>))
              .toList() ??
          [],
      motivoRechazo: json['motivo_rechazo'] as String?,
      ordenId: json['orden_id'] as String?,
    );
  }

  /// Copiar solicitud con cambios
  Solicitud copyWith({
    String? id,
    String? clienteId,
    String? vehiculoId,
    DateTime? fechaCreacion,
    DateTime? fechaDeseada,
    DateTime? fechaAceptada,
    int? duracionEstimadaHoras,
    String? observaciones,
    EstadoSolicitud? estado,
    List<PropuestaFecha>? historialPropuestas,
    String? motivoRechazo,
    String? ordenId,
  }) {
    return Solicitud(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaDeseada: fechaDeseada ?? this.fechaDeseada,
      fechaAceptada: fechaAceptada ?? this.fechaAceptada,
      duracionEstimadaHoras: duracionEstimadaHoras ?? this.duracionEstimadaHoras,
      observaciones: observaciones ?? this.observaciones,
      estado: estado ?? this.estado,
      historialPropuestas: historialPropuestas ?? this.historialPropuestas,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      ordenId: ordenId ?? this.ordenId,
    );
  }

  /// Obtener la última propuesta
  PropuestaFecha? get ultimaPropuesta {
    if (historialPropuestas.isEmpty) return null;
    return historialPropuestas.last;
  }

  /// Verificar si hay propuestas pendientes del admin
  bool get tienePropuestaAdminPendiente {
    if (ultimaPropuesta == null) return false;
    return ultimaPropuesta!.propuestaPor == 'admin';
  }

  /// Verificar si hay propuestas pendientes del cliente
  bool get tienePropuestaClientePendiente {
    if (ultimaPropuesta == null) return false;
    return ultimaPropuesta!.propuestaPor == 'cliente' && historialPropuestas.length > 1;
  }
}


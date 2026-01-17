/// Enumeración para el estado de la orden
enum EstadoOrden {
  EN_COTIZACION,
  COTIZACION_RESERVA,
  EN_PROCESO,
  FINALIZADO,
  ENTREGADO;

  String toJson() => name;

  static EstadoOrden fromJson(String json) {
    return EstadoOrden.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EstadoOrden.EN_COTIZACION,
    );
  }

  String get displayName {
    switch (this) {
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
}

/// Enumeración para el estado de un servicio individual
enum EstadoServicio {
  PENDIENTE,
  TRABAJANDO,
  LISTO;

  String toJson() => name;

  static EstadoServicio fromJson(String json) {
    return EstadoServicio.values.firstWhere(
      (e) => e.name == json,
      orElse: () => EstadoServicio.PENDIENTE,
    );
  }

  String get displayName {
    switch (this) {
      case EstadoServicio.PENDIENTE:
        return 'Pendiente';
      case EstadoServicio.TRABAJANDO:
        return 'Trabajando';
      case EstadoServicio.LISTO:
        return 'Listo';
    }
  }
}

/// Clase Servicio - Catálogo de servicios disponibles
class Servicio {
  final String id; // ID único del servicio
  final String nombre; // Ej: "Lavado", "Pulido", "Pintura"
  final String? descripcion; // Descripción del servicio
  final double? precioEstimado; // Precio estimado base
  final String? duracionEstimada; // Duración estimada (ej: "2 horas", "1 día")

  Servicio({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.precioEstimado,
    this.duracionEstimada,
  });

  /// Convertir a Map para guardar en Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_estimado': precioEstimado,
      'duracion_estimada': duracionEstimada,
    };
  }

  /// Crear desde Map de Firebase
  factory Servicio.fromJson(Map<dynamic, dynamic> json) {
    return Servicio(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      descripcion: json['descripcion'] as String?,
      precioEstimado: (json['precio_estimado'] as num?)?.toDouble(),
      duracionEstimada: json['duracion_estimada'] as String?,
    );
  }

  /// Copiar servicio con cambios
  Servicio copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    double? precioEstimado,
    String? duracionEstimada,
  }) {
    return Servicio(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioEstimado: precioEstimado ?? this.precioEstimado,
      duracionEstimada: duracionEstimada ?? this.duracionEstimada,
    );
  }
}

/// Clase DetalleOrden - Representa un servicio específico dentro de una orden
class DetalleOrden {
  final String id; // ID único del detalle
  final String servicioId; // Referencia al servicio del catálogo
  final String servicioNombre; // Nombre del servicio (guardado para referencia)
  final double precio; // Precio específico para este servicio en esta orden
  final EstadoServicio estadoItem; // Estado de este servicio
  final int progreso; // Porcentaje de 0-100
  final String? observacionesTecnicas; // Notas del trabajador
  final String? trabajadorAsignado; // UID del trabajador asignado (opcional)

  DetalleOrden({
    required this.id,
    required this.servicioId,
    required this.servicioNombre,
    required this.precio,
    this.estadoItem = EstadoServicio.PENDIENTE,
    this.progreso = 0,
    this.observacionesTecnicas,
    this.trabajadorAsignado,
  });

  /// Convertir a Map para guardar en Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'servicio_id': servicioId,
      'servicio_nombre': servicioNombre,
      'precio': precio,
      'estado_item': estadoItem.toJson(),
      'progreso': progreso,
      'observaciones_tecnicas': observacionesTecnicas,
      'trabajador_asignado': trabajadorAsignado,
    };
  }

  /// Crear desde Map de Firebase
  factory DetalleOrden.fromJson(Map<dynamic, dynamic> json) {
    return DetalleOrden(
      id: json['id'] as String? ?? '',
      servicioId: json['servicio_id'] as String? ?? '',
      servicioNombre: json['servicio_nombre'] as String? ?? '',
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      estadoItem: EstadoServicio.fromJson(json['estado_item'] as String? ?? 'PENDIENTE'),
      progreso: json['progreso'] as int? ?? 0,
      observacionesTecnicas: json['observaciones_tecnicas'] as String?,
      trabajadorAsignado: json['trabajador_asignado'] as String?,
    );
  }

  /// Copiar detalle con cambios
  DetalleOrden copyWith({
    String? id,
    String? servicioId,
    String? servicioNombre,
    double? precio,
    EstadoServicio? estadoItem,
    int? progreso,
    String? observacionesTecnicas,
    String? trabajadorAsignado,
  }) {
    return DetalleOrden(
      id: id ?? this.id,
      servicioId: servicioId ?? this.servicioId,
      servicioNombre: servicioNombre ?? this.servicioNombre,
      precio: precio ?? this.precio,
      estadoItem: estadoItem ?? this.estadoItem,
      progreso: progreso ?? this.progreso,
      observacionesTecnicas: observacionesTecnicas ?? this.observacionesTecnicas,
      trabajadorAsignado: trabajadorAsignado ?? this.trabajadorAsignado,
    );
  }

  /// Calcular el total de este detalle
  double get total => precio;
}

/// Clase Orden - Orden de trabajo
class Orden {
  final String id; // ID único de la orden
  final String clienteId; // UID del cliente
  final String vehiculoId; // ID del vehículo
  final DateTime fechaCreacion; // Fecha de creación
  final DateTime? fechaPromesa; // Fecha prometida de entrega
  final EstadoOrden estado; // Estado general de la orden
  final List<DetalleOrden> detalles; // Lista de servicios (detalles)
  final double? total; // Total de la orden (suma de todos los detalles)

  Orden({
    required this.id,
    required this.clienteId,
    required this.vehiculoId,
    required this.fechaCreacion,
    this.fechaPromesa,
    this.estado = EstadoOrden.EN_COTIZACION,
    this.detalles = const [],
    this.total,
  });

  /// Convertir a Map para guardar en Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'vehiculo_id': vehiculoId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_promesa': fechaPromesa?.toIso8601String(),
      'estado': estado.toJson(),
      'detalles': detalles.map((d) => d.toJson()).toList(),
      'total': total ?? calcularTotal(),
    };
  }

  /// Crear desde Map de Firebase
  factory Orden.fromJson(Map<dynamic, dynamic> json) {
    return Orden(
      id: json['id'] as String? ?? '',
      clienteId: json['cliente_id'] as String? ?? '',
      vehiculoId: json['vehiculo_id'] as String? ?? '',
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'] as String)
          : DateTime.now(),
      fechaPromesa: json['fecha_promesa'] != null
          ? DateTime.parse(json['fecha_promesa'] as String)
          : null,
      estado: EstadoOrden.fromJson(json['estado'] as String? ?? 'EN_COTIZACION'),
      detalles: (json['detalles'] as List<dynamic>?)
              ?.map((d) => DetalleOrden.fromJson(d as Map<dynamic, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble(),
    );
  }

  /// Copiar orden con cambios
  Orden copyWith({
    String? id,
    String? clienteId,
    String? vehiculoId,
    DateTime? fechaCreacion,
    DateTime? fechaPromesa,
    EstadoOrden? estado,
    List<DetalleOrden>? detalles,
    double? total,
  }) {
    return Orden(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      vehiculoId: vehiculoId ?? this.vehiculoId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaPromesa: fechaPromesa ?? this.fechaPromesa,
      estado: estado ?? this.estado,
      detalles: detalles ?? this.detalles,
      total: total ?? this.total,
    );
  }

  /// Calcular total de la orden
  double calcularTotal() {
    return detalles.fold(0.0, (sum, detalle) => sum + detalle.precio);
  }

  /// Calcular progreso promedio de todos los servicios
  int calcularProgresoPromedio() {
    if (detalles.isEmpty) return 0;
    final totalProgreso = detalles.fold(0, (sum, detalle) => sum + detalle.progreso);
    return (totalProgreso / detalles.length).round();
  }

  /// Verificar si todos los servicios están completados
  bool get todosServiciosCompletos {
    return detalles.isNotEmpty && detalles.every((d) => d.estadoItem == EstadoServicio.LISTO);
  }
}


/// Enumeración para tipos de vehículo
enum TipoVehiculo {
  CARRO,
  MOTO;

  String toJson() => name;

  static TipoVehiculo fromJson(String json) {
    return TipoVehiculo.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TipoVehiculo.CARRO,
    );
  }

  String get displayName {
    switch (this) {
      case TipoVehiculo.CARRO:
        return 'Carro';
      case TipoVehiculo.MOTO:
        return 'Moto';
    }
  }
}

/// Clase Vehículo según el diagrama
class Vehiculo {
  final String? id; // ID único en la base de datos
  final String placa;
  final String marca;
  final String modelo;
  final int generacion;
  final String color;
  final List<String> clienteIds; // Lista de IDs de clientes dueños
  final TipoVehiculo tipoVehiculo;
  final List<String> fotosUrls; // URLs de Firebase Storage

  Vehiculo({
    this.id,
    required this.placa,
    required this.marca,
    required this.modelo,
    required this.generacion,
    required this.color,
    List<String>? clienteIds,
    required this.tipoVehiculo,
    List<String>? fotosUrls,
  }) : clienteIds = clienteIds ?? [],
       fotosUrls = fotosUrls ?? [];

  // Convertir a Map para guardar en Realtime Database
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'generacion': generacion,
      'color': color,
      'cliente_ids': clienteIds,
      'tipo_vehiculo': tipoVehiculo.toJson(),
      'fotos_urls': fotosUrls,
    };
  }

  // Crear desde Map de Realtime Database
  factory Vehiculo.fromJson(Map<dynamic, dynamic> json, {String? id}) {
    // Manejar compatibilidad con el campo antiguo cliente_id
    List<String> clientes = [];
    if (json['cliente_ids'] != null) {
      clientes = (json['cliente_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
    } else if (json['cliente_id'] != null) {
      // Compatibilidad con versión antigua
      clientes = [json['cliente_id'] as String];
    }

    return Vehiculo(
      id: id ?? json['id'] as String?,
      placa: json['placa'] as String? ?? '',
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      generacion: json['generacion'] as int? ?? 0,
      color: json['color'] as String? ?? '',
      clienteIds: clientes,
      tipoVehiculo: TipoVehiculo.fromJson(
        json['tipo_vehiculo'] as String? ?? 'CARRO',
      ),
      fotosUrls: (json['fotos_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  // Crear copia con cambios
  Vehiculo copyWith({
    String? id,
    String? placa,
    String? marca,
    String? modelo,
    int? generacion,
    String? color,
    List<String>? clienteIds,
    TipoVehiculo? tipoVehiculo,
    List<String>? fotosUrls,
  }) {
    return Vehiculo(
      id: id ?? this.id,
      placa: placa ?? this.placa,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      generacion: generacion ?? this.generacion,
      color: color ?? this.color,
      clienteIds: clienteIds ?? this.clienteIds,
      tipoVehiculo: tipoVehiculo ?? this.tipoVehiculo,
      fotosUrls: fotosUrls ?? this.fotosUrls,
    );
  }

  // Validar que tenga al menos 3 fotos
  bool get tieneFotosSuficientes => fotosUrls.length >= 3;

  // Validar que tenga al menos un cliente
  bool get tieneClientes => clienteIds.isNotEmpty;

  // Obtener descripción del vehículo
  String get descripcion => '$marca $modelo $generacion';
}


/// Enumeración para los tipos de documento
enum TipoDocumento {
  CC,
  CE,
  NIT,
  PP;

  String toJson() => name;

  static TipoDocumento fromJson(String json) {
    return TipoDocumento.values.firstWhere(
      (e) => e.name == json,
      orElse: () => TipoDocumento.CC,
    );
  }
}

/// Enumeración para los roles de usuario
enum RolUsuario {
  ADMIN,
  CLIENTE,
  TRABAJADOR;

  String toJson() => name;

  static RolUsuario fromJson(String json) {
    return RolUsuario.values.firstWhere(
      (e) => e.name == json,
      orElse: () => RolUsuario.CLIENTE,
    );
  }
}

/// Clase base Usuario
class Usuario {
  final String uid;
  final String nombres;
  final String apellidos;
  final TipoDocumento tipoDocumento;
  final String numeroDocumento;
  final String correo;
  final String telefono;
  final String? password; // Solo para creación, no se guarda en DB
  final RolUsuario rol;
  final double calificacion;
  final String? fotoPerfil; // Link a Firebase Storage

  Usuario({
    required this.uid,
    required this.nombres,
    required this.apellidos,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.correo,
    required this.telefono,
    this.password,
    required this.rol,
    this.calificacion = 0.0,
    this.fotoPerfil,
  });

  // Convertir a Map para guardar en Realtime Database
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'nombres': nombres,
      'apellidos': apellidos,
      'tipo_documento': tipoDocumento.toJson(),
      'numero_documento': numeroDocumento,
      'correo': correo,
      'telefono': telefono,
      'rol': rol.toJson(),
      'calificacion': calificacion,
      'foto_perfil': fotoPerfil,
    };
  }

  // Crear desde Map de Realtime Database
  factory Usuario.fromJson(Map<dynamic, dynamic> json) {
    return Usuario(
      uid: json['uid'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      tipoDocumento: TipoDocumento.fromJson(json['tipo_documento'] as String? ?? 'CC'),
      numeroDocumento: json['numero_documento'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      rol: RolUsuario.fromJson(json['rol'] as String? ?? 'CLIENTE'),
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      fotoPerfil: json['foto_perfil'] as String?,
    );
  }

  // Crear copia con cambios
  Usuario copyWith({
    String? uid,
    String? nombres,
    String? apellidos,
    TipoDocumento? tipoDocumento,
    String? numeroDocumento,
    String? correo,
    String? telefono,
    String? password,
    RolUsuario? rol,
    double? calificacion,
    String? fotoPerfil,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      password: password ?? this.password,
      rol: rol ?? this.rol,
      calificacion: calificacion ?? this.calificacion,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
    );
  }
}

/// Clase Cliente (hereda de Usuario)
class Cliente extends Usuario {
  final String direccion;
  final DateTime fechaRegistro;

  Cliente({
    required super.uid,
    required super.nombres,
    required super.apellidos,
    required super.tipoDocumento,
    required super.numeroDocumento,
    required super.correo,
    required super.telefono,
    super.password,
    super.calificacion,
    super.fotoPerfil,
    required this.direccion,
    DateTime? fechaRegistro,
  })  : fechaRegistro = fechaRegistro ?? DateTime.now(),
        super(rol: RolUsuario.CLIENTE);

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'direccion': direccion,
      'fecha_registro': fechaRegistro.toIso8601String(),
    });
    return map;
  }

  factory Cliente.fromJson(Map<dynamic, dynamic> json) {
    return Cliente(
      uid: json['uid'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      tipoDocumento: TipoDocumento.fromJson(json['tipo_documento'] as String? ?? 'CC'),
      numeroDocumento: json['numero_documento'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      fotoPerfil: json['foto_perfil'] as String?,
      direccion: json['direccion'] as String? ?? '',
      fechaRegistro: json['fecha_registro'] != null
          ? DateTime.parse(json['fecha_registro'] as String)
          : DateTime.now(),
    );
  }
}

/// Clase Trabajador (hereda de Usuario)
class Trabajador extends Usuario {
  final String area; // Mecánico, Pintura, Etc
  final double sueldo;
  final bool estadoDisponibilidad;

  Trabajador({
    required super.uid,
    required super.nombres,
    required super.apellidos,
    required super.tipoDocumento,
    required super.numeroDocumento,
    required super.correo,
    required super.telefono,
    super.password,
    super.rol = RolUsuario.TRABAJADOR,  // Permitir especificar el rol
    super.calificacion,
    super.fotoPerfil,
    required this.area,
    this.sueldo = 0.0,
    this.estadoDisponibilidad = true,
  });

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'area': area,
      'sueldo': sueldo,
      'estado_disponibilidad': estadoDisponibilidad,
    });
    return map;
  }

  factory Trabajador.fromJson(Map<dynamic, dynamic> json) {
    return Trabajador(
      uid: json['uid'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      tipoDocumento: TipoDocumento.fromJson(json['tipo_documento'] as String? ?? 'CC'),
      numeroDocumento: json['numero_documento'].toString(),  // Convertir a String
      correo: json['correo'] as String? ?? '',
      telefono: json['telefono'].toString(),  // Convertir a String
      rol: RolUsuario.fromJson(json['rol'] as String? ?? 'TRABAJADOR'),  // Leer el rol del JSON
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      fotoPerfil: json['foto_perfil'] as String?,
      area: json['area'] as String? ?? '',
      sueldo: (json['sueldo'] as num?)?.toDouble() ?? 0.0,
      estadoDisponibilidad: json['estado_disponibilidad'] as bool? ?? true,
    );
  }
}


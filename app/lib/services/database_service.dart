import 'package:firebase_database/firebase_database.dart';
import '../models/usuario.dart' as models;
import '../models/vehiculo.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Referencias a las colecciones
  DatabaseReference get _usuariosRef => _database.child('usuarios');
  DatabaseReference get _clientesRef => _database.child('clientes');
  DatabaseReference get _trabajadoresRef => _database.child('trabajadores');
  DatabaseReference get _vehiculosRef => _database.child('vehiculos');

  /// Crear un nuevo cliente en la base de datos
  Future<void> createCliente(models.Cliente cliente) async {
    try {
      // Guardar en nodo de usuarios
      await _usuariosRef.child(cliente.uid).set(cliente.toJson());

      // Guardar también en nodo de clientes para consultas rápidas
      await _clientesRef.child(cliente.uid).set(cliente.toJson());
    } catch (e) {
      throw 'Error al crear cliente: ${e.toString()}';
    }
  }

  /// Crear un nuevo trabajador en la base de datos
  Future<void> createTrabajador(models.Trabajador trabajador) async {
    try {
      // Guardar en nodo de usuarios
      await _usuariosRef.child(trabajador.uid).set(trabajador.toJson());

      // Guardar también en nodo de trabajadores para consultas rápidas
      await _trabajadoresRef.child(trabajador.uid).set(trabajador.toJson());
    } catch (e) {
      throw 'Error al crear trabajador: ${e.toString()}';
    }
  }

  /// Obtener usuario por UID
  Future<models.Usuario?> getUsuario(String uid) async {
    try {
      final snapshot = await _usuariosRef.child(uid).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final rol = models.RolUsuario.fromJson(data['rol'] as String? ?? 'CLIENTE');

      // Retornar el tipo específico según el rol
      switch (rol) {
        case models.RolUsuario.CLIENTE:
          return models.Cliente.fromJson(data);
        case models.RolUsuario.TRABAJADOR:
        case models.RolUsuario.ADMIN:
          return models.Trabajador.fromJson(data);
      }
    } catch (e) {
      throw 'Error al obtener usuario: ${e.toString()}';
    }
  }

  /// Verificar si un usuario existe
  Future<bool> existeUsuario(String uid) async {
    try {
      final snapshot = await _usuariosRef.child(uid).get();
      return snapshot.exists;
    } catch (e) {
      return false;
    }
  }

  /// Obtener el rol de un usuario
  Future<models.RolUsuario?> getRolUsuario(String uid) async {
    try {
      final snapshot = await _usuariosRef.child(uid).child('rol').get();

      if (!snapshot.exists) {
        return null;
      }

      return models.RolUsuario.fromJson(snapshot.value as String);
    } catch (e) {
      return null;
    }
  }

  /// Actualizar usuario
  Future<void> updateUsuario(String uid, Map<String, dynamic> updates) async {
    try {
      await _usuariosRef.child(uid).update(updates);

      // Actualizar también en el nodo específico según el rol
      final rol = await getRolUsuario(uid);
      if (rol == models.RolUsuario.CLIENTE) {
        await _clientesRef.child(uid).update(updates);
      } else if (rol == models.RolUsuario.TRABAJADOR || rol == models.RolUsuario.ADMIN) {
        await _trabajadoresRef.child(uid).update(updates);
      }
    } catch (e) {
      throw 'Error al actualizar usuario: ${e.toString()}';
    }
  }

  /// Eliminar usuario
  Future<void> deleteUsuario(String uid) async {
    try {
      // Eliminar de todos los nodos
      await _usuariosRef.child(uid).remove();
      await _clientesRef.child(uid).remove();
      await _trabajadoresRef.child(uid).remove();
    } catch (e) {
      throw 'Error al eliminar usuario: ${e.toString()}';
    }
  }

  /// Obtener todos los clientes
  Future<List<models.Cliente>> getAllClientes() async {
    try {
      final snapshot = await _clientesRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((e) => models.Cliente.fromJson(e as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener clientes: ${e.toString()}';
    }
  }

  /// Obtener todos los trabajadores
  Future<List<models.Trabajador>> getAllTrabajadores() async {
    try {
      final snapshot = await _trabajadoresRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((e) => models.Trabajador.fromJson(e as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener trabajadores: ${e.toString()}';
    }
  }

  /// Obtener trabajadores por área
  Future<List<models.Trabajador>> getTrabajadoresByArea(String area) async {
    try {
      final snapshot = await _trabajadoresRef
          .orderByChild('area')
          .equalTo(area)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((e) => models.Trabajador.fromJson(e as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener trabajadores por área: ${e.toString()}';
    }
  }

  /// Obtener trabajadores disponibles
  Future<List<models.Trabajador>> getTrabajadoresDisponibles() async {
    try {
      final snapshot = await _trabajadoresRef
          .orderByChild('estado_disponibilidad')
          .equalTo(true)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values
          .map((e) => models.Trabajador.fromJson(e as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener trabajadores disponibles: ${e.toString()}';
    }
  }

  /// Stream de cambios en tiempo real de un usuario
  Stream<models.Usuario?> usuarioStream(String uid) {
    return _usuariosRef.child(uid).onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final rol = models.RolUsuario.fromJson(data['rol'] as String? ?? 'CLIENTE');

      switch (rol) {
        case models.RolUsuario.CLIENTE:
          return models.Cliente.fromJson(data);
        case models.RolUsuario.TRABAJADOR:
        case models.RolUsuario.ADMIN:
          return models.Trabajador.fromJson(data);
      }
    });
  }

  // ==========================================
  // Métodos para gestión de vehículos
  // ==========================================

  /// Verificar si existe un vehículo con la placa dada
  Future<bool> existeVehiculoConPlaca(String placa) async {
    try {
      final snapshot = await _vehiculosRef
          .orderByChild('placa')
          .equalTo(placa.toUpperCase())
          .get();

      return snapshot.exists;
    } catch (e) {
      throw 'Error al verificar placa: ${e.toString()}';
    }
  }

  /// Crear un nuevo vehículo
  Future<String> createVehiculo(Vehiculo vehiculo) async {
    try {
      // Verificar si ya existe un vehículo con esa placa
      final placaExiste = await existeVehiculoConPlaca(vehiculo.placa);
      if (placaExiste) {
        throw 'Ya existe un vehículo registrado con la placa ${vehiculo.placa}';
      }

      // Generar ID único si no tiene
      final String vehiculoId = vehiculo.id ?? _vehiculosRef.push().key!;

      final vehiculoConId = vehiculo.copyWith(id: vehiculoId);

      await _vehiculosRef.child(vehiculoId).set(vehiculoConId.toJson());

      return vehiculoId;
    } catch (e) {
      // Re-lanzar el error original si es el de placa duplicada
      if (e.toString().contains('Ya existe un vehículo')) {
        rethrow;
      }
      throw 'Error al crear vehículo: ${e.toString()}';
    }
  }

  /// Obtener vehículo por ID
  Future<Vehiculo?> getVehiculo(String vehiculoId) async {
    try {
      final snapshot = await _vehiculosRef.child(vehiculoId).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return Vehiculo.fromJson(data, id: vehiculoId);
    } catch (e) {
      throw 'Error al obtener vehículo: ${e.toString()}';
    }
  }

  /// Obtener vehículos de un cliente
  Future<List<Vehiculo>> getVehiculosByCliente(String clienteId) async {
    try {
      // Obtener todos los vehículos y filtrar localmente
      // (Firebase Realtime Database no soporta búsquedas en arrays directamente)
      final snapshot = await _vehiculosRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final vehiculos = data.entries
          .map((e) => Vehiculo.fromJson(
                e.value as Map<dynamic, dynamic>,
                id: e.key,
              ))
          .where((vehiculo) => vehiculo.clienteIds.contains(clienteId))
          .toList();

      return vehiculos;
    } catch (e) {
      throw 'Error al obtener vehículos del cliente: ${e.toString()}';
    }
  }

  /// Actualizar vehículo
  Future<void> updateVehiculo(String vehiculoId, Map<String, dynamic> updates) async {
    try {
      await _vehiculosRef.child(vehiculoId).update(updates);
    } catch (e) {
      throw 'Error al actualizar vehículo: ${e.toString()}';
    }
  }

  /// Eliminar vehículo
  Future<void> deleteVehiculo(String vehiculoId) async {
    try {
      await _vehiculosRef.child(vehiculoId).remove();
    } catch (e) {
      throw 'Error al eliminar vehículo: ${e.toString()}';
    }
  }

  /// Obtener todos los vehículos
  Future<List<Vehiculo>> getAllVehiculos() async {
    try {
      final snapshot = await _vehiculosRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Vehiculo.fromJson(
                e.value as Map<dynamic, dynamic>,
                id: e.key,
              ))
          .toList();
    } catch (e) {
      throw 'Error al obtener vehículos: ${e.toString()}';
    }
  }

  /// Stream de vehículos de un cliente en tiempo real
  Stream<List<Vehiculo>> vehiculosByClienteStream(String clienteId) {
    return _vehiculosRef
        .orderByChild('cliente_id')
        .equalTo(clienteId)
        .onValue
        .map((event) {
      if (!event.snapshot.exists) {
        return <Vehiculo>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Vehiculo.fromJson(
                e.value as Map<dynamic, dynamic>,
                id: e.key,
              ))
          .toList();
    });
  }
}


import 'package:firebase_database/firebase_database.dart';
import '../models/usuario.dart' as models;

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Referencias a las colecciones
  DatabaseReference get _usuariosRef => _database.child('usuarios');
  DatabaseReference get _clientesRef => _database.child('clientes');
  DatabaseReference get _trabajadoresRef => _database.child('trabajadores');

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
}


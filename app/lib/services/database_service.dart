import 'package:firebase_database/firebase_database.dart';
import '../models/usuario.dart' as models;
import '../models/vehiculo.dart';
import '../models/orden.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Referencias a las colecciones
  DatabaseReference get _usuariosRef => _database.child('usuarios');
  DatabaseReference get _clientesRef => _database.child('clientes');
  DatabaseReference get _trabajadoresRef => _database.child('trabajadores');
  DatabaseReference get _vehiculosRef => _database.child('vehiculos');
  DatabaseReference get _serviciosRef => _database.child('servicios');
  DatabaseReference get _ordenesRef => _database.child('ordenes');

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

  /// Obtener todos los usuarios (Fuente de verdad unificada)
  Future<List<models.Usuario>> getAllUsuarios() async {
    try {
      final snapshot = await _usuariosRef.get(); // Leer de 'usuarios', no de las listas separadas

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.values.map((u) {
        final userMap = Map<String, dynamic>.from(u as Map);
        final rolStr = userMap['rol'] as String? ?? 'CLIENTE';
        final rol = models.RolUsuario.fromJson(rolStr);

        // Deserialización Polimórfica
        switch (rol) {
          case models.RolUsuario.CLIENTE:
            return models.Cliente.fromJson(userMap);
          case models.RolUsuario.TRABAJADOR:
          case models.RolUsuario.ADMIN:
            return models.Trabajador.fromJson(userMap);
        }
      }).toList();
    } catch (e) {
      throw 'Error al obtener usuarios: ${e.toString()}';
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
      print('DEBUG: Iniciando updateUsuario para $uid');
      print('DEBUG: Updates recibidos: $updates');

      // 1. Obtener el rol actual antes de actualizar
      final oldRole = await getRolUsuario(uid);
      print('DEBUG: Rol actual en BD: $oldRole');
      
      // 2. Actualizar el nodo principal de usuarios
      await _usuariosRef.child(uid).update(updates);
      print('DEBUG: Nodo principal actualizado');

      // 3. Determinar el nuevo rol
      models.RolUsuario? newRole;
      if (updates.containsKey('rol')) {
        final rolVal = updates['rol'];
        if (rolVal is String) {
          newRole = models.RolUsuario.fromJson(rolVal);
        } else {
           newRole = models.RolUsuario.fromJson(rolVal.toString());
        }
      } else {
        newRole = oldRole;
      }
      print('DEBUG: Nuevo rol calculado: $newRole');

      if (oldRole == null || newRole == null) {
        print('DEBUG: Error determinando roles (old: $oldRole, new: $newRole)');
        return;
      }

      // 4. Manejar cambio de nodo si el rol cambió
      if (oldRole != newRole) {
        print('DEBUG: Detectado cambio de rol de $oldRole a $newRole. Iniciando migración...');

        // Obtener datos completos (ojo: obtenemos del nodo principal que YA fue actualizado en paso 2)
        // Esto debería traer los datos "nuevos", pero por seguridad, mergeamos manualmente en memoria.
        final userSnapshot = await _usuariosRef.child(uid).get();
        if (!userSnapshot.exists) return;
        
        // Merge manual para asegurar consistencia
        final currentData = Map<String, dynamic>.from(userSnapshot.value as Map);
        final newData = Map<String, dynamic>.from(currentData);
        newData.addAll(updates);
        // Forzar el rol nuevo en el mapa para evitar inconsistencias
        newData['rol'] = newRole.toJson();
        
        print('DEBUG: Datos para migración preparados: $newData');

        // Definir referencias
        DatabaseReference? oldNodeRef;
        DatabaseReference? newNodeRef;

        if (oldRole == models.RolUsuario.CLIENTE) {
          oldNodeRef = _clientesRef.child(uid);
        } else {
          oldNodeRef = _trabajadoresRef.child(uid);
        }

        if (newRole == models.RolUsuario.CLIENTE) {
          newNodeRef = _clientesRef.child(uid);
        } else {
          newNodeRef = _trabajadoresRef.child(uid);
        }

        print('DEBUG: Escribiendo en nuevo nodo: ${newNodeRef.path}');
        // Ejecutar migración: Crear en nuevo, Borrar en viejo
        await newNodeRef.set(newData);
        print('DEBUG: Escritura en nuevo nodo exitosa');
        
        print('DEBUG: Borrando nodo antiguo: ${oldNodeRef.path}');
        await oldNodeRef.remove();
        print('DEBUG: Borrado de nodo antiguo exitoso');
        
      } else {
        // Caso: Mismo Rol -> Solo actualizar el nodo correspondiente
        print('DEBUG: El rol no cambió. Actualizando nodo específico...');
        if (newRole == models.RolUsuario.CLIENTE) {
          await _clientesRef.child(uid).update(updates);
        } else {
          await _trabajadoresRef.child(uid).update(updates);
        }
        print('DEBUG: Actualización de nodo específico exitosa');
      }

    } catch (e) {
      print('DEBUG: Error CRÍTICO en updateUsuario: $e');
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

  /// Alias para compatibilidad
  Future<List<Vehiculo>> getVehiculosByClienteId(String clienteId) {
    return getVehiculosByCliente(clienteId);
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

  // ============================================
  // MÉTODOS PARA SERVICIOS
  // ============================================

  /// Crear un nuevo servicio
  Future<void> createServicio(Servicio servicio) async {
    try {
      await _serviciosRef.child(servicio.id).set(servicio.toJson());
    } catch (e) {
      throw 'Error al crear servicio: ${e.toString()}';
    }
  }

  /// Obtener servicio por ID
  Future<Servicio?> getServicio(String id) async {
    try {
      final snapshot = await _serviciosRef.child(id).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return Servicio.fromJson(data);
    } catch (e) {
      throw 'Error al obtener servicio: ${e.toString()}';
    }
  }

  /// Obtener todos los servicios
  Future<List<Servicio>> getAllServicios() async {
    try {
      final snapshot = await _serviciosRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Servicio.fromJson(e.value as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener servicios: ${e.toString()}';
    }
  }

  /// Stream de todos los servicios
  Stream<List<Servicio>> getServiciosStream() {
    return _serviciosRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return <Servicio>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Servicio.fromJson(e.value as Map<dynamic, dynamic>))
          .toList();
    });
  }

  /// Actualizar servicio
  Future<void> updateServicio(String id, Map<String, dynamic> updates) async {
    try {
      await _serviciosRef.child(id).update(updates);
    } catch (e) {
      throw 'Error al actualizar servicio: ${e.toString()}';
    }
  }

  /// Eliminar servicio
  Future<void> deleteServicio(String id) async {
    try {
      await _serviciosRef.child(id).remove();
    } catch (e) {
      throw 'Error al eliminar servicio: ${e.toString()}';
    }
  }

  // ============================================
  // MÉTODOS PARA ÓRDENES
  // ============================================

  /// Crear una nueva orden
  Future<void> createOrden(Orden orden) async {
    try {
      await _ordenesRef.child(orden.id).set(orden.toJson());
    } catch (e) {
      throw 'Error al crear orden: ${e.toString()}';
    }
  }

  /// Obtener orden por ID
  Future<Orden?> getOrden(String id) async {
    try {
      final snapshot = await _ordenesRef.child(id).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return Orden.fromJson(data);
    } catch (e) {
      throw 'Error al obtener orden: ${e.toString()}';
    }
  }

  /// Obtener todas las órdenes
  Future<List<Orden>> getAllOrdenes() async {
    try {
      final snapshot = await _ordenesRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Orden.fromJson(e.value as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener órdenes: ${e.toString()}';
    }
  }

  /// Stream de todas las órdenes
  Stream<List<Orden>> getOrdenesStream() {
    return _ordenesRef.onValue.map((event) {
      if (!event.snapshot.exists) {
        return <Orden>[];
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Orden.fromJson(e.value as Map<dynamic, dynamic>))
          .toList();
    });
  }

  /// Obtener órdenes de un cliente específico
  Future<List<Orden>> getOrdenesByCliente(String clienteId) async {
    try {
      final snapshot = await _ordenesRef
          .orderByChild('cliente_id')
          .equalTo(clienteId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Orden.fromJson(e.value as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener órdenes del cliente: ${e.toString()}';
    }
  }

  /// Obtener órdenes de un vehículo específico
  Future<List<Orden>> getOrdenesByVehiculo(String vehiculoId) async {
    try {
      final snapshot = await _ordenesRef
          .orderByChild('vehiculo_id')
          .equalTo(vehiculoId)
          .get();

      if (!snapshot.exists) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data.entries
          .map((e) => Orden.fromJson(e.value as Map<dynamic, dynamic>))
          .toList();
    } catch (e) {
      throw 'Error al obtener órdenes del vehículo: ${e.toString()}';
    }
  }

  /// Verificar si un vehículo tiene órdenes activas (EN_COTIZACION, EN_PROCESO, FINALIZADO)
  Future<bool> vehiculoTieneOrdenesActivas(String vehiculoId) async {
    try {
      final ordenes = await getOrdenesByVehiculo(vehiculoId);
      return ordenes.any((orden) =>
          orden.estado == EstadoOrden.EN_COTIZACION ||
          orden.estado == EstadoOrden.EN_PROCESO ||
          orden.estado == EstadoOrden.FINALIZADO);
    } catch (e) {
      throw 'Error al verificar órdenes activas: ${e.toString()}';
    }
  }

  /// Actualizar orden
  Future<void> updateOrden(String id, Map<String, dynamic> updates) async {
    try {
      await _ordenesRef.child(id).update(updates);
    } catch (e) {
      throw 'Error al actualizar orden: ${e.toString()}';
    }
  }

  /// Actualizar estado de la orden
  Future<void> updateEstadoOrden(String id, EstadoOrden estado) async {
    try {
      await _ordenesRef.child(id).update({'estado': estado.toJson()});
    } catch (e) {
      throw 'Error al actualizar estado de la orden: ${e.toString()}';
    }
  }

  /// Actualizar un detalle específico de la orden
  Future<void> updateDetalleOrden(String ordenId, int detalleIndex, Map<String, dynamic> updates) async {
    try {
      await _ordenesRef.child(ordenId).child('detalles').child(detalleIndex.toString()).update(updates);
    } catch (e) {
      throw 'Error al actualizar detalle de la orden: ${e.toString()}';
    }
  }

  /// Eliminar orden
  Future<void> deleteOrden(String id) async {
    try {
      await _ordenesRef.child(id).remove();
    } catch (e) {
      throw 'Error al eliminar orden: ${e.toString()}';
    }
  }
}


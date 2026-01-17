import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';
import '../models/usuario.dart' as models;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener datos del usuario actual desde la base de datos
  Future<models.Usuario?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await _dbService.getUsuario(currentUser!.uid);
  }

  // Obtener rol del usuario actual
  Future<models.RolUsuario?> getCurrentUserRole() async {
    if (currentUser == null) return null;
    return await _dbService.getRolUsuario(currentUser!.uid);
  }

  // Registro de Cliente con email y contraseña
  Future<String> registerCliente({
    required models.Cliente cliente,
  }) async {
    User? adminUser = _auth.currentUser;

    try {
      // Si hay un admin autenticado, guardar referencia
      bool isAdminCreating = adminUser != null;

      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: cliente.correo,
        password: cliente.password!,
      );

      String newUserId = userCredential.user!.uid;

      // Actualizar el UID del cliente con el UID de Firebase Auth
      final clienteConUid = models.Cliente(
        uid: newUserId,
        nombres: cliente.nombres,
        apellidos: cliente.apellidos,
        tipoDocumento: cliente.tipoDocumento,
        numeroDocumento: cliente.numeroDocumento,
        correo: cliente.correo,
        telefono: cliente.telefono,
        direccion: cliente.direccion,
        calificacion: cliente.calificacion,
        fotoPerfil: cliente.fotoPerfil,
      );

      // Guardar datos del cliente en Realtime Database
      await _dbService.createCliente(clienteConUid);

      // Actualizar el displayName en Firebase Auth
      await userCredential.user?.updateDisplayName(
        '${cliente.nombres} ${cliente.apellidos}',
      );

      // Si un admin estaba creando, cerrar sesión del nuevo usuario
      if (isAdminCreating) {
        await _auth.signOut();
        // NOTA: El admin necesitará volver a iniciar sesión manualmente
        // En producción esto se resuelve con Firebase Admin SDK en el backend
      }

      return newUserId;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar cliente: ${e.toString()}';
    }
  }

  // Registro de Trabajador con email y contraseña (solo para ADMIN)
  Future<String> registerTrabajador({
    required models.Trabajador trabajador,
  }) async {
    User? adminUser;
    try {
      // Verificar que el usuario actual sea ADMIN
      final currentUserRole = await getCurrentUserRole();
      if (currentUserRole != models.RolUsuario.ADMIN) {
        throw 'Solo los administradores pueden crear trabajadores.';
      }

      // Guardar referencia al usuario admin actual
      adminUser = _auth.currentUser;
      if (adminUser == null) {
        throw 'No hay sesión de administrador activa.';
      }

      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: trabajador.correo,
        password: trabajador.password!,
      );

      String newUserId = userCredential.user!.uid;

      // Actualizar el UID del trabajador con el UID de Firebase Auth
      final trabajadorConUid = models.Trabajador(
        uid: newUserId,
        nombres: trabajador.nombres,
        apellidos: trabajador.apellidos,
        tipoDocumento: trabajador.tipoDocumento,
        numeroDocumento: trabajador.numeroDocumento,
        correo: trabajador.correo,
        telefono: trabajador.telefono,
        rol: trabajador.rol, // Respetar el rol (puede ser TRABAJADOR o ADMIN)
        area: trabajador.area,
        sueldo: trabajador.sueldo,
        estadoDisponibilidad: trabajador.estadoDisponibilidad,
        calificacion: trabajador.calificacion,
        fotoPerfil: trabajador.fotoPerfil,
      );

      // Guardar datos del trabajador en Realtime Database
      await _dbService.createTrabajador(trabajadorConUid);

      // Actualizar el displayName en Firebase Auth
      await userCredential.user?.updateDisplayName(
        '${trabajador.nombres} ${trabajador.apellidos}',
      );

      // CRÍTICO: Cerrar sesión del trabajador recién creado
      await _auth.signOut();

      // CRÍTICO: El admin necesitará volver a iniciar sesión
      // En producción, esto se resuelve con Firebase Admin SDK en el backend

      return newUserId;
    } on FirebaseAuthException catch (e) {
      // Si hay error, el admin necesitará volver a iniciar sesión
      throw _handleAuthException(e);
    } catch (e) {
      // Si hay error, el admin necesitará volver a iniciar sesión
      throw 'Error al registrar trabajador: ${e.toString()}';
    }
  }

  // Inicio de sesión con email y contraseña
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Restablecer contraseña
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Actualizar perfil de usuario
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw 'Error al actualizar el perfil: ${e.toString()}';
    }
  }

  // Actualizar datos del usuario en la base de datos
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) throw 'Usuario no autenticado';

      await FirebaseDatabase.instance.ref('usuarios/$uid').update(updates);

      // También actualizar en el nodo específico según el rol
      final rolSnapshot = await FirebaseDatabase.instance.ref('usuarios/$uid/rol').get();
      if (rolSnapshot.exists) {
        final rol = rolSnapshot.value as String;
        if (rol == 'CLIENTE') {
          await FirebaseDatabase.instance.ref('clientes/$uid').update(updates);
        } else if (rol == 'TRABAJADOR' || rol == 'ADMIN') {
          await FirebaseDatabase.instance.ref('trabajadores/$uid').update(updates);
        }
      }
    } catch (e) {
      throw 'Error al actualizar datos del usuario: ${e.toString()}';
    }
  }

  // Actualizar datos de otro usuario en la base de datos (para admins)
  Future<void> updateOtherUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await FirebaseDatabase.instance.ref('usuarios/$userId').update(updates);

      // También actualizar en el nodo específico según el rol
      final rolSnapshot = await FirebaseDatabase.instance.ref('usuarios/$userId/rol').get();
      if (rolSnapshot.exists) {
        final rol = rolSnapshot.value as String;
        if (rol == 'CLIENTE') {
          await FirebaseDatabase.instance.ref('clientes/$userId').update(updates);
        } else if (rol == 'TRABAJADOR' || rol == 'ADMIN') {
          await FirebaseDatabase.instance.ref('trabajadores/$userId').update(updates);
        }
      }
    } catch (e) {
      throw 'Error al actualizar datos del usuario: ${e.toString()}';
    }
  }

  // Manejo de excepciones de Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-not-found':
        return 'No se encontró ningún usuario con este correo electrónico.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor, intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}

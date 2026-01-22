import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database_service.dart';
import '../models/usuario.dart' as models;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<models.Usuario?> getCurrentUserData() async {
    if (currentUser == null) return null;
    return await _dbService.getUsuario(currentUser!.uid);
  }

  Future<models.RolUsuario?> getCurrentUserRole() async {
    if (currentUser == null) return null;
    return await _dbService.getRolUsuario(currentUser!.uid);
  }

  Future<String> registerCliente({
    required models.Cliente cliente,
  }) async {
    models.RolUsuario? callerRole;
    if (_auth.currentUser != null) {
      try {
        callerRole = await getCurrentUserRole();
      } catch (_) {
        callerRole = null;
      }
    }

    bool isAdminCreating = callerRole == models.RolUsuario.ADMIN;

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: cliente.correo,
        password: cliente.password!,
      );

      String newUserId = userCredential.user!.uid;

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

      await _dbService.createCliente(clienteConUid);

      await userCredential.user?.updateDisplayName(
        '${cliente.nombres} ${cliente.apellidos}',
      );

      if (isAdminCreating) {
        await _auth.signOut();
      }

      return newUserId;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar cliente: ${e.toString()}';
    }
  }

  Future<String> registerTrabajador({
    required models.Trabajador trabajador,
  }) async {
    try {
      final currentUserRole = await getCurrentUserRole();
      if (currentUserRole != models.RolUsuario.ADMIN) {
        throw 'Solo los administradores pueden crear trabajadores.';
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: trabajador.correo,
        password: trabajador.password!,
      );

      String newUserId = userCredential.user!.uid;

      final trabajadorConUid = models.Trabajador(
        uid: newUserId,
        nombres: trabajador.nombres,
        apellidos: trabajador.apellidos,
        tipoDocumento: trabajador.tipoDocumento,
        numeroDocumento: trabajador.numeroDocumento,
        correo: trabajador.correo,
        telefono: trabajador.telefono,
        rol: trabajador.rol,
        area: trabajador.area,
        sueldo: trabajador.sueldo,
        estadoDisponibilidad: trabajador.estadoDisponibilidad,
        calificacion: trabajador.calificacion,
        fotoPerfil: trabajador.fotoPerfil,
      );

      await _dbService.createTrabajador(trabajadorConUid);

      await userCredential.user?.updateDisplayName(
        '${trabajador.nombres} ${trabajador.apellidos}',
      );

      await _auth.signOut();

      return newUserId;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar trabajador: ${e.toString()}';
    }
  }

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

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw 'Error al actualizar el perfil: ${e.toString()}';
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) throw 'Usuario no autenticado';

      await FirebaseDatabase.instance.ref('usuarios/$uid').update(updates);

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

  Future<void> updateOtherUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await FirebaseDatabase.instance.ref('usuarios/$userId').update(updates);

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
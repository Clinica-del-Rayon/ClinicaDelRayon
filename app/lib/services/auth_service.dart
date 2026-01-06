import 'package:firebase_auth/firebase_auth.dart';
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
  Future<UserCredential?> registerCliente({
    required models.Cliente cliente,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: cliente.correo,
        password: cliente.password!,
      );

      // Actualizar el UID del cliente con el UID de Firebase Auth
      final clienteConUid = models.Cliente(
        uid: userCredential.user!.uid,
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

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al registrar cliente: ${e.toString()}';
    }
  }

  // Registro de Trabajador con email y contraseña (solo para ADMIN)
  Future<UserCredential?> registerTrabajador({
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

      // Actualizar el UID del trabajador con el UID de Firebase Auth
      final trabajadorConUid = models.Trabajador(
        uid: userCredential.user!.uid,
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

      // CRÍTICO: Restaurar la sesión del admin
      // Nota: En producción, deberías usar Firebase Admin SDK
      // Por ahora, el usuario deberá refrescar la sesión

      return userCredential;
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

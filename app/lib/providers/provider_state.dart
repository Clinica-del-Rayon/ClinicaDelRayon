import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/usuario.dart' as models;

class ProviderState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  User? _currentUser;
  models.Usuario? _currentUserData;
  models.RolUsuario? _currentUserRole;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  models.Usuario? get currentUserData => _currentUserData;
  models.RolUsuario? get currentUserRole => _currentUserRole;
  bool get isLoading => _isLoading;

  ProviderState() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserData();
      } else {
        _currentUserData = null;
        _currentUserRole = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUserData = await _authService.getCurrentUserData();
      _currentUserRole = await _authService.getCurrentUserRole();
    } catch (e) {
      debugPrint("Error loading user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (e) {
      rethrow;
    } finally {
      // Listener will handle state update
      _isLoading = false; 
      notifyListeners();
    }
  }

  Future<String> registerCliente(models.Cliente cliente) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.registerCliente(cliente: cliente);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> registerTrabajador(models.Trabajador trabajador) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _authService.registerTrabajador(trabajador: trabajador);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

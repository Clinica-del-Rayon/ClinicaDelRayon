import 'package:flutter/foundation.dart';
import '../models/solicitud.dart';
import '../services/database_service.dart';

class SolicitudesProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Solicitud> _solicitudes = [];
  List<Solicitud> _solicitudesPendientes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Solicitud> get solicitudes => _solicitudes;
  List<Solicitud> get solicitudesPendientes => _solicitudesPendientes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get cantidadPendientes => _solicitudesPendientes.length;

  /// Cargar todas las solicitudes
  Future<void> loadSolicitudes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _solicitudes = await _dbService.getAllSolicitudes();
      _solicitudesPendientes = _solicitudes
          .where((s) => s.estado == EstadoSolicitud.EN_REVISION)
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar solicitudes de un cliente específico
  Future<void> loadSolicitudesByCliente(String clienteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _solicitudes = await _dbService.getSolicitudesByCliente(clienteId);
      _solicitudesPendientes = _solicitudes
          .where((s) => s.estado == EstadoSolicitud.EN_REVISION)
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Escuchar cambios en tiempo real (para admin)
  Stream<List<Solicitud>> getSolicitudesStream() {
    return _dbService.getSolicitudesStream();
  }

  /// Escuchar cambios para un cliente
  Stream<List<Solicitud>> getSolicitudesByClienteStream(String clienteId) {
    return _dbService.getSolicitudesByClienteStream(clienteId);
  }

  /// Crear nueva solicitud
  Future<void> createSolicitud(Solicitud solicitud) async {
    try {
      await _dbService.createSolicitud(solicitud);
      await loadSolicitudes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Aceptar solicitud
  Future<void> aceptarSolicitud(
    String solicitudId,
    DateTime fechaAceptada,
    int duracionEstimadaHoras,
  ) async {
    try {
      await _dbService.aceptarSolicitud(
        solicitudId,
        fechaAceptada,
        duracionEstimadaHoras,
      );
      await loadSolicitudes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Rechazar solicitud
  Future<void> rechazarSolicitud(String solicitudId, String motivo) async {
    try {
      await _dbService.rechazarSolicitud(solicitudId, motivo);
      await loadSolicitudes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Agregar propuesta de fecha
  Future<void> agregarPropuestaFecha(
    String solicitudId,
    PropuestaFecha propuesta,
  ) async {
    try {
      await _dbService.agregarPropuestaFecha(solicitudId, propuesta);
      await loadSolicitudes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Obtener solicitudes aceptadas (para calendario)
  List<Solicitud> get solicitudesAceptadas {
    return _solicitudes
        .where((s) => s.estado == EstadoSolicitud.ACEPTADA)
        .toList();
  }

  /// Obtener solicitudes por fecha (para calendario)
  List<Solicitud> getSolicitudesByFecha(DateTime fecha) {
    return solicitudesAceptadas.where((s) {
      final fechaAceptada = s.fechaAceptada;
      if (fechaAceptada == null) return false;
      return fechaAceptada.year == fecha.year &&
          fechaAceptada.month == fecha.month &&
          fechaAceptada.day == fecha.day;
    }).toList();
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}


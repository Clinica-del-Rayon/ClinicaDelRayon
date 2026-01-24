import '../models/vehiculo.dart';

class VehiculoValidator {
  /// Valida el formato de placa según el tipo de vehículo
  /// Carro: LLL-NNN (3 letras, 3 números)
  /// Moto: LLL-NNL (3 letras, 2 números, 1 letra)
  static String? validatePlaca(String? placa, TipoVehiculo tipoVehiculo) {
    if (placa == null || placa.trim().isEmpty) {
      return 'Por favor ingrese la placa';
    }

    final placaUpper = placa.trim().toUpperCase().replaceAll('-', '').replaceAll(' ', '');

    if (tipoVehiculo == TipoVehiculo.CARRO) {
      // Formato: LLL###
      final regexCarro = RegExp(r'^[A-Z]{3}[0-9]{3}$');
      if (!regexCarro.hasMatch(placaUpper)) {
        return 'Formato inválido. Debe ser: LLL###\nEjemplo: ABC123';
      }
    } else if (tipoVehiculo == TipoVehiculo.MOTO) {
      // Formato: LLL##L
      final regexMoto = RegExp(r'^[A-Z]{3}[0-9]{2}[A-Z]$');
      if (!regexMoto.hasMatch(placaUpper)) {
        return 'Formato inválido. Debe ser: LLL##L\nEjemplo: ABC12D';
      }
    }

    return null;
  }

  /// Formatea la placa con guión
  /// Ejemplo: ABC123 -> ABC-123, ABC12D -> ABC-12D
  static String formatPlaca(String placa, TipoVehiculo tipoVehiculo) {
    final placaUpper = placa.trim().toUpperCase().replaceAll('-', '').replaceAll(' ', '');

    if (tipoVehiculo == TipoVehiculo.CARRO && placaUpper.length == 6) {
      return '${placaUpper.substring(0, 3)}-${placaUpper.substring(3)}';
    } else if (tipoVehiculo == TipoVehiculo.MOTO && placaUpper.length == 6) {
      return '${placaUpper.substring(0, 3)}-${placaUpper.substring(3)}';
    }

    return placaUpper;
  }

  /// Obtiene hint text según el tipo de vehículo
  static String getPlacaHint(TipoVehiculo tipoVehiculo) {
    return tipoVehiculo == TipoVehiculo.CARRO
        ? 'ABC123 o ABC-123'
        : 'ABC12D o ABC-12D';
  }

  /// Obtiene label text según el tipo de vehículo
  static String getPlacaLabel(TipoVehiculo tipoVehiculo) {
    return tipoVehiculo == TipoVehiculo.CARRO
        ? 'Placa (LLL-###)'
        : 'Placa (LLL-##L)';
  }
}


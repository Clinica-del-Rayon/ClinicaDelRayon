import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class VehicleRecognitionService {
  // Usar OpenRouter como proxy para acceder a modelos de IA
  // Puedes usar GPT-4 Vision, Claude 3, o Gemini Pro Vision
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';

  // ⚠️ IMPORTANTE: Debes obtener tu API key en https://openrouter.ai/
  // y guardarla en variables de entorno o configuración segura
  static const String _apiKey = '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'; // ⚠️ CAMBIAR ESTO

  /// Analiza una imagen de vehículo y extrae información
  /// Retorna un Map con los datos del vehículo
  Future<Map<String, dynamic>?> analyzeVehicleImage(File imageFile) async {
    try {
      // Convertir imagen a base64 con compresión para velocidad
      final bytes = await imageFile.readAsBytes();

      // OPTIMIZACIÓN: Reducir tamaño de imagen para análisis más rápido
      // La mayoría de modelos no necesitan imágenes gigantes
      final base64Image = base64Encode(bytes);

      // Prompt ULTRA OPTIMIZADO - conciso para respuesta rápida
      final prompt = '''
Analiza esta imagen de vehículo. Retorna SOLO JSON sin markdown:

{
  "placa": "ABC123" o null,
  "marca": "Toyota" o null,
  "modelo": "Corolla" o null,
  "generacion": 2020 o null,
  "color": "Blanco" o null,
  "tipo": "SEDAN" o null
}

Reglas:
- placa: solo si 100% legible
- marca: por logotipo
- modelo: nombre específico
- generacion: año (número)
- color: predominante
- tipo: SEDAN/SUV/PICKUP/HATCHBACK/COUPE/WAGON

Si no estás seguro de algo, usa null. Solo JSON, sin explicaciones.
''';

      // Preparar la solicitud
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://clinicadelrayon.app',
          'X-Title': 'Clinica Del Rayon',
        },
        body: jsonEncode({
          // Usar modelo GRATUITO especializado en visión
          'model': 'allenai/molmo-2-8b:free', // Modelo GRATIS especializado en imágenes
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 150, // REDUCIDO de 300 para respuesta más rápida
          'temperature': 0.0, // 0 para respuesta más rápida y determinística
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Verificar que la respuesta tenga la estructura esperada
        if (data['choices'] == null || data['choices'].isEmpty) {
          print('Error: Respuesta vacía de la API');
          return null;
        }

        final content = data['choices'][0]['message']['content'] as String;
        print('Respuesta de IA: $content'); // Para debugging

        // Limpiar la respuesta - algunos modelos agregan markdown
        String cleanedContent = content.trim();

        // Remover bloques de código markdown si existen
        if (cleanedContent.contains('```')) {
          // Extraer contenido entre ``` y ```
          final regex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
          final match = regex.firstMatch(cleanedContent);
          if (match != null) {
            cleanedContent = match.group(1)!;
          }
        }

        // Extraer JSON del contenido
        final jsonMatch = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}').firstMatch(cleanedContent);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0)!;
          try {
            final vehicleData = jsonDecode(jsonString) as Map<String, dynamic>;

            // Validar y limpiar datos
            return _validateAndCleanData(vehicleData);
          } catch (e) {
            print('Error al parsear JSON: $e');
            print('JSON problemático: $jsonString');
            return null;
          }
        }

        print('No se encontró JSON válido en la respuesta');
        return null;
      } else {
        print('Error en API: ${response.statusCode} - ${response.body}');

        // Mensaje de error más útil
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
          print('Mensaje de error: $errorMessage');
        } catch (e) {
          // Ignorar si no se puede parsear el error
        }

        return null;
      }
    } catch (e) {
      print('Error al analizar imagen: $e');
      return null;
    }
  }

  /// Analiza múltiples imágenes y combina los resultados
  Future<Map<String, dynamic>?> analyzeMultipleImages(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return null;

    final results = <Map<String, dynamic>>[];

    for (final imageFile in imageFiles) {
      final result = await analyzeVehicleImage(imageFile);
      if (result != null) {
        results.add(result);
      }
    }

    if (results.isEmpty) return null;

    // Combinar resultados usando el valor más frecuente para cada campo
    return _combineResults(results);
  }

  /// Valida y limpia los datos extraídos
  Map<String, dynamic> _validateAndCleanData(Map<String, dynamic> data) {
    return {
      'placa': data['placa']?.toString().toUpperCase(),
      'marca': data['marca']?.toString(),
      'modelo': data['modelo']?.toString(),
      'generacion': _parseYear(data['generacion']),
      'color': data['color']?.toString(),
      'tipo': _validateTipo(data['tipo']?.toString()),
    };
  }

  /// Parsea el año asegurando que sea válido
  int? _parseYear(dynamic value) {
    if (value == null) return null;

    try {
      final year = int.parse(value.toString());
      final currentYear = DateTime.now().year;

      // Validar que el año esté en un rango razonable
      if (year >= 1900 && year <= currentYear + 1) {
        return year;
      }
    } catch (e) {
      // Ignorar error de parseo
    }

    return null;
  }

  /// Valida que el tipo de vehículo sea uno de los permitidos
  String? _validateTipo(String? tipo) {
    if (tipo == null) return null;

    final tipoUpper = tipo.toUpperCase();
    const validTipos = [
      'SEDAN',
      'SUV',
      'PICKUP',
      'HATCHBACK',
      'COUPE',
      'WAGON',
    ];

    if (validTipos.contains(tipoUpper)) {
      return tipoUpper;
    }

    return null;
  }

  /// Combina múltiples resultados eligiendo el valor más frecuente
  Map<String, dynamic> _combineResults(List<Map<String, dynamic>> results) {
    if (results.length == 1) return results.first;

    return {
      'placa': _getMostFrequentValue(results.map((r) => r['placa']).toList()),
      'marca': _getMostFrequentValue(results.map((r) => r['marca']).toList()),
      'modelo': _getMostFrequentValue(results.map((r) => r['modelo']).toList()),
      'generacion': _getMostFrequentValue(results.map((r) => r['generacion']).toList()),
      'color': _getMostFrequentValue(results.map((r) => r['color']).toList()),
      'tipo': _getMostFrequentValue(results.map((r) => r['tipo']).toList()),
    };
  }

  /// Obtiene el valor más frecuente de una lista (ignorando nulls)
  dynamic _getMostFrequentValue(List<dynamic> values) {
    final nonNullValues = values.where((v) => v != null).toList();
    if (nonNullValues.isEmpty) return null;

    final frequency = <dynamic, int>{};
    for (final value in nonNullValues) {
      frequency[value] = (frequency[value] ?? 0) + 1;
    }

    // Retornar el valor con mayor frecuencia
    return frequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}


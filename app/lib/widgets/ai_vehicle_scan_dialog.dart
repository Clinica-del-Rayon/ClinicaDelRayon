import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/vehicle_recognition_service.dart';

class AIVehicleScanDialog extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataExtracted; // Opcional ahora

  const AIVehicleScanDialog({
    super.key,
    this.onDataExtracted, // Opcional
  });

  @override
  State<AIVehicleScanDialog> createState() => _AIVehicleScanDialogState();
}

class _AIVehicleScanDialogState extends State<AIVehicleScanDialog> {
  final ImagePicker _picker = ImagePicker();
  final VehicleRecognitionService _aiService = VehicleRecognitionService();

  List<File> _selectedImages = [];
  bool _isAnalyzing = false;
  String _statusMessage = '';

  Future<void> _takePhoto() async {
    // Verificar límite de 10 fotos
    if (_selectedImages.length >= 10) {
      _showError('Máximo 10 fotos permitidas');
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showError('Error al tomar foto: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    // Verificar cuántas fotos más se pueden agregar
    final fotosRestantes = 10 - _selectedImages.length;
    if (fotosRestantes <= 0) {
      _showError('Máximo 10 fotos permitidas');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // Solo agregar hasta el límite de 10
        final imagesToAdd = images.take(fotosRestantes).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
        });

        if (images.length > fotosRestantes) {
          _showError('Solo se agregaron $fotosRestantes fotos (límite: 10 fotos)');
        }
      }
    } catch (e) {
      _showError('Error al seleccionar imágenes: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _analyzeWithAI() async {
    if (_selectedImages.isEmpty) {
      _showError('Por favor, agrega al menos una foto del vehículo');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Analizando imágenes con IA...';
    });

    try {
      Map<String, dynamic>? vehicleData;

      if (_selectedImages.length == 1) {
        vehicleData = await _aiService.analyzeVehicleImage(_selectedImages.first);
      } else {
        vehicleData = await _aiService.analyzeMultipleImages(_selectedImages);
      }

      if (vehicleData != null) {
        if (mounted) {
          // Retornar datos Y las fotos seleccionadas
          final result = {
            'vehicleData': vehicleData,
            'images': _selectedImages,
          };
          Navigator.pop(context, result);

          // Luego mostrar el snackbar en el contexto padre
          Future.delayed(Duration(milliseconds: 100), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Datos extraídos exitosamente con IA'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        }
      } else {
        _showError('No se pudo extraer información del vehículo. Intenta con otras fotos más claras.');
      }
    } catch (e) {
      _showError('Error al analizar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF1E88E5);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Título
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_awesome, color: primaryColor, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Escaneo con IA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      Text(
                        'Toma fotos del vehículo',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: _isAnalyzing ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Botones de captura
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _takePhoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Cámara'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Galería'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Información
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: primaryColor, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Toma fotos claras del frente, costados y placa del vehículo para mejores resultados.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Lista de imágenes
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'Imágenes seleccionadas (${_selectedImages.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[800],
                ),
              ),
              SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedImages[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (!_isAnalyzing)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
            ] else ...[
              Container(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No hay imágenes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Mensaje de estado
            if (_statusMessage.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Botón de analizar
            ElevatedButton.icon(
              onPressed: _isAnalyzing || _selectedImages.isEmpty
                  ? null
                  : _analyzeWithAI,
              icon: Icon(Icons.auto_awesome),
              label: Text(
                _isAnalyzing ? 'Analizando...' : 'Analizar con IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/vehiculo.dart';

class CreateVehiculoScreen extends StatefulWidget {
  final String clienteId;
  final String clienteNombre;

  const CreateVehiculoScreen({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  State<CreateVehiculoScreen> createState() => _CreateVehiculoScreenState();
}

class _CreateVehiculoScreenState extends State<CreateVehiculoScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _generacionController = TextEditingController();
  final _colorController = TextEditingController();

  TipoVehiculo _tipoVehiculo = TipoVehiculo.CARRO;
  List<XFile> _imagenesLocales = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _generacionController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _storageService.takePicture();
      if (image != null) {
        setState(() {
          _imagenesLocales.add(image);
        });
      }
    } catch (e) {
      _mostrarError(e.toString());
    }
  }

  Future<void> _seleccionarDesdeGaleria() async {
    try {
      final List<XFile> images = await _storageService.pickMultipleImages();
      setState(() {
        _imagenesLocales.addAll(images);
      });
    } catch (e) {
      _mostrarError(e.toString());
    }
  }

  void _eliminarFoto(int index) {
    setState(() {
      _imagenesLocales.removeAt(index);
    });
  }

  Future<void> _crearVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar mínimo 3 fotos
    if (_imagenesLocales.length < 3) {
      _mostrarError('Debes agregar mínimo 3 fotos del vehículo');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear vehículo temporalmente para obtener ID
      final vehiculoTemp = Vehiculo(
        placa: _placaController.text.trim().toUpperCase(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        generacion: int.parse(_generacionController.text.trim()),
        color: _colorController.text.trim(),
        clienteId: widget.clienteId,
        tipoVehiculo: _tipoVehiculo,
      );

      // Crear vehículo en DB y obtener ID
      final vehiculoId = await _dbService.createVehiculo(vehiculoTemp);

      // Subir fotos a Firebase Storage
      final List<String> fotosUrls = [];
      for (int i = 0; i < _imagenesLocales.length; i++) {
        _mostrarProgreso('Subiendo foto ${i + 1} de ${_imagenesLocales.length}...');

        final url = await _storageService.uploadVehiclePhoto(
          vehiculoId,
          _imagenesLocales[i],
          i,
        );
        fotosUrls.add(url);
      }

      // Actualizar vehículo con las URLs de las fotos
      await _dbService.updateVehiculo(vehiculoId, {
        'fotos_urls': fotosUrls,
      });

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        Navigator.pop(context); // Volver a lista de vehículos

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text('¡Vehículo Registrado!'),
              ],
            ),
            content: Text(
              'El vehículo ha sido registrado exitosamente con ${fotosUrls.length} fotos.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        _mostrarError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _mostrarProgreso(String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text(mensaje)),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Vehículo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del cliente
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Cliente: ${widget.clienteNombre}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Tipo de vehículo
              Text(
                'Tipo de Vehículo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              SegmentedButton<TipoVehiculo>(
                segments: const [
                  ButtonSegment(
                    value: TipoVehiculo.CARRO,
                    label: Text('Carro'),
                    icon: Icon(Icons.directions_car),
                  ),
                  ButtonSegment(
                    value: TipoVehiculo.MOTO,
                    label: Text('Moto'),
                    icon: Icon(Icons.two_wheeler),
                  ),
                ],
                selected: {_tipoVehiculo},
                onSelectionChanged: (Set<TipoVehiculo> newSelection) {
                  setState(() {
                    _tipoVehiculo = newSelection.first;
                  });
                },
              ),
              SizedBox(height: 24),

              // Campos del vehículo
              TextFormField(
                controller: _placaController,
                decoration: InputDecoration(
                  labelText: 'Placa',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                  hintText: 'ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ingresa la placa' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _marcaController,
                decoration: InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Icons.branding_watermark),
                  border: OutlineInputBorder(),
                  hintText: 'Toyota, Chevrolet, etc.',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ingresa la marca' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _modeloController,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                  hintText: 'Corolla, Spark, etc.',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ingresa el modelo' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _generacionController,
                decoration: InputDecoration(
                  labelText: 'Año/Generación',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                  hintText: '2024',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Ingresa el año';
                  final year = int.tryParse(value!);
                  if (year == null) return 'Año inválido';
                  if (year < 1900 || year > DateTime.now().year + 1) {
                    return 'Año fuera de rango';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(
                  labelText: 'Color',
                  prefixIcon: Icon(Icons.palette),
                  border: OutlineInputBorder(),
                  hintText: 'Rojo, Azul, Negro, etc.',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Ingresa el color' : null,
              ),
              SizedBox(height: 24),

              // Sección de fotos
              Text(
                'Fotos del Vehículo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Mínimo 3 fotos requeridas (${_imagenesLocales.length}/3)',
                style: TextStyle(
                  color: _imagenesLocales.length < 3
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),

              // Botones para agregar fotos
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _tomarFoto,
                      icon: Icon(Icons.camera_alt),
                      label: Text('Tomar Foto'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarDesdeGaleria,
                      icon: Icon(Icons.photo_library),
                      label: Text('Galería'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Grid de fotos
              if (_imagenesLocales.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _imagenesLocales.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_imagenesLocales[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarFoto(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              SizedBox(height: 32),

              // Botón crear
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _crearVehiculo,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.check),
                label: Text(
                  _isLoading ? 'Creando...' : 'Registrar Vehículo',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


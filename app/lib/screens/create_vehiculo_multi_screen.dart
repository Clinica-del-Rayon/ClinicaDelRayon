import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/vehiculo.dart';

class CreateVehiculoMultiScreen extends StatefulWidget {
  const CreateVehiculoMultiScreen({super.key});

  @override
  State<CreateVehiculoMultiScreen> createState() => _CreateVehiculoMultiScreenState();
}

class _CreateVehiculoMultiScreenState extends State<CreateVehiculoMultiScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  late List<String> _clienteIds;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clienteIds = ModalRoute.of(context)!.settings.arguments as List<String>;
  }

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

  void _eliminarImagen(int index) {
    setState(() {
      _imagenesLocales.removeAt(index);
    });
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

  Future<void> _crearVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagenesLocales.length < 3) {
      _mostrarError('Debes agregar mínimo 3 fotos');
      return;
    }

    setState(() => _isLoading = true);

    String? vehiculoId;
    try {
      // Crear vehículo temporalmente para obtener ID
      final vehiculoTemp = Vehiculo(
        placa: _placaController.text.trim().toUpperCase(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        generacion: int.parse(_generacionController.text.trim()),
        color: _colorController.text.trim(),
        clienteIds: _clienteIds,
        tipoVehiculo: _tipoVehiculo,
      );

      // Crear vehículo en DB y obtener ID (esto ya valida placa duplicada)
      vehiculoId = await _dbService.createVehiculo(vehiculoTemp);

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

        // Mostrar mensaje de éxito con SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Vehículo registrado exitosamente con ${fotosUrls.length} fotos'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Si se creó el vehículo pero falló la subida de fotos, eliminar el vehículo
      if (vehiculoId != null) {
        try {
          await _dbService.deleteVehiculo(vehiculoId);
          print('Vehículo eliminado tras error en subida de fotos');
        } catch (deleteError) {
          print('Error al eliminar vehículo tras fallo: $deleteError');
        }
      }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Vehículo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info de clientes seleccionados
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '${_clienteIds.length} cliente(s) seleccionado(s)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Tipo de vehículo
              Text(
                'Tipo de Vehículo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

              // Campos del formulario
              TextFormField(
                controller: _placaController,
                decoration: InputDecoration(
                  labelText: 'Placa',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value?.isEmpty ?? true ? 'Ingresa la placa' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _marcaController,
                decoration: InputDecoration(
                  labelText: 'Marca',
                  prefixIcon: Icon(Icons.branding_watermark),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Ingresa la marca' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _modeloController,
                decoration: InputDecoration(
                  labelText: 'Modelo',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Ingresa el modelo' : null,
              ),
              SizedBox(height: 16),

              TextFormField(
                controller: _generacionController,
                decoration: InputDecoration(
                  labelText: 'Año/Generación',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
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
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Ingresa el color' : null,
              ),
              SizedBox(height: 24),

              // Sección de fotos
              Text(
                'Fotos del Vehículo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Mínimo 3 fotos (${_imagenesLocales.length}/3)',
                style: TextStyle(
                  color: _imagenesLocales.length < 3 ? Colors.red : Colors.green,
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
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _seleccionarDesdeGaleria,
                      icon: Icon(Icons.photo_library),
                      label: Text('Galería'),
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
                            onTap: () => _eliminarImagen(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, color: Colors.white, size: 20),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.add),
                label: Text(
                  _isLoading ? 'Creando...' : 'Crear Vehículo',
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


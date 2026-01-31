import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/vehiculo.dart';
import '../utils/vehiculo_validator.dart';
import '../widgets/ai_vehicle_scan_dialog.dart';

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

  Future<void> _escanearConIA() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AIVehicleScanDialog(),
    );

    if (result != null) {
      print('Resultado de IA recibido: $result'); // Debug

      // Extraer datos del vehículo
      final vehicleData = result['vehicleData'] as Map<String, dynamic>?;
      // Extraer fotos - cast correcto
      final imagesList = result['images'];

      if (vehicleData != null) {
        _llenarCamposConDatosIA(vehicleData);
      }

      // Agregar las fotos usadas en el escaneo a las fotos del vehículo
      if (imagesList != null && imagesList is List) {
        setState(() {
          // Convertir File a XFile y agregar
          for (var file in imagesList) {
            if (file is File) {
              _imagenesLocales.add(XFile(file.path));
              print('Foto agregada: ${file.path}'); // Debug
            }
          }
        });

        print('Total de fotos después de IA: ${_imagenesLocales.length}'); // Debug
      }
    }
  }

  void _llenarCamposConDatosIA(Map<String, dynamic> data) {
    setState(() {
      // Solo llenar los campos que la IA pudo detectar (que no sean null o vacíos)
      if (data['placa'] != null && data['placa'].toString().isNotEmpty) {
        _placaController.text = data['placa'];
      }
      if (data['marca'] != null && data['marca'].toString().isNotEmpty) {
        _marcaController.text = data['marca'];
      }
      if (data['modelo'] != null && data['modelo'].toString().isNotEmpty) {
        _modeloController.text = data['modelo'];
      }
      if (data['generacion'] != null) {
        _generacionController.text = data['generacion'].toString();
      }
      if (data['color'] != null && data['color'].toString().isNotEmpty) {
        _colorController.text = data['color'];
      }
      if (data['tipo'] != null && data['tipo'].toString().isNotEmpty) {
        final tipo = data['tipo'].toString().toUpperCase();
        _tipoVehiculo = (tipo == 'MOTO' || tipo == 'MOTORCYCLE')
            ? TipoVehiculo.MOTO
            : TipoVehiculo.CARRO;
      }
    });

    // Mostrar mensaje indicando qué campos se llenaron
    final camposLlenados = <String>[];
    if (data['placa'] != null && data['placa'].toString().isNotEmpty) {
      camposLlenados.add('Placa');
    }
    if (data['marca'] != null && data['marca'].toString().isNotEmpty) {
      camposLlenados.add('Marca');
    }
    if (data['modelo'] != null && data['modelo'].toString().isNotEmpty) {
      camposLlenados.add('Modelo');
    }
    if (data['generacion'] != null) camposLlenados.add('Año');
    if (data['color'] != null && data['color'].toString().isNotEmpty) {
      camposLlenados.add('Color');
    }
    if (data['tipo'] != null && data['tipo'].toString().isNotEmpty) {
      camposLlenados.add('Tipo');
    }

    if (camposLlenados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo detectar ningún dato. Completa manualmente.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Campos detectados: ${camposLlenados.join(", ")}. ${camposLlenados.length < 6 ? "Completa los demás manualmente." : "Verifica los datos."}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _crearVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar rango de fotos: mínimo 3, máximo 10
    if (_imagenesLocales.length < 3) {
      _mostrarError('Debes agregar mínimo 3 fotos del vehículo');
      return;
    }

    if (_imagenesLocales.length > 10) {
      _mostrarError('Máximo 10 fotos permitidas. Por favor elimina ${_imagenesLocales.length - 10} foto(s)');
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
        clienteIds: [widget.clienteId], // Usar lista con el cliente actual
        tipoVehiculo: _tipoVehiculo,
      );

      // Crear vehículo en DB y obtener ID (esto ya valida placa duplicada)
      vehiculoId = await _dbService.createVehiculo(vehiculoTemp);

      // Mostrar un solo diálogo de progreso
      if (mounted) {
        _mostrarProgreso('Subiendo ${_imagenesLocales.length} fotos...');
      }

      // Subir fotos a Firebase Storage
      final List<String> fotosUrls = [];
      for (int i = 0; i < _imagenesLocales.length; i++) {
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
        Navigator.pop(context, true); // Volver a lista con resultado exitoso

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Vehículo registrado exitosamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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

              // Botón de escaneo con IA
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _escanearConIA,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Escanear con IA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Detectar automáticamente los datos del vehículo',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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
                  labelText: VehiculoValidator.getPlacaLabel(_tipoVehiculo),
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                  hintText: VehiculoValidator.getPlacaHint(_tipoVehiculo),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  // Auto-formatear mientras escribe
                  if (value.length == 6 && !value.contains('-')) {
                    _placaController.value = TextEditingValue(
                      text: VehiculoValidator.formatPlaca(value, _tipoVehiculo),
                      selection: TextSelection.collapsed(offset: 7),
                    );
                  }
                },
                validator: (value) => VehiculoValidator.validatePlaca(value, _tipoVehiculo),
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


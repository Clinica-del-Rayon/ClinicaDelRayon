import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/vehiculo.dart';
import '../models/usuario.dart';

class EditVehiculoScreen extends StatefulWidget {
  const EditVehiculoScreen({super.key});

  @override
  State<EditVehiculoScreen> createState() => _EditVehiculoScreenState();
}

class _EditVehiculoScreenState extends State<EditVehiculoScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  late Vehiculo _vehiculo;
  List<Cliente> _todosClientes = [];
  List<String> _clientesSeleccionados = [];

  // Controladores
  late TextEditingController _placaController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _generacionController;
  late TextEditingController _colorController;

  late TipoVehiculo _tipoVehiculo;
  List<String> _fotosUrlsExistentes = [];
  List<XFile> _nuevasFotos = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _vehiculo = ModalRoute.of(context)!.settings.arguments as Vehiculo;

    // Inicializar controladores
    _placaController = TextEditingController(text: _vehiculo.placa);
    _marcaController = TextEditingController(text: _vehiculo.marca);
    _modeloController = TextEditingController(text: _vehiculo.modelo);
    _generacionController = TextEditingController(text: _vehiculo.generacion.toString());
    _colorController = TextEditingController(text: _vehiculo.color);
    _tipoVehiculo = _vehiculo.tipoVehiculo;
    _fotosUrlsExistentes = List.from(_vehiculo.fotosUrls);
    _clientesSeleccionados = List.from(_vehiculo.clienteIds);

    _loadClientes();
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

  Future<void> _loadClientes() async {
    try {
      final clientes = await _dbService.getAllClientes();
      setState(() {
        _todosClientes = clientes;
      });
    } catch (e) {
      _mostrarError('Error al cargar clientes: ${e.toString()}');
    }
  }

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _storageService.takePicture();
      if (image != null) {
        setState(() {
          _nuevasFotos.add(image);
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
        _nuevasFotos.addAll(images);
      });
    } catch (e) {
      _mostrarError(e.toString());
    }
  }

  void _eliminarFotoExistente(int index) {
    setState(() {
      _fotosUrlsExistentes.removeAt(index);
    });
  }

  void _eliminarNuevaFoto(int index) {
    setState(() {
      _nuevasFotos.removeAt(index);
    });
  }

  void _toggleCliente(String clienteId) {
    setState(() {
      if (_clientesSeleccionados.contains(clienteId)) {
        _clientesSeleccionados.remove(clienteId);
      } else {
        _clientesSeleccionados.add(clienteId);
      }
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar al menos 3 fotos totales
    final totalFotos = _fotosUrlsExistentes.length + _nuevasFotos.length;
    if (totalFotos < 3) {
      _mostrarError('El vehículo debe tener mínimo 3 fotos');
      return;
    }

    // Validar al menos 1 cliente
    if (_clientesSeleccionados.isEmpty) {
      _mostrarError('Debes seleccionar al menos un cliente');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Subir nuevas fotos si hay
      List<String> nuevasUrls = [];
      if (_nuevasFotos.isNotEmpty) {
        for (int i = 0; i < _nuevasFotos.length; i++) {
          _mostrarProgreso('Subiendo foto ${i + 1} de ${_nuevasFotos.length}...');

          final url = await _storageService.uploadVehiclePhoto(
            _vehiculo.id!,
            _nuevasFotos[i],
            _fotosUrlsExistentes.length + i,
          );
          nuevasUrls.add(url);
        }
      }

      // Combinar fotos existentes con nuevas
      final todasLasFotos = [..._fotosUrlsExistentes, ...nuevasUrls];

      // Actualizar vehículo
      await _dbService.updateVehiculo(_vehiculo.id!, {
        'placa': _placaController.text.trim().toUpperCase(),
        'marca': _marcaController.text.trim(),
        'modelo': _modeloController.text.trim(),
        'generacion': int.parse(_generacionController.text.trim()),
        'color': _colorController.text.trim(),
        'cliente_ids': _clientesSeleccionados,
        'tipo_vehiculo': _tipoVehiculo.toJson(),
        'fotos_urls': todasLasFotos,
      });

      if (mounted) {
        Navigator.pop(context); // Cerrar loading si está abierto
        Navigator.pop(context, true); // Volver con resultado exitoso

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Vehículo actualizado exitosamente')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
        title: Text('Editar Vehículo'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Campos del vehículo
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

              // Clientes asociados
              Text(
                'Clientes Asociados',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Selecciona al menos un cliente (${_clientesSeleccionados.length} seleccionados)',
                style: TextStyle(
                  color: _clientesSeleccionados.isEmpty ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),

              Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _todosClientes.length,
                  itemBuilder: (context, index) {
                    final cliente = _todosClientes[index];
                    final isSelected = _clientesSeleccionados.contains(cliente.uid);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => _toggleCliente(cliente.uid),
                      title: Text('${cliente.nombres} ${cliente.apellidos}'),
                      subtitle: Text(cliente.correo),
                      secondary: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),

              // Fotos
              Text(
                'Fotos del Vehículo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Mínimo 3 fotos (${_fotosUrlsExistentes.length + _nuevasFotos.length}/3)',
                style: TextStyle(
                  color: (_fotosUrlsExistentes.length + _nuevasFotos.length) < 3
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

              // Grid de fotos existentes
              if (_fotosUrlsExistentes.isNotEmpty) ...[
                Text('Fotos actuales:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _fotosUrlsExistentes.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _fotosUrlsExistentes[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarFotoExistente(index),
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
                SizedBox(height: 16),
              ],

              // Grid de nuevas fotos
              if (_nuevasFotos.isNotEmpty) ...[
                Text('Nuevas fotos:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _nuevasFotos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_nuevasFotos[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarNuevaFoto(index),
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
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NUEVA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16),
              ],

              SizedBox(height: 32),

              // Botón guardar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _guardarCambios,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Guardando...' : 'Guardar Cambios',
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


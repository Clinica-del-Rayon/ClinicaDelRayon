import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/orden.dart';
import '../widgets/fotos_servicio_selector.dart';

class AvancesServicioScreen extends StatefulWidget {
  final Orden orden;
  final DetalleOrden detalle;
  final int detalleIndex;

  const AvancesServicioScreen({
    super.key,
    required this.orden,
    required this.detalle,
    required this.detalleIndex,
  });

  @override
  State<AvancesServicioScreen> createState() => _AvancesServicioScreenState();
}

class _AvancesServicioScreenState extends State<AvancesServicioScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();

  late List<AvanceServicio> _avances;
  late int _progresoActual;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _avances = List.from(widget.detalle.avances);
    _progresoActual = widget.detalle.progreso;
  }

  Future<void> _mostrarDialogoNuevoAvance() async {
    final observacionesController = TextEditingController();
    final progresoController = TextEditingController(text: _progresoActual.toString());
    List<XFile> fotosAvance = [];

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Nuevo Avance'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Servicio: ${widget.detalle.servicioNombre}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: progresoController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) return newValue;
                          final value = int.tryParse(newValue.text);
                          if (value == null || value < 0 || value > 100) {
                            return oldValue;
                          }
                          return newValue;
                        }),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Progreso (%)',
                        prefixIcon: const Icon(Icons.percent),
                        border: const OutlineInputBorder(),
                        helperText: 'Progreso actual: $_progresoActual%',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: observacionesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones del avance',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                        hintText: 'Describe el trabajo realizado...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    FotosServicioSelector(
                      titulo: 'Fotos del avance',
                      onFotosSeleccionadas: (fotos) {
                        setDialogState(() {
                          fotosAvance = fotos;
                        });
                      },
                      maxFotos: 5,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final progreso = int.tryParse(progresoController.text);
                  final observaciones = observacionesController.text.trim();

                  if (progreso == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingresa un progreso válido (0-100)'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (observaciones.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Las observaciones son obligatorias'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'progreso': progreso,
                    'observaciones': observaciones,
                    'fotos': fotosAvance,
                  });
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Agregar'),
              ),
            ],
          );
        },
      ),
    );

    if (resultado != null) {
      await _agregarAvance(
        resultado['progreso'],
        resultado['observaciones'],
        resultado['fotos'],
      );
    }
  }

  Future<void> _agregarAvance(int nuevoProgreso, String observaciones, List<XFile> fotos) async {
    setState(() => _isLoading = true);

    try {
      // Crear ID del avance
      final avanceId = DateTime.now().millisecondsSinceEpoch.toString();

      // Subir fotos del avance
      List<String> fotosUrls = [];
      for (int i = 0; i < fotos.length; i++) {
        try {
          final url = await _storageService.uploadAvancePhoto(
            widget.orden.id,
            widget.detalle.id,
            avanceId,
            fotos[i],
            i,
          );
          fotosUrls.add(url);
        } catch (e) {
          print('Error al subir foto $i: $e');
        }
      }

      // Crear nuevo avance
      final nuevoAvance = AvanceServicio(
        id: avanceId,
        fecha: DateTime.now(),
        observaciones: observaciones,
        fotosUrls: fotosUrls,
        progresoAnterior: _progresoActual,
        progresoNuevo: nuevoProgreso,
      );

      setState(() {
        _avances.add(nuevoAvance);
        _progresoActual = nuevoProgreso;
      });

      // Actualizar en Firebase
      final detalleActualizado = widget.detalle.copyWith(
        progreso: nuevoProgreso,
        avances: _avances,
      );

      // Actualizar la orden completa
      final detallesActualizados = List<DetalleOrden>.from(widget.orden.detalles);
      detallesActualizados[widget.detalleIndex] = detalleActualizado;

      final ordenActualizada = widget.orden.copyWith(detalles: detallesActualizados);
      await _dbService.updateOrden(widget.orden.id, ordenActualizada.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avance agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar avance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avances - ${widget.detalle.servicioNombre}'),
        backgroundColor: Colors.teal,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header con progreso actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.teal.withOpacity(0.1),
            child: Column(
              children: [
                const Text(
                  'Progreso Actual',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '$_progresoActual%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _progresoActual / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ],
            ),
          ),

          // Lista de avances
          Expanded(
            child: _avances.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No hay avances registrados',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Presiona el botón + para agregar uno',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _avances.length,
                    itemBuilder: (context, index) {
                      final avance = _avances[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Fecha
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${avance.fecha.day}/${avance.fecha.month}/${avance.fecha.year} - ${avance.fecha.hour}:${avance.fecha.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Cambio de progreso
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange),
                                    ),
                                    child: Text(
                                      '${avance.progresoAnterior}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 16),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green),
                                    ),
                                    child: Text(
                                      '${avance.progresoNuevo}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Observaciones
                              const Text(
                                'Observaciones:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(avance.observaciones),

                              // Fotos
                              if (avance.fotosUrls.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Fotos:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: avance.fotosUrls.length,
                                    itemBuilder: (context, fotoIndex) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            avance.fotosUrls[fotoIndex],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.broken_image),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: widget.orden.estado == EstadoOrden.EN_PROCESO
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _mostrarDialogoNuevoAvance,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Avance'),
            )
          : null,
    );
  }
}


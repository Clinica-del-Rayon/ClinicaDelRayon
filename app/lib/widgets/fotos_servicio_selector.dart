import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class FotosServicioSelector extends StatefulWidget {
  final String titulo;
  final List<String> fotosUrls;
  final Function(List<XFile>) onFotosSeleccionadas;
  final int maxFotos;

  const FotosServicioSelector({
    super.key,
    this.titulo = 'Fotos',
    this.fotosUrls = const [],
    required this.onFotosSeleccionadas,
    this.maxFotos = 5,
  });

  @override
  State<FotosServicioSelector> createState() => _FotosServicioSelectorState();
}

class _FotosServicioSelectorState extends State<FotosServicioSelector> {
  final StorageService _storageService = StorageService();
  List<XFile> _fotosLocales = [];

  Future<void> _tomarFoto() async {
    if (_fotosLocales.length + widget.fotosUrls.length >= widget.maxFotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo ${widget.maxFotos} fotos permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _storageService.takePicture();
      if (image != null) {
        setState(() {
          _fotosLocales.add(image);
        });
        widget.onFotosSeleccionadas(_fotosLocales);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al tomar foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _seleccionarDesdeGaleria() async {
    final fotosRestantes = widget.maxFotos - (_fotosLocales.length + widget.fotosUrls.length);
    if (fotosRestantes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo ${widget.maxFotos} fotos permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.length > fotosRestantes) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solo puedes agregar $fotosRestantes foto(s) más'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _fotosLocales.addAll(images.take(fotosRestantes));
        });
      } else {
        setState(() {
          _fotosLocales.addAll(images);
        });
      }
      widget.onFotosSeleccionadas(_fotosLocales);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar fotos: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _eliminarFoto(int index) {
    setState(() {
      _fotosLocales.removeAt(index);
    });
    widget.onFotosSeleccionadas(_fotosLocales);
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _tomarFoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarDesdeGaleria();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalFotos = _fotosLocales.length + widget.fotosUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.titulo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '$totalFotos/${widget.maxFotos}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Botones de acción
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: totalFotos < widget.maxFotos ? _tomarFoto : null,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Cámara', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: totalFotos < widget.maxFotos ? _seleccionarDesdeGaleria : null,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Galería', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Galería de fotos
        if (totalFotos > 0)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.fotosUrls.length + _fotosLocales.length,
              itemBuilder: (context, index) {
                final bool esUrl = index < widget.fotosUrls.length;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: esUrl
                            ? Image.network(
                                widget.fotosUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              )
                            : Image.file(
                                File(_fotosLocales[index - widget.fotosUrls.length].path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      if (!esUrl)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _eliminarFoto(index - widget.fotosUrls.length),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          )
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Sin fotos',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}


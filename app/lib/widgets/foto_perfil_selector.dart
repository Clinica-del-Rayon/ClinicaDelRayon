import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class FotoPerfilSelector extends StatefulWidget {
  final String? fotoPerfilUrl;
  final Function(XFile?) onFotoSeleccionada;
  final Function()? onFotoEliminada;

  const FotoPerfilSelector({
    super.key,
    this.fotoPerfilUrl,
    required this.onFotoSeleccionada,
    this.onFotoEliminada,
  });

  @override
  State<FotoPerfilSelector> createState() => _FotoPerfilSelectorState();
}

class _FotoPerfilSelectorState extends State<FotoPerfilSelector> {
  final StorageService _storageService = StorageService();
  XFile? _fotoLocal;

  Future<void> _tomarFoto() async {
    try {
      final XFile? image = await _storageService.takePicture();
      if (image != null) {
        setState(() {
          _fotoLocal = image;
        });
        widget.onFotoSeleccionada(image);
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
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _fotoLocal = image;
        });
        widget.onFotoSeleccionada(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar foto: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _eliminarFoto() {
    setState(() {
      _fotoLocal = null;
    });
    widget.onFotoSeleccionada(null);
    if (widget.onFotoEliminada != null) {
      widget.onFotoEliminada!();
    }
  }

  void _mostrarOpciones() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.blue),
                title: Text('Tomar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _tomarFoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarDesdeGaleria();
                },
              ),
              if (_fotoLocal != null || widget.fotoPerfilUrl != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Eliminar Foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _eliminarFoto();
                  },
                ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancelar'),
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
    return Column(
      children: [
        Text(
          'Foto de Perfil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: _mostrarOpciones,
          child: Stack(
            children: [
              // Avatar con foto
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: _fotoLocal != null
                    ? FileImage(File(_fotoLocal!.path))
                    : (widget.fotoPerfilUrl != null
                        ? NetworkImage(widget.fotoPerfilUrl!)
                        : null) as ImageProvider?,
                child: (_fotoLocal == null && widget.fotoPerfilUrl == null)
                    ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                    : null,
              ),
              // Botón de cámara flotante
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Toca para cambiar la foto',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}


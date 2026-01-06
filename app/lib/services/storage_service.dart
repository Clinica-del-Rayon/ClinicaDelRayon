import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Tomar foto con la cámara
  Future<XFile?> takePicture() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw 'Error al tomar la foto: ${e.toString()}';
    }
  }

  /// Seleccionar foto de la galería
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } catch (e) {
      throw 'Error al seleccionar la foto: ${e.toString()}';
    }
  }

  /// Seleccionar múltiples fotos de la galería
  Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return images;
    } catch (e) {
      throw 'Error al seleccionar las fotos: ${e.toString()}';
    }
  }

  /// Subir foto de perfil de usuario
  Future<String> uploadUserProfilePicture(String userId, XFile imageFile) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('usuarios/$userId/$fileName');

      final File file = File(imageFile.path);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Error al subir la foto de perfil: ${e.toString()}';
    }
  }

  /// Subir foto de vehículo
  Future<String> uploadVehiclePhoto(
    String vehiculoId,
    XFile imageFile,
    int index,
  ) async {
    try {
      final String fileName = 'vehiculo_${vehiculoId}_$index.jpg';
      final Reference ref = _storage.ref().child('vehiculos/$vehiculoId/$fileName');

      final File file = File(imageFile.path);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw 'Error al subir la foto del vehículo: ${e.toString()}';
    }
  }

  /// Eliminar foto de perfil de usuario
  Future<void> deleteUserProfilePicture(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Error al eliminar la foto: ${e.toString()}';
    }
  }

  /// Eliminar foto de vehículo
  Future<void> deleteVehiclePhoto(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Error al eliminar la foto: ${e.toString()}';
    }
  }

  /// Eliminar todas las fotos de un vehículo
  Future<void> deleteAllVehiclePhotos(String vehiculoId) async {
    try {
      final Reference ref = _storage.ref().child('vehiculos/$vehiculoId');
      final ListResult result = await ref.listAll();

      for (Reference fileRef in result.items) {
        await fileRef.delete();
      }
    } catch (e) {
      throw 'Error al eliminar las fotos del vehículo: ${e.toString()}';
    }
  }

  /// Obtener tamaño de la imagen
  Future<int> getImageSize(XFile imageFile) async {
    final File file = File(imageFile.path);
    return await file.length();
  }

  /// Validar que la imagen no sea muy grande (máx 5MB)
  Future<bool> validateImageSize(XFile imageFile, {int maxSizeMB = 5}) async {
    final int sizeInBytes = await getImageSize(imageFile);
    final int maxSizeInBytes = maxSizeMB * 1024 * 1024;
    return sizeInBytes <= maxSizeInBytes;
  }
}


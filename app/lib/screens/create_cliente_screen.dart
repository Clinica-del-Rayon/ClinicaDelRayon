import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/usuario.dart';
import '../widgets/foto_perfil_selector.dart';

class CreateClienteScreen extends StatefulWidget {
  const CreateClienteScreen({super.key});

  @override
  State<CreateClienteScreen> createState() => _CreateClienteScreenState();
}

class _CreateClienteScreenState extends State<CreateClienteScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  TipoDocumento _tipoDocumento = TipoDocumento.CC;
  XFile? _fotoPerfil;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  //Arreglado bugsito
  Future<void> _createCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cliente = Cliente(
        uid: '',
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _numeroDocumentoController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        password: _passwordController.text,
      );

      final newUserId = await _authService.registerCliente(cliente: cliente);

      if (_fotoPerfil != null) {
        try {
          final fotoUrl = await _storageService.uploadUserProfilePicture(newUserId, _fotoPerfil!);
          await _authService.updateOtherUserProfile(newUserId, {'foto_perfil': fotoUrl});
        } catch (e) {
          print('Error al subir foto de perfil: $e');
        }
      }

      if (mounted) {// YA NO HAY Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada! Entrando a Clínica del Rayón...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Text('Error al crear cliente: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
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
        title: const Text('Crear Cuenta de Cliente'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto de perfil
            FotoPerfilSelector(
              onFotoSeleccionada: (foto) {
                setState(() {
                  _fotoPerfil = foto;
                });
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Crear Nuevo Cliente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestión de clientes',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Nombres
            TextFormField(
              controller: _nombresController,
              decoration: const InputDecoration(
                labelText: 'Nombres',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Apellidos
            TextFormField(
              controller: _apellidosController,
              decoration: const InputDecoration(
                labelText: 'Apellidos',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Tipo de Documento
            DropdownButtonFormField<TipoDocumento>(
              value: _tipoDocumento,
              decoration: const InputDecoration(
                labelText: 'Tipo de Documento',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              items: TipoDocumento.values.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _tipoDocumento = value!),
            ),
            const SizedBox(height: 16),

            // Número de Documento
            TextFormField(
              controller: _numeroDocumentoController,
              decoration: const InputDecoration(
                labelText: 'Número de Documento',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Correo
            TextFormField(
              controller: _correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (!value!.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Dirección (específico de Cliente)
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Contraseña
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (value!.length < 6) return 'Mínimo 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirmar Contraseña
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Botón Crear
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createCliente,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_isLoading ? 'Creando...' : 'Crear Cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


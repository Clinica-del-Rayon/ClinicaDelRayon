import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/usuario.dart';
import '../widgets/foto_perfil_selector.dart';

class EditUserScreen extends StatefulWidget {
  const EditUserScreen({super.key});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final DatabaseService _dbService = DatabaseService();
  final StorageService _storageService = StorageService();
  final _formKey = GlobalKey<FormState>();

  late Usuario _usuario;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _correoController;
  late TextEditingController _telefonoController;
  late TextEditingController _direccionController;
  late TextEditingController _areaController;
  late TextEditingController _sueldoController;

  late TipoDocumento _tipoDocumento;
  late RolUsuario _rolSeleccionado;
  late bool _estadoDisponibilidad;
  bool _isLoading = false;

  String? _fotoPerfilUrl; // URL actual de la foto
  XFile? _nuevaFotoPerfil; // Nueva foto seleccionada

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Obtener el usuario de los argumentos
    _usuario = ModalRoute.of(context)!.settings.arguments as Usuario;

    // Inicializar controladores con los datos actuales
    _nombresController = TextEditingController(text: _usuario.nombres);
    _apellidosController = TextEditingController(text: _usuario.apellidos);
    _numeroDocumentoController = TextEditingController(text: _usuario.numeroDocumento);
    _correoController = TextEditingController(text: _usuario.correo);
    _telefonoController = TextEditingController(text: _usuario.telefono);
    _tipoDocumento = _usuario.tipoDocumento;
    _rolSeleccionado = _usuario.rol;
    _fotoPerfilUrl = _usuario.fotoPerfil; // Inicializar foto actual

    // Inicializar campos específicos según el rol
    if (_usuario is Cliente) {
      _direccionController = TextEditingController(text: (_usuario as Cliente).direccion);
    } else {
      _direccionController = TextEditingController();
    }

    if (_usuario is Trabajador) {
      final trabajador = _usuario as Trabajador;
      _areaController = TextEditingController(text: trabajador.area ?? '');
      _sueldoController = TextEditingController(text: trabajador.sueldo?.toString() ?? '0');
      _estadoDisponibilidad = trabajador.estadoDisponibilidad ?? true;
    } else {
      _areaController = TextEditingController();
      _sueldoController = TextEditingController(text: '0');
      _estadoDisponibilidad = true;
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _areaController.dispose();
    _sueldoController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Subir nueva foto si existe
      String? fotoUrl = _fotoPerfilUrl;
      if (_nuevaFotoPerfil != null) {
        fotoUrl = await _storageService.uploadUserProfilePicture(
          _usuario.uid,
          _nuevaFotoPerfil!,
        );
      }

      // Crear el usuario actualizado según el rol seleccionado
      Usuario usuarioActualizado;

      if (_rolSeleccionado == RolUsuario.CLIENTE) {
        usuarioActualizado = Cliente(
          uid: _usuario.uid,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          tipoDocumento: _tipoDocumento,
          numeroDocumento: _numeroDocumentoController.text.trim(),
          correo: _correoController.text.trim(),
          telefono: _telefonoController.text.trim(),
          direccion: _direccionController.text.trim(),
          calificacion: _usuario.calificacion,
          fotoPerfil: fotoUrl,
        );
      } else {
        // Para TRABAJADOR o ADMIN
        usuarioActualizado = Trabajador(
          uid: _usuario.uid,
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          tipoDocumento: _tipoDocumento,
          numeroDocumento: _numeroDocumentoController.text.trim(),
          correo: _correoController.text.trim(),
          telefono: _telefonoController.text.trim(),
          rol: _rolSeleccionado,
          // Solo incluir estos campos si NO es ADMIN
          area: _rolSeleccionado != RolUsuario.ADMIN ? _areaController.text.trim() : null,
          sueldo: _rolSeleccionado != RolUsuario.ADMIN ? (double.tryParse(_sueldoController.text) ?? 0.0) : null,
          estadoDisponibilidad: _rolSeleccionado != RolUsuario.ADMIN ? _estadoDisponibilidad : null,
          calificacion: _usuario.calificacion,
          fotoPerfil: fotoUrl,
        );
      }

      // Guardar cambios en Firebase
      await _dbService.updateUsuario(_usuario.uid, usuarioActualizado.toJson());

      if (mounted) {
        // Mostrar mensaje de éxito con SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Usuario actualizado exitosamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Actualizar el estado local
        setState(() {
          _usuario = usuarioActualizado;
        });

        // Volver con resultado true para indicar que hubo cambios
        Navigator.pop(context, true);
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
              content: Text('Error al guardar cambios: ${e.toString()}'),
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
        title: const Text('Editar Usuario'),
        backgroundColor: Colors.purple,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Foto de perfil
            FotoPerfilSelector(
              fotoPerfilUrl: _fotoPerfilUrl,
              onFotoSeleccionada: (foto) {
                setState(() {
                  _nuevaFotoPerfil = foto;
                });
              },
              onFotoEliminada: () {
                setState(() {
                  _fotoPerfilUrl = null;
                  _nuevaFotoPerfil = null;
                });
              },
            ),
            const SizedBox(height: 24),

            // Selector de Rol
            DropdownButtonFormField<RolUsuario>(
              value: _rolSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Rol del Usuario',
                prefixIcon: Icon(Icons.admin_panel_settings),
                border: OutlineInputBorder(),
              ),
              items: RolUsuario.values.map((rol) {
                return DropdownMenuItem(
                  value: rol,
                  child: Text(rol.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _rolSeleccionado = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Campos comunes
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
              onChanged: (value) {
                setState(() {
                  _tipoDocumento = value!;
                });
              },
            ),
            const SizedBox(height: 16),

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

            TextFormField(
              controller: _correoController,
              enabled: false, // Email no se puede cambiar
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'El correo no se puede modificar',
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Campos específicos según el rol
            if (_rolSeleccionado == RolUsuario.CLIENTE) ...[
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
            ],

            if (_rolSeleccionado == RolUsuario.TRABAJADOR) ...[
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Área',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _sueldoController,
                decoration: const InputDecoration(
                  labelText: 'Sueldo',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (double.tryParse(value!) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Estado de Disponibilidad'),
                subtitle: Text(_estadoDisponibilidad ? 'Disponible' : 'No disponible'),
                value: _estadoDisponibilidad,
                onChanged: (value) {
                  setState(() {
                    _estadoDisponibilidad = value;
                  });
                },
              ),
            ],

            const SizedBox(height: 32),

            // Botón Guardar Cambios
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


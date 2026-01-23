import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../models/usuario.dart';
import '../../widgets/foto_perfil_selector.dart';

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

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_isInitialized) return;

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
    
    _isInitialized = true;
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

  // Modern Colors
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  // ... (existing variables)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Editar Usuario',
          style: TextStyle(color: Colors.blueGrey[800], fontWeight: FontWeight.bold),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey[700]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1E88E5),
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
          padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 32),

            _buildSectionLabel('Rol y Permisos'),
            _buildDropdown(
              value: _rolSeleccionado,
              items: RolUsuario.values,
              label: 'Rol del Usuario',
              icon: Icons.admin_panel_settings_outlined,
              onChanged: (val) => setState(() => _rolSeleccionado = val!),
              itemLabel: (val) => val.name,
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('Información Personal'),
            _buildTextField(
              controller: _nombresController,
              label: 'Nombres',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _apellidosController,
              label: 'Apellidos',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              value: _tipoDocumento,
              items: TipoDocumento.values,
              label: 'Tipo de Documento',
              icon: Icons.credit_card_outlined,
              onChanged: (val) => setState(() => _tipoDocumento = val!),
              itemLabel: (val) => val.name,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _numeroDocumentoController,
              label: 'Número de Documento',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('Contacto'),
            _buildTextField(
              controller: _correoController,
              label: 'Correo Electrónico',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _telefonoController,
              label: 'Teléfono',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 24),

            // Campos específicos
            if (_rolSeleccionado == RolUsuario.CLIENTE) ...[
              _buildSectionLabel('Datos de Cliente'),
              _buildTextField(
                controller: _direccionController,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 24),
            ],

            if (_rolSeleccionado != RolUsuario.CLIENTE) ...[
              _buildSectionLabel('Datos Laborales'),
              if (_rolSeleccionado != RolUsuario.ADMIN) ...[
                _buildTextField(
                  controller: _areaController,
                  label: 'Área',
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _sueldoController,
                  label: 'Sueldo',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val?.isEmpty ?? true) return 'Campo requerido';
                    if (double.tryParse(val!) == null) return 'Ingrese un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: Offset(0, 2)),
                    ],
                  ),
                  child: SwitchListTile(
                    title: const Text('Disponible', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_estadoDisponibilidad ? 'El trabajador recibirá órdenes' : 'No recibirá órdenes'),
                    value: _estadoDisponibilidad,
                    activeColor: _primaryColor,
                    onChanged: (value) => setState(() => _estadoDisponibilidad = value),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],

            // Botón Guardar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.blueGrey[400],
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(fontWeight: FontWeight.w500, color: enabled ? Colors.black87 : Colors.grey),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: enabled ? const Color(0xFF1E88E5) : Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),
        validator: validator ?? (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String label,
    required IconData icon,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(itemLabel(item), style: TextStyle(fontWeight: FontWeight.w500)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}


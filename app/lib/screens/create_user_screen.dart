import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controladores comunes
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controladores específicos por rol
  final _direccionController = TextEditingController(); // Cliente
  final _areaController = TextEditingController(); // Trabajador
  final _sueldoController = TextEditingController(); // Trabajador

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  TipoDocumento _tipoDocumento = TipoDocumento.CC;
  RolUsuario _rolSeleccionado = RolUsuario.CLIENTE;
  bool _estadoDisponibilidad = true; // Para trabajadores

  final List<String> _areasDisponibles = [
    'Mecánico',
    'Pintura',
    'Electricidad',
    'Tapicería',
    'Latonería',
    'Diagnóstico',
    'Lavado',
    'Otro',
  ];

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _direccionController.dispose();
    _areaController.dispose();
    _sueldoController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_rolSeleccionado == RolUsuario.CLIENTE) {
        await _createCliente();
      } else {
        await _createTrabajador();
      }

      if (mounted) {
        Navigator.pop(context);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 30),
                  SizedBox(width: 10),
                  Text('¡Usuario Creado!'),
                ],
              ),
              content: Text(
                'El usuario ha sido creado exitosamente.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Entendido',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.toString(),
                  style: TextStyle(fontSize: 13, color: Colors.red[900]),
                ),
              ),
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

  Future<void> _createCliente() async {
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

    await _authService.registerCliente(cliente: cliente);
  }

  Future<void> _createTrabajador() async {
    final trabajador = Trabajador(
      uid: '',
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      tipoDocumento: _tipoDocumento,
      numeroDocumento: _numeroDocumentoController.text.trim(),
      correo: _correoController.text.trim(),
      telefono: _telefonoController.text.trim(),
      area: _areaController.text.trim(),
      sueldo: double.tryParse(_sueldoController.text) ?? 0.0,
      estadoDisponibilidad: _estadoDisponibilidad,
      password: _passwordController.text,
    );

    await _authService.registerTrabajador(trabajador: trabajador);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Usuario'),
        backgroundColor: Colors.red,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: Colors.red,
                ),
                SizedBox(height: 24),
                Text(
                  'Crear Nuevo Usuario',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Solo administradores',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 32),

                // Selector de tipo de cuenta
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tipo de Cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        SegmentedButton<RolUsuario>(
                          segments: const [
                            ButtonSegment<RolUsuario>(
                              value: RolUsuario.CLIENTE,
                              label: Text('Cliente'),
                              icon: Icon(Icons.person),
                            ),
                            ButtonSegment<RolUsuario>(
                              value: RolUsuario.TRABAJADOR,
                              label: Text('Trabajador'),
                              icon: Icon(Icons.engineering),
                            ),
                            ButtonSegment<RolUsuario>(
                              value: RolUsuario.ADMIN,
                              label: Text('Admin'),
                              icon: Icon(Icons.admin_panel_settings),
                            ),
                          ],
                          selected: {_rolSeleccionado},
                          onSelectionChanged: (Set<RolUsuario> newSelection) {
                            setState(() {
                              _rolSeleccionado = newSelection.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Campos comunes
                _buildTextField(
                  controller: _nombresController,
                  label: 'Nombres',
                  icon: Icons.person,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingresa los nombres' : null,
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _apellidosController,
                  label: 'Apellidos',
                  icon: Icons.person_outline,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingresa los apellidos' : null,
                ),
                SizedBox(height: 16),

                DropdownButtonFormField<TipoDocumento>(
                  initialValue: _tipoDocumento,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Documento',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                  items: TipoDocumento.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(tipo.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tipoDocumento = value);
                    }
                  },
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _numeroDocumentoController,
                  label: 'Número de Documento',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingresa el documento' : null,
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _correoController,
                  label: 'Correo electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Ingresa el correo';
                    if (!value!.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                _buildTextField(
                  controller: _telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingresa el teléfono' : null,
                ),
                SizedBox(height: 16),

                // Campos específicos según el rol
                if (_rolSeleccionado == RolUsuario.CLIENTE) ...[
                  _buildTextField(
                    controller: _direccionController,
                    label: 'Dirección',
                    icon: Icons.home,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Ingresa la dirección' : null,
                  ),
                  SizedBox(height: 16),
                ],

                if (_rolSeleccionado == RolUsuario.TRABAJADOR ||
                    _rolSeleccionado == RolUsuario.ADMIN) ...[
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _areasDisponibles;
                      }
                      return _areasDisponibles.where((String option) {
                        return option.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    onSelected: (String selection) {
                      _areaController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      _areaController.text = controller.text;
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Área',
                          prefixIcon: Icon(Icons.work),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Ingresa el área' : null,
                      );
                    },
                  ),
                  SizedBox(height: 16),

                  _buildTextField(
                    controller: _sueldoController,
                    label: 'Sueldo',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Ingresa el sueldo';
                      if (double.tryParse(value!) == null)
                        return 'Número inválido';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  SwitchListTile(
                    title: Text('Disponible'),
                    subtitle: Text('El trabajador está disponible'),
                    value: _estadoDisponibilidad,
                    onChanged: (value) {
                      setState(() => _estadoDisponibilidad = value);
                    },
                  ),
                  SizedBox(height: 16),
                ],

                // Contraseñas
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscureText: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: 16),

                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar Contraseña',
                  obscureText: _obscureConfirmPassword,
                  onToggle: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Confirma la contraseña';
                    if (value != _passwordController.text)
                      return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Botón crear
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createUser,
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.check),
                  label: Text(
                    _isLoading ? 'Creando...' : 'Crear Usuario',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(),
      ),
      validator: validator ??
          (value) {
            if (value?.isEmpty ?? true) return 'Ingresa la contraseña';
            if (value!.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
    );
  }
}


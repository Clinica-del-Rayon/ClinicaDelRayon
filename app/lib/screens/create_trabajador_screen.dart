import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';

class CreateTrabajadorScreen extends StatefulWidget {
  const CreateTrabajadorScreen({super.key});

  @override
  State<CreateTrabajadorScreen> createState() => _CreateTrabajadorScreenState();
}

class _CreateTrabajadorScreenState extends State<CreateTrabajadorScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _areaController = TextEditingController();
  final _sueldoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _estadoDisponibilidad = true;
  TipoDocumento _tipoDocumento = TipoDocumento.CC;

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroDocumentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _areaController.dispose();
    _sueldoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createTrabajador() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final trabajador = Trabajador(
        uid: '',
        nombres: _nombresController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _numeroDocumentoController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        rol: RolUsuario.TRABAJADOR,
        area: _areaController.text.trim(),
        sueldo: double.tryParse(_sueldoController.text) ?? 0.0,
        estadoDisponibilidad: _estadoDisponibilidad,
        password: _passwordController.text,
      );

      await _authService.registerTrabajador(trabajador: trabajador);

      if (mounted) {
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
                  Expanded(child: Text('¡Trabajador Creado!')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('El trabajador ha sido registrado exitosamente.'),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Debes volver a iniciar sesión',
                            style: TextStyle(fontSize: 13, color: Colors.orange[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cerrar modal
                    Navigator.of(context).pop(); // Volver a selector
                    Navigator.of(context).pop(); // Volver a admin home
                    // Forzar logout
                    _authService.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Entendido'),
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
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 30),
                  SizedBox(width: 10),
                  Text('Error'),
                ],
              ),
              content: Text('Error al crear trabajador: ${e.toString()}'),
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
        title: const Text('Crear Cuenta de Trabajador'),
        backgroundColor: Colors.orange,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.engineering, size: 80, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Crear Nuevo Trabajador',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Solo administradores',
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

            // Área (específico de Trabajador)
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Área (Mecánico, Pintura, etc.)',
                prefixIcon: Icon(Icons.work),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Sueldo (específico de Trabajador)
            TextFormField(
              controller: _sueldoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sueldo',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo requerido';
                if (double.tryParse(value!) == null) return 'Ingrese un número válido';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Estado de Disponibilidad
            SwitchListTile(
              title: const Text('El trabajador está disponible para trabajar'),
              value: _estadoDisponibilidad,
              onChanged: (value) => setState(() => _estadoDisponibilidad = value),
              activeColor: Colors.green,
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
              onPressed: _isLoading ? null : _createTrabajador,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.engineering),
              label: Text(_isLoading ? 'Creando...' : 'Crear Trabajador'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


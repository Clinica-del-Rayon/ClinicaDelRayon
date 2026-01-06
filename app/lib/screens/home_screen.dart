import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';
import 'cliente_home_screen.dart';
import 'trabajador_home_screen.dart';
import 'admin_home_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return FutureBuilder<Usuario?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        final usuario = snapshot.data;

        if (usuario == null) {
          // Si no hay datos del usuario, cerrar sesión y volver a login
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await authService.signOut();
          });

          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cerrando sesión...'),
                ],
              ),
            ),
          );
        }

        // DEBUG: Imprimir información del usuario
        print('=== DEBUG HOME SCREEN ===');
        print('Usuario: ${usuario.nombres} ${usuario.apellidos}');
        print('Tipo de clase: ${usuario.runtimeType}');
        print('Rol del usuario: ${usuario.rol}');
        print('Rol es ADMIN: ${usuario.rol == RolUsuario.ADMIN}');
        print('Rol es TRABAJADOR: ${usuario.rol == RolUsuario.TRABAJADOR}');
        print('Rol es CLIENTE: ${usuario.rol == RolUsuario.CLIENTE}');
        print('========================');

        // Mostrar pantalla según el rol
        switch (usuario.rol) {
          case RolUsuario.CLIENTE:
            return ClienteHomeScreen(
              usuario: usuario as Cliente,
              authService: authService,
            );
          case RolUsuario.TRABAJADOR:
            return TrabajadorHomeScreen(
              usuario: usuario as Trabajador,
              authService: authService,
            );
          case RolUsuario.ADMIN:
            return AdminHomeScreen(
              usuario: usuario,
              authService: authService,
            );
        }
      },
    );
  }
}


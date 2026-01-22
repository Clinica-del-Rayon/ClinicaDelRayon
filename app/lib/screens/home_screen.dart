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
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sincronizando perfil...'),
                ],
              ),
            ),
          );
        }

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
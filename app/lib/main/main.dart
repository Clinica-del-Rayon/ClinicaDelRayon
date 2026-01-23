import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/auth_wrapper.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/register_trabajador_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/common/home_screen.dart';
import '../screens/create_user_screen.dart';
import '../screens/clientes_list_screen.dart';
import '../screens/vehiculos_cliente_screen.dart';
import '../screens/create_vehiculo_screen.dart';
import '../screens/select_account_type_screen.dart';
import '../screens/admin/edit_user_screen.dart';
import '../screens/create_cliente_screen.dart';
import '../screens/create_trabajador_screen.dart';
import '../screens/create_admin_screen.dart';
import '../screens/admin/usuarios_management_screen.dart';
import '../screens/admin/user_details_screen.dart';
import '../screens/admin/vehiculos_management_screen.dart';
import '../screens/vehiculo_details_screen.dart';
import '../screens/admin/servicios_management_screen.dart';
import '../screens/create_servicio_screen.dart';
import '../screens/admin/ordenes_management_screen.dart';
import '../screens/create_orden_screen.dart';
import '../screens/edit_vehiculo_screen.dart';
import '../screens/select_clientes_vehiculo_screen.dart';
import '../screens/create_vehiculo_multi_screen.dart';

import 'package:provider/provider.dart';
import '../providers/provider_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProviderState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica del Rayón',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/register-trabajador': (context) => const RegisterTrabajadorScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/create-user': (context) => const CreateUserScreen(),
        '/clientes-list': (context) => const ClientesListScreen(),
        '/select-account-type': (context) => const SelectAccountTypeScreen(),
        '/edit-user': (context) => const EditUserScreen(),
        '/create-cliente': (context) => const CreateClienteScreen(),
        '/create-trabajador': (context) => const CreateTrabajadorScreen(),
        '/create-admin': (context) => const CreateAdminScreen(),
        '/usuarios-management': (context) => const UsuariosManagementScreen(),
        '/user-details': (context) => const UserDetailsScreen(),
        '/vehiculos-management': (context) => const VehiculosManagementScreen(),
        '/vehiculo-details': (context) => const VehiculoDetailsScreen(),
        '/edit-vehiculo': (context) => const EditVehiculoScreen(),
        '/select-clientes-vehiculo': (context) => const SelectClientesVehiculoScreen(),
        '/create-vehiculo-multi': (context) => const CreateVehiculoMultiScreen(),
        '/servicios-management': (context) => const ServiciosManagementScreen(),
        '/create-servicio': (context) => const CreateServicioScreen(),
        '/ordenes-management': (context) => const OrdenesManagementScreen(),
        '/create-orden': (context) => const CreateOrdenScreen(),
      },
      onGenerateRoute: (settings) {
        // Rutas con parámetros
        if (settings.name == '/vehiculos-cliente') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VehiculosClienteScreen(
              clienteId: args['clienteId'],
              clienteNombre: args['clienteNombre'],
            ),
          );
        }
        if (settings.name == '/create-vehiculo') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => CreateVehiculoScreen(
              clienteId: args['clienteId'],
              clienteNombre: args['clienteNombre'],
            ),
          );
        }
        return null;
      },
    );
  }
}

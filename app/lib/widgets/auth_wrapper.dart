import 'package:provider/provider.dart';
import '../providers/provider_state.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProviderState>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.currentUser != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}


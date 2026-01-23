# Documentación de Providers (Gestión de Estado)

La aplicación utiliza el patrón **Provider** para la gestión de estado global, específicamente para la sesión de usuario.

## `ProviderState` (`provider_state.dart`)

Es el `ChangeNotifier` principal que envuelve toda la aplicación. Se inicializa en el `main.dart` (típicamente) y provee el contexto de autenticación a todo el árbol de widgets.

### Estado Gestionado:
- **`user`** (`User?`): Objeto de usuario de Firebase Auth.
- **`userData`** (`models.Usuario?`): Datos completos del perfil traídos de la base de datos (incluye rol, nombre, etc.).
- **`isLoading`** (`bool`): Indicador de carga global (útil para mostrar splash screens o spinners mientras se verifica la sesión).
- **`userRole`**: Rol del usuario actual para control de acceso rápido.

### Comportamiento:
- **Inicialización**: Escucha `authService.authStateChanges`. Cuando un usuario se loguea, automáticamente dispara `_loadUserData()` para traer su perfil completo desde la base de datos.
- **Métodos Públicos**:
  - Expones métodos proxy hacia `AuthService` (`signIn`, `signOut`, `register...`) que manejan automáticamente los estados de carga (`isLoading`) y notifican a la UI (`notifyListeners`) para mostrar feedback visual durante operaciones asíncronas.

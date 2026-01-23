# Documentación de Providers (Gestión de Estado)

La aplicación utiliza el patrón **Provider** para la gestión de estado global, específicamente para la sesión de usuario.

## `ProviderState` (`provider_state.dart`)

Es el `ChangeNotifier` principal que envuelve toda la aplicación. Se inicializa en el `main.dart` (típicamente) y provee el contexto de autenticación a todo el árbol de widgets.

### Estado Gestionado:
- **`user`** (`User?`): Objeto de usuario de Firebase Auth.
- **`userData`** (`models.Usuario?`): Datos completos del perfil traídos de la base de datos (incluye rol, nombre, etc.).
- **`isLoading`** (`bool`): Indicador de carga global (útil para mostrar splash screens o spinners mientras se verifica la sesión).
- **`userRole`**: Rol del usuario actual para control de acceso rápido.
- **`allUsers`** (`List<models.Usuario>`): Lista global de todos los usuarios, obtenida de la fuente de verdad única (`usuarios/`) para evitar inconsistencias.

### Comportamiento:
- **Inicialización**: Escucha `authService.authStateChanges`. Cuando un usuario se loguea:
  - Carga su perfil (`_loadUserData`).
  - Si es Admin (o según lógica), pre-carga la lista de usuarios (`fetchAllUsers`).
- **Métodos Públicos**:
  - `signIn`, `signOut`, `register...`: Proxies a `AuthService` con gestión de estado de carga.
  - **`fetchAllUsers()`**: Fuerza la recarga de la lista global de usuarios desde la base de datos.
  - **`deleteUser(uid)`**: Coordina la eliminación de un usuario y refresca la lista local.

# Documentación de Servicios

Capa de lógica de negocio y comunicación con Firebase.

## 1. `DatabaseService` (`database_service.dart`)

Encapsula todas las interacciones con **Firebase Realtime Database**.

### Funcionalidades Principales:
- **Usuarios**:
  - `createCliente`, `createTrabajador`: Guarda en nodo `/usuarios` y nodos específicos (`/clientes`, `/trabajadores`) para optimizar lecturas.
  - `getUsuario`: Recupera información y la instancia en la clase correcta (`Cliente` o `Trabajador`) según el rol almacenado.
- **Vehículos**:
  - CRUD completo (`create`, `get`, `update`, `delete`).
  - `vehiculosByClienteStream`: Stream para escuchar cambios en vehículos de un cliente en tiempo real.
  - `existeVehiculoConPlaca`: Validación de unicidad.
- **Órdenes**:
  - Gestión del ciclo de vida de la orden (`createOrden`, `updateEstadoOrden`).
  - `vehiculoTieneOrdenesActivas`: Regla de negocio para impedir múltiples órdenes activas simultáneas.
  - Gestión de detalles (`updateDetalleOrden`) para actualizar progresos individuales.
- **Servicios (Catálogo)**:
  - ABM del catálogo de servicios base.

---

## 2. `AuthService` (`auth_service.dart`)

Maneja la autenticación con **Firebase Auth** y coordina con `DatabaseService` para guardar los datos del perfil.

### Funcionalidades:
- **Registro**:
  - `registerCliente`: Crea usuario en Auth y guarda datos extendidos en DB.
  - `registerTrabajador`: Permite a un ADMIN crear cuentas de trabajadores (cierra sesión temporalmente si es necesario o maneja la creación de credenciales).
- **Sesión**:
  - `signInWithEmailAndPassword`, `signOut`.
  - `authStateChanges`: Stream del estado de autenticación.
- **Datos de Usuario**:
  - `getCurrentUserData`: Obtiene el objeto `Usuario` completo (con rol y datos extra) del usuario logueado.

---

## 3. `StorageService` (`storage_service.dart`)

Maneja la subida de archivos a **Firebase Storage** y la selección de imágenes.

### Funcionalidades:
- **Selección de Imágenes**:
  - Wrappers sobre `image_picker` para Cámara y Galería (simple y múltiple).
  - Validaciones de tamaño.
- **Subida de Archivos**:
  - Rutas organizadas:
    - Perfil: `usuarios/{uid}/profile.jpg`
    - Vehículos: `vehiculos/{id}/{timestamp}.jpg`
    - Órdenes (Fotos iniciales): `ordenes/{ordenId}/servicios/{servicioId}/...`
    - Avances: `ordenes/{ordenId}/.../avances/...`
- **Gestión**:
  - Eliminación de fotos individuales o carpetas completas (al borrar vehículos).

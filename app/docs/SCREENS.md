# Documentación de Pantallas - Clínica del Rayón

Este documento describe las pantallas existentes en la aplicación, su propósito y funcionalidad actual.

## 1. Autenticación y Onboarding

### `LoginScreen`
- **Ubicación:** `lib/screens/login_screen.dart`
- **Propósito:** Permite a los usuarios iniciar sesión con correo y contraseña.
- **Funcionalidad:**
  - Validación de campos.
  - Inicio de sesión mediante `AuthService`.
  - Redirección automática según el rol del usuario (Admin, Trabajador, Cliente).
  - Enlaces a registro y recuperación de contraseña.

### `RegisterScreen`
- **Ubicación:** `lib/screens/register_screen.dart`
- **Propósito:** Registro de nuevos usuarios (principalmente Clientes).
- **Funcionalidad:**
  - Formulario con datos personales (Nombres, Apellidos, Documento, Dirección, Teléfono, Correo, Contraseña).
  - Selección de tipo de documento.
  - Creación de cuenta en Firebase Auth y base de datos.

### `SelectAccountTypeScreen`
- **Ubicación:** `lib/screens/select_account_type_screen.dart`
- **Propósito:** Pantalla intermedia para seleccionar el tipo de cuenta a registrar (si aplicara múltiples flujos públicos, actualmente redirige a Login o Registro).

### `ForgotPasswordScreen`
- **Ubicación:** `lib/screens/forgot_password_screen.dart`
- **Propósito:** Recuperación de contraseña.
- **Funcionalidad:** Envío de correo de restablecimiento de contraseña.

---

## 2. Pantallas Principales (Home)

### `AdminHomeScreen`
- **Ubicación:** `lib/screens/admin_home_screen.dart`
- **Propósito:** Panel de control principal para Administradores.
- **Funcionalidad:**
  - Resumen de estadísticas (usuarios, vehículos, órdenes).
  - Botones de acceso rápido a los módulos de gestión (Usuarios, Vehículos, Servicios, Órdenes).
  - Menú lateral (Drawer) para navegación.

### `ClienteHomeScreen`
- **Ubicación:** `lib/screens/cliente_home_screen.dart`
- **Propósito:** Pantalla de inicio para Clientes.
- **Funcionalidad:**
  - Visualización del perfil del usuario.
  - **Pendiente:** Botón "Solicitar Servicio" (actualmente muestra "Próximamente").
  - **Pendiente:** Lista de "Mis Órdenes" (no implementada aún).

### `TrabajadorHomeScreen`
- **Ubicación:** `lib/screens/trabajador_home_screen.dart`
- **Propósito:** Pantalla de inicio para Trabajadores.
- **Funcionalidad:**
  - Visualización del perfil del trabajador (incluyendo área y disponibilidad).
  - **Pendiente:** Botón "Ver Órdenes Asignadas" (actualmente muestra "Próximamente").

---

## 3. Gestión de Usuarios

### Diseño General (Admin UI)
Todas las pantallas de gestión (`Usuarios`, `Vehículos`, `Servicios`, `Órdenes`) han sido actualizadas al nuevo estándar visual:
- **Paleta**: Azul Principal (`0xFF1E88E5`) y Fondo Neutro (`0xFFF5F7FA`).
- **Componentes**: AppBars personalizadas (sin elevación), Buscadores Flotantes y Tarjetas con sombra suave (`blurRadius: 15`).

### `UsuariosManagementScreen`
- **Ubicación:** `lib/screens/usuarios_management_screen.dart`
- **Propósito:** Lista y administración de todos los usuarios.
- **Funcionalidad:**
  - Listado con buscador y filtro por rol (Cliente, Trabajador, Admin).
  - Opciones para ver detalles, editar o eliminar usuarios.
  - Botón flotante para crear nuevos usuarios.

### `CreateUserScreen` y derivados
- **Ubicación:** `lib/screens/create_user_screen.dart` (Genérica), `create_cliente_screen.dart`, `create_trabajador_screen.dart`, `create_admin_screen.dart`.
- **Propósito:** Formularios para crear usuarios manualmente desde el panel de administración.
- **Funcionalidad:**
  - Validación de datos específicos por rol (ej. sueldo y área para trabajadores).

### `EditUserScreen`
- **Ubicación:** `lib/screens/edit_user_screen.dart`
- **Propósito:** Edición de datos de un usuario existente.
- **Funcionalidad:** Permite modificar información personal y roles.

### `UserDetailsScreen`
- **Ubicación:** `lib/screens/user_details_screen.dart`
- **Propósito:** Visa de solo lectura de la información completa de un usuario.

---

## 4. Gestión de Vehículos

### `VehiculosManagementScreen`
- **Ubicación:** `lib/screens/vehiculos_management_screen.dart`
- **Propósito:** Lista global de vehículos registrados.
- **Funcionalidad:**
  - Buscador por placa, marca o cliente asociado.
  - Opciones para editar o eliminar.

### `VehiculosClienteScreen`
- **Ubicación:** `lib/screens/vehiculos_cliente_screen.dart`
- **Propósito:** Lista de vehículos pertenecientes a un cliente específico.

### `CreateVehiculoScreen`
- **Ubicación:** `lib/screens/create_vehiculo_screen.dart`
- **Propósito:** Registro de un nuevo vehículo para un cliente.
- **Funcionalidad:**
  - Formulario de datos del vehículo (Placa, Marca, Modelo, Color, etc.).
  - Carga de fotos (mínimo 3 requeridas) usando cámara o galería.

### `CreateVehiculoMultiScreen`
- **Ubicación:** `lib/screens/create_vehiculo_multi_screen.dart`
- **Propósito:** Similar a `CreateVehiculoScreen`, pero permite asociar el vehículo a múltiples clientes seleccionados previamente.

### `EditVehiculoScreen`
- **Ubicación:** `lib/screens/edit_vehiculo_screen.dart`
- **Propósito:** Edición de vehículo.
- **Funcionalidad:**
  - Modificar datos del vehículo.
  - Agregar o eliminar fotos.
  - Gestionar asociación de clientes (agregar/quitar dueños).

### `VehiculoDetailsScreen`
- **Ubicación:** `lib/screens/vehiculo_details_screen.dart`
- **Propósito:** Vista detallada del vehículo.
- **Funcionalidad:** Galería de fotos y lista de clientes propietarios.

---

## 5. Gestión de Servicios (Catálogo)

### `ServiciosManagementScreen`
- **Ubicación:** `lib/screens/servicios_management_screen.dart`
- **Propósito:** Administración del catálogo de servicios ofrecidos.
- **Funcionalidad:** Listado, búsqueda, eliminación.

### `CreateServicioScreen` / `EditServicioScreen`
- **Ubicación:** `lib/screens/create_servicio_screen.dart`, `lib/screens/edit_servicio_screen.dart`
- **Propósito:** Crear o editar tipos de servicios.
- **Funcionalidad:** Definir nombre, descripción, precio estimado y duración estimada.

### `ServicioDetailsScreen`
- **Ubicación:** `lib/screens/servicio_details_screen.dart`
- **Propósito:** Vista detallada de un servicio del catálogo.

---

## 6. Gestión de Órdenes

### `OrdenesManagementScreen`
- **Ubicación:** `lib/screens/ordenes_management_screen.dart`
- **Propósito:** Panel central de gestión de órdenes de trabajo.
- **Funcionalidad:**
  - Listado de todas las órdenes.
  - Filtros por estado (En Cotización, En Proceso, Finalizado, etc.) y búsqueda.
  - Resumen visual del estado y total.

### `CreateOrdenScreen`
- **Ubicación:** `lib/screens/create_orden_screen.dart`
- **Propósito:** Creación de una nueva orden.
- **Funcionalidad:**
  - Selección de cliente y vehículo (con buscadores).
  - Selección múltiple de servicios del catálogo.
  - Personalización de precio y observaciones por servicio.
  - Carga de fotos iniciales por servicio.
  - Definición de fecha promesa de entrega.

### `EditOrdenScreen`
- **Ubicación:** `lib/screens/edit_orden_screen.dart`
- **Propósito:** Edición de una orden existente.
- **Funcionalidad:**
  - Cambiar estado de la orden (flujo principal).
  - Modificar fecha promesa.
  - Editar cliente/vehículo (solo en estados iniciales).

### `OrdenDetailsScreen`
- **Ubicación:** `lib/screens/orden_details_screen.dart`
- **Propósito:** Vista maestra de la orden.
- **Funcionalidad:**
  - Información completa (Cliente, Vehículo, Fechas, Totales).
  - Lista de servicios incluidos con su estado individual y progreso.
  - Acceso a los avances de cada servicio.

### `AvancesServicioScreen`
- **Ubicación:** `lib/screens/avances_servicio_screen.dart`
- **Propósito:** Registro de progreso en un servicio específico de una orden.
- **Funcionalidad:**
  - Ver historial de avances (timeline).
  - Agregar nuevo avance con porcentaje, observaciones y fotos de evidencia.

---

## Notas de Implementación Pendiente
1. **Flujo de Cliente:** Pantallas para que el cliente vea sus propias órdenes y solicite servicios.
2. **Flujo de Trabajador:** Pantalla para que el trabajador vea solo las órdenes/servicios asignados a él (actualmente no hay asignación directa de trabajador a servicio en la UI de creación de orden).

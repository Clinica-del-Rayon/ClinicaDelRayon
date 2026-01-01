# 🔥 Firebase Realtime Database - Implementación Completa

## ✅ LO QUE SE HA IMPLEMENTADO:

### 1. **Modelos de Datos** (`lib/models/usuario.dart`)
Basados en tu diagrama de clases:

- **Usuario** (clase base)
  - uid, nombres, apellidos
  - tipo_documento (CC, CE, NIT, PP)
  - numero_documento, correo, telefono
  - password (solo para creación)
  - rol (ADMIN, CLIENTE, TRABAJADOR)
  - calificacion (0.0-5.0)
  - foto_perfil_url (Link a Firebase Storage)

- **Cliente** (hereda de Usuario)
  - direccion
  - fecha_registro

- **Trabajador** (hereda de Usuario)
  - area (Mecánico, Pintura, etc.)
  - sueldo
  - estado_disponibilidad (Boolean)

### 2. **Servicios** 

#### `DatabaseService` (`lib/services/database_service.dart`)
Maneja todas las operaciones con Realtime Database:

- ✅ `createCliente()` - Crear nuevo cliente
- ✅ `createTrabajador()` - Crear nuevo trabajador
- ✅ `getUsuario(uid)` - Obtener usuario por UID
- ✅ `getRolUsuario(uid)` - Obtener solo el rol
- ✅ `updateUsuario()` - Actualizar datos
- ✅ `deleteUsuario()` - Eliminar usuario
- ✅ `getAllClientes()` - Listar todos los clientes
- ✅ `getAllTrabajadores()` - Listar todos los trabajadores
- ✅ `getTrabajadoresByArea()` - Filtrar por área
- ✅ `getTrabajadoresDisponibles()` - Solo disponibles
- ✅ `usuarioStream()` - Cambios en tiempo real

#### `AuthService` (`lib/services/auth_service.dart`)
Integrado con DatabaseService:

- ✅ `registerCliente()` - Registro completo (Auth + Database)
- ✅ `registerTrabajador()` - Solo para ADMIN
- ✅ `getCurrentUserData()` - Datos del usuario actual
- ✅ `getCurrentUserRole()` - Rol del usuario actual
- ✅ `signInWithEmailAndPassword()` - Login
- ✅ `signOut()` - Cerrar sesión

### 3. **Pantallas**

#### `RegisterScreen` - Registro de Clientes
- Formulario completo con todos los campos
- Validación de datos
- Creación automática en Auth y Realtime Database
- Público - cualquiera puede crear cuenta de cliente

#### `RegisterTrabajadorScreen` - Registro de Trabajadores
- Solo accesible por ADMIN
- Formulario con campos específicos de trabajador
- Dropdown con áreas predefinidas
- Switch para disponibilidad

#### `HomeScreen` - Pantalla principal
3 variantes según el rol:

**Cliente:**
- Muestra datos personales
- Botón "Solicitar Servicio" (próximamente)

**Trabajador:**
- Muestra datos laborales
- Área, sueldo, disponibilidad
- Botón "Ver Órdenes Asignadas" (próximamente)

**Administrador:**
- Botón "Crear Nuevo Trabajador"
- Botón "Ver Trabajadores" (próximamente)
- Botón "Ver Clientes" (próximamente)

---

## 📊 ESTRUCTURA DE LA BASE DE DATOS:

```
firebase-realtime-database/
├── usuarios/
│   ├── {uid}/
│   │   ├── uid: "..."
│   │   ├── nombres: "..."
│   │   ├── apellidos: "..."
│   │   ├── tipo_documento: "CC"
│   │   ├── numero_documento: "..."
│   │   ├── correo: "..."
│   │   ├── telefono: "..."
│   │   ├── rol: "CLIENTE" | "TRABAJADOR" | "ADMIN"
│   │   ├── calificacion: 0.0
│   │   ├── foto_perfil: null | "url"
│   │   ├── [Si es Cliente]
│   │   │   ├── direccion: "..."
│   │   │   └── fecha_registro: "2025-12-31T..."
│   │   └── [Si es Trabajador]
│   │       ├── area: "Mecánico"
│   │       ├── sueldo: 1500000
│   │       └── estado_disponibilidad: true
│   └── ...
├── clientes/
│   └── {uid}/ (copia para consultas rápidas)
└── trabajadores/
    └── {uid}/ (copia para consultas rápidas)
```

---

## 🚀 CÓMO USAR:

### **1. Habilitar Realtime Database en Firebase Console**

```
1. Ve a Firebase Console: https://console.firebase.google.com
2. Selecciona tu proyecto
3. En el menú lateral: "Realtime Database"
4. Clic en "Crear base de datos"
5. Selecciona ubicación: "us-central1"
6. Modo: "Comenzar en modo de prueba" (temporal)
7. Clic en "Habilitar"
```

### **2. Configurar Reglas de Seguridad**

En la consola de Firebase → Realtime Database → Reglas:

```json
{
  "rules": {
    "usuarios": {
      "$uid": {
        ".read": "auth != null && (auth.uid == $uid || root.child('usuarios').child(auth.uid).child('rol').val() == 'ADMIN')",
        ".write": "auth != null && (auth.uid == $uid || root.child('usuarios').child(auth.uid).child('rol').val() == 'ADMIN')"
      }
    },
    "clientes": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && root.child('usuarios').child(auth.uid).child('rol').val() == 'ADMIN'"
      }
    },
    "trabajadores": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && root.child('usuarios').child(auth.uid).child('rol').val() == 'ADMIN'"
      }
    }
  }
}
```

**Explicación:**
- Los usuarios pueden leer/escribir sus propios datos
- Los ADMIN pueden leer/escribir todos los datos
- Todos pueden leer la lista de clientes y trabajadores
- Solo ADMIN puede modificar listas de clientes y trabajadores

### **3. Crear tu primera cuenta ADMIN**

**Opción A: Manualmente desde Firebase Console**

```
1. Firebase Console → Authentication → Users
2. Clic en "Agregar usuario"
3. Email: admin@clinicadelrayon.com
4. Contraseña: (elige una segura)
5. Clic en "Agregar usuario"
6. Copia el UID del usuario creado

7. Ve a Realtime Database → Datos
8. Clic en "+" para agregar datos
9. Crear estructura:
   usuarios/
     {UID_DEL_ADMIN}/
       uid: "{UID_DEL_ADMIN}"
       nombres: "Administrador"
       apellidos: "Sistema"
       tipo_documento: "CC"
       numero_documento: "000000000"
       correo: "admin@clinicadelrayon.com"
       telefono: "0000000000"
       rol: "ADMIN"
       calificacion: 5.0
       foto_perfil: null
```

**Opción B: Desde la app (modificar temporalmente)**

1. Comenta la validación de ADMIN en `auth_service.dart` línea ~75:
```dart
// if (currentUserRole != models.RolUsuario.ADMIN) {
//   throw 'Solo los administradores pueden crear trabajadores.';
// }
```

2. Ejecuta la app
3. Registra un trabajador con datos de admin
4. Ve a Firebase Console → Realtime Database
5. Cambia el rol de ese usuario a "ADMIN"
6. Descomenta la validación
7. Ya tienes tu cuenta ADMIN

---

## 🔐 FLUJO DE AUTENTICACIÓN:

### **Registro de Cliente (Público)**

```
1. Usuario abre la app
2. Clic en "Crear cuenta nueva"
3. Completa formulario RegisterScreen
4. AuthService.registerCliente():
   a. Crea usuario en Firebase Auth
   b. DatabaseService.createCliente():
      - Guarda en nodo usuarios/
      - Guarda en nodo clientes/
5. Redirect → HomeScreen (vista de cliente)
```

### **Inicio de Sesión**

```
1. Usuario ingresa email y contraseña
2. AuthService.signInWithEmailAndPassword()
3. AuthWrapper detecta cambio
4. AuthService.getCurrentUserData()
5. DatabaseService.getUsuario(uid)
6. HomeScreen muestra vista según rol:
   - CLIENTE → _ClienteHomeScreen
   - TRABAJADOR → _TrabajadorHomeScreen  
   - ADMIN → _AdminHomeScreen
```

### **Creación de Trabajador (Solo ADMIN)**

```
1. ADMIN inicia sesión
2. _AdminHomeScreen muestra botón "Crear Nuevo Trabajador"
3. Navega a RegisterTrabajadorScreen
4. AuthService.registerTrabajador():
   a. Verifica que usuario actual sea ADMIN
   b. Crea usuario en Firebase Auth
   c. DatabaseService.createTrabajador():
      - Guarda en nodo usuarios/
      - Guarda en nodo trabajadores/
5. Redirect → _AdminHomeScreen
```

---

## 🧪 TESTING:

### **1. Probar registro de cliente**

```dart
// La app ya lo hace automáticamente
// Solo ingresa datos en el formulario de registro
```

### **2. Probar consultas desde código**

```dart
final dbService = DatabaseService();

// Obtener todos los clientes
final clientes = await dbService.getAllClientes();
print('Total clientes: ${clientes.length}');

// Obtener trabajadores de mecánica
final mecanicos = await dbService.getTrabajadoresByArea('Mecánico');
print('Mecánicos: ${mecanicos.length}');

// Obtener trabajadores disponibles
final disponibles = await dbService.getTrabajadoresDisponibles();
print('Disponibles: ${disponibles.length}');

// Escuchar cambios en tiempo real
dbService.usuarioStream('uid_del_usuario').listen((usuario) {
  print('Usuario actualizado: ${usuario?.nombres}');
});
```

---

## 📱 PRÓXIMOS PASOS:

### **Funcionalidades pendientes (TODO):**

1. ✅ **Gestión de Órdenes** (según tu diagrama)
   - Crear modelos: Orden, DetalleOrden, Servicio
   - CRUD de órdenes
   - Asignar trabajadores a órdenes

2. ✅ **Gestión de Vehículos**
   - Crear modelo Vehículo
   - Vincular con clientes
   - CRUD de vehículos

3. ✅ **Gestión de Facturas**
   - Crear modelo Factura
   - Generar PDF
   - Enviar por email

4. ✅ **Gestión de Inspecciones**
   - Crear modelo Inspección
   - Subir fotos a Firebase Storage
   - Checklist de inspección

5. ✅ **Sistema de Calificaciones**
   - Permitir a clientes calificar trabajadores
   - Calcular promedio automáticamente

---

## 🛠️ SOLUCIÓN DE PROBLEMAS:

### **Error: "No se encontraron datos del usuario"**

**Causa:** El usuario se autenticó pero no existe en Realtime Database

**Solución:**
```dart
// Verificar en Firebase Console → Realtime Database
// Debe existir: usuarios/{uid del usuario}
// Si no existe, el registro no se completó correctamente
```

### **Error: "Solo los administradores pueden crear trabajadores"**

**Causa:** Intentas crear un trabajador sin ser ADMIN

**Solución:**
1. Crea tu cuenta ADMIN primero (ver sección 3)
2. Inicia sesión con esa cuenta
3. Ahora podrás crear trabajadores

### **Error: Permission denied**

**Causa:** Reglas de seguridad muy restrictivas

**Solución temporal (SOLO DESARROLLO):**
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

**⚠️ IMPORTANTE:** Esto es INSEGURO. Solo para desarrollo.
Usa las reglas recomendadas en producción.

---

## ✅ CHECKLIST DE CONFIGURACIÓN:

- [ ] Firebase Realtime Database habilitado
- [ ] Reglas de seguridad configuradas
- [ ] Cuenta ADMIN creada
- [ ] flutter pub get ejecutado
- [ ] App ejecutándose sin errores
- [ ] Registro de cliente funcionando
- [ ] Login funcionando
- [ ] Pantallas diferentes según rol
- [ ] Creación de trabajadores (como ADMIN)

---

**¡La implementación de Realtime Database está completa y lista para usar!** 🎉


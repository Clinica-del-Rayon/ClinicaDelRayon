# Documentación de Modelos de Datos

Este documento describe las estructuras de datos fundamentales (modelos) utilizadas en la aplicación Clínica del Rayón.

## 1. Orden (`orden.dart`)

Modelo central que representa una orden de trabajo.

### Enum: `EstadoOrden`
Estados posibles de una orden:
- `EN_COTIZACION`: Orden creada pero aún en definición de precios/servicios.
- `COTIZACION_RESERVA`: Presupuesto aprobado, esperando ingreso del vehículo.
- `EN_PROCESO`: Trabajo en curso.
- `FINALIZADO`: Trabajo terminado, listo para entrega.
- `ENTREGADO`: Vehículo entregado al cliente.

### Enum: `EstadoServicio`
Estado individual de cada servicio dentro de una orden:
- `PENDIENTE`: Aún no iniciado.
- `TRABAJANDO`: En progreso.
- `LISTO`: Completado.

### Clases:
- **`Orden`**: Entidad principal.
  - Campos clave: `id`, `clienteId`, `vehiculoId`, `estado`, `detalles` (lista de servicios), `fechaPromesa`, `total`.
  - Métodos: `calcularTotal()`, `calcularProgresoPromedio()`.
- **`DetalleOrden`**: Representa un ítem de servicio en la orden.
  - Contiene: `servicioId`, `precio` (acordado), `estadoItem`, `progreso` (0-100%), `fotosIniciales`, `avances` (historial).
- **`AvanceServicio`**: Registro de actualización de progreso.
  - Contiene: `fecha`, `observaciones`, `fotosUrls`, cambio de progreso (`anterior` -> `nuevo`).
- **`Servicio`**: Definición del catálogo (nombre, descripción base, precio estimado).

---

## 2. Usuario (`usuario.dart`)

Sistema de usuarios utilizando herencia para manejar roles.

### Roles y Enums:
- **`RolUsuario`**: `ADMIN`, `CLIENTE`, `TRABAJADOR`.
- **`TipoDocumento`**: `CC`, `CE`, `NIT`, `PP`.

### Clases:
- **`Usuario` (Base)**
  - Datos comunes: `uid` (Firebase Auth ID), `nombres`, `apellidos`, `documento`, `correo`, `telefono`, `fotoPerfil`.
- **`Cliente` (Extends `Usuario`)**
  - Datos adicionales: `direccion`, `fechaRegistro`.
- **`Trabajador` (Extends `Usuario`)**
  - Datos adicionales: `area` (ej. Pintura, Mecánica), `sueldo`, `estadoDisponibilidad`.

---

## 3. Vehículo (`vehiculo.dart`)

Representa los vehículos atendidos en el taller.

### Enum: `TipoVehiculo`
- `CARRO`
- `MOTO`

### Clase: `Vehiculo`
- Campos: `placa`, `marca`, `modelo`, `generacion` (año), `color`.
- Relaciones: `clienteIds` (lista de dueños, permite multi-propiedad).
- Multimedia: `fotosUrls` (galería del vehículo).
- Métodos auxiliares: `tieneFotosSuficientes` (mínimo 3).

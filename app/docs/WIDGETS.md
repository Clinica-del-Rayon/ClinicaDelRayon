# Documentación de Widgets Reutilizables

Widgets personalizados creados para encapsular lógica común o UI compleja reutilizada en varias pantallas.

## 1. `AuthWrapper` (`auth_wrapper.dart`)

Widget raíz encargado del enrutamiento basado en autenticación.
- **Función**: Escucha el `ProviderState`.
- **Lógica**:
  - Si `isLoading` es true -> Muestra `CircularProgressIndicator`.
  - Si `user` es null -> Muestra `LoginScreen`.
  - Si `user` existe -> Muestra `HomeScreen` (que a su vez deriva al home específico según el rol).

## 2. `SearchableDropdown` (`searchable_dropdown.dart`)

Un dropdown avanzado que permite buscar dentro de las opciones.
- **Uso**: Selección de Clientes y Vehículos en los formularios de creación de órdenes.
- **Props**:
  - `items`: Lista de objetos.
  - `itemLabel`: Función para obtener el texto a mostrar de cada objeto.
  - `filter`: Lógica de búsqueda local.
- **UI**: Muestra un campo de texto que al tocarse abre un diálogo con un buscador y la lista filtrable.

## 3. `FotoPerfilSelector` (`foto_perfil_selector.dart`)

Componente de UI para gestionar la foto de perfil en formularios de registro/edición.
- **Funcionalidad**:
  - Muestra la foto actual (URL o File local).
  - Botón flotante para cambiar.
  - Modal (BottomSheet) con opciones: Cámara, Galería, Eliminar.

## 4. `FotosServicioSelector` (`fotos_servicio_selector.dart`)

Componente para gestionar listas de fotos (evidencias).
- **Uso**: En creación de órdenes (fotos iniciales) y en reporte de avances.
- **UI**:
  - Botones "Cámara" y "Galería".
  - Carrusel horizontal de miniaturas de fotos seleccionadas.
  - Opción para eliminar fotos de la selección actual.
- **Validaciones**: Controla el número máximo de fotos permitidas.

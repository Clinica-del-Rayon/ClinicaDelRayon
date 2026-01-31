import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/orden.dart';
import '../../models/usuario.dart';

enum PeriodoTiempo { DIARIO, MENSUAL, ANUAL }

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final DatabaseService _dbService = DatabaseService();

  PeriodoTiempo _periodoSeleccionado = PeriodoTiempo.MENSUAL;
  bool _isLoading = false;

  // Datos de estadísticas
  List<Orden> _ordenes = [];
  List<Usuario> _clientes = [];
  List<Servicio> _servicios = [];

  // Métricas calculadas
  double _totalVentas = 0.0;
  double _totalGanancias = 0.0;
  int _totalOrdenes = 0;
  Map<String, int> _serviciosPorId = {};
  Map<String, double> _ventasPorCliente = {};

  // Colores
  final Color _primaryColor = const Color(0xFF1E88E5);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadEstadisticas();
  }

  Future<void> _loadEstadisticas() async {
    setState(() => _isLoading = true);

    try {
      // Cargar datos
      final ordenes = await _dbService.getAllOrdenes();
      final clientes = await _dbService.getAllUsuarios();
      final servicios = await _dbService.getAllServicios();

      setState(() {
        _ordenes = ordenes;
        _clientes = clientes.whereType<Cliente>().toList();
        _servicios = servicios;
      });

      _calcularEstadisticas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calcularEstadisticas() {
    // Filtrar órdenes según el período seleccionado
    final now = DateTime.now();
    final ordenesFiltradas = _ordenes.where((orden) {
      switch (_periodoSeleccionado) {
        case PeriodoTiempo.DIARIO:
          return orden.fechaCreacion.year == now.year &&
                 orden.fechaCreacion.month == now.month &&
                 orden.fechaCreacion.day == now.day;
        case PeriodoTiempo.MENSUAL:
          return orden.fechaCreacion.year == now.year &&
                 orden.fechaCreacion.month == now.month;
        case PeriodoTiempo.ANUAL:
          return orden.fechaCreacion.year == now.year;
      }
    }).toList();

    // Calcular métricas
    double totalVentas = 0.0;
    double totalCostos = 0.0;
    Map<String, int> serviciosPorId = {};
    Map<String, double> ventasPorCliente = {};

    for (var orden in ordenesFiltradas) {
      // Contar todas las órdenes
      for (var detalle in orden.detalles) {
        totalVentas += detalle.precio;

        // Calcular costo del servicio
        try {
          final servicio = _servicios.firstWhere((s) => s.id == detalle.servicioId);
          if (servicio.costoEstimado != null) {
            totalCostos += servicio.costoEstimado!;
          }
        } catch (e) {
          // Si no se encuentra el servicio, no se suma al costo
        }

        // Contar servicios
        serviciosPorId[detalle.servicioId] =
          (serviciosPorId[detalle.servicioId] ?? 0) + 1;
      }

      // Ventas por cliente
      ventasPorCliente[orden.clienteId] =
        (ventasPorCliente[orden.clienteId] ?? 0) +
        orden.detalles.fold<double>(0, (sum, d) => sum + d.precio);
    }

    setState(() {
      _totalVentas = totalVentas;
      _totalGanancias = totalVentas - totalCostos; // Ganancias = Ventas - Costos
      _totalOrdenes = ordenesFiltradas.length;
      _serviciosPorId = serviciosPorId;
      _ventasPorCliente = ventasPorCliente;
    });
  }

  List<MapEntry<String, int>> _getMejoresServicios() {
    final entries = _serviciosPorId.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  List<MapEntry<String, double>> _getMejoresClientes() {
    final entries = _ventasPorCliente.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  String _getNombreServicio(String servicioId) {
    try {
      return _servicios.firstWhere((s) => s.id == servicioId).nombre;
    } catch (e) {
      return 'Desconocido';
    }
  }

  String _getNombreCliente(String clienteId) {
    try {
      final cliente = _clientes.firstWhere((c) => c.uid == clienteId);
      return cliente.nombres;
    } catch (e) {
      return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.blueGrey[700], size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Selector de Período
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildPeriodoButton('Diario', PeriodoTiempo.DIARIO),
                    _buildPeriodoButton('Mensual', PeriodoTiempo.MENSUAL),
                    _buildPeriodoButton('Anual', PeriodoTiempo.ANUAL),
                  ],
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryColor),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEstadisticas,
                      color: _primaryColor,
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tarjetas de métricas principales
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'Ventas Totales',
                                    '\$${_totalVentas.toStringAsFixed(2)}',
                                    Icons.attach_money_rounded,
                                    Colors.green,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Ganancias',
                                    '\$${_totalGanancias.toStringAsFixed(2)}',
                                    Icons.trending_up_rounded,
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricCard(
                                    'Órdenes',
                                    _totalOrdenes.toString(),
                                    Icons.assignment_outlined,
                                    Colors.orange,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricCard(
                                    'Promedio/Orden',
                                    _totalOrdenes > 0
                                      ? '\$${(_totalVentas / _totalOrdenes).toStringAsFixed(2)}'
                                      : '\$0.00',
                                    Icons.calculate_rounded,
                                    Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 32),

                            // Mejores Servicios
                            _buildSectionTitle('Top 5 Servicios Más Solicitados'),
                            SizedBox(height: 12),
                            _buildMejoresServiciosSection(),
                            SizedBox(height: 32),

                            // Mejores Clientes
                            _buildSectionTitle('Top 5 Mejores Clientes'),
                            SizedBox(height: 12),
                            _buildMejoresClientesSection(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodoButton(String label, PeriodoTiempo periodo) {
    final isSelected = _periodoSeleccionado == periodo;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _periodoSeleccionado = periodo;
              _calcularEstadisticas();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? _primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
    );
  }

  Widget _buildMejoresServiciosSection() {
    final mejoresServicios = _getMejoresServicios();

    if (mejoresServicios.isEmpty) {
      return _buildEmptyState('No hay datos de servicios');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: mejoresServicios.asMap().entries.map((entry) {
          final index = entry.key;
          final servicioId = entry.value.key;
          final cantidad = entry.value.value;
          final isLast = index == mejoresServicios.length - 1;

          return Column(
            children: [
              _buildRankingItem(
                index + 1,
                _getNombreServicio(servicioId),
                '$cantidad solicitudes',
                Colors.teal,
              ),
              if (!isLast) Divider(height: 1, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMejoresClientesSection() {
    final mejoresClientes = _getMejoresClientes();

    if (mejoresClientes.isEmpty) {
      return _buildEmptyState('No hay datos de clientes');
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: mejoresClientes.asMap().entries.map((entry) {
          final index = entry.key;
          final clienteId = entry.value.key;
          final total = entry.value.value;
          final isLast = index == mejoresClientes.length - 1;

          return Column(
            children: [
              _buildRankingItem(
                index + 1,
                _getNombreCliente(clienteId),
                '\$${total.toStringAsFixed(2)}',
                Colors.amber,
              ),
              if (!isLast) Divider(height: 1, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankingItem(int rank, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? color.withValues(alpha: 0.2) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? color : Colors.grey[600],
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (rank <= 3)
            Icon(
              rank == 1 ? Icons.emoji_events : Icons.workspace_premium,
              color: color,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


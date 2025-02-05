import 'package:flutter/material.dart';
import 'modal_metas.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/api_service_metas.dart';

class GoalsSection extends StatefulWidget {
  final bool isLoading;
  final Function(String, String, double, DateTime, String, String) onSave;

  const GoalsSection({
    super.key,
    required this.isLoading,
    required this.onSave,
  });

  @override
  State<GoalsSection> createState() => _GoalsSectionState();
}

class _GoalsSectionState extends State<GoalsSection> {
  late Future<List<Meta>> _metasFuture;
  final ApiServiceGetMetas _metaService = ApiServiceGetMetas();

  @override
  void initState() {
    super.initState();
    _loadMetas();
  }

  void _loadMetas() {
    setState(() {
      _metasFuture = _metaService.getMetasWithCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: widget.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF228B22)),
            )
          : FutureBuilder<List<Meta>>(
              future: _metasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF228B22)),
                  );
                }

                final metas = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildAddButton(context),
                    metas.isEmpty
                        ? _buildEmptyState() // Mostrar estado vacío
                        : Expanded(
                            child: _buildGoalsCarousel(metas),
                          ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'No tienes metas creadas',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Presiona el botón "Agregar Meta" para comenzar',
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 20),
          const Text(
            'Error al cargar las metas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadMetas,
            child: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: TextButton.icon(
        icon:
            const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
        label: const Text('Agregar Meta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            )),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          backgroundColor: Color(0xFF228B22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF228B22), width: 1),
          ),
        ),
        onPressed: () => _showAddGoalModal(context),
      ),
    );
  }

  Widget _buildGoalsCarousel(List<Meta> metas) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: PageView.builder(
        itemCount: metas.length,
        itemBuilder: (context, index) {
          final meta = metas[index];
          return Padding(
            padding: const EdgeInsets.all(10),
            child: _buildGoalPage(
              meta.nombreMeta,
              meta.montoActual / meta.montoObjetivo,
              meta.montoObjetivo,
              meta.montoActual,
              meta.categoriaNombre,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalPage(String title, double progress, double metaTotal,
      double metaActual, String categoriaNombre) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircularPercentIndicator(
                radius: MediaQuery.of(context).size.width * 0.35,
                lineWidth: 12,
                percent: clampedProgress,
                animation: true,
                animationDuration: 800,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: const Color(0xFF228B22),
                backgroundColor: Colors.grey[200]!,
                center: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(categoriaNombre),
                      size: 30,
                      color: const Color(0xFF228B22),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              '${(clampedProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF228B22),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                children: [
                  TextSpan(
                    text: 'Actual: \$${metaActual.toStringAsFixed(0)}\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF228B22),
                    ),
                  ),
                  TextSpan(
                    text: 'Meta total: \$${metaTotal.toStringAsFixed(0)}',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MetasModal(
        onMetaCreated: () {
          widget.onSave('', '', 0.0, DateTime.now(), '', '');
          _loadMetas();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meta creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }
}

IconData _getCategoryIcon(String? categoryName) {
  switch (categoryName?.toLowerCase() ?? 'default') {
    case 'ahorro':
      return Icons.savings;
    case 'viaje':
      return Icons.flight;
    case 'emprendimiento':
      return Icons.business;
    case 'proyecto':
      return Icons.assignment;
    case 'caridad':
      return Icons.volunteer_activism;
    case 'logro':
      return Icons.emoji_events;
    case 'medio ambiente':
      return Icons.eco;
    case 'seguridad':
      return Icons.security;
    case 'estrella':
      return Icons.star;
    default:
      return Icons.more_horiz;
  }
}

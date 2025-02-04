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

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${snapshot.error}'),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _loadMetas,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final metas = snapshot.data ?? [];

                if (metas.isEmpty) {
                  return const Center(
                    child: Text('No hay metas registradas'),
                  );
                }

                return Column(
                  children: [
                    _buildAddButton(context),
                    Expanded(
                      child: _buildGoalsCarousel(metas),
                    ),
                  ],
                );
              },
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildGoalPage(
      String title, double progress, double metaTotal, double metaActual) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: CircularPercentIndicator(
                radius: MediaQuery.of(context).size.width * 0.35,
                lineWidth: 12,
                percent: progress,
                progressColor: const Color(0xFF228B22),
                backgroundColor: Colors.grey[200]!,
                circularStrokeCap: CircularStrokeCap.round,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
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

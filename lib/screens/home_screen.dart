import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_theme.dart';
import '../config/app_config.dart';
import '../models/procurement_process.dart';
import '../state/search_controller.dart';
import '../state/search_state.dart';
import '../widgets/academic_disclaimer.dart';
import '../widgets/process_card.dart';
import '../widgets/status_view.dart';
import 'process_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController(
    text: 'Alborada',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProcurementSearchController>().buscar(
        _searchController.text,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<ProcurementSearchController>().buscar(_searchController.text);
  }

  void _openDetails(ProcurementProcess process) {
    final ocid = process.ocid?.trim();
    if (ocid == null || ocid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este proceso no tiene un OCID disponible.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProcessDetailScreen(process: process),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProcurementSearchController>();
    final hasResults = controller.state.status == SearchStatus.results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta ciudadana'),
        leading: const Icon(Icons.account_balance_outlined),
      ),
      body: SafeArea(
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.list(
                children: [
                  _buildHero(context),
                  const SizedBox(height: 12),
                  const AcademicDisclaimer(),
                  const SizedBox(height: 12),
                  _buildSearchCard(context, controller),
                  if (hasResults) ...[
                    const SizedBox(height: 16),
                    _buildResultsHeader(context, controller.results.length),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            if (hasResults)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList.separated(
                  itemCount: controller.results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final process = controller.results[index];
                    return ProcessCard(
                      process: process,
                      onViewDetails: process.ocid?.trim().isNotEmpty ?? false
                          ? () => _openDetails(process)
                          : null,
                    );
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(height: 250, child: _buildStatus(controller)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/guayaquil_hero.png'),
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                AppTheme.primaryBlue.withValues(alpha: 0.94),
                AppTheme.primaryBlue.withValues(alpha: 0.72),
                AppTheme.primaryBlue.withValues(alpha: 0.14),
                Colors.transparent,
              ],
              stops: const <double>[0, 0.38, 0.58, 0.72],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final preferredTextWidth = compact
                    ? constraints.maxWidth * 0.62
                    : constraints.maxWidth * 0.58;
                final availableTextWidth = compact
                    ? constraints.maxWidth
                    : constraints.maxWidth - 60;
                final textWidth = preferredTextWidth < availableTextWidth
                    ? preferredTextWidth
                    : availableTextWidth;
                final cityIcon = Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.location_city_outlined,
                    color: Colors.white,
                  ),
                );
                final copy = ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: textWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConfig.appName,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.18,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Consulta obras y procesos publicados en contratación abierta.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [cityIcon, const SizedBox(height: 12), copy],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [cityIcon, const SizedBox(width: 14), copy],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(
    BuildContext context,
    ProcurementSearchController controller,
  ) {
    final loading = controller.state.status == SearchStatus.loading;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: '¿Qué obra estás buscando?',
                hintText: 'Alborada, aeropuerto, pavimentación…',
                prefixIcon: const Icon(Icons.search_rounded),
                errorText: controller.validationMessage,
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: loading ? null : _search,
              icon: const Icon(Icons.travel_explore_rounded),
              label: const Text('Buscar procesos'),
            ),
            if (loading) ...[
              const SizedBox(height: 10),
              Text(
                'Consultando procesos de 2024 a 2026…',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(BuildContext context, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count procesos encontrados',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          'Más recientes primero',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(ProcurementSearchController controller) {
    return switch (controller.state.status) {
      SearchStatus.initial => const StatusView(
        message: 'Escribe una palabra para consultar procesos.',
      ),
      SearchStatus.loading => const StatusView(
        message: 'Preparando resultados…',
        loading: true,
      ),
      SearchStatus.empty => const StatusView(
        message:
            'No se encontraron procesos de la Municipalidad de Guayaquil para esta búsqueda.',
        icon: Icons.search_off,
      ),
      SearchStatus.error => StatusView(
        message: controller.errorMessage ?? 'No fue posible buscar procesos.',
        icon: Icons.error_outline,
      ),
      SearchStatus.results => const SizedBox.shrink(),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_theme.dart';
import '../models/procurement_detail.dart';
import '../models/procurement_process.dart';
import '../repositories/procurement_repository.dart';
import '../widgets/info_chip.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_card.dart';
import '../widgets/status_view.dart';

class ProcessDetailScreen extends StatefulWidget {
  const ProcessDetailScreen({required this.process, super.key});

  final ProcurementProcess process;

  @override
  State<ProcessDetailScreen> createState() => _ProcessDetailScreenState();
}

class _ProcessDetailScreenState extends State<ProcessDetailScreen> {
  ProcurementDetail? _detail;
  bool _loading = true;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final ocid = widget.process.ocid?.trim();
    if (ocid == null || ocid.isEmpty) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final detail = await context.read<ProcurementRepository>().obtenerDetalle(
        ocid,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del proceso')),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: StatusView(
          message: 'Cargando información del proceso…',
          loading: true,
        ),
      );
    }
    if (_failed) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: StatusView(
          message: 'No fue posible cargar el detalle del proceso.',
          icon: Icons.cloud_off_outlined,
          actionLabel: 'Intentar de nuevo',
          onAction: _loadDetail,
        ),
      );
    }

    final detail = _detail;
    if (detail == null || !detail.hasMeaningfulInformation) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: StatusView(
          message: 'Este proceso no contiene suficiente información detallada.',
          icon: Icons.content_paste_off_outlined,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryCard(process: widget.process, detail: detail),
          if (_metrics(detail).isNotEmpty) ...[
            const SizedBox(height: 14),
            _MetricsGrid(metrics: _metrics(detail)),
          ],
          if (_text(detail.description) != null) ...[
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.subject_outlined,
              title: 'Descripción',
              child: Text(
                detail.description!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ),
          ],
          if (_hasDates(detail)) ...[
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.event_outlined,
              title: 'Fechas importantes',
              child: Column(
                children: [
                  if (detail.tenderStartDate != null)
                    _InfoRow(
                      label: 'Inicio del proceso',
                      value: _date(detail.tenderStartDate!),
                    ),
                  if (detail.tenderEndDate != null)
                    _InfoRow(
                      label: 'Cierre del proceso',
                      value: _date(detail.tenderEndDate!),
                    ),
                  if (detail.awardDate != null)
                    _InfoRow(
                      label: 'Adjudicación',
                      value: _date(detail.awardDate!),
                    ),
                  if (detail.signedDate != null)
                    _InfoRow(
                      label: 'Firma del contrato',
                      value: _date(detail.signedDate!),
                    ),
                  if (detail.contractStartDate != null)
                    _InfoRow(
                      label: 'Inicio contractual',
                      value: _date(detail.contractStartDate!),
                    ),
                  if (detail.contractEndDate != null)
                    _InfoRow(
                      label: 'Fin contractual',
                      value: _date(detail.contractEndDate!),
                      showDivider: false,
                    ),
                ],
              ),
            ),
          ],
          if (_text(detail.buyerName) != null ||
              _text(detail.buyerId) != null) ...[
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.account_balance_outlined,
              title: 'Información del comprador',
              child: Column(
                children: [
                  if (_text(detail.buyerName) != null)
                    _InfoRow(label: 'Entidad', value: detail.buyerName!),
                  if (_text(detail.buyerId) != null)
                    _InfoRow(
                      label: 'Identificador',
                      value: detail.buyerId!,
                      showDivider: false,
                    ),
                ],
              ),
            ),
          ],
          if (_hasTender(detail)) ...[
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.assignment_outlined,
              title: 'Información del proceso',
              child: Column(
                children: [
                  if (_text(detail.methodDetails) != null)
                    _InfoRow(label: 'Tipo', value: detail.methodDetails!),
                  if (_text(detail.method) != null)
                    _InfoRow(label: 'Método', value: _friendly(detail.method!)),
                  if (_text(detail.category) != null)
                    _InfoRow(
                      label: 'Categoría',
                      value: _friendly(detail.category!),
                    ),
                  if (_text(detail.tenderStatus) != null)
                    _InfoRow(
                      label: 'Estado',
                      value: _friendly(detail.tenderStatus!),
                      showDivider: detail.tenderValue != null,
                    ),
                  if (detail.tenderValue != null)
                    _InfoRow(
                      label: 'Valor del procedimiento',
                      value: _money(detail.tenderValue!),
                      showDivider: false,
                    ),
                ],
              ),
            ),
          ],
          if (_hasAward(detail)) ...[
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.workspace_premium_outlined,
              title: 'Adjudicación',
              child: Column(
                children: [
                  if (_text(detail.awardedSupplier) != null)
                    _InfoRow(
                      label: 'Proveedor adjudicado',
                      value: detail.awardedSupplier!,
                    ),
                  if (detail.awardedAmount != null)
                    _InfoRow(
                      label: 'Monto adjudicado',
                      value: _money(detail.awardedAmount!),
                      showDivider: _text(detail.awardDescription) != null,
                    ),
                  if (_text(detail.awardDescription) != null)
                    _InfoRow(
                      label: 'Resumen',
                      value: detail.awardDescription!,
                      showDivider: false,
                    ),
                ],
              ),
            ),
          ],
          if (_hasContract(detail)) ...[
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.handshake_outlined,
              title: 'Contrato',
              child: Column(
                children: [
                  if (_text(detail.contractStatus) != null)
                    _InfoRow(
                      label: 'Estado contractual',
                      value: _friendly(detail.contractStatus!),
                    ),
                  if (detail.contractAmount != null)
                    _InfoRow(
                      label: 'Monto contractual',
                      value: _money(detail.contractAmount!),
                    ),
                  if (_text(detail.contractId) != null)
                    _InfoRow(
                      label: 'Código de contrato',
                      value: detail.contractId!,
                      showDivider: false,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.fingerprint_outlined,
            title: 'OCID y trazabilidad',
            child: Column(
              children: [
                if (_text(detail.ocid ?? widget.process.ocid) != null)
                  _InfoRow(
                    label: 'OCID',
                    value: detail.ocid ?? widget.process.ocid!,
                  ),
                if (_text(detail.version) != null)
                  _InfoRow(label: 'Versión OCDS', value: detail.version!),
                if (detail.publishedDate != null)
                  _InfoRow(
                    label: 'Publicación del paquete',
                    value: _date(detail.publishedDate!),
                  ),
                if (detail.releaseDate != null)
                  _InfoRow(
                    label: 'Última actualización',
                    value: _date(detail.releaseDate!),
                    showDivider: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SourceCard(detail: detail),
        ],
      ),
    );
  }

  List<_MetricData> _metrics(ProcurementDetail detail) {
    return <_MetricData>[
      if (detail.budget != null)
        _MetricData(
          Icons.savings_outlined,
          'Presupuesto',
          _money(detail.budget!),
        ),
      if (detail.awardedAmount != null)
        _MetricData(
          Icons.workspace_premium_outlined,
          'Monto adjudicado',
          _money(detail.awardedAmount!),
        ),
      if (detail.contractAmount != null)
        _MetricData(
          Icons.handshake_outlined,
          'Monto contractual',
          _money(detail.contractAmount!),
        ),
      if (_text(detail.awardedSupplier) != null)
        _MetricData(
          Icons.business_center_outlined,
          'Proveedor',
          detail.awardedSupplier!,
        ),
    ];
  }

  bool _hasDates(ProcurementDetail detail) =>
      detail.tenderStartDate != null ||
      detail.tenderEndDate != null ||
      detail.awardDate != null ||
      detail.signedDate != null ||
      detail.contractStartDate != null ||
      detail.contractEndDate != null;

  bool _hasTender(ProcurementDetail detail) =>
      _text(detail.methodDetails) != null ||
      _text(detail.method) != null ||
      _text(detail.category) != null ||
      _text(detail.tenderStatus) != null ||
      detail.tenderValue != null;

  bool _hasAward(ProcurementDetail detail) =>
      _text(detail.awardedSupplier) != null ||
      detail.awardedAmount != null ||
      _text(detail.awardDescription) != null;

  bool _hasContract(ProcurementDetail detail) =>
      _text(detail.contractStatus) != null ||
      detail.contractAmount != null ||
      _text(detail.contractId) != null;

  String _money(double amount) =>
      'USD ${NumberFormat('#,##0.00', 'es_EC').format(amount)}';

  String _date(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  String? _text(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _friendly(String value) {
    return switch (value.trim().toLowerCase()) {
      'open' => 'Abierto',
      'active' => 'Activo',
      'complete' => 'Completado',
      'completed' => 'Completado',
      'cancelled' => 'Cancelado',
      'terminated' => 'Finalizado',
      'works' => 'Obras',
      'goods' => 'Bienes',
      'services' => 'Servicios',
      _ => value,
    };
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.process, required this.detail});

  final ProcurementProcess process;
  final ProcurementDetail detail;

  @override
  Widget build(BuildContext context) {
    final type = detail.methodDetails ?? process.internalType;
    final status = detail.tenderStatus ?? detail.contractStatus;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppTheme.primaryBlue, Color(0xFF65779D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (process.title != null) ...[
            Text(
              process.title!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            process.resolveDisplayTitle(
              detailedDescription: detail.description,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          if (detail.buyerName != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail.buyerName!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (type != null || status != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (type != null)
                  InfoChip(icon: Icons.category_outlined, label: type),
                if (status != null)
                  InfoChip(
                    icon: Icons.circle,
                    label: _summaryFriendly(status),
                    emphasized: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _summaryFriendly(String value) {
    return switch (value.toLowerCase()) {
      'active' => 'Activo',
      'terminated' => 'Finalizado',
      'complete' || 'completed' => 'Completado',
      _ => value,
    };
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: MetricCard(
                  icon: metric.icon,
                  label: metric.label,
                  value: metric.value,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.detail});

  final ProcurementDetail detail;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(detail.uri ?? '');
    final usable =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.hasAuthority;

    return SectionCard(
      icon: Icons.open_in_new_outlined,
      title: 'Fuente oficial',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            usable
                ? 'Abre el registro publicado por el SERCOP en tu navegador.'
                : 'Consulta este proceso en la plataforma oficial del SERCOP usando el OCID.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          if (usable) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _openSource(context, uri),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir fuente oficial'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSource(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible abrir la fuente oficial.'),
        ),
      );
    }
  }
}

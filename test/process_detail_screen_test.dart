import 'package:alcaldia_app/models/procurement_detail.dart';
import 'package:alcaldia_app/models/procurement_process.dart';
import 'package:alcaldia_app/repositories/procurement_repository.dart';
import 'package:alcaldia_app/screens/process_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('renderiza un detalle parcial y oculta secciones ausentes', (
    tester,
  ) async {
    final detail = ProcurementDetail.fromJson(<String, dynamic>{
      'releases': <Map<String, dynamic>>[
        <String, dynamic>{
          'ocid': 'ocid-parcial',
          'buyer': <String, dynamic>{
            'id': 'buyer-parcial',
            'name': 'Municipalidad de Guayaquil',
          },
        },
      ],
    });

    await _pumpDetail(tester, detail);

    expect(find.text('Información del comprador'), findsOneWidget);
    expect(find.text('Municipalidad de Guayaquil'), findsWidgets);
    expect(find.text('Adjudicación'), findsNothing);
    expect(find.text('Contrato'), findsNothing);
    expect(find.text('Fechas importantes'), findsNothing);
    expect(
      find.textContaining('Consulta este proceso en la plataforma oficial'),
      findsOneWidget,
    );
  });

  testWidgets('muestra estado insuficiente sin romperse con campos ausentes', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      const ProcurementDetail(),
      process: const ProcurementProcess(ocid: 'ocid-parcial'),
    );

    expect(
      find.text('Este proceso no contiene suficiente información detallada.'),
      findsOneWidget,
    );
    expect(find.text('Proceso sin descripción'), findsNothing);
    expect(find.text('Información del comprador'), findsNothing);
  });

  testWidgets(
    'usa tender.description cuando el resumen no tiene título ni descripción',
    (tester) async {
      const description =
          'FISCALIZACIÓN DE LA OBRA: RENOVACIÓN URBANÍSTICA DE LA ALBORADA';
      final detail = _detailWithDescription(description);
      const process = ProcurementProcess(ocid: 'ocid-descripcion');

      await _pumpDetail(tester, detail, process: process);

      expect(find.text(description), findsNWidgets(2));
      expect(find.text('Proceso sin descripción'), findsNothing);
      expect(process.title, isNull);
      expect(process.description, isNull);
      expect(process.displayTitle, 'Proceso ocid-descripcion');
    },
  );

  testWidgets('la descripción detallada prevalece sobre el título resumido', (
    tester,
  ) async {
    const detailedDescription = 'Descripción recuperada desde tender';

    await _pumpDetail(
      tester,
      _detailWithDescription(detailedDescription),
      process: const ProcurementProcess(
        ocid: 'ocid-prioridad',
        title: 'Título resumido',
      ),
    );

    final titleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .where((widget) => widget.data == detailedDescription);
    expect(titleTexts, hasLength(2));
    expect(titleTexts.first.maxLines, 5);
  });

  testWidgets('una descripción extensa no produce overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final longDescription = List<String>.filled(
      30,
      'RENOVACIÓN URBANÍSTICA INTEGRAL DE ESPACIOS PÚBLICOS',
    ).join(' ');

    await _pumpDetail(
      tester,
      _detailWithDescription(longDescription),
      process: const ProcurementProcess(ocid: 'ocid-extenso'),
    );

    final visibleTitles = tester.widgetList<Text>(find.text(longDescription));
    expect(visibleTitles.first.maxLines, 5);
    expect(tester.takeException(), isNull);
  });
}

ProcurementDetail _detailWithDescription(String description) {
  return ProcurementDetail.fromJson(<String, dynamic>{
    'releases': <Map<String, dynamic>>[
      <String, dynamic>{
        'ocid': 'ocid-descripcion',
        'tender': <String, dynamic>{'description': description},
      },
    ],
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  ProcurementDetail detail, {
  ProcurementProcess process = const ProcurementProcess(
    ocid: 'ocid-parcial',
    title: 'Proceso parcial',
  ),
}) async {
  await tester.pumpWidget(
    Provider<ProcurementRepository>.value(
      value: _DetailRepository(detail),
      child: MaterialApp(home: ProcessDetailScreen(process: process)),
    ),
  );
  await tester.pumpAndSettle();
}

class _DetailRepository implements ProcurementRepository {
  const _DetailRepository(this.detail);

  final ProcurementDetail detail;

  @override
  Future<List<ProcurementProcess>> buscarProcesos(String palabraClave) async {
    return const <ProcurementProcess>[];
  }

  @override
  Future<ProcurementDetail> obtenerDetalle(String ocid) async => detail;
}

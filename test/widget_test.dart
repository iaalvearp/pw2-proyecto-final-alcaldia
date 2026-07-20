import 'package:alcaldia_app/app/app.dart';
import 'package:alcaldia_app/repositories/local_procurement_repository.dart';
import 'package:alcaldia_app/repositories/procurement_repository.dart';
import 'package:alcaldia_app/state/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('muestra el aviso y resultados locales', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = LocalProcurementRepository(
      simulatedDelay: Duration.zero,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ProcurementRepository>.value(value: repository),
          ChangeNotifierProvider<ProcurementSearchController>(
            create: (context) => ProcurementSearchController(
              context.read<ProcurementRepository>(),
            ),
          ),
        ],
        child: const AlcaldiaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aplicación académica no oficial'), findsOneWidget);
    expect(find.text('Buscar procesos'), findsOneWidget);
    expect(find.textContaining('DATO LOCAL DE DESARROLLO'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    final detailsButton = find.text('Ver detalles').first;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(detailsButton);
    await tester.pumpAndSettle();

    expect(find.text('Detalle del proceso'), findsOneWidget);
    expect(find.text('Información del comprador'), findsOneWidget);
  });
}

import 'package:aireclaro/core/validators.dart';
import 'package:aireclaro/features/report/report_draft.dart';
import 'package:aireclaro/features/report/vehicle_step_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late ProviderContainer container;

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: VehicleStepScreen()),
    ));
  }

  ReportDraft draft() => container.read(reportDraftProvider);
  Finder plateField() => find.widgetWithText(TextFormField, 'Placa');
  bool nextEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Siguiente')).onPressed != null;

  Future<void> chooseVehicle(WidgetTester tester, String label) async {
    await tester.tap(find.text('Tipo de vehículo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('Validators.plate', () {
    test('accepts ABC123 and ABC12D, rejects other formats', () {
      expect(Validators.plate('ABC123'), isNull);
      expect(Validators.plate('abc12d'), isNull);
      expect(Validators.plate('AB123'), isNotNull);
      expect(Validators.plate('ABC1D2'), isNotNull);
      expect(Validators.plate(''), 'La placa es obligatoria.');
    });
  });

  testWidgets('plate is uppercased and limited to letters and digits', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(plateField(), 'abc-12d');
    await tester.pump();
    expect(draft().plate, 'ABC12D');
  });

  testWidgets('invalid plate shows the error and keeps «Siguiente» disabled', (tester) async {
    await pumpScreen(tester);
    await chooseVehicle(tester, 'Bus o buseta');
    await tester.tap(find.text('Negro'));
    await tester.enterText(plateField(), 'AB123');
    await tester.pump();

    expect(find.text('La placa debe tener el formato ABC123 o ABC12D.'), findsOneWidget);
    expect(nextEnabled(tester), isFalse);
  });

  testWidgets('type, valid plate and smoke color enable «Siguiente» and fill the draft',
      (tester) async {
    await pumpScreen(tester);
    expect(nextEnabled(tester), isFalse);

    await chooseVehicle(tester, 'Tractomula');
    await tester.enterText(plateField(), 'xyz789');
    await tester.tap(find.text('Gris'));
    await tester.enterText(find.widgetWithText(TextFormField, 'Descripción (opcional)'), 'Humo denso');
    await tester.pump();

    expect(nextEnabled(tester), isTrue);
    expect(draft().vehicleType, 'tractomula');
    expect(draft().plate, 'XYZ789');
    expect(draft().smokeColor, 'gris');
    expect(draft().description, 'Humo denso');
  });

  testWidgets('description has a 500-character counter', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción (opcional)'), 'a' * 520);
    await tester.pump();

    expect(draft().description.length, 500);
    expect(find.text('500/500'), findsOneWidget);
  });

  testWidgets('the screen starts with the values already in the draft', (tester) async {
    await pumpScreen(tester);
    container.read(reportDraftProvider.notifier).updateVehicle(plate: 'DEF456');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: VehicleStepScreen()),
    ));
    expect(find.text('DEF456'), findsOneWidget);
  });
}

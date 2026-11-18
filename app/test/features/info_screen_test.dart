import 'package:aireclaro/features/info/info_screen.dart';
import 'package:aireclaro/features/report/authorities_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

class _Authorities implements AuthoritiesRepository {
  bool fail = false;

  @override
  Future<List<Authority>> list() async {
    if (fail) throw networkError;
    return const [
      Authority(
        id: 1,
        code: 'CAR',
        name: 'Corporación Autónoma Regional de Cundinamarca (CAR)',
        portalUrl: 'https://sidcar.car.gov.co',
        canEmail: true,
      ),
      Authority(
        id: 3,
        code: 'SDM',
        name: 'Secretaría Distrital de Movilidad de Bogotá',
        portalUrl: 'https://www.movilidadbogota.gov.co',
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Authorities authorities;

  Future<void> pumpInfo(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [authoritiesRepositoryProvider.overrideWithValue(authorities)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: InfoScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => authorities = _Authorities());

  testWidgets('shows the 4 steps of docs/06', (tester) async {
    await pumpInfo(tester);
    for (final step in [
      '1. Captura la evidencia',
      '2. Completa los datos',
      '3. Genera la solicitud',
      '4. Preséntala a la autoridad',
    ]) {
      expect(find.text(step), findsOneWidget);
    }
  });

  testWidgets('lists the authorities and how each one receives the request', (
    tester,
  ) async {
    await pumpInfo(tester);
    expect(
      find.text('Corporación Autónoma Regional de Cundinamarca (CAR)'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Recibe la solicitud por correo desde la app o en su portal oficial.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Secretaría Distrital de Movilidad de Bogotá'),
      findsOneWidget,
    );
    expect(find.text('Se radica en su portal oficial.'), findsOneWidget);
  });

  testWidgets('scope notice (RNF-08) and the data policy', (tester) async {
    await pumpInfo(tester);
    expect(
      find.textContaining('AireClaro no mide emisiones ni impone sanciones'),
      findsOneWidget,
    );

    await tester.tap(find.text('Política de tratamiento de datos'));
    await tester.pumpAndSettle();
    expect(find.text('Tratamiento de datos personales'), findsOneWidget);
  });

  testWidgets('authorities error: «Reintentar» loads them again', (
    tester,
  ) async {
    authorities.fail = true;
    await pumpInfo(tester);
    expect(find.textContaining('No pudimos conectar'), findsOneWidget);
    // The rest of the screen still works without the API.
    expect(find.text('1. Captura la evidencia'), findsOneWidget);

    authorities.fail = false;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Secretaría Distrital de Movilidad de Bogotá'),
      findsOneWidget,
    );
  });
}

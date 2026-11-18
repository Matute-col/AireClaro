import 'package:aireclaro/app.dart';
import 'package:aireclaro/core/token_storage.dart';
import 'package:aireclaro/features/auth/auth_repository.dart';
import 'package:aireclaro/features/map/map_reports.dart';
import 'package:aireclaro/features/report/reports_repository.dart';
import 'package:aireclaro/shared/widgets/auth_image.dart';
import 'package:aireclaro/shared/widgets/osm_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fakes.dart';

/// Runs the whole app (router included) with fake API and storage.
Future<void> pumpApp(WidgetTester tester, {String? savedToken}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      tokenStorageProvider.overrideWithValue(MemoryTokenStorage(savedToken)),
      reportsRepositoryProvider.overrideWithValue(FakeReportsListRepository(total: 3)),
      authTokenProvider.overrideWith((ref) async => null),
      mapReportsProvider.overrideWith((ref) async => const <MapReport>[]),
      mapTilesEnabledProvider.overrideWithValue(false),
    ],
    child: const AireClaroApp(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('without a session the app opens on Bienvenida', (tester) async {
    await pumpApp(tester);

    expect(find.text('AireClaro'), findsOneWidget);
    expect(find.text('Reporta vehículos contaminantes en el corredor Soacha–Bogotá'),
        findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Crear cuenta'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('with a saved session the app opens on Inicio with the bottom bar',
      (tester) async {
    await pumpApp(tester, savedToken: 'saved');

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Nuevo reporte'), findsOneWidget);
    expect(find.text('3 reportes'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom bar and shortcut cards switch tabs', (tester) async {
    await pumpApp(tester, savedToken: 'saved');

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Mapa'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mapa de reportes'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Inicio'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¿Cómo funciona?'));
    await tester.pumpAndSettle();
    expect(find.text('Muy pronto'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('profile opens without the bottom bar and logout goes to Bienvenida',
      (tester) async {
    await pumpApp(tester, savedToken: 'saved');

    await tester.tap(find.byTooltip('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });
}

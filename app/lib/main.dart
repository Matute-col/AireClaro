import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/config.dart';

Future<void> main() async {
  if (!AppConfig.hasApiBaseUrl) {
    // Without the API URL nothing works: say it clearly instead of failing later.
    runApp(const _MissingConfigApp());
    return;
  }
  // Spanish (Colombia) month and day names for dates.
  await initializeDateFormatting('es_CO');
  runApp(const ProviderScope(child: AireClaroApp()));
}

class _MissingConfigApp extends StatelessWidget {
  const _MissingConfigApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Falta la URL del API.\n\nEjecuta la app con:\n'
              'flutter run --dart-define=API_BASE_URL=http://localhost:3000/api',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

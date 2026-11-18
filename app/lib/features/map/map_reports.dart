import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';
import '../auth/auth_controller.dart';

/// One pin of the reports map (GET /map/reports). Only what RB-07 allows:
/// position, vehicle type and date. No plate, photos, address or people.
class MapReport {
  const MapReport({
    required this.id,
    required this.lat,
    required this.lng,
    required this.vehicleType,
    required this.occurredAt,
  });

  final String id;
  final double lat;
  final double lng;
  final String vehicleType;
  final DateTime occurredAt;

  factory MapReport.fromJson(Map<String, dynamic> json) => MapReport(
        id: json['id'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        vehicleType: json['vehicle_type'] as String,
        occurredAt: DateTime.parse(json['occurred_at'] as String).toLocal(),
      );
}

/// Date filter of the map, as simple choices for a phone.
enum MapPeriod {
  all('Todo', null),
  today('Hoy', 0),
  week('7 días', 6),
  month('30 días', 29);

  const MapPeriod(this.label, this.daysBack);

  final String label;

  /// Days before today included (null = no date filter).
  final int? daysBack;
}

class MapFilters {
  const MapFilters({this.vehicleTypes = const {}, this.period = MapPeriod.all});

  /// Empty = every type.
  final Set<String> vehicleTypes;
  final MapPeriod period;

  bool get isDefault => vehicleTypes.isEmpty && period == MapPeriod.all;

  /// Query of GET /map/reports. Dates are calendar days of the phone (Colombia).
  Map<String, String> toQuery(DateTime today) {
    final query = <String, String>{};
    if (vehicleTypes.isNotEmpty) query['vehicle_type'] = (vehicleTypes.toList()..sort()).join(',');
    final days = period.daysBack;
    if (days != null) {
      final format = DateFormat('yyyy-MM-dd');
      query['from'] = format.format(today.subtract(Duration(days: days)));
      query['to'] = format.format(today);
    }
    return query;
  }
}

class MapFiltersController extends Notifier<MapFilters> {
  @override
  MapFilters build() => const MapFilters();

  void toggleType(String type) {
    final types = {...state.vehicleTypes};
    if (!types.remove(type)) types.add(type);
    state = MapFilters(vehicleTypes: types, period: state.period);
  }

  void setPeriod(MapPeriod period) {
    state = MapFilters(vehicleTypes: state.vehicleTypes, period: period);
  }

  void clear() => state = const MapFilters();
}

final mapFiltersProvider = NotifierProvider<MapFiltersController, MapFilters>(MapFiltersController.new);

class MapRepository {
  MapRepository(this._dio);

  final Dio _dio;

  Future<List<MapReport>> list(MapFilters filters) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/map/reports',
        queryParameters: filters.toQuery(DateTime.now()),
      );
      return response.data!.map((e) => MapReport.fromJson(e as Map<String, dynamic>)).toList();
    } catch (error) {
      throw toApiException(error);
    }
  }
}

final mapRepositoryProvider = Provider<MapRepository>(
  (ref) => MapRepository(ref.watch(apiClientProvider)),
);

/// Pins for the current filters; reloads when the filters or the user change.
final mapReportsProvider = FutureProvider<List<MapReport>>((ref) {
  ref.watch(authControllerProvider.select((s) => s.user?.id));
  return ref.watch(mapRepositoryProvider).list(ref.watch(mapFiltersProvider));
});

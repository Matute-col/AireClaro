import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_error.dart';
import '../auth/auth_controller.dart';
import '../report/reports_repository.dart';
import 'report_summary.dart';

/// State of «Mis reportes»: the pages loaded so far.
class ReportsListState {
  const ReportsListState({
    this.items = const [],
    this.total = 0,
    this.page = 0,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.loadMoreError,
  });

  final List<ReportSummary> items;
  final int total;
  final int page;

  /// First page loading.
  final bool loading;
  final bool loadingMore;

  /// The first page failed: the whole screen shows «Reintentar».
  final String? error;

  /// A later page failed: only the bottom of the list shows «Reintentar».
  final String? loadMoreError;

  bool get hasMore => items.length < total;
  bool get isEmpty => !loading && error == null && items.isEmpty;
}

class ReportsListController extends Notifier<ReportsListState> {
  static const pageSize = 20;

  @override
  ReportsListState build() {
    // Start again if another user signs in.
    ref.watch(authControllerProvider.select((s) => s.user?.id));
    Future.microtask(refresh);
    return const ReportsListState(loading: true);
  }

  ReportsRepository get _repository => ref.read(reportsRepositoryProvider);

  /// Loads the first page (also used by pull-to-refresh and «Reintentar»).
  Future<void> refresh() async {
    state = ReportsListState(items: state.items, total: state.total, page: state.page, loading: true);
    try {
      final first = await _repository.list(page: 1, limit: pageSize);
      state = ReportsListState(items: first.items, total: first.total, page: 1);
    } on ApiException catch (error) {
      state = ReportsListState(error: error.message);
    }
  }

  /// Next page, when the user scrolls near the end.
  Future<void> loadMore() async {
    final current = state;
    if (current.loading || current.loadingMore || !current.hasMore) return;
    state = ReportsListState(
      items: current.items,
      total: current.total,
      page: current.page,
      loadingMore: true,
    );
    try {
      final next = await _repository.list(page: current.page + 1, limit: pageSize);
      state = ReportsListState(
        items: [...current.items, ...next.items],
        total: next.total,
        page: next.page,
      );
    } on ApiException catch (error) {
      state = ReportsListState(
        items: current.items,
        total: current.total,
        page: current.page,
        loadMoreError: error.message,
      );
    }
  }
}

final reportsListProvider =
    NotifierProvider<ReportsListController, ReportsListState>(ReportsListController.new);

/// Number of reports for the «Mis reportes» card on Inicio.
final reportsCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authControllerProvider.select((s) => s.user?.id));
  final page = await ref.watch(reportsRepositoryProvider).list(page: 1, limit: 1);
  return page.total;
});

import '../models/procurement_process.dart';

enum SearchStatus { initial, loading, results, empty, error }

class SearchState {
  const SearchState._({
    required this.status,
    this.results = const <ProcurementProcess>[],
    this.errorMessage,
  });

  const SearchState.initial() : this._(status: SearchStatus.initial);
  const SearchState.loading() : this._(status: SearchStatus.loading);
  const SearchState.results(List<ProcurementProcess> results)
    : this._(status: SearchStatus.results, results: results);
  const SearchState.empty() : this._(status: SearchStatus.empty);
  const SearchState.error(String message)
    : this._(status: SearchStatus.error, errorMessage: message);

  final SearchStatus status;
  final List<ProcurementProcess> results;
  final String? errorMessage;
}

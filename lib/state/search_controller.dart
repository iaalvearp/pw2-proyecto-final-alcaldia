import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../models/procurement_process.dart';
import '../repositories/procurement_repository.dart';
import 'search_state.dart';

class ProcurementSearchController extends ChangeNotifier {
  ProcurementSearchController(this._repository);

  final ProcurementRepository _repository;
  SearchState _state = const SearchState.initial();
  String? _validationMessage;
  String? _activeQuery;
  String? _lastCompletedQuery;
  int _requestId = 0;

  SearchState get state => _state;
  List<ProcurementProcess> get results => _state.results;
  String? get errorMessage => _state.errorMessage;
  String? get validationMessage => _validationMessage;

  Future<void> buscar(String palabraClave) async {
    final query = palabraClave.trim();
    if (query.length < 3) {
      _requestId++;
      _activeQuery = null;
      _validationMessage = 'Escribe al menos tres caracteres.';
      _state = const SearchState.initial();
      notifyListeners();
      return;
    }

    final queryKey = query.toLowerCase();
    if (_activeQuery == queryKey ||
        (_lastCompletedQuery == queryKey &&
            (_state.status == SearchStatus.results ||
                _state.status == SearchStatus.empty))) {
      return;
    }

    _validationMessage = null;
    _activeQuery = queryKey;
    final currentRequest = ++_requestId;
    _state = const SearchState.loading();
    notifyListeners();

    try {
      final found = await _repository.buscarProcesos(query);
      if (currentRequest != _requestId) return;
      _state = found.isEmpty
          ? const SearchState.empty()
          : SearchState.results(found);
      _lastCompletedQuery = queryKey;
    } on AppException catch (error) {
      if (currentRequest != _requestId) return;
      _state = SearchState.error(error.userMessage);
    } catch (_) {
      if (currentRequest != _requestId) return;
      _state = const SearchState.error(
        'Ocurrió un problema inesperado. Inténtalo nuevamente.',
      );
    } finally {
      if (currentRequest == _requestId) {
        _activeQuery = null;
        notifyListeners();
      }
    }
  }
}

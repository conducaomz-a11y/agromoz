/// Shared UI state machine used by every ViewModel.
enum ViewStatus { initial, loading, loadingMore, success, empty, error }

extension ViewStatusX on ViewStatus {
  bool get isLoading => this == ViewStatus.loading;
  bool get isLoadingMore => this == ViewStatus.loadingMore;
  bool get isError => this == ViewStatus.error;
  bool get isEmpty => this == ViewStatus.empty;
  bool get isSuccess => this == ViewStatus.success;
}

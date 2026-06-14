class ResultState<T> {
  const ResultState._({
    this.data,
    this.error,
    this.isLoading = false,
  });

  const ResultState.idle() : this._();

  const ResultState.loading([T? data]) : this._(data: data, isLoading: true);

  const ResultState.success(T data) : this._(data: data);

  const ResultState.failure(String error, [T? data])
      : this._(data: data, error: error);

  final T? data;
  final String? error;
  final bool isLoading;

  bool get hasData => data != null;
}

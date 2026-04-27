import 'dart:async';

typedef FlushCallback = Future<void> Function();

final class FlushScheduler {
  Future<void>? _activeDrain;
  Completer<void>? _pendingCompleter;
  bool _flushRequested = false;

  Future<void> schedule(FlushCallback flush) {
    _flushRequested = true;
    final completer = _pendingCompleter ??= Completer<void>();

    _activeDrain ??= Future<void>.microtask(() => _drain(flush)).whenComplete(
      () => _activeDrain = null,
    );

    return completer.future;
  }

  Future<void> _drain(FlushCallback flush) async {
    while (_flushRequested) {
      _flushRequested = false;

      final completer = _pendingCompleter;
      _pendingCompleter = null;
      if (completer == null) {
        continue;
      }

      try {
        await flush();
        if (!completer.isCompleted) {
          completer.complete();
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      }
    }
  }
}

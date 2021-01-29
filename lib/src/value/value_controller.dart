import 'dart:async';

import 'package:rxdart/rxdart.dart' show ErrorAndStackTrace, ValueWrapper;

import 'not_replay_value_stream.dart';
import 'stream_event.dart';

/// TODO
class ValueStreamController<T> implements StreamController<T> {
  final StreamController<T> _delegate;
  final StreamEvent<T> _dataOrError;

  ValueStreamController._(this._delegate, this._dataOrError);

  /// TODO
  factory ValueStreamController(
    T seedValue, {
    void Function()? onListen,
    void Function()? onPause,
    void Function()? onResume,
    FutureOr<void> Function()? onCancel,
    bool sync = false,
  }) {
    final controller = StreamController<T>(
      onListen: onListen,
      onPause: onPause,
      onResume: onResume,
      onCancel: onCancel,
      sync: sync,
    );
    return ValueStreamController._(
      controller,
      StreamEvent.data(seedValue),
    );
  }

  @override
  FutureOr<void> Function()? get onCancel => _delegate.onCancel;

  @override
  set onCancel(FutureOr<void> Function()? onCancelHandler) =>
      _delegate.onCancel = onCancelHandler;

  @override
  void Function()? get onListen => _delegate.onListen;

  @override
  set onListen(void Function()? onListenHandler) =>
      _delegate.onListen = onListenHandler;

  @override
  void Function()? get onPause => _delegate.onPause;

  @override
  set onPause(void Function()? onPauseHandler) =>
      _delegate.onPause = onPauseHandler;

  @override
  void Function()? get onResume => _delegate.onResume;

  @override
  set onResume(void Function()? onResumeHandler) =>
      _delegate.onResume = onResumeHandler;

  @override
  void add(T event) {
    _dataOrError.onData(event);
    _delegate.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _dataOrError.onError(ErrorAndStackTrace(error, stackTrace));
    _delegate.addError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<T> source, {bool? cancelOnError}) =>
      _delegate.addStream(source, cancelOnError: cancelOnError);

  @override
  Future<void> close() => _delegate.close();

  @override
  Future<void> get done => _delegate.done;

  @override
  bool get hasListener => _delegate.hasListener;

  @override
  bool get isClosed => _delegate.isClosed;

  @override
  bool get isPaused => _delegate.isPaused;

  @override
  StreamSink<T> get sink => _delegate.sink;

  @override
  NotReplayValueStream<T> get stream => _ValueStreamControllerStream(this);
}

class _ValueStreamControllerStream<T> extends Stream<T>
    implements NotReplayValueStream<T> {
  final ValueStreamController<T> controller;

  _ValueStreamControllerStream(this.controller);

  @override
  bool get isBroadcast => false;

  @override
  ErrorAndStackTrace? get errorAndStackTrace =>
      controller._dataOrError.errorAndStacktrace;

  @override
  ValueWrapper<T>? get valueWrapper => controller._dataOrError.value;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      controller._delegate.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
}

/// TODO
extension ToNotReplayValueStreamExtension<T> on Stream<T> {
  /// TODO
  NotReplayValueStream<T> toNotReplayValueStream(T value) {
    final controller = ValueStreamController(value, sync: true);
    late StreamSubscription<T> subscription;

    controller.onListen = () {
      subscription = listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );

      if (!isBroadcast) {
        controller.onPause = subscription.pause;
        controller.onResume = subscription.resume;
      }
    };
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }
}

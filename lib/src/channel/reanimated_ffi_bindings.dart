/// FFI bindings to reanimated_dartnative's native side.
///
/// iOS: `@_cdecl` functions in `ios/Classes/ReanimatedDartNative.swift`,
/// resolved from the app binary. Android: exported C functions in
/// `android/src/main/cpp/reanimated_dartnative.cpp`
/// (libreanimated_dartnative.so), which call `ReanimatedDartNativeBridge.kt`
/// over JNI.
///
/// Sensor readings and reduce-motion changes arrive through one dispatcher
/// pointer, on the main thread, with no platform channels.
library;

import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:math' show Random;

import 'package:ffi/ffi.dart';

import '../device/reduced_motion.dart';

typedef _SetDispatcherC = Void Function(Int64);
typedef _SetDispatcherD = void Function(int);
typedef _CallC = Int32 Function(Int64, Pointer<Utf8>, Pointer<Utf8>);
typedef _CallD = int Function(int, Pointer<Utf8>, Pointer<Utf8>);
typedef _CancelC = Int32 Function(Int64);
typedef _CancelD = int Function(int);
typedef _DispatchC = Void Function(Int64, Int32, Pointer<Utf8>);

/// Handler for events delivered to a token.
typedef ReanimatedEventHandler = void Function(int type, String payload);

/// Event types delivered from native.
abstract final class ReanimatedEventType {
  static const int success = 0;
  static const int error = 1;
}

/// Return codes of [ReanimatedFFIBindings.listen].
abstract final class ReanimatedResult {
  static const int ok = 0;
  static const int unknownChannel = -1;
  static const int unavailable = -2;
  static const int notLoaded = -10;
}

abstract final class ReanimatedFFIBindings {
  static bool _loaded = false;

  /// Whether the native library is loaded (false in unit tests).
  static bool get isLoaded => _loaded;

  static _CallD? _invoke;
  static _CallD? _listen;
  static _CancelD? _cancel;

  /// Loads the native symbols and starts following the reduce-motion
  /// setting. DartNative's plugin registrant calls this at startup; calling
  /// it again does nothing.
  static void loadSymbols() {
    if (_loaded) return;
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      final lib = Platform.isAndroid
          ? DynamicLibrary.open('libreanimated_dartnative.so')
          : DynamicLibrary.process();
      final setDispatcher = lib.lookupFunction<_SetDispatcherC, _SetDispatcherD>(
          'ReanimatedSetDispatcher');
      _invoke = lib.lookupFunction<_CallC, _CallD>('ReanimatedInvoke');
      _listen = lib.lookupFunction<_CallC, _CallD>('ReanimatedListen');
      _cancel = lib.lookupFunction<_CancelC, _CancelD>('ReanimatedCancel');
      setDispatcher(_dispatchPtr.address);
      _loaded = true;
    } catch (_) {
      return; // no native side (pure Dart, tests)
    }
    _followReducedMotion();
  }

  static void _followReducedMotion() {
    final token = registerHandler((type, payload) {
      if (type == ReanimatedEventType.success) {
        ReducedMotion.debugSetEnabled(payload.trim() == '1');
      }
    });
    listen(token, 'reducedMotion', '');
  }

  static final Map<int, ReanimatedEventHandler> _handlers = {};
  static int _nextToken = (Random().nextInt(1 << 20) + 1) << 20;

  static void _dispatch(int token, int type, Pointer<Utf8> payload) {
    final handler = _handlers[token];
    if (handler == null) return;
    handler(type, payload == nullptr ? '' : payload.toDartString());
  }

  static final Pointer<NativeFunction<_DispatchC>> _dispatchPtr =
      Pointer.fromFunction<_DispatchC>(_dispatch);

  static int registerHandler(ReanimatedEventHandler handler) {
    final token = _nextToken++;
    _handlers[token] = handler;
    return token;
  }

  static void removeHandler(int token) => _handlers.remove(token);

  /// Calls a native method; the reply arrives at [token]'s handler.
  static int invoke(int token, String method, String args) =>
      _call(_invoke, token, method, args);

  /// Starts a native stream. Returns a [ReanimatedResult] code.
  static int listen(int token, String channel, String args) =>
      _call(_listen, token, channel, args);

  /// Stops a native stream.
  static int cancel(int token) => _cancel?.call(token) ?? ReanimatedResult.notLoaded;

  static int _call(_CallD? fn, int token, String a, String b) {
    if (fn == null) return ReanimatedResult.notLoaded;
    final pa = a.toNativeUtf8(), pb = b.toNativeUtf8();
    try {
      return fn(token, pa, pb);
    } finally {
      calloc.free(pa);
      calloc.free(pb);
    }
  }
}

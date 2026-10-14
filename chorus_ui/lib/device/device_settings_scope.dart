/// Hands this device's settings to the child's board, wherever it opens.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../contracts_device.dart';

/// When the last word on the child's board spoke, for "Ignore repeat
/// taps": one clock for the whole board, so a second word straight after
/// the first is ignored too.
class TouchClock {
  Timer? _quiet;

  /// Whether a word may speak now; if so, words are ignored for [guard]
  /// from now.
  bool allow(Duration guard) {
    if (_quiet?.isActive ?? false) return false;
    _quiet = guard > Duration.zero ? Timer(guard, () {}) : null;
    return true;
  }
}

/// Puts [store] above [child], so the child's board and "This device" read
/// the same settings. Without one, every screen works as it always has.
class DeviceSettingsScope extends StatefulWidget {
  const DeviceSettingsScope({
    super.key,
    required this.store,
    required this.child,
  });

  final DeviceSettingsStore store;
  final Widget child;

  /// The store, or null where there is no scope.
  static DeviceSettingsStore? storeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_DeviceSettingsInherited>()
      ?.notifier;

  /// The settings now, rebuilding [context] when they change; the defaults
  /// where there is no scope.
  static DeviceSettings of(BuildContext context) =>
      storeOf(context)?.settings ?? const DeviceSettings();

  /// The board's one clock for "Ignore repeat taps"; null without a scope.
  static TouchClock? clockOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_DeviceSettingsInherited>()?.clock;

  @override
  State<DeviceSettingsScope> createState() => _DeviceSettingsScopeState();
}

class _DeviceSettingsScopeState extends State<DeviceSettingsScope> {
  final TouchClock _clock = TouchClock();

  @override
  Widget build(BuildContext context) => _DeviceSettingsInherited(
    notifier: widget.store,
    clock: _clock,
    child: widget.child,
  );
}

class _DeviceSettingsInherited extends InheritedNotifier<DeviceSettingsStore> {
  const _DeviceSettingsInherited({
    required super.notifier,
    required this.clock,
    required super.child,
  });

  final TouchClock clock;
}

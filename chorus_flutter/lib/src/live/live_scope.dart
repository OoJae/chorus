/// Widgets that give a screen its live session and a guardian the sharing
/// switch.
library;

import 'package:chorus_ui/contracts_live.dart';
import 'package:flutter/material.dart';

import 'chorus_live_session.dart';
import 'live_settings.dart';

/// Owns a [ChorusLiveSession] for as long as a screen is open: makes it,
/// starts it and disposes it, so the stream is closed when the screen is.
class LiveScope extends StatefulWidget {
  const LiveScope({super.key, required this.create, required this.builder});

  /// Makes the session. Called once.
  final ChorusLiveSession Function() create;
  final Widget Function(BuildContext context, LiveSession live) builder;

  @override
  State<LiveScope> createState() => _LiveScopeState();
}

class _LiveScopeState extends State<LiveScope> {
  late final ChorusLiveSession _live = widget.create()..start();

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _live);
}

/// The guardian's switch for sharing what is said from this device.
///
/// Off until a guardian turns it on. It takes effect the next time the
/// talker is opened, which reads the same saved value.
class ShareSaidSwitch extends StatefulWidget {
  const ShareSaidSwitch({
    super.key,
    required this.userId,
    required this.circleId,
    required this.childName,
  });

  final String userId;
  final String circleId;
  final String childName;

  @override
  State<ShareSaidSwitch> createState() => _ShareSaidSwitchState();
}

class _ShareSaidSwitchState extends State<ShareSaidSwitch> {
  bool _on = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ShareSaidSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.circleId != widget.circleId) {
      _on = false;
      _loaded = false;
      _load();
    }
  }

  Future<void> _load() async {
    final userId = widget.userId, circleId = widget.circleId;
    final on = await readShareSaid(userId, circleId);
    if (!mounted || userId != widget.userId || circleId != widget.circleId) {
      return;
    }
    setState(() {
      _on = on;
      _loaded = true;
    });
  }

  Future<void> _set(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final before = _on;
    setState(() => _on = value);
    try {
      await writeShareSaid(widget.userId, widget.circleId, value);
    } catch (_) {
      if (!mounted) return;
      setState(() => _on = before);
      messenger.showSnackBar(
        const SnackBar(content: Text('That could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _on,
      onChanged: _loaded ? _set : null,
      secondary: const Icon(Icons.podcasts),
      title: const Text('Share what is said'),
      subtitle: Text(
        'While the talker is open on this device, each sentence '
        '${widget.childName} speaks is shown to the adults in the circle who '
        'are connected at that moment. Nothing is saved. The board shows a '
        'bar while this is on, and a tap on it turns it off.',
      ),
    );
  }
}

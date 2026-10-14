/// "This device": the adult's settings for how the child's board works on
/// this device, and the circle's voice.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../brand/tokens.dart';
import '../contracts_device.dart';
import '../contracts_voice.dart';
import '../features/flags/w3.dart';
import 'keyguard_template_screen.dart';

/// The page's title, and home's entry to it.
const String deviceSettingsTitle = 'This device';

/// One line under home's entry.
const String deviceSettingsDetail = 'Touch, switches, voice and keyguard';

const String touchHeading = 'Touch';
const String switchAccessHeading = 'Switch access';
const String voiceHeading = 'Voice';
const String keyguardHeading = 'Keyguard';

const String holdTimeLabel = 'Hold time';
const String holdTimeHelp = 'A word speaks only after it is held this long.';
const String repeatGuardLabel = 'Ignore repeat taps';
const String repeatGuardHelp =
    'After a word speaks, touches are ignored for this long.';
const String selectOnReleaseLabel = 'Select on release';
const String selectOnReleaseHelp =
    'A word speaks when the finger lifts. Off: as soon as it is touched '
    '(or held for the hold time).';

const String scanModeLabel = 'Scanning';
const String scanModeHelp =
    'Switches send space and enter. One switch: the highlight moves by '
    'itself, a row then a word, and the switch chooses. Two switches: space '
    'moves, enter chooses.';
const String scanOffLabel = 'Off';
const String scanOneLabel = 'One switch';
const String scanTwoLabel = 'Two switches';
const String scanSpeedLabel = 'Speed';
const String scanPreviewLabel = 'Say each word quietly';

const String voiceLabel = 'Which voice';
const String deviceVoiceLabel = "This device's voice";
const String voiceSpeedLabel = 'Speed';
const String voicePitchLabel = 'Pitch';
const String tryVoiceLabel = 'Try it';

/// What "Try it" says.
const String tryVoiceSentence = 'I want juice';
const String voiceSharedHelp =
    'The same voice, speed and pitch on every device in the circle. A '
    'device without this voice uses its own.';
const String voiceReadOnlyHelp =
    'An adult who edits the board can change the voice.';
const String voiceNotSavedMessage =
    'That change could not be saved. Try again in a moment.';

const String keyguardModeLabel = 'Keyguard mode';
const String keyguardModeHelp =
    'The board keeps one fixed size and place, and nothing ever appears '
    'above it, so a plastic keyguard lines up with every word.';
const String keyguardTemplateLabel = 'Keyguard template';

/// "Off" or the time in seconds, as "0.3 s".
String durationLabel(Duration value) {
  if (value == Duration.zero) return 'Off';
  final seconds = value.inMilliseconds / 1000;
  final text = seconds == seconds.roundToDouble()
      ? seconds.toStringAsFixed(0)
      : seconds.toString();
  return '$text s';
}

/// The scan speeds by name, slowest first.
const List<String> scanSpeedNames = ['Slow', 'Steady', 'Quick'];

/// The voice speeds by name (see [VoicePrefs.rates]).
const List<String> voiceSpeedNames = ['Slow', 'Steady', 'Normal', 'Quick'];

/// The pitches by name (see [VoicePrefs.pitches]).
const List<String> voicePitchNames = ['Lower', 'Natural', 'Higher'];

/// The settings page. Each section shows only when its feature is on.
///
/// [store] holds this device's settings; [voice] is the circle's voice,
/// null where there is no circle (the voice section then says nothing).
/// [boardRows] and [boardCols] size the keyguard template.
class DeviceSettingsScreen extends StatelessWidget {
  const DeviceSettingsScreen({
    super.key,
    required this.store,
    this.voice,
    this.boardRows,
    this.boardCols,
  });

  final DeviceSettingsStore store;
  final VoiceChoice? voice;
  final int? boardRows;
  final int? boardCols;

  @override
  Widget build(BuildContext context) {
    final voice = this.voice;
    return Scaffold(
      appBar: AppBar(title: const Text(deviceSettingsTitle)),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final settings = store.settings;
            void save(DeviceSettings next) => unawaited(store.save(next));
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (touchSettingsEnabled) ..._touch(context, settings, save),
                if (switchAccessEnabled) ..._switches(context, settings, save),
                if (voiceChoiceEnabled && voice != null) ...[
                  const _Heading(voiceHeading),
                  VoiceSection(voice: voice),
                ],
                if (keyguardEnabled) ..._keyguard(context, settings, save),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _touch(
    BuildContext context,
    DeviceSettings settings,
    void Function(DeviceSettings) save,
  ) => [
    const _Heading(touchHeading),
    _Choice<Duration>(
      label: holdTimeLabel,
      help: holdTimeHelp,
      values: DeviceSettings.holdTimes,
      names: [
        for (final value in DeviceSettings.holdTimes) durationLabel(value),
      ],
      selected: settings.holdTime,
      onChanged: (value) => save(settings.copyWith(holdTime: value)),
    ),
    _Choice<Duration>(
      label: repeatGuardLabel,
      help: repeatGuardHelp,
      values: DeviceSettings.repeatGuards,
      names: [
        for (final value in DeviceSettings.repeatGuards) durationLabel(value),
      ],
      selected: settings.repeatGuard,
      onChanged: (value) => save(settings.copyWith(repeatGuard: value)),
    ),
    SwitchListTile(
      title: const Text(selectOnReleaseLabel),
      subtitle: const Text(selectOnReleaseHelp),
      value: settings.selectOnRelease,
      onChanged: (value) => save(settings.copyWith(selectOnRelease: value)),
    ),
  ];

  List<Widget> _switches(
    BuildContext context,
    DeviceSettings settings,
    void Function(DeviceSettings) save,
  ) => [
    const _Heading(switchAccessHeading),
    _Choice<ScanMode>(
      label: scanModeLabel,
      help: scanModeHelp,
      values: ScanMode.values,
      names: const [scanOffLabel, scanOneLabel, scanTwoLabel],
      selected: settings.scanMode,
      onChanged: (value) => save(settings.copyWith(scanMode: value)),
    ),
    if (settings.scanMode == ScanMode.oneSwitch)
      _Choice<Duration>(
        label: scanSpeedLabel,
        values: DeviceSettings.scanSteps,
        names: scanSpeedNames,
        selected: settings.scanStep,
        onChanged: (value) => save(settings.copyWith(scanStep: value)),
      ),
    if (settings.scanMode != ScanMode.off)
      SwitchListTile(
        title: const Text(scanPreviewLabel),
        value: settings.scanPreview,
        onChanged: (value) => save(settings.copyWith(scanPreview: value)),
      ),
  ];

  List<Widget> _keyguard(
    BuildContext context,
    DeviceSettings settings,
    void Function(DeviceSettings) save,
  ) {
    final rows = boardRows;
    final cols = boardCols;
    return [
      const _Heading(keyguardHeading),
      SwitchListTile(
        title: const Text(keyguardModeLabel),
        subtitle: const Text(keyguardModeHelp),
        value: settings.keyguard,
        onChanged: (value) => save(settings.copyWith(keyguard: value)),
      ),
      if (rows != null && cols != null && rows > 0 && cols > 0)
        ListTile(
          leading: const Icon(Icons.grid_on_rounded),
          title: const Text(keyguardTemplateLabel),
          trailing: const Icon(Icons.chevron_right_rounded),
          minTileHeight: 56,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => KeyguardTemplateScreen(rows: rows, cols: cols),
            ),
          ),
        ),
    ];
  }
}

/// A section head in the headline face.
class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: ChorusType.headline.copyWith(
          color: ChorusColors.of(context).ink,
        ),
      ),
    ),
  );
}

/// A row of choices with its label and a line of help.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.values,
    required this.names,
    required this.selected,
    required this.onChanged,
    this.help,
  });

  final String label;
  final String? help;
  final List<T> values;
  final List<String> names;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final help = this.help;
    final onChanged = this.onChanged;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ChorusType.label.copyWith(color: colors.ink)),
          if (help != null) ...[
            const SizedBox(height: 2),
            Text(help, style: ChorusType.body.copyWith(color: colors.inkMuted)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: ChorusSpace.targetGap,
            runSpacing: ChorusSpace.targetGap,
            children: [
              for (var i = 0; i < values.length; i++)
                ChoiceChip(
                  label: Text(names[i]),
                  selected: values[i] == selected,
                  onSelected: onChanged == null
                      ? null
                      : (_) => onChanged(values[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The circle's voice: which voice, its speed and pitch, and "Try it".
class VoiceSection extends StatefulWidget {
  const VoiceSection({super.key, required this.voice});

  final VoiceChoice voice;

  @override
  State<VoiceSection> createState() => _VoiceSectionState();
}

class _VoiceSectionState extends State<VoiceSection> {
  late Future<List<String>> _names = widget.voice.voiceNames();
  String? _problem;

  @override
  void didUpdateWidget(VoiceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voice != widget.voice) _names = widget.voice.voiceNames();
  }

  Future<void> _choose(VoicePrefs prefs) async {
    setState(() => _problem = null);
    try {
      await widget.voice.choose(prefs);
    } catch (_) {
      if (mounted) setState(() => _problem = voiceNotSavedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final voice = widget.voice;
    return ListenableBuilder(
      listenable: voice,
      builder: (context, _) {
        final prefs = voice.prefs;
        final canChange = voice.canChange;
        final problem = _problem;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                canChange ? voiceSharedHelp : voiceReadOnlyHelp,
                style: ChorusType.body.copyWith(color: colors.inkMuted),
              ),
            ),
            FutureBuilder<List<String>>(
              future: _names,
              builder: (context, snapshot) {
                final names = snapshot.data ?? const <String>[];
                final chosen = prefs.voiceName;
                final options = [
                  null,
                  ...names,
                  if (chosen != null && !names.contains(chosen)) chosen,
                ];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: DropdownButtonFormField<String?>(
                    initialValue: chosen,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: voiceLabel),
                    items: [
                      for (final name in options)
                        DropdownMenuItem<String?>(
                          value: name,
                          child: Text(
                            name ?? deviceVoiceLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: canChange
                        ? (name) =>
                              _choose(prefs.copyWith(voiceName: () => name))
                        : null,
                  ),
                );
              },
            ),
            _Choice<double>(
              label: voiceSpeedLabel,
              values: VoicePrefs.rates,
              names: voiceSpeedNames,
              selected: prefs.rate,
              onChanged: canChange
                  ? (rate) => _choose(prefs.copyWith(rate: rate))
                  : null,
            ),
            _Choice<double>(
              label: voicePitchLabel,
              values: VoicePrefs.pitches,
              names: voicePitchNames,
              selected: prefs.pitch,
              onChanged: canChange
                  ? (pitch) => _choose(prefs.copyWith(pitch: pitch))
                  : null,
            ),
            if (problem != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  problem,
                  style: ChorusType.body.copyWith(color: colors.alert),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(
                    voice.tryIt(tryVoiceSentence).catchError((Object _) {}),
                  ),
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text(tryVoiceLabel),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

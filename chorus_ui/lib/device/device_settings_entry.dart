/// Home's way into "This device".
library;

import 'package:chorus_shared/chorus_shared.dart';
import 'package:flutter/material.dart';

import '../contracts_voice.dart';
import '../features/flags/w3.dart';
import '../home/home_actions.dart';
import 'device_settings_scope.dart';
import 'device_settings_screen.dart';

/// Home's "This device" row, or null where there is nothing to show: the
/// features are off, or the app keeps no device settings.
///
/// [voice] is the circle's voice; [board] sizes the keyguard template.
Widget? deviceSettingsEntry(
  BuildContext context, {
  VoiceChoice? voice,
  BoardFacts? board,
}) {
  final store = DeviceSettingsScope.storeOf(context);
  if (!deviceSettingsEnabled || store == null) return null;
  return HomeEntry(
    icon: Icons.tune_rounded,
    label: deviceSettingsTitle,
    detail: deviceSettingsDetail,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceSettingsScreen(
          store: store,
          voice: voice,
          boardRows: board?.rows,
          boardCols: board?.cols,
        ),
      ),
    ),
  );
}

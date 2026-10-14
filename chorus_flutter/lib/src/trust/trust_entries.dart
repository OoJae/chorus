/// Home's entries for "Who is up to date" and "Under the hood".
library;

import 'package:chorus_ui/contracts.dart' show SyncStatus;
import 'package:chorus_ui/features/flags/w1.dart';
import 'package:chorus_ui/features/trust/under_the_hood_screen.dart';
import 'package:chorus_ui/features/trust/who_is_up_to_date_screen.dart';
import 'package:chorus_ui/home/home_actions.dart';
import 'package:flutter/material.dart';

import 'trust_services.dart';

/// The entries [trust] offers, in home's quiet list; none without it.
List<Widget> trustEntries(
  BuildContext context, {
  required TrustServices? trust,
  required SyncStatus sync,
}) {
  final devices = trust?.devices;
  final inspector = trust?.inspector;
  void open(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));
  return [
    if (whoIsUpToDateEnabled && devices != null)
      HomeEntry(
        icon: Icons.devices_rounded,
        label: whoIsUpToDateTitle,
        onTap: () =>
            open(WhoIsUpToDateScreen(directory: devices, sync: sync)),
      ),
    if (underTheHoodEnabled && inspector != null)
      HomeEntry(
        icon: Icons.storage_rounded,
        label: underTheHoodTitle,
        onTap: () => open(UnderTheHoodScreen(inspector: inspector)),
      ),
  ];
}

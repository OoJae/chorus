/// Home's hooks for "What changed", "Suggest a word" and "People in this
/// circle". Each checks its flag, so a flag set to false leaves home as it
/// was.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_ui/activity/activity_screen.dart';
import 'package:chorus_ui/activity/activity_text.dart';
import 'package:chorus_ui/activity/members_screen.dart';
import 'package:chorus_ui/contracts.dart' show BoardStore;
import 'package:chorus_ui/contracts_activity.dart';
import 'package:chorus_ui/contracts_edits.dart';
import 'package:chorus_ui/editor/word_suggestions_tray.dart';
import 'package:chorus_ui/features/flags/w2.dart' as w2;
import 'package:chorus_ui/home/home_actions.dart';
import 'package:flutter/material.dart';

import 'w2_parts.dart';

/// "Since you last looked: 3 changes" on home, or null when the feed is
/// off or there is no adult to remember the look for.
Widget? w2ActivityBanner({
  required CircleInfo selected,
  required BoardStore store,
  required String? userId,
  required ValueChanged<Widget> open,
}) {
  if (!w2.activityFeedEnabled || userId == null) return null;
  final parts = w2PartsFor(selected, userId);
  // Left out, not drawn empty, while there is nothing new: home spaces
  // every note it is given.
  final seen = parts.seen;
  if (!seen.loaded) return null;
  final edits = store is EditLog ? (store as EditLog).edits : <EditFacts>[];
  if (changesSince(activityOf(store.tiles, edits), seen.known) == 0) {
    return null;
  }
  return ActivityBanner(
    key: ValueKey('w2-banner-${selected.spaceUuid.uuid}'),
    store: store,
    seen: parts.seen,
    onOpen: () => open(_feed(store, parts)),
  );
}

/// "What changed" for [store], with a sitter's words where they may be
/// seen.
Widget _feed(BoardStore store, W2Parts parts) => ActivityScreen(
  store: store,
  seen: parts.seen,
  sitterTaps: w2.sitterTapsInFeedEnabled ? parts.sitterTaps : null,
);

/// The entries home lists for these features.
List<Widget> w2HomeEntries({
  required BuildContext context,
  required CircleInfo selected,
  required BoardStore store,
  required String? userId,
  required ValueChanged<Widget> open,
}) {
  if (userId == null) return const [];
  final parts = w2PartsFor(selected, userId);
  final suggestions = parts.suggestions;
  final members = parts.members;
  final partner = selected.myRole == CircleRole.partner;
  return [
    if (w2.activityFeedEnabled)
      HomeEntry(
        icon: Icons.history_rounded,
        label: activityTitle,
        detail: activityEntryDetail,
        onTap: () => open(_feed(store, parts)),
      ),
    if (w2.suggestWordEnabled && partner && suggestions != null)
      HomeEntry(
        icon: Icons.lightbulb_outline_rounded,
        label: suggestWordLabel,
        detail: suggestWordDetail,
        opensScreen: false,
        onTap: () => showSuggestWordDialog(context, suggestions),
      ),
    if (w2.circleMembersEnabled && members != null)
      HomeEntry(
        icon: Icons.group_outlined,
        label: membersTitle,
        detail: membersEntryDetail,
        onTap: () => open(MembersScreen(members: members)),
      ),
  ];
}

/// [screen] with the circle's suggested words above it, so the editor's
/// "Needs a home" can show them to an editor.
Widget w2Scope({
  required CircleInfo selected,
  required String? userId,
  required Widget screen,
}) {
  if (!w2.suggestWordEnabled || userId == null) return screen;
  if (selected.myRole == CircleRole.partner) return screen;
  final suggestions = w2PartsFor(selected, userId).suggestions;
  if (suggestions == null) return screen;
  return WordSuggestionsScope(suggestions: suggestions, child: screen);
}

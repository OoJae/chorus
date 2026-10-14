/// What home offers: the thumb's two actions and the quiet list.
library;

import 'package:flutter/material.dart';

import '../brand/pressable_surface.dart';
import '../brand/tokens.dart';

/// The actions in the thumb's reach: [openLabel] opens the child's board,
/// on an ink laminated face that sinks under the finger, and [editLabel]
/// opens the editor. A read-only partner gets no [editLabel].
///
/// A null callback shows the action disabled: there is no board to open
/// yet.
class HomeActions extends StatelessWidget {
  const HomeActions({
    super.key,
    required this.openLabel,
    required this.onOpen,
    this.editLabel,
    this.onEdit,
  });

  /// "Open Maya's board", or "View Maya's board" for a partner.
  final String openLabel;
  final VoidCallback? onOpen;

  /// "Edit words"; null leaves the action out.
  final String? editLabel;
  final VoidCallback? onEdit;

  /// The primary action's face, for tests.
  @visibleForTesting
  static const Key openKey = ValueKey('HomeActions.open');

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final enabled = onOpen != null;
    final editLabel = this.editLabel;
    // On a short screen (a phone held sideways) the two sit side by side,
    // so both stay in the bottom third. There they go without their icons,
    // so each label keeps to one line at the usual text size.
    final short =
        editLabel != null && MediaQuery.sizeOf(context).height < shortScreen;
    final open = PressableSurface(
      key: openKey,
      onTap: onOpen,
      semanticLabel: openLabel,
      // Disabled: the face goes to the hairline colour and its words to
      // muted ink, with no edge to press.
      color: enabled ? null : colors.line,
      edgeColor: enabled ? null : colors.line,
      foregroundColor: enabled ? null : colors.inkMuted,
      padding: EdgeInsets.symmetric(horizontal: short ? 12 : 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!short) ...[
            const Icon(Icons.grid_view_rounded),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              openLabel,
              textAlign: TextAlign.center,
              style: ChorusType.label.copyWith(fontSize: 17, height: 22 / 17),
            ),
          ),
        ],
      ),
    );
    if (editLabel == null) return open;
    final editStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: short ? const EdgeInsets.symmetric(horizontal: 12) : null,
    );
    if (short) {
      final edit = OutlinedButton(
        onPressed: onEdit,
        style: editStyle,
        child: Text(editLabel, textAlign: TextAlign.center),
      );
      // One height for both, should a long name or large text wrap one.
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: open),
            const SizedBox(width: ChorusSpace.targetGap),
            Expanded(flex: 2, child: edit),
          ],
        ),
      );
    }
    final edit = OutlinedButton.icon(
      onPressed: onEdit,
      style: editStyle,
      icon: const Icon(Icons.edit_rounded),
      label: Text(editLabel),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        open,
        const SizedBox(height: ChorusSpace.targetGap),
        edit,
      ],
    );
  }

  /// Below this height the two actions sit side by side.
  static const double shortScreen = 480;
}

/// One row of home's quiet list: an ink icon, the words, and a chevron when
/// it opens another screen.
class HomeEntry extends StatelessWidget {
  const HomeEntry({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.detail,
    this.opensScreen = true,
  });

  final IconData icon;
  final String label;

  /// One line under the label.
  final String? detail;

  final VoidCallback? onTap;

  /// True draws a chevron: the row leads somewhere.
  final bool opensScreen;

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: detail == null ? null : Text(detail),
      trailing: opensScreen ? const Icon(Icons.chevron_right_rounded) : null,
      minTileHeight: 56,
      onTap: onTap,
      enabled: onTap != null,
    );
  }
}

/// A note in the list or under the board: an icon and plain words, quiet
/// unless it is an [alert].
class HomeNote extends StatelessWidget {
  const HomeNote({
    super.key,
    required this.icon,
    required this.message,
    this.alert = false,
    this.action,
  });

  /// The note's mark; a skeleton note passes a small progress mark.
  final Widget icon;
  final String message;

  /// True draws the edge in the alert colour: something failed.
  final bool alert;

  /// A button at the end, such as "Retry".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = ChorusColors.of(context);
    final action = this.action;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(ChorusSpace.buttonRadius),
        border: Border.all(
          color: alert ? colors.alert : colors.line,
          width: alert ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          IconTheme.merge(
            data: IconThemeData(color: alert ? colors.alert : colors.ink),
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: Text(
                message,
                style: ChorusType.body.copyWith(color: colors.ink),
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

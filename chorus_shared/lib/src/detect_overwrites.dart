/// Finds the edits a merge silently replaced.
///
/// Two adults who change the same property of a tile without seeing each
/// other's change both succeed on their own device; the merge keeps one value
/// and says nothing. The edit log still holds both, and each edit names the
/// edit it was made on top of, so the replaced one can be found afterwards.
/// Run this after every merge: no event fires.
library;

import 'edit_facts.dart';
import 'facts.dart';

/// The tile properties whose overwrites are reported and can be put back.
const Set<String> restorableProps = {'label', 'speech', 'colorKey'};

/// An edit that lost to another made without sight of it.
class Overwrite {
  const Overwrite({required this.lost, required this.kept, required this.tile});

  /// The edit whose value the merge replaced.
  final EditFacts lost;

  /// The edit whose value the tile holds now.
  final EditFacts kept;

  /// The tile as it is now.
  final TileFacts tile;

  /// The property both edits changed.
  String get prop => lost.prop;

  @override
  bool operator ==(Object other) =>
      other is Overwrite &&
      other.lost == lost &&
      other.kept == kept &&
      other.tile == tile;

  @override
  int get hashCode => Object.hash(lost, kept, tile);

  @override
  String toString() =>
      'Overwrite(${lost.prop} of ${tile.id}: '
      '"${lost.newValue}" lost to "${kept.newValue}")';
}

/// What [tile] holds for [prop], or null for a property not in
/// [restorableProps]. An empty value reads as null, as the store writes it.
String? currentValueOf(TileFacts tile, String prop) => _norm(switch (prop) {
  'label' => tile.label,
  'speech' => tile.speech,
  'colorKey' => tile.colorKey,
  _ => null,
});

/// Every edit in [edits] that was replaced by one made without sight of it,
/// newest first.
///
/// Per tile and property the edits form a tree through `baseEditId`. An edit
/// nobody built on is a tip. One tip means everyone saw everyone's change,
/// however often they changed their mind. Several tips mean the edits were
/// made side by side: the tip whose value the tile holds is the one kept,
/// and each other tip is an overwrite unless
///
///  * it asked for the value the tile holds anyway, or
///  * the kept line of edits already held that same value and moved on, or
///  * an edit on the kept line replaced that very value knowingly: a
///    restore, or an edit whose old value is not what its own base wrote,
///    which only happens when the author was looking at a merged tile.
///
/// Which edit won is read from the tile's value, never from the clocks.
/// Archived tiles, tiles not in [tiles] and properties outside
/// [restorableProps] are ignored. Two lost tips asking for the same value
/// are reported once.
List<Overwrite> detectOverwrites(
  Iterable<EditFacts> edits,
  Iterable<TileFacts> tiles,
) {
  final live = {
    for (final tile in tiles)
      if (!tile.archived) tile.id: tile,
  };
  final groups = <(String, String), Map<String, EditFacts>>{};
  for (final edit in edits) {
    if (!restorableProps.contains(edit.prop)) continue;
    if (!live.containsKey(edit.tileId)) continue;
    groups.putIfAbsent((edit.tileId, edit.prop), () => {})[edit.id] = edit;
  }

  final found = <Overwrite>[];
  for (final MapEntry(key: (tileId, prop), value: byId) in groups.entries) {
    found.addAll(_inGroup(live[tileId]!, prop, byId));
  }
  found.sort((a, b) => _newestFirst(a.lost, b.lost));
  return found;
}

/// The overwrites among the edits of one property of one tile.
List<Overwrite> _inGroup(
  TileFacts tile,
  String prop,
  Map<String, EditFacts> byId,
) {
  if (byId.length < 2) return const [];
  final current = currentValueOf(tile, prop);

  /// [edit]'s base, its base, and so on. Stops at a base that is not in the
  /// log (not synced yet) and at a loop, which only corrupt data could make.
  List<EditFacts> ancestorsOf(EditFacts edit) {
    final seen = <String>{edit.id};
    final line = <EditFacts>[];
    var base = byId[edit.baseEditId];
    while (base != null && seen.add(base.id)) {
      line.add(base);
      base = byId[base.baseEditId];
    }
    return line;
  }

  final builtOn = {
    for (final edit in byId.values)
      if (byId.containsKey(edit.baseEditId)) edit.baseEditId!,
  };
  final tips = [
    for (final edit in byId.values)
      if (!builtOn.contains(edit.id)) edit,
  ];
  if (tips.length < 2) return const [];

  // The tips that wrote the value the tile holds. If none did (the winning
  // write is not a tip, which a refused or missing edit can cause), fall
  // back to any edit that wrote it.
  var winners = [
    for (final tip in tips)
      if (_norm(tip.newValue) == current) tip,
  ];
  if (winners.isEmpty) {
    winners = [
      for (final edit in byId.values)
        if (_norm(edit.newValue) == current) edit,
    ];
  }
  // Nothing in the log explains the tile's value: there is no kept edit to
  // name, so nothing is reported rather than something guessed.
  if (winners.isEmpty) return const [];
  winners.sort(_newestFirst);
  final kept = winners.first;

  // Every edit the kept value was built on, the winners included.
  final keptLine = <String, EditFacts>{};
  for (final winner in winners) {
    keptLine[winner.id] = winner;
    for (final edit in ancestorsOf(winner)) {
      keptLine[edit.id] = edit;
    }
  }

  final lostByValue = <String?, EditFacts>{};
  for (final tip in tips..sort(_newestFirst)) {
    final wanted = _norm(tip.newValue);
    if (wanted == current) continue;
    final ancestors = ancestorsOf(tip);
    // Built on a winner: a later change of mind the merge itself undid is
    // not something this function can explain, so it is left alone.
    if (ancestors.any((edit) => winners.contains(edit))) continue;
    final own = {for (final edit in ancestors) edit.id};

    bool settledBy(EditFacts decision) {
      // An edit the tip was built on was made before it and cannot have
      // judged it.
      if (own.contains(decision.id)) return false;
      if (_norm(decision.newValue) == wanted) return true;
      if (_norm(decision.oldValue) != wanted) return false;
      if (decision.reason == restoreReason) return true;
      final base = byId[decision.baseEditId];
      return base != null && _norm(base.newValue) != _norm(decision.oldValue);
    }

    if (keptLine.values.any(settledBy)) continue;
    lostByValue.putIfAbsent(wanted, () => tip);
  }

  return [
    for (final lost in lostByValue.values)
      Overwrite(lost: lost, kept: kept, tile: tile),
  ];
}

/// Newest first by the authors' clocks, ties broken by id. Only orders the
/// result and picks which of several equal winners to name.
int _newestFirst(EditFacts a, EditFacts b) {
  final byTime = b.editedAt.compareTo(a.editedAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

String? _norm(String? value) => (value == null || value.isEmpty) ? null : value;

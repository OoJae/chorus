/// The practice partner of "Try a clash", over the server's practice
/// endpoint.
library;

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_shared/chorus_shared.dart' show placedKey;
import 'package:chorus_ui/contracts_clash.dart';

import '../sync/sync_supervisor.dart';

/// [ClashPartner] for one circle.
class ServerClashPartner implements ClashPartner {
  ServerClashPartner(this._call, {required this.circleSpace, this.supervisor});

  /// Over the generated client.
  factory ServerClashPartner.forClient(
    Client client, {
    required UuidValue circleSpace,
    SyncSupervisor? supervisor,
  }) => ServerClashPartner(
    (space, board, cell) => client.practice.partnerWord(space, board, cell),
    circleSpace: circleSpace,
    supervisor: supervisor,
  );

  final Future<PracticeWord> Function(
    UuidValue circleSpace,
    UuidValue boardId,
    String cellKey,
  )
  _call;

  final UuidValue circleSpace;

  /// When given, a one-shot sync the engine is still finishing is waited
  /// for first, so it cannot bring the partner's word in early.
  final SyncSupervisor? supervisor;

  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<PartnerWord> putWord({
    required String boardId,
    required int row,
    required int col,
  }) async {
    await supervisor?.settled();
    try {
      final word = await _call(
        circleSpace,
        UuidValue.fromString(boardId),
        placedKey(boardId, row, col),
      ).timeout(_timeout);
      return PartnerWord(
        tileId: word.tileId.uuid,
        label: word.label,
        partnerName: word.partnerName,
      );
    } on PracticeException catch (e) {
      throw PracticeRefused(switch (e.failure) {
        PracticeFailure.cellTaken => PracticeRefusal.cellTaken,
        PracticeFailure.noSuchCell => PracticeRefusal.noSuchCell,
        PracticeFailure.tooMany => PracticeRefusal.tooMany,
      });
    } on CircleException {
      throw const PracticeRefused(PracticeRefusal.notAllowed);
    } catch (_) {
      throw const PracticeRefused(PracticeRefusal.unreachable);
    }
  }
}

// One circle's features at a time: made once per role, made again after
// the old ones are disposed when the role changes, and left out for good
// when they cannot be made.
import 'package:chorus_flutter/src/features/feature_wiring.dart';
import 'package:flutter_test/flutter_test.dart';

class _Features {
  _Features(this.role);

  final String role;
  bool disposed = false;
}

void main() {
  late List<_Features> made;
  late FeatureSlot<_Features> slot;

  setUp(() {
    made = [];
    slot = FeatureSlot((features) => features.disposed = true);
  });

  _Features open(String role) {
    final features = _Features(role);
    made.add(features);
    return features;
  }

  test('asked again for the same role, it hands back the same features', () {
    final first = slot.forRole('guardian', () => open('guardian'));
    final again = slot.forRole('guardian', () => open('guardian'));
    expect(again, same(first));
    expect(made, hasLength(1));
    expect(slot.role, 'guardian');
  });

  test('a new role disposes the old features before making new ones', () {
    final guardian = slot.forRole('guardian', () => open('guardian'))!;
    final partner = slot.forRole('partner', () {
      // Never two word logs of one circle at once.
      expect(guardian.disposed, isTrue);
      return open('partner');
    })!;
    expect(partner.role, 'partner');
    expect(partner.disposed, isFalse);
    expect(made, hasLength(2));
  });

  test('when making them fails it gives none for that role and does not '
      'try again, but tries for another role', () {
    var tries = 0;
    _Features fail() {
      tries++;
      throw StateError('no storage');
    }

    expect(slot.forRole('guardian', fail), isNull);
    expect(slot.forRole('guardian', fail), isNull);
    expect(tries, 1);
    expect(slot.forRole('teacher', () => open('teacher')), isNotNull);
  });

  test('dispose disposes what it holds, and it makes nothing after', () {
    final held = slot.forRole('guardian', () => open('guardian'))!;
    slot.dispose();
    expect(held.disposed, isTrue);
    expect(slot.forRole('guardian', () => open('guardian')), isNull);
    expect(made, hasLength(1));
  });
}

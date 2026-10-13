import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

void main() {
  test('attempt 0 waits the base delay', () {
    expect(backoffDelay(0), const Duration(seconds: 1));
    expect(
      backoffDelay(0, base: const Duration(milliseconds: 250)),
      const Duration(milliseconds: 250),
    );
  });

  test('doubles each attempt and stops at the cap', () {
    final seconds = [for (var i = 0; i < 7; i++) backoffDelay(i).inSeconds];
    expect(seconds, [1, 2, 4, 8, 16, 30, 30]);
  });

  test('a very large attempt stays at the cap', () {
    expect(backoffDelay(1000), const Duration(seconds: 30));
  });

  test('a negative attempt counts as 0', () {
    expect(backoffDelay(-3), const Duration(seconds: 1));
  });

  test('a base above the cap gives the cap', () {
    expect(
      backoffDelay(0,
          base: const Duration(minutes: 1), max: const Duration(seconds: 30)),
      const Duration(seconds: 30),
    );
  });

  test('custom base and cap', () {
    const base = Duration(milliseconds: 500);
    const max = Duration(seconds: 3);
    final millis = [
      for (var i = 0; i < 5; i++)
        backoffDelay(i, base: base, max: max).inMilliseconds,
    ];
    expect(millis, [500, 1000, 2000, 3000, 3000]);
  });
}

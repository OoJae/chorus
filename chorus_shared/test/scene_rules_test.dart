import 'package:chorus_shared/chorus_shared.dart';
import 'package:test/test.dart';

Matcher closeRect(SpotRect r) => predicate<SpotRect>(
  (s) =>
      (s.x - r.x).abs() < 1e-9 &&
      (s.y - r.y).abs() < 1e-9 &&
      (s.width - r.width).abs() < 1e-9 &&
      (s.height - r.height).abs() < 1e-9,
  'close to $r',
);

void main() {
  group('scene name', () {
    test('needs a name, tidied, of at most 30 characters', () {
      expect(sceneNameProblem('  '), 'Give the scene a name.');
      expect(sceneNameProblem('At the park'), isNull);
      expect(sceneNameProblem('a' * 30), isNull);
      expect(
        sceneNameProblem('a' * 31),
        'Keep the name to 30 characters or fewer.',
      );
    });
  });

  group('a spot drawn by a drag', () {
    test('works in either direction', () {
      expect(
        SpotRect.fromDrag(0.6, 0.7, 0.2, 0.3),
        closeRect(const SpotRect(0.2, 0.3, 0.4, 0.4)),
      );
      expect(
        SpotRect.fromDrag(0.2, 0.3, 0.6, 0.7),
        closeRect(const SpotRect(0.2, 0.3, 0.4, 0.4)),
      );
    });

    test('is kept on the photo', () {
      final spot = SpotRect.fromDrag(-0.5, 0.5, 1.5, 2);
      expect(spot, closeRect(const SpotRect(0, 0.5, 1, 0.5)));
      expect(spot.isValid, isTrue);
    });

    test('a tap or a short drag still makes a spot a fingertip wide', () {
      final tap = SpotRect.fromDrag(0.5, 0.5, 0.5, 0.5);
      expect(tap.width, minSpotSide);
      expect(tap.height, minSpotSide);
      expect(tap.x, 0.5);
      // Towards where the finger went, turning back at the edge.
      final back = SpotRect.fromDrag(0.5, 0.5, 0.49, 0.49);
      expect(back.x, closeTo(0.5 - minSpotSide, 1e-9));
      final edge = SpotRect.fromDrag(0.99, 0.99, 1, 1);
      expect(edge.right, closeTo(1, 1e-9));
      expect(edge.isValid, isTrue);
    });

    test('ignores numbers that are not finite', () {
      expect(SpotRect.fromDrag(double.nan, 0, 0.5, 0.5).isValid, isTrue);
    });
  });

  group('moving and resizing a spot', () {
    const spot = SpotRect(0.2, 0.2, 0.3, 0.3);

    test('a move keeps the size and stops at the edges', () {
      expect(
        spot.moved(0.1, 0.1),
        closeRect(const SpotRect(0.3, 0.3, 0.3, 0.3)),
      );
      expect(spot.moved(1, 1), closeRect(const SpotRect(0.7, 0.7, 0.3, 0.3)));
      expect(spot.moved(-1, -1), closeRect(const SpotRect(0, 0, 0.3, 0.3)));
    });

    test('a resize keeps the top-left corner, the edges and the minimum', () {
      expect(
        spot.resized(0.1, -0.1),
        closeRect(const SpotRect(0.2, 0.2, 0.4, 0.2)),
      );
      expect(spot.resized(5, 5), closeRect(const SpotRect(0.2, 0.2, 0.8, 0.8)));
      final small = spot.resized(-5, -5);
      expect(small.width, minSpotSide);
      expect(small.height, minSpotSide);
    });

    test('clamped makes any rectangle valid', () {
      expect(const SpotRect(0.9, 0.9, 0.5, 0.5).isValid, isFalse);
      expect(
        const SpotRect(0.9, 0.9, 0.5, 0.5).clamped(),
        closeRect(const SpotRect(0.5, 0.5, 0.5, 0.5)),
      );
      expect(const SpotRect(-1, 0, 0, 2).clamped().isValid, isTrue);
      expect(const SpotRect(0.1, 0.1, 0.01, 0.2).isValid, isFalse);
    });
  });

  group('hit-testing', () {
    const person = SpotRect(0.1, 0.1, 0.5, 0.8);
    const face = SpotRect(0.2, 0.15, 0.1, 0.1);
    const dog = SpotRect(0.7, 0.6, 0.2, 0.3);

    test('finds the spot under the finger, or none', () {
      expect(spotAt([person, dog], 0.8, 0.7), 1);
      expect(spotAt([person, dog], 0.65, 0.05), isNull);
      expect(spotAt(const [], 0.5, 0.5), isNull);
    });

    test('where spots overlap, the smallest wins, whatever the order', () {
      expect(spotAt([person, face], 0.25, 0.2), 1);
      expect(spotAt([face, person], 0.25, 0.2), 0);
      expect(spotAt([face, person], 0.4, 0.5), 1);
    });

    test('edges count as inside', () {
      expect(spotAt([dog], 0.7, 0.6), 0);
      expect(spotAt([dog], 0.9, 0.9), 0);
    });

    test('of equal spots, the one drawn last wins', () {
      expect(spotAt([dog, dog], 0.8, 0.7), 1);
    });
  });

  group('fitting a photo in a box', () {
    test('a wide photo fills the width and is centred up and down', () {
      final fit = fitPhoto(
        boxWidth: 400,
        boxHeight: 400,
        imageWidth: 800,
        imageHeight: 400,
      );
      expect(fit, (left: 0.0, top: 100.0, width: 400.0, height: 200.0));
    });

    test('a tall photo fills the height and is centred across', () {
      final fit = fitPhoto(
        boxWidth: 800,
        boxHeight: 400,
        imageWidth: 300,
        imageHeight: 600,
      );
      expect(fit, (left: 300.0, top: 0.0, width: 200.0, height: 400.0));
    });

    test('nothing to fit gives an empty rectangle', () {
      expect(
        fitPhoto(boxWidth: 0, boxHeight: 10, imageWidth: 1, imageHeight: 1),
        (left: 0.0, top: 0.0, width: 0.0, height: 0.0),
      );
    });
  });

  group("a spot's word", () {
    test('needs a label and keeps both within the word limits', () {
      expect(spotWordProblem(' '), 'Type the word this spot says.');
      expect(spotWordProblem('Grandma'), isNull);
      expect(spotWordProblem('a' * 31), isNotNull);
      expect(spotWordProblem('Nan', speech: 'a' * 81), isNotNull);
      expect(spotWordProblem('Nan', speech: 'Grandma Rose'), isNull);
    });
  });
}

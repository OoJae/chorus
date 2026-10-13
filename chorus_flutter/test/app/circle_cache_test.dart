import 'dart:convert';

import 'package:chorus_client/chorus_client.dart';
import 'package:chorus_flutter/screens/support/circle_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a circle survives the text form the cache stores', () {
    final before = circle(role: CircleRole.partner, myName: 'Gran');

    final text = jsonEncode([before.toJson()]);
    final after = CircleInfo.fromJson(
      ((jsonDecode(text) as List).single as Map).cast<String, dynamic>(),
    );

    expect(after.spaceUuid, before.spaceUuid);
    expect(after.childName, 'Maya');
    expect(after.myRole, CircleRole.partner);
    expect(after.members.single.displayName, 'Gran');
  });

  test('with no storage the cache is empty and saving is quiet', () async {
    await writeCircleCache('user', [circle()]);
    expect(await readCircleCache('user'), isEmpty);
  });
}

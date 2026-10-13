/// File storage for the circle cache on phones and desktops.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> _file(String name) async {
  final dir = await getApplicationSupportDirectory();
  return File(p.join(dir.path, name));
}

Future<String?> readText(String name) async {
  final file = await _file(name);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> writeText(String name, String text) async {
  final file = await _file(name);
  await file.parent.create(recursive: true);
  await file.writeAsString(text, flush: true);
}

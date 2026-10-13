import 'package:flutter/material.dart';

import 'app.dart';
import 'client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const ChorusApp());
}

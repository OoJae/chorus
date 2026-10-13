/// Circle cache storage where there is neither a file system nor a browser:
/// keeps nothing.
library;

Future<String?> readText(String name) async => null;

Future<void> writeText(String name, String text) async {}

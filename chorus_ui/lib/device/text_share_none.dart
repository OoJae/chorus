/// No share sheet and no file saving outside a browser: the app carries no
/// plugin for either.
library;

bool canShareText() => false;

Future<bool> shareText(String text) async => false;

bool canSaveFiles() => false;

Future<bool> saveTextFile(String fileName, String text) async => false;

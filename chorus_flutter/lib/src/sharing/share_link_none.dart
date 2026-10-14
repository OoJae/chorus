/// No share sheet outside a browser: the app carries no share plugin.
library;

bool canShareLinks() => false;

Future<bool> shareLink(String url, String text, String title) async => false;

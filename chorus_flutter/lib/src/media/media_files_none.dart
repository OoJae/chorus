/// Media storage where there is neither a file system nor a browser.
library;

import 'media_files.dart';

Future<MediaFiles> openPlatformMediaFiles() async => MemoryMediaFiles();

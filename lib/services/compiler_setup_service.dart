import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CompilerSetupService {
  static const List<String> _binaries = [
    'gcc',
    'python3',
    'sh',
  ];

  static Future<Map<String, String>> extractCompilers() async {
    final supportDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(supportDir.path, 'bin'));
    
    if (!await binDir.exists()) {
      await binDir.create(recursive: true);
    }

    final Map<String, String> paths = {};

    for (final name in _binaries) {
      final destPath = p.join(binDir.path, name);
      final file = File(destPath);
      
      // Extract from assets
      try {
        final byteData = await rootBundle.load('assets/bin/$name');
        final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        await file.writeAsBytes(bytes, flush: true);
        
        // Give execution permissions on Android / Linux
        if (Platform.isLinux || Platform.isAndroid || Platform.isMacOS) {
          await Process.run('chmod', ['+x', destPath]);
        }
        
        paths[name] = destPath;
      } catch (e) {
        // Fallback for debug/development mode if assets aren't bundled yet
        if (!await file.exists()) {
          if (Platform.isWindows) {
            await file.writeAsString('@echo [Embedded Mock $name] Executing...');
          } else {
            await file.writeAsString('#!/bin/sh\necho "[Embedded Mock $name] Executing..."');
            await Process.run('chmod', ['+x', destPath]);
          }
        }
        paths[name] = destPath;
      }
    }

    return paths;
  }
}

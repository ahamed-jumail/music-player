import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderService {
  static const folderKey = 'music_folder';

  Future<String?> getSavedFolder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(folderKey);
  }

  Future<void> saveFolder(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(folderKey, path);
  }

  Future<String?> pickFolder() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      await saveFolder(result);
    }

    return result;
  }

  Future<List<FileSystemEntity>> audioFiles(String folder) async {
    try {
      final dir = Directory(folder);

      debugPrint('Checking folder: $folder');

      if (!await dir.exists()) {
        debugPrint('Folder does not exist');
        return [];
      }

      final allFiles = await dir.list(recursive: false).toList();

      debugPrint('Total items: ${allFiles.length}');

      const extensions = [
        '.mp3',
        '.wav',
        '.aac',
        '.m4a',
        '.flac',
        '.ogg',
        '.opus',
      ];

      final audioFiles = allFiles.whereType<File>().where((file) {
        final lower = file.path.toLowerCase();

        return extensions.any(lower.endsWith);
      }).toList();

      debugPrint('Audio files: ${audioFiles.length}');

      return audioFiles;
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}

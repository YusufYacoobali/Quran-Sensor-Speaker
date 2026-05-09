import 'dart:io';

import 'package:file_picker/file_picker.dart';

class SelectedUploadFile {
  const SelectedUploadFile({required this.name, required this.bytes});

  final String name;
  final List<int> bytes;

  int get sizeBytes => bytes.length;
}

class UploadFilePicker {
  const UploadFilePicker();

  // The app keeps the chosen bytes in memory for the prototype so upload.prepare
  // and the Wi-Fi PUT always refer to the exact same file contents.
  Future<SelectedUploadFile?> pickMp3() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['mp3'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final bytes =
        file.bytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());

    if (bytes == null || bytes.isEmpty) {
      return SelectedUploadFile(name: file.name, bytes: const <int>[]);
    }

    return SelectedUploadFile(name: file.name, bytes: bytes);
  }
}

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload audio file for voice recording
  /// Returns the download URL
  Future<String> uploadAudio({
    required String uid,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final ref = _storage.ref().child('$uid/audio/$fileName');
    final metadata = SettableMetadata(contentType: mimeType);
    await ref.putData(fileBytes, metadata);
    return await ref.getDownloadURL();
  }

  /// Upload KB document (PDF)
  /// Returns the storage reference path
  Future<String> uploadKbDocument({
    required String uid,
    required String projectId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final path = '$uid/kb/$projectId/$fileName';
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: mimeType);
    await ref.putData(fileBytes, metadata);
    return path;
  }

  /// Get download URL for a storage reference
  Future<String> getDownloadUrl(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return await ref.getDownloadURL();
  }

  /// Delete a file from storage
  Future<void> deleteFile(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    await ref.delete();
  }
}

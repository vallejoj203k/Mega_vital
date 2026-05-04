import 'dart:io';
import 'package:video_compress/video_compress.dart';

class VideoTooLargeException implements Exception {
  final String message;
  const VideoTooLargeException(this.message);
  @override
  String toString() => message;
}

class VideoCompressService {
  static const int _maxBytes = 10 * 1024 * 1024; // 10 MB

  /// Comprime [file] y retorna el archivo comprimido.
  /// Lanza [VideoTooLargeException] si tras comprimir sigue > 10 MB.
  /// El llamador es responsable de llamar [clearCache] después de subir el archivo.
  static Future<File> compress(File file) async {
    final info = await VideoCompress.compressVideo(
      file.path,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );

    final compressed = info?.file;
    if (compressed == null) throw Exception('La compresión de video falló.');

    final size = await compressed.length();
    if (size > _maxBytes) {
      await clearCache();
      throw VideoTooLargeException(
        'El video sigue siendo mayor a 10 MB después de comprimir '
        '(${(size / 1024 / 1024).toStringAsFixed(1)} MB). '
        'Usa un video más corto.',
      );
    }

    return compressed;
  }

  static Future<void> clearCache() async {
    await VideoCompress.deleteAllCache();
  }
}

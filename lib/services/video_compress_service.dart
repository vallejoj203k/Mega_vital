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
  /// Siempre limpia el caché de video_compress al terminar.
  static Future<File> compress(File file) async {
    MediaInfo? info;
    try {
      info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      final compressed = info?.file;
      if (compressed == null) throw Exception('La compresión falló.');

      final size = await compressed.length();
      if (size > _maxBytes) {
        throw VideoTooLargeException(
          'El video sigue siendo mayor a 10 MB después de comprimir '
          '(${(size / 1024 / 1024).toStringAsFixed(1)} MB). '
          'Usa un video más corto.',
        );
      }

      return compressed;
    } finally {
      await VideoCompress.deleteAllCache();
    }
  }
}

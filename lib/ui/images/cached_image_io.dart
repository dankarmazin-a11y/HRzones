import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

ImageProvider cachedNetworkImage(String url) => DiskCachedImage(url);

/// Loads [url] from the app's files if it was downloaded before, otherwise
/// downloads it and saves it for next time.
@immutable
class DiskCachedImage extends ImageProvider<DiskCachedImage> {
  const DiskCachedImage(this.url);

  final String url;

  static Future<Directory>? _dir;

  static Future<Directory> _folder() => _dir ??= () async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/images');
    await d.create(recursive: true);
    return d;
  }();

  @override
  Future<DiskCachedImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(DiskCachedImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _load(decode), scale: 1, debugLabel: url);

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final bytes = await _bytes();
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  Future<Uint8List> _bytes() async {
    File? file;
    try {
      final name = Uri.parse(url).path.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      file = File('${(await _folder()).path}/$name');
      if (await file.exists()) return await file.readAsBytes();
    } catch (_) {
      file = null; // no folder: just download
    }
    final client = HttpClient();
    try {
      final res = await (await client.getUrl(Uri.parse(url))).close();
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(url));
      final bytes = await consolidateHttpClientResponseBytes(res);
      if (file != null && bytes.isNotEmpty) {
        // Write next to it, then rename: never leave half a picture behind.
        final tmp = File('${file.path}.part');
        await tmp.writeAsBytes(bytes, flush: true);
        await tmp.rename(file.path);
      }
      return bytes;
    } finally {
      client.close();
    }
  }

  @override
  bool operator ==(Object other) => other is DiskCachedImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}

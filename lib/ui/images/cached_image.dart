import 'package:flutter/painting.dart';

import 'cached_image_stub.dart' if (dart.library.io) 'cached_image_io.dart' as impl;

/// A picture from the web that is kept on the phone after the first download
/// (exercise photos were downloaded again on every launch). On the web
/// preview the browser caches them, so it is a plain [NetworkImage] there.
ImageProvider cachedNetworkImage(String url) => impl.cachedNetworkImage(url);

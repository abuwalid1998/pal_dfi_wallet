// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';

final Map<String, html.VideoElement> _videoElements = {};
final Map<String, html.MediaStream> _mediaStreams = {};

Future<bool> initializeWebCamera(String viewId) async {
  try {
    if (html.window.navigator.mediaDevices == null) {
      return false;
    }

    final stream = await html.window.navigator.mediaDevices!.getUserMedia({
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 640},
        'height': {'ideal': 480},
      },
      'audio': false,
    });

    final video = html.VideoElement()
      ..srcObject = stream
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)'; // Mirror front camera view

    _videoElements[viewId] = video;
    _mediaStreams[viewId] = stream;

    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => video,
    );

    return true;
  } catch (e) {
    // Permission dismissed or headless
    return false;
  }
}

void disposeWebCamera(String viewId) {
  final stream = _mediaStreams.remove(viewId);
  if (stream != null) {
    for (final track in stream.getTracks()) {
      track.stop();
    }
  }
  final video = _videoElements.remove(viewId);
  if (video != null) {
    video.srcObject = null;
  }
}

Widget buildWebCameraWidget(String viewId) {
  return HtmlElementView(viewType: viewId);
}

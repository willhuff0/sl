import 'dart:js_interop';

import 'package:sl_engine/logger.dart';
import 'package:web/web.dart' as web;
import 'package:webxr/webxr.dart';

late final bool vrSupported;
late final XRSystem xr;
late final XRSession xrSession;
late final web.XRReferenceSpace xrReferenceSpace;

Future<bool> initVr() async {
  final navigator = Navigator.$(web.window.navigator);
  final webXr = navigator.xr;
  if (webXr == null) return vrSupported = false;
  xr = webXr;

  try {
    return vrSupported = (await xr.isSessionSupported('immersive-vr'.toJS).toDart).toDart;
  } catch (e) {
    Logger.log('An error occurred while checking for WebXR support:\n$e', .warning);
    return vrSupported = false;
  }
}

Future<void> beginVrSession() async {
  try {
    xrSession = await xr.requestSession('immersive-vr'.toJS).toDart;
    xrReferenceSpace = (await xrSession.requestReferenceSpace('local'.toJS).toDart) as web.XRReferenceSpace;
  } catch (e) {
    Logger.log('An error occurred while trying to begin a VR session:\n$e', .warning);
  }
}

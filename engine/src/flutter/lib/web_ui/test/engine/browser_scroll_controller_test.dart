// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late EngineFlutterView view;
  late BrowserScrollController controller;
  late DomElement hostElement;

  setUp(() {
    hostElement = createDomHTMLDivElement();
    domDocument.body!.append(hostElement);
    view = EngineFlutterView(EnginePlatformDispatcher.instance, hostElement);
    controller = view.browserScrollController;
  });

  tearDown(() {
    view.dispose();
    hostElement.remove();
  });

  group('enable/disable', () {
    test('starts disabled', () {
      expect(controller.enabled, isFalse);
    });

    test('does not enable when strategy does not support it', () {
      controller.enable();
      expect(controller.enabled, isFalse);
    });

    test('disable when already disabled is a no-op', () {
      controller.disable();
      expect(controller.enabled, isFalse);
    });
  });

  group('dispose', () {
    test('disable is called on dispose', () {
      controller.dispose();
      expect(controller.enabled, isFalse);
    });

    test('can dispose when already disabled', () {
      controller.dispose();
      controller.dispose();
      expect(controller.enabled, isFalse);
    });
  });
}

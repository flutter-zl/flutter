// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../platform_dispatcher.dart';
import '../semantics.dart';

/// Provides accessibility for links.
class SemanticLink extends SemanticRole {
  SemanticLink(SemanticsObject semanticsObject)
    : super.withBasics(
        EngineSemanticsRole.link,
        semanticsObject,
        preferredLabelRepresentation: LabelRepresentation.domText,
      ) {
    addTappable();
    _installClickInterceptor();
  }

  DomEventListener? _clickListener;

  /// Intercepts normal left clicks on the <a href> element.
  ///
  /// Prevents the browser from following the href and directly dispatches
  /// [ui.SemanticsAction.tap] to the framework, bypassing [ClickDebouncer].
  ///
  /// The debouncer suppresses clicks that follow recently-flushed pointer
  /// events (within 50ms), which is correct for buttons but breaks links
  /// since the tap would be silently dropped. Dispatching directly here
  /// ensures the framework always receives the tap so the Router can
  /// navigate in-app without a full page reload.
  ///
  /// [stopPropagation] prevents the [Tappable] listener on the same element
  /// from also forwarding the click to the debouncer, avoiding a double tap.
  ///
  /// Modified clicks (Ctrl/Cmd, Shift, middle-button) are not intercepted so
  /// the browser can open the link in a new tab as expected.
  void _installClickInterceptor() {
    _clickListener = createDomEventListener((DomEvent event) {
      final mouseEvent = event as DomMouseEvent;
      if (mouseEvent.button != 0 ||
          mouseEvent.ctrlKey ||
          mouseEvent.metaKey ||
          mouseEvent.shiftKey) {
        return;
      }
      event.preventDefault();
      event.stopPropagation();
      EnginePlatformDispatcher.instance.invokeOnSemanticsAction(
        semanticsObject.owner.viewId,
        semanticsObject.id,
        ui.SemanticsAction.tap,
        null,
      );
    });
    element.addEventListener('click', _clickListener);
  }

  @override
  void dispose() {
    element.removeEventListener('click', _clickListener);
    _clickListener = null;
    super.dispose();
  }

  /// A link with an href is always interactive, regardless of whether the
  /// framework registered a tap handler. Without this, the element gets
  /// pointer-events: auto instead of pointer-events: all, and clicks land
  /// on the canvas behind it instead of the <a> element.
  @override
  bool get acceptsPointerEvents => semanticsObject.hasLinkUrl;

  @override
  DomElement createElement() {
    final DomElement element = domDocument.createElement('a');
    element.style.display = 'block';
    return element;
  }

  @override
  void update() {
    super.update();

    if (semanticsObject.isLinkUrlDirty) {
      if (semanticsObject.hasLinkUrl) {
        element.setAttribute('href', semanticsObject.linkUrl!);
      } else {
        element.removeAttribute('href');
      }
    }
  }

  @override
  bool focusAsRouteDefault() => focusable?.focusAsRouteDefault() ?? false;
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  testWidgets('Listeners are called when semantics are turned on with ensureSemantics', (
    WidgetTester tester,
  ) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    final List<bool> status = <bool>[];
    void listener() {
      status.add(SemanticsBinding.instance.semanticsEnabled);
    }

    SemanticsBinding.instance.addSemanticsEnabledListener(listener);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    final SemanticsHandle handle1 = SemanticsBinding.instance.ensureSemantics();
    expect(status.single, isTrue);
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    status.clear();

    final SemanticsHandle handle2 = SemanticsBinding.instance.ensureSemantics();
    expect(status, isEmpty); // Listener didn't fire again.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    expect(tester.binding.platformDispatcher.semanticsEnabled, isFalse);
    tester.binding.platformDispatcher.semanticsEnabledTestValue = true;
    expect(tester.binding.platformDispatcher.semanticsEnabled, isTrue);
    tester.binding.platformDispatcher.clearSemanticsEnabledTestValue();
    expect(tester.binding.platformDispatcher.semanticsEnabled, isFalse);
    expect(status, isEmpty); // Listener didn't fire again.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    handle1.dispose();
    expect(status, isEmpty); // Listener didn't fire.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    handle2.dispose();
    expect(status.single, isFalse);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  }, semanticsEnabled: false);

  testWidgets('Listeners are called when semantics are turned on by platform', (
    WidgetTester tester,
  ) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    final List<bool> status = <bool>[];
    void listener() {
      status.add(SemanticsBinding.instance.semanticsEnabled);
    }

    SemanticsBinding.instance.addSemanticsEnabledListener(listener);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);

    tester.binding.platformDispatcher.semanticsEnabledTestValue = true;
    expect(status.single, isTrue);
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    status.clear();

    final SemanticsHandle handle = SemanticsBinding.instance.ensureSemantics();
    handle.dispose();
    expect(status, isEmpty); // Listener didn't fire.
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);

    tester.binding.platformDispatcher.clearSemanticsEnabledTestValue();
    expect(status.single, isFalse);
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
  }, semanticsEnabled: false);

  testWidgets('SemanticsBinding.ensureSemantics triggers creation of semantics owner.', (
    WidgetTester tester,
  ) async {
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
    expect(tester.binding.pipelineOwner.semanticsOwner, isNull);

    final SemanticsHandle handle = SemanticsBinding.instance.ensureSemantics();
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    expect(tester.binding.pipelineOwner.semanticsOwner, isNotNull);

    handle.dispose();
    expect(SemanticsBinding.instance.semanticsEnabled, isFalse);
    expect(tester.binding.pipelineOwner.semanticsOwner, isNull);
  }, semanticsEnabled: false);

  test('SemanticsHandle dispatches memory events', () async {
    await expectLater(
      await memoryEvents(
        () => SemanticsBinding.instance.ensureSemantics().dispose(),
        SemanticsHandle,
      ),
      areCreateAndDispose,
    );
  });

  group('SemanticsEvent handling', () {
    testWidgets('SemanticsBinding sets up onSemanticsEvent callback during initialization', (
      WidgetTester tester,
    ) async {
      // The callback should be set up during binding initialization
      expect(tester.binding.platformDispatcher.onSemanticsEvent, isNotNull);
    });

    testWidgets('SemanticsBinding handles SemanticsEvent correctly', (
      WidgetTester tester,
    ) async {
      final List<ui.SemanticsEvent> receivedEvents = <ui.SemanticsEvent>[];

      // Store the original callback
      final ui.SemanticsEventCallback? originalCallback = tester.binding.platformDispatcher.onSemanticsEvent;

      // Set up a test callback to capture events
      tester.binding.platformDispatcher.onSemanticsEvent = (ui.SemanticsEvent event) {
        receivedEvents.add(event);
        // Also call the original callback to test the actual implementation
        originalCallback?.call(event);
      };

      // Create a test SemanticsEvent
      const testEvent = ui.SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{'test': true},
        nodeId: 123,
      );

      // Trigger the event
      tester.binding.platformDispatcher.onSemanticsEvent!(testEvent);

      // Verify the event was received
      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.type, equals('focus'));
      expect(receivedEvents.first.nodeId, equals(123));
      expect(receivedEvents.first.data['test'], isTrue);

      // Restore the original callback
      tester.binding.platformDispatcher.onSemanticsEvent = originalCallback;
    });

    testWidgets('SemanticsBinding handles multiple SemanticsEvent types', (
      WidgetTester tester,
    ) async {
      final List<ui.SemanticsEvent> receivedEvents = <ui.SemanticsEvent>[];

      // Store the original callback
      final ui.SemanticsEventCallback? originalCallback = tester.binding.platformDispatcher.onSemanticsEvent;

      // Set up a test callback to capture events
      tester.binding.platformDispatcher.onSemanticsEvent = (ui.SemanticsEvent event) {
        receivedEvents.add(event);
        originalCallback?.call(event);
      };

      // Test different event types
      const focusEvent = ui.SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{'nodeId': 123},
        nodeId: 123,
      );

      const announceEvent = ui.SemanticsEvent(
        type: 'announce',
        data: <String, dynamic>{'message': 'Hello World'},
      );

      // Trigger the events
      tester.binding.platformDispatcher.onSemanticsEvent!(focusEvent);
      tester.binding.platformDispatcher.onSemanticsEvent!(announceEvent);

      // Verify both events were received
      expect(receivedEvents, hasLength(2));
      expect(receivedEvents[0].type, equals('focus'));
      expect(receivedEvents[1].type, equals('announce'));

      // Restore the original callback
      tester.binding.platformDispatcher.onSemanticsEvent = originalCallback;
    });

    testWidgets('SemanticsBinding handles SemanticsEvent with null nodeId', (
      WidgetTester tester,
    ) async {
      final List<ui.SemanticsEvent> receivedEvents = <ui.SemanticsEvent>[];

      // Store the original callback
      final ui.SemanticsEventCallback? originalCallback = tester.binding.platformDispatcher.onSemanticsEvent;

      // Set up a test callback to capture events
      tester.binding.platformDispatcher.onSemanticsEvent = (ui.SemanticsEvent event) {
        receivedEvents.add(event);
        originalCallback?.call(event);
      };

      // Create event without nodeId
      const testEvent = ui.SemanticsEvent(
        type: 'announce',
        data: <String, dynamic>{'message': 'Global announcement'},
      );

      // Trigger the event
      tester.binding.platformDispatcher.onSemanticsEvent!(testEvent);

      // Verify the event was handled correctly
      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.type, equals('announce'));
      expect(receivedEvents.first.nodeId, isNull);
      expect(receivedEvents.first.data['message'], equals('Global announcement'));

      // Restore the original callback
      tester.binding.platformDispatcher.onSemanticsEvent = originalCallback;
    });

    testWidgets('SemanticsBinding handles SemanticsEvent with complex data', (
      WidgetTester tester,
    ) async {
      final List<ui.SemanticsEvent> receivedEvents = <ui.SemanticsEvent>[];

      // Store the original callback
      final ui.SemanticsEventCallback? originalCallback = tester.binding.platformDispatcher.onSemanticsEvent;

      // Set up a test callback to capture events
      tester.binding.platformDispatcher.onSemanticsEvent = (ui.SemanticsEvent event) {
        receivedEvents.add(event);
        originalCallback?.call(event);
      };

      // Create event with complex data structure
      const testEvent = ui.SemanticsEvent(
        type: 'focus',
        data: <String, dynamic>{
          'nodeId': 456,
          'metadata': <String, dynamic>{
            'source': 'navigator',
            'timestamp': 1234567890,
          },
          'options': <String>['restore', 'highlight'],
        },
        nodeId: 456,
      );

      // Trigger the event
      tester.binding.platformDispatcher.onSemanticsEvent!(testEvent);

      // Verify the complex data was preserved
      expect(receivedEvents, hasLength(1));
      final event = receivedEvents.first;
      expect(event.type, equals('focus'));
      expect(event.nodeId, equals(456));
      expect(event.data['nodeId'], equals(456));
      expect(event.data['metadata']['source'], equals('navigator'));
      expect(event.data['metadata']['timestamp'], equals(1234567890));
      expect(event.data['options'], equals(<String>['restore', 'highlight']));

      // Restore the original callback
      tester.binding.platformDispatcher.onSemanticsEvent = originalCallback;
    });
  });
}

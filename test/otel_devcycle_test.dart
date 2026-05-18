// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_devcycle/otel_devcycle.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_devcycle-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('variable.value records type + variation + edge', () async {
    await tracedDevcycle<String>(
      operation: 'variable.value',
      invoke: () async => const DevcycleCallResult(
        value: 'ok',
        result: DevcycleResult(
          variableKey: 'show_banner',
          variableType: 'Boolean',
          featureKey: 'banner_test',
          variation: 'on',
          environmentKey: 'production',
          servedFromEdge: true,
          usedDefault: false,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('devcycle variable.value')!);
    expect(a['devcycle.variable.key'], 'show_banner');
    expect(a['devcycle.variable.type'], 'Boolean');
    expect(a['devcycle.feature.key'], 'banner_test');
    expect(a['devcycle.served_from_edge'], true);
  });

  test('used_default sets span error', () async {
    await tracedDevcycle<String>(
      operation: 'variable.defaulted',
      invoke: () async => const DevcycleCallResult(
        value: 'ok',
        result: DevcycleResult(usedDefault: true),
      ),
    );
    expect(
      spans.findSpanByName('devcycle variable.defaulted')!.status,
      SpanStatusCode.Error,
    );
  });

  test('events.flush records batch count', () async {
    await tracedDevcycle<String>(
      operation: 'events.flush',
      invoke: () async => const DevcycleCallResult(
        value: 'ok',
        result: DevcycleResult(eventsBatched: 87),
      ),
    );
    final a = attrsOf(spans.findSpanByName('devcycle events.flush')!);
    expect(a['devcycle.events_batched'], 87);
  });

  test('suppression skips spans', () async {
    await runWithoutDevcycleInstrumentationAsync(() async {
      await tracedDevcycle<String>(
        operation: 'all_variables',
        invoke: () async => const DevcycleCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('devcycle '), isEmpty);
  });
}

// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_devcycle/otel_devcycle.dart';

/// Traces DevCycle calls with OpenTelemetry.
///
/// `otel_devcycle` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each DevCycle call in
/// [tracedDevcycle]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'devcycle-example');

  // Wraps a DevCycle API call in a CLIENT span.
  final devcycleId = await tracedDevcycle<String>(
    operation: 'features.create',
    invoke: () async {
      // Make the DevCycle call here, then report what it returned.
      const id = 'devcycle_8f3a2c';
      return const DevcycleCallResult(
          value: id,
          result: DevcycleResult(
              variableKey: 'orders/2026/inv-1042.pdf',
              variableType: 'Boolean',
              featureKey: 'orders/2026/inv-1042.pdf',
              variation: 'example',
              environmentKey: 'production',
              servedFromEdge: true,
              usedDefault: true,
              eventsBatched: 1,
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedDevcycle features.create returned $devcycleId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutDevcycleInstrumentationAsync.
  await runWithoutDevcycleInstrumentationAsync(
    () => tracedDevcycle<String>(
      operation: 'features.create',
      invoke: () async {
        const id = 'devcycle_8f3a2c';
        return const DevcycleCallResult(
            value: id,
            result: DevcycleResult(
                variableKey: 'orders/2026/inv-1042.pdf',
                variableType: 'Boolean',
                featureKey: 'orders/2026/inv-1042.pdf',
                variation: 'example',
                environmentKey: 'production',
                servedFromEdge: true,
                usedDefault: true,
                eventsBatched: 1,
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}

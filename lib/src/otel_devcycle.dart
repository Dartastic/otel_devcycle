// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_devcycle_suppression.dart';

const _tracerName = 'dartastic_otel_libs_devcycle';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class DevcycleResult {
  /// Creates a result.
  const DevcycleResult({
    this.variableKey,
    this.variableType,
    this.featureKey,
    this.variation,
    this.environmentKey,
    this.servedFromEdge,
    this.usedDefault,
    this.eventsBatched,
    this.requestId,
    this.statusCode,
  });

  /// Variable key.
  final String? variableKey;

  /// `Boolean` / `String` / `Number` / `JSON`.
  final String? variableType;

  /// Parent feature key (variables map to a feature).
  final String? featureKey;

  /// Variation key served.
  final String? variation;

  /// `production` / `staging` / `development` / custom.
  final String? environmentKey;

  /// True when answered from DevCycle edge worker vs origin (DevCycle
  /// runs evaluations at edge by default).
  final bool? servedFromEdge;

  /// True when the SDK fell back to the supplied default.
  final bool? usedDefault;

  /// Events batched in this flush call.
  final int? eventsBatched;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class DevcycleCallResult<T> {
  /// Creates a call result.
  const DevcycleCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final DevcycleResult? result;
}

/// Wraps a DevCycle API call in a CLIENT span. [operation] is one of
/// `variable.value`, `variable.defaulted`, `all_variables`,
/// `all_features`, `events.track`, `events.flush`, `user.identify`,
/// `user.reset`, `features.list`, `features.create`,
/// `variables.list`, `environments.list`, `audiences.list`.
Future<T> tracedDevcycle<T>({
  required String operation,
  required Future<DevcycleCallResult<T>> Function() invoke,
}) async {
  if (devcycleInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'devcycle',
    'rpc.method': operation,
    'devcycle.operation': operation,
  };

  final span = _tracer().startSpan(
    'devcycle $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.variableKey != null) {
        extras.add(OTelAPI.attributeString(
          'devcycle.variable.key',
          r.result!.variableKey!,
        ));
      }
      if (r.result!.variableType != null) {
        extras.add(OTelAPI.attributeString(
          'devcycle.variable.type',
          r.result!.variableType!,
        ));
      }
      if (r.result!.featureKey != null) {
        extras.add(OTelAPI.attributeString(
          'devcycle.feature.key',
          r.result!.featureKey!,
        ));
      }
      if (r.result!.variation != null) {
        extras.add(OTelAPI.attributeString(
          'devcycle.variation',
          r.result!.variation!,
        ));
      }
      if (r.result!.environmentKey != null) {
        extras.add(OTelAPI.attributeString(
          'devcycle.environment.key',
          r.result!.environmentKey!,
        ));
      }
      if (r.result!.servedFromEdge != null) {
        extras.add(OTelAPI.attributeBool(
          'devcycle.served_from_edge',
          r.result!.servedFromEdge!,
        ));
      }
      if (r.result!.usedDefault != null) {
        extras.add(OTelAPI.attributeBool(
          'devcycle.used_default',
          r.result!.usedDefault!,
        ));
        if (r.result!.usedDefault == true) {
          span.setStatus(
            SpanStatusCode.Error,
            'DevCycle returned default value',
          );
        }
      }
      if (r.result!.eventsBatched != null) {
        extras.add(OTelAPI.attributeInt(
          'devcycle.events_batched',
          r.result!.eventsBatched!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'devcycle.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'DevCycle HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

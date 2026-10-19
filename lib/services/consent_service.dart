import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'analytics_service.dart';
import 'consent_mode.dart';

enum PrivacyOptionsResult { updated, notRequired, failed }

abstract class ConsentPlatform {
  Future<void> requestConsentInfoUpdate();
  Future<void> loadAndShowFormIfRequired();
  Future<void> showPrivacyOptionsForm();
  Future<bool> canRequestAds();
  Future<String> consentStatus();
  Future<bool> privacyOptionsRequired();
  Future<({String consentModeValues, String purposeConsents})> readStorage();
}

class ConsentCoordinator {
  ConsentCoordinator({
    ConsentPlatform? platform,
    AnalyticsService? analytics,
    ConsentModeMapper? mapper,
  })  : _platform = platform ?? UmpConsentPlatform(),
        _analytics = analytics,
        _mapper = mapper ?? const ConsentModeMapper();

  final ConsentPlatform _platform;
  final AnalyticsService? _analytics;
  final ConsentModeMapper _mapper;

  ConsentModeDecision decision = ConsentModeDecision.unavailable;

  bool get canRequestAds => decision.canRequestAds;

  Future<ConsentModeDecision> gather({required String source}) async {
    try {
      await _platform.requestConsentInfoUpdate();
      await _platform.loadAndShowFormIfRequired();
      decision = await _read();
    } catch (e, stack) {
      debugPrint('UMP consent failed: $e\n$stack');
      try {
        decision = await _read();
      } catch (inner) {
        debugPrint('UMP consent read failed: $inner');
        decision = ConsentModeDecision.unavailable;
      }
    }
    try {
      await _analytics?.applyConsent(decision, source: source);
    } catch (e) {
      debugPrint('Applying consent mode failed: $e');
    }
    return decision;
  }

  Future<PrivacyOptionsResult> showPrivacyOptions() async {
    try {
      final required = await _platform.privacyOptionsRequired();
      if (!required) return PrivacyOptionsResult.notRequired;
      await _platform.showPrivacyOptionsForm();
      decision = await _read();
      await _analytics?.applyConsent(decision, source: 'settings');
      return PrivacyOptionsResult.updated;
    } catch (e) {
      debugPrint('Privacy options failed: $e');
      return PrivacyOptionsResult.failed;
    }
  }

  Future<ConsentModeDecision> _read() async {
    final storage = await _platform.readStorage();
    final status = await _platform.consentStatus();
    final canRequest = await _platform.canRequestAds();
    return _mapper.decide(
      UmpConsentSnapshot(
        status: status,
        canRequestAds: canRequest,
        consentModeValues: storage.consentModeValues,
        purposeConsents: storage.purposeConsents,
      ),
    );
  }
}

class UmpConsentPlatform implements ConsentPlatform {
  static const _channel = MethodChannel('se.cognifox.blockshade/ump');
  static const _debugGeographyName = String.fromEnvironment('UMP_DEBUG_GEOGRAPHY');

  @override
  Future<void> requestConsentInfoUpdate() {
    final completer = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(consentDebugSettings: _debugSettings()),
        () {
          if (!completer.isCompleted) completer.complete();
        },
        (FormError error) {
          if (!completer.isCompleted) {
            completer.completeError(StateError(error.message));
          }
        },
      );
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }
    return completer.future;
  }

  @override
  Future<void> loadAndShowFormIfRequired() {
    final completer = Completer<void>();
    try {
      ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
        if (!completer.isCompleted) completer.complete();
        if (error != null) {
          debugPrint('Consent form error: ${error.message}');
        }
      });
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }
    return completer.future;
  }

  @override
  Future<void> showPrivacyOptionsForm() {
    final completer = Completer<void>();
    try {
      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (!completer.isCompleted) {
          if (error == null) {
            completer.complete();
          } else {
            completer.completeError(StateError(error.message));
          }
        }
      });
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }
    return completer.future;
  }

  @override
  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('canRequestAds failed: $e');
      return false;
    }
  }

  @override
  Future<String> consentStatus() async {
    try {
      final status = await ConsentInformation.instance.getConsentStatus();
      switch (status) {
        case ConsentStatus.obtained:
          return 'obtained';
        case ConsentStatus.required:
          return 'required';
        case ConsentStatus.notRequired:
          return 'not_required';
        case ConsentStatus.unknown:
          return 'unknown';
      }
    } catch (e) {
      debugPrint('consent status failed: $e');
      return 'unknown';
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      debugPrint('privacy options status failed: $e');
      return false;
    }
  }

  @override
  Future<({String consentModeValues, String purposeConsents})> readStorage() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('readConsentStorage');
      return (
        consentModeValues: raw?['consentModeValues'] as String? ?? '',
        purposeConsents: raw?['purposeConsents'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('UMP storage read failed: $e');
      return (consentModeValues: '', purposeConsents: '');
    }
  }

  ConsentDebugSettings? _debugSettings() {
    final geography = switch (_debugGeographyName) {
      'EEA' => DebugGeography.debugGeographyEea,
      'NOT_EEA' => DebugGeography.debugGeographyOther,
      _ => null,
    };
    if (geography == null) return null;
    return ConsentDebugSettings(debugGeography: geography);
  }
}

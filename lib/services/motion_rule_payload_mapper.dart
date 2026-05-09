import '../models/device_models.dart';

class MotionRulePayload {
  const MotionRulePayload({required this.trigger, required this.action});

  final String trigger;
  final Map<String, Object?> action;
}

class MotionRulePayloadMapper {
  const MotionRulePayloadMapper();

  // UI rules are deliberately display-friendly; this mapper is the single place
  // that translates them into the compact firmware command payload.
  MotionRulePayload toPayload(MotionRule rule) {
    return MotionRulePayload(
      trigger: _triggerForRule(rule),
      action: _actionForRule(rule),
    );
  }

  String _triggerForRule(MotionRule rule) {
    if (rule.id == 'morning') {
      return 'motion.firstAfter.06:00';
    }
    if (rule.id == 'night') {
      return 'motion.after.22:30';
    }
    return 'motion.detected';
  }

  Map<String, Object?> _actionForRule(MotionRule rule) {
    if (rule.id == 'entry') {
      return const <String, Object?>{
        'type': 'playRange',
        'surah': 1,
        'fromAyah': 1,
        'toAyah': 7,
        'repeatCount': 3,
        'volume': 0.55,
      };
    }
    if (rule.id == 'night') {
      return const <String, Object?>{
        'type': 'playRange',
        'surah': 112,
        'fromAyah': 1,
        'toAyah': 4,
        'repeatCount': 1,
        'volume': 0.35,
      };
    }
    return const <String, Object?>{
      'type': 'playRange',
      'surah': 18,
      'fromAyah': 1,
      'toAyah': 10,
      'repeatCount': 1,
      'volume': 0.55,
    };
  }
}

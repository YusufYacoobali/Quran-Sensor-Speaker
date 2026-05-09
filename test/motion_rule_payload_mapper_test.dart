import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_speaker/models/device_models.dart';
import 'package:quran_speaker/services/motion_rule_payload_mapper.dart';

void main() {
  test('maps display motion rules into firmware payloads', () {
    const mapper = MotionRulePayloadMapper();
    const rule = MotionRule(
      id: 'night',
      name: 'Quiet night mode',
      triggerLabel: 'Motion after 10:30 PM',
      actionLabel: 'Play Al-Ikhlas at 35% volume',
      enabled: false,
      icon: Icons.nightlight_outlined,
      accent: Colors.teal,
    );

    final payload = mapper.toPayload(rule);

    expect(payload.trigger, 'motion.after.22:30');
    expect(payload.action['type'], 'playRange');
    expect(payload.action['surah'], 112);
    expect(payload.action['volume'], 0.35);
  });
}

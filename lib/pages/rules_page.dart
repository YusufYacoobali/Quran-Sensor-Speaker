part of 'app_shell.dart';

class RulesPage extends StatelessWidget {
  const RulesPage({required this.controller, super.key});

  final DeviceController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        _PageTitle(
          title: 'Motion Rules',
          subtitle: 'Make the speaker respond when the room comes alive.',
          trailing: FilledButton.icon(
            onPressed: () {
              unawaited(controller.addSuggestedRule());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Suggested rule added')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: 16),
        _RuleBuilderCard(
          onAdd: () {
            unawaited(controller.addSuggestedRule());
          },
        ),
        const SizedBox(height: 16),
        ...controller.rules.map(
          (rule) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RuleCard(
              rule: rule,
              onChanged: (enabled) {
                unawaited(controller.setRuleEnabled(rule.id, enabled));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleBuilderCard extends StatelessWidget {
  const _RuleBuilderCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.motion_photos_on_outlined, color: AppTheme.gold),
          const SizedBox(height: 12),
          const Text(
            'When motion is detected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a surah, ayah range, repeat count, and volume profile.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.ink,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create suggested rule'),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onChanged});

  final MotionRule rule;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: rule.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(rule.icon, color: rule.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    rule.name,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rule.triggerLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    rule.actionLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Switch(value: rule.enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

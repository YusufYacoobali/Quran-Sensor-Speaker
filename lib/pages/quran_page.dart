part of 'app_shell.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({required this.controller, super.key});

  final DeviceController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        const _PageTitle(
          title: 'Quran',
          subtitle: 'Choose a stored recitation range for the speaker.',
        ),
        const SizedBox(height: 16),
        _ReciterSelector(currentReciter: controller.playback.reciter),
        const SizedBox(height: 16),
        ...controller.quranSelections.map(
          (selection) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectionCard(
              selection: selection,
              onPlay: () {
                unawaited(controller.playSelection(selection));
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReciterSelector extends StatelessWidget {
  const _ReciterSelector({required this.currentReciter});

  final String currentReciter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            const CircleAvatar(
              backgroundColor: Color(0xFFDDF3EA),
              foregroundColor: AppTheme.emerald,
              child: Icon(Icons.record_voice_over_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Reciter',
                    style: TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    currentReciter,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({required this.selection, required this.onPlay});

  final QuranSelection selection;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selection.surahNumber.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    selection.surahName,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${selection.translation} - Ayah ${selection.fromAyah}-${selection.toAyah} - ${selection.repeatCount}x',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Play',
              onPressed: onPlay,
              icon: const Icon(Icons.play_arrow),
            ),
          ],
        ),
      ),
    );
  }
}

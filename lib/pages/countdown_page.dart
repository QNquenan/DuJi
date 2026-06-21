import 'package:flutter/material.dart';
import '../models/countdown_event.dart';
import '../services/app_settings.dart';

/// 倒数日页面
class CountdownPage extends StatelessWidget {
  final List<CountdownEvent> events;
  final void Function(int index)? onTap;
  final String searchQuery;
  final DisplayMode displayMode;
  final CountdownSortMode sortMode;

  const CountdownPage({
    super.key,
    this.events = const [],
    this.onTap,
    this.searchQuery = '',
    this.displayMode = DisplayMode.list,
    this.sortMode = CountdownSortMode.created,
  });

  List<CountdownEvent> get _filteredList {
    var list = events.toList();

    // 排序（置顶优先，组内遵守排序规则）
    switch (sortMode) {
      case CountdownSortMode.created:
        list.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return int.parse(b.id).compareTo(int.parse(a.id));
        });
      case CountdownSortMode.eventDate:
        list.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return b.targetDate.compareTo(a.targetDate);
        });
    }

    // 搜索过滤
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((e) =>
              e.emojiName.toLowerCase().contains(q) ||
              e.title.toLowerCase().contains(q) ||
              e.notes.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredList;

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note_outlined, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text('倒数日', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 8),
            Text('还没有日子，点击右下角 + 添加', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('没有匹配的日子', style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (displayMode == DisplayMode.grid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) =>
            _CountdownGridTile(event: filtered[index], index: events.indexOf(filtered[index]), onTap: onTap),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _CountdownTile(event: filtered[index], index: events.indexOf(filtered[index]), onTap: onTap);
      },
    );
  }
}

class _CountdownTile extends StatelessWidget {
  final CountdownEvent event;
  final int index;
  final void Function(int index)? onTap;

  const _CountdownTile({required this.event, required this.index, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = computeCountdownStatus(event);
    final dateStr = status.dateStr;
    final includeStart = appSettings.value.countdownIncludeStartDay;
    final diff = (event.type != CountdownType.anniversary && includeStart && status.diff > 0) ? status.diff + 1 : status.diff;

    String statusText;
    if (event.type == CountdownType.anniversary) {
      statusText = '已经 $diff 周年';
    } else if (diff > 0) {
      statusText = '还有 $diff 天';
    } else if (diff == 0) {
      statusText = '就是今天！';
    } else {
      statusText = '已经 ${-diff} 天';
    }

    Color daysColor;
    if (diff == 0) {
      daysColor = Colors.orange;
    } else if (diff < 0 && event.repeatCycle == RepeatCycle.none) {
      daysColor = cs.onSurfaceVariant;
    } else if (diff > 0 && diff <= 7) {
      daysColor = Colors.orange;
    } else {
      daysColor = cs.primary;
    }

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(index) : null,
      child: Card(
        color: Theme.of(context).cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant, width: 0.5),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(event.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (event.isPinned) ...[
                          Icon(Icons.push_pin, size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            event.title,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: daysColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 网格视图的倒数日卡片
class _CountdownGridTile extends StatelessWidget {
  final CountdownEvent event;
  final int index;
  final void Function(int index)? onTap;

  const _CountdownGridTile({required this.event, required this.index, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = computeCountdownStatus(event);
    final dateStr = status.dateStr;
    final includeStart = appSettings.value.countdownIncludeStartDay;
    final diff = (event.type != CountdownType.anniversary && includeStart && status.diff > 0) ? status.diff + 1 : status.diff;

    String statusText;
    if (event.type == CountdownType.anniversary) {
      statusText = '已经 $diff 周年';
    } else if (diff > 0) {
      statusText = '还有 $diff 天';
    } else if (diff == 0) {
      statusText = '就是今天！';
    } else {
      statusText = '已经 ${-diff} 天';
    }

    Color daysColor;
    if (diff == 0) {
      daysColor = Colors.orange;
    } else if (diff < 0 && event.repeatCycle == RepeatCycle.none) {
      daysColor = cs.onSurfaceVariant;
    } else if (diff > 0 && diff <= 7) {
      daysColor = Colors.orange;
    } else {
      daysColor = cs.primary;
    }

    return GestureDetector(
      onTap: onTap != null ? () => onTap!(index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(event.emoji, style: const TextStyle(fontSize: 26)),
                ),
                if (event.isPinned) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.push_pin, size: 16, color: cs.primary),
                ],
              ],
            ),
            const Spacer(),
            Text(
              event.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: daysColor),
            ),
          ],
        ),
      ),
    );
  }
}

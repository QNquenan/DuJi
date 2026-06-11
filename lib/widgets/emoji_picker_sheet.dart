import 'package:flutter/material.dart';

/// 单个表情选项
class EmojiOption {
  final String emoji;
  final String name;
  const EmojiOption(this.emoji, this.name);
}

/// 预设表情列表
const List<EmojiOption> presetEmojis = [
  EmojiOption('📱', '手机'),
  EmojiOption('⌚️', '手表'),
  EmojiOption('🖥️', '电脑'),
  EmojiOption('🖨️', '打印机'),
  EmojiOption('🖱️', '鼠标'),
  EmojiOption('🖲️', '轨迹球'),
  EmojiOption('🕹️', '游戏机'),
  EmojiOption('📺', '电视'),
  EmojiOption('🎧', '耳机'),
  EmojiOption('💻', '笔记本'),
  EmojiOption('⌨️', '键盘'),
  EmojiOption('📷', '相机'),
  EmojiOption('🎮', '手柄'),
  EmojiOption('🖊️', '笔'),
  EmojiOption('📦', '箱子'),
  EmojiOption('🔑', '钥匙'),
  EmojiOption('💡', '灯泡'),
  EmojiOption('🎒', '背包'),
  EmojiOption('👟', '鞋子'),
  EmojiOption('👕', '衣服'),
  EmojiOption('🕶️', '墨镜'),
  EmojiOption('🧢', '帽子'),
  EmojiOption('💍', '戒指'),
  EmojiOption('🎸', '吉他'),
];

/// 弹出表情选择底部抽屉
/// 返回选中的 [EmojiOption]，取消返回 null
Future<EmojiOption?> showEmojiPicker(BuildContext context) {
  return showModalBottomSheet<EmojiOption>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EmojiPickerSheet(),
  );
}

class _EmojiPickerSheet extends StatefulWidget {
  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  EmojiOption? _selected;

  void _customEmoji() {
    String emojiText = '';
    showDialog<EmojiOption>(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: Theme.of(ctx).dialogTheme.backgroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('自定义表情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 20),
              TextField(
                textAlign: TextAlign.center,
                autofocus: true,
                onChanged: (v) => emojiText = v,
                style: TextStyle(fontSize: 32, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: '😎',
                  hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 32),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(EmojiOption(
                        emojiText.isNotEmpty ? emojiText : '😎',
                        '自定义',
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ).then((result) {
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('选择表情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: presetEmojis.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selected = presetEmojis[i]),
                child: Container(
                  decoration: BoxDecoration(
                    color: _selected?.emoji == presetEmojis[i].emoji
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: _selected?.emoji == presetEmojis[i].emoji
                        ? Border.all(color: cs.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(presetEmojis[i].emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(presetEmojis[i].name,
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('取消', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _customEmoji,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('自定义', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected != null ? () => Navigator.pop(context, _selected) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      disabledBackgroundColor: cs.surfaceContainerHighest,
                      disabledForegroundColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

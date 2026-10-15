/// A lightweight, self-contained emoji picker for the message board composer.
///
/// Deliberately dependency-free: a curated set of emoji is bundled below
/// rather than pulling in a full Unicode database package, keeping the
/// picker small and its layout predictable. Emoji are grouped into a few
/// categories behind a tab bar; tapping one invokes [onSelected] with the
/// literal character so the caller can insert it at the caret.
library;

import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// One emoji category: an icon for the tab bar plus its characters.
class EmojiCategory {
  const EmojiCategory({
    required this.icon,
    required this.emoji,
  });

  final IconData icon;
  final List<String> emoji;
}

/// Curated emoji, grouped by category. Kept modest on purpose — enough for
/// expressive board posts without shipping the entire Unicode emoji set.
const List<EmojiCategory> kEmojiCategories = [
  EmojiCategory(
    icon: Icons.emoji_emotions_outlined,
    emoji: [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
      '🙂', '🙃', '😉', '😊', '😇', '🥰', '😍', '🤩',
      '😘', '😗', '😚', '😙', '🥲', '😋', '😛', '😜',
      '🤪', '😝', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨',
      '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
      '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕',
      '🤢', '🤮', '🥵', '🥶', '🥴', '😵', '🤯', '🤠',
      '🥳', '🥸', '😎', '🤓', '🧐', '😕', '😟', '🙁',
      '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨',
      '😰', '😥', '😢', '😭', '😱', '😖', '😣', '😞',
      '😓', '😩', '😫', '🥱', '😤', '😡', '😠', '🤬',
      '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '👏',
      '🙌', '👐', '🤲', '🙏', '💪', '👀', '👋', '🤝',
    ],
  ),
  EmojiCategory(
    icon: Icons.favorite_outline,
    emoji: [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
      '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
      '💘', '💝', '💟', '💌', '💋', '💯', '💢', '💥',
      '💫', '💦', '💨', '🕳️', '💤', '✨', '⭐', '🌟',
      '🔥', '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🎯',
    ],
  ),
  EmojiCategory(
    icon: Icons.pets_outlined,
    emoji: [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼',
      '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵', '🐔',
      '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺',
      '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞',
      '🐢', '🐍', '🦖', '🐙', '🦑', '🦐', '🦞', '🐬',
      '🐳', '🐋', '🦈', '🐊', '🌵', '🎄', '🌲', '🌳',
      '🌴', '🌱', '🌿', '☘️', '🍀', '🌾', '🌺', '🌻',
      '🌹', '🥀', '🌷', '🌼', '🌸', '💐', '🍄', '🌰',
    ],
  ),
  EmojiCategory(
    icon: Icons.fastfood_outlined,
    emoji: [
      '🍏', '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇',
      '🍓', '🫐', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥',
      '🥝', '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌶️',
      '🌽', '🥕', '🧄', '🧅', '🥔', '🍠', '🥐', '🥯',
      '🍞', '🥖', '🥨', '🧀', '🥚', '🍳', '🧈', '🥞',
      '🧇', '🥓', '🍔', '🍟', '🍕', '🌭', '🥪', '🌮',
      '🍜', '🍝', '🍣', '🍤', '🍦', '🍩', '🍪', '🎂',
      '🍰', '🧁', '🥧', '🍫', '🍬', '🍭', '☕', '🍵',
      '🧃', '🥤', '🍺', '🍻', '🥂', '🍷', '🍾', '🧉',
    ],
  ),
  EmojiCategory(
    icon: Icons.sports_esports_outlined,
    emoji: [
      '⚽', '🏀', '🏈', '⚾', '🥎', '🎾', '🏐', '🏉',
      '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🥅', '⛳',
      '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹',
      '🛼', '🛷', '⛸️', '🥌', '🎿', '⛷️', '🏂', '🪂',
      '🎮', '🕹️', '🎰', '🎲', '🧩', '🧸', '🎭', '🎨',
      '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺',
      '🎸', '🪕', '🎻', '📱', '💻', '⌨️', '🖥️', '🖨️',
      '🚗', '🚕', '🚌', '🚎', '🏎️', '🚓', '✈️', '🚀',
    ],
  ),
  EmojiCategory(
    icon: Icons.tag_outlined,
    emoji: [
      '✅', '❌', '❓', '❗', '‼️', '⁉️', '🔴', '🟠',
      '🟡', '🟢', '🔵', '🟣', '⚫', '⚪', '🟤', '🔺',
      '🔻', '🔸', '🔹', '🔶', '🔷', '▪️', '▫️', '⬛',
      '⬜', '🔈', '🔉', '🔊', '🔇', '📢', '📣', '🔔',
      '🔕', '💬', '💭', '🗯️', '♠️', '♣️', '♥️', '♦️',
      '🃏', '🀄', '🎴', '⏰', '⌛', '⏳', '📅', '📆',
      '🔗', '📌', '📍', '✂️', '🔒', '🔓', '🔑', '🛠️',
      '⚙️', '🔧', '🔨', '💡', '🔦', '🕯️', '🧯', '🛢️',
    ],
  ),
];

/// A compact emoji picker: a category tab bar above a scrollable grid.
///
/// Sized to sit inside the composer sheet without dominating it. The caller
/// owns visibility; this widget only renders the grid and reports taps.
class EmojiPicker extends StatefulWidget {
  const EmojiPicker({
    super.key,
    required this.onSelected,
    this.height = 260,
  });

  /// Invoked with the chosen emoji character.
  final ValueChanged<String> onSelected;

  /// Total height of the picker (tab bar + grid).
  final double height;

  @override
  State<EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<EmojiPicker> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = kEmojiCategories[_category];

    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          // Category tabs: a thin icon row, underline marks the selection.
          SizedBox(
            height: 40,
            child: Row(
              children: [
                for (var i = 0; i < kEmojiCategories.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _category = i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            kEmojiCategories[i].icon,
                            size: 20,
                            color: i == _category
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            height: 2,
                            width: 18,
                            decoration: BoxDecoration(
                              color: i == _category
                                  ? scheme.primary
                                  : Colors.transparent,
                              borderRadius: Radii.smAll,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.sm,
                vertical: Spacing.sm,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 48,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: category.emoji.length,
              itemBuilder: (context, index) {
                final emoji = category.emoji[index];
                return InkWell(
                  onTap: () => widget.onSelected(emoji),
                  borderRadius: Radii.smAll,
                  child: Center(
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

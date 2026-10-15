import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stream_mediary/features/community/emoji_picker.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('EmojiPicker', () {
    testWidgets('renders the first category grid and reports taps',
        (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(
        harness(EmojiPicker(onSelected: selected.add)),
      );

      // The first category's emoji are visible; tapping one reports it.
      final first = kEmojiCategories.first.emoji.first;
      expect(find.text(first), findsOneWidget);
      await tester.tap(find.text(first));
      expect(selected, [first]);
    });

    testWidgets('switching category tab shows that category emoji',
        (tester) async {
      await tester.pumpWidget(
        harness(EmojiPicker(onSelected: (_) {})),
      );

      // Second category's first emoji is not shown until its tab is tapped.
      final secondCategory = kEmojiCategories[1];
      final secondFirst = secondCategory.emoji.first;
      expect(find.text(secondFirst), findsNothing);

      await tester.tap(find.byIcon(secondCategory.icon));
      await tester.pumpAndSettle();
      expect(find.text(secondFirst), findsOneWidget);
    });

    test('every category is non-empty and has an icon', () {
      for (final category in kEmojiCategories) {
        expect(category.emoji, isNotEmpty);
        expect(category.icon, isNotNull);
      }
    });
  });
}

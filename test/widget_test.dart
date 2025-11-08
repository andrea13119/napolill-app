// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:napolill/models/user_prefs.dart';

void main() {
  test('UserPrefs copyWith updates selected topic and keeps others', () {
    final original = UserPrefs(
      selectedTopic: 'selbstbewusstsein',
      level: 'beginner',
      consentAccepted: true,
      privacyAccepted: true,
      agbAccepted: true,
    );

    final updated = original.copyWith(
      selectedTopic: 'selbstwert',
      consentAccepted: false,
    );

    expect(updated.selectedTopic, 'selbstwert');
    expect(updated.level, original.level);
    expect(updated.privacyAccepted, original.privacyAccepted);
    expect(updated.agbAccepted, original.agbAccepted);
    expect(updated.consentAccepted, isFalse);
  });
}

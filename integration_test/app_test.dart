import 'package:bookshelf/main.dart' as app;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('BookShelf real Firebase end-to-end evidence', (tester) async {
    const email = String.fromEnvironment('TEST_EMAIL');
    const password = String.fromEnvironment('TEST_PASSWORD');
    expect(
      email,
      isNotEmpty,
      reason: 'Provide dedicated test account via --dart-define.',
    );
    await app.main();
    await FirebaseAuth.instance.signOut();
    await binding.convertFlutterSurfaceToImage();

    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        if (finder.evaluate().isNotEmpty) return;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      fail('Timed out waiting for $finder');
    }

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 250));
      await binding.takeScreenshot(name);
    }

    Future<void> tapText(String text) async {
      final target = find.text(text).last;
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> enter(String label, String value) async {
      final target = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.ensureVisible(target);
      await tester.enterText(target, value);
      await tester.pump();
    }

    Future<void> choose(String label, String option) async {
      final target = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == label,
      );
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
      await tester.tap(find.text(option).last);
      await tester.pumpAndSettle();
    }

    await waitFor(find.text('Track your books'));
    await shot('01-home');
    await tapText('Register');
    await tapText('Register');
    await shot('02-register-validation');
    await enter(
      'Email',
      'empty.qe190017.${DateTime.now().millisecondsSinceEpoch}@example.com',
    );
    await enter('Password', password);
    await enter('Confirm password', password);
    await tapText('Register');
    await waitFor(find.text('Registration successful'));
    await shot('03-register-success');
    await waitFor(find.text('No books found'));
    await shot('04-empty-state');
    await tapText('Logout');
    await waitFor(find.text('Track your books'));
    await tapText('Login');
    await shot('05-login');
    await enter('Email', email);
    await enter('Password', password);
    await tapText('Login');
    await waitFor(find.text('Atomic Habits'));
    await shot('06-list-after-login');
    await tapText('Add a book');
    await tapText('Add Book');
    await tester.ensureVisible(find.text('Title is required'));
    await shot('07-add-validation');
    const addedTitle = 'A Book for UI Verification';
    await enter('Title', addedTitle);
    await enter('Author', 'QE190017');
    await choose('Genre', 'Fiction');
    await choose('Status', 'Reading');
    await enter('Rating', '4');
    await enter(
      'Notes',
      'Created in the Android emulator to verify the complete book workflow.',
    );
    await tapText('Add Book');
    await waitFor(find.text('Book added'));
    await tapText('Add a book');
    await tester.ensureVisible(find.text(addedTitle));
    await shot('08-add-success');
    await tester.tap(find.widgetWithText(ListTile, addedTitle));
    await tester.pumpAndSettle();
    await shot('09-detail-view');
    await tapText('Edit');
    await enter('Title', ' ');
    await tapText('Save');
    await tester.ensureVisible(find.text('Title is required'));
    await shot('10-detail-edit-validation');
    await enter('Title', addedTitle);
    await enter('Notes', 'Edited and saved from the Detail screen.');
    await tapText('Save');
    await waitFor(find.text('Book saved'));
    await shot('11-detail-after-save');
    await tester.ensureVisible(find.byTooltip('Add to favorites'));
    await shot('12-favorite-before');
    await tester.tap(find.byTooltip('Add to favorites'));
    await waitFor(find.byTooltip('Remove from favorites'));
    await shot('13-favorite-after');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await choose('Genre filter', 'Fiction');
    await shot('14-genre-filter');
    await choose('Status filter', 'Reading');
    await shot('15-status-filter');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await shot('16-favorites-filter');
    await enter('Search', ' UI verification ');
    await shot('17-search');
    await tapText('Clear');
    await tester.ensureVisible(find.text('Books: 6'));
    await shot('18-summary');
    await tester.ensureVisible(find.text(addedTitle));
    await tester.tap(find.widgetWithText(ListTile, addedTitle));
    await tester.pumpAndSettle();
    await tapText('Delete');
    await shot('19-delete-confirmation');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await waitFor(find.text('Your bookshelf'));
    await tester.ensureVisible(find.text('Books: 5'));
    expect(find.text(addedTitle), findsNothing);
    await shot('20-after-delete');
  });
}

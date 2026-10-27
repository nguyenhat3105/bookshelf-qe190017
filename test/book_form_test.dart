import 'package:bookshelf/widgets/book_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Empty Add form shows errors only after submit and clears valid field error', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: BookForm(onSave: (_) async {})))));
    expect(find.text('Title is required'), findsNothing);
    await tester.ensureVisible(find.text('Add Book'));
    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Author is required'), findsOneWidget);
    expect(find.text('Please choose a genre'), findsOneWidget);
    expect(find.text('Please choose a status'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Dune');
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsNothing);
    expect(find.text('Author is required'), findsOneWidget);
  });
}

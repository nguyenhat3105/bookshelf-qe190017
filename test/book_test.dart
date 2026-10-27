import 'package:bookshelf/core/validators.dart';
import 'package:bookshelf/models/book.dart';
import 'package:flutter_test/flutter_test.dart';

Book book(
  String title,
  String author,
  String status, {
  bool favorite = false,
  String genre = 'Fiction',
}) => Book(
  id: bookId('owner', title, author),
  userId: 'owner',
  title: title,
  author: author,
  genre: genre,
  status: status,
  favorite: favorite,
  createdAt: null,
);

void main() {
  test('Canonical identity ignores case and edge spaces, preserves field boundaries', () {
    expect(
      bookId('a', ' Dune ', 'Frank Herbert'),
      bookId('a', 'dune', 'FRANK HERBERT'),
    );
    expect(
      bookId('a', 'Dune', 'Frank Herbert'),
      isNot(bookId('b', 'Dune', 'Frank Herbert')),
    );
    expect(bookId('a', 'a|b', 'c'), isNot(bookId('a', 'a', 'b|c')));
  });
  test('Book validators enforce exact limits and optional integer rating', () {
    expect(Validators.title('   '), 'Title is required');
    expect(Validators.title('a' * 100), isNull);
    expect(Validators.title('a' * 101), 'Title must be at most 100 characters');
    expect(Validators.author('a' * 61), 'Author must be at most 60 characters');
    for (final value in ['-1', '6', '2.5', 'hello']) {
      expect(Validators.rating(value), isNotNull);
    }
    for (final value in ['', '0', '5']) {
      expect(Validators.rating(value), isNull);
    }
    expect(Validators.notes('a' * 301), 'Notes must be at most 300 characters');
  });
  test('Auth validators distinguish login and registration', () {
    expect(Validators.email(''), 'Email is required');
    expect(Validators.email('a@b'), 'Please enter a valid email address');
    expect(Validators.email(' user@example.com '), isNull);
    expect(
      Validators.password('123', register: true),
      'Password must be at least 6 characters',
    );
    expect(Validators.password('123'), isNull);
    expect(Validators.confirm('', '123456'), 'Confirm password is required');
    expect(Validators.confirm('1234567', '123456'), 'Passwords do not match');
  });
  test(
    'All filters combine, sorting ignores case and breaks ties by author',
    () {
      final source = [
        book('dune', 'Z', 'Reading', favorite: true),
        book('Dune', 'A', 'Reading', favorite: true),
        book('Another', 'Dune Writer', 'Finished', genre: 'Academic'),
        book('Other', 'B', 'To Read'),
      ];
      final all = const BookFilter().apply(source);
      expect(all.map((b) => b.author), ['Dune Writer', 'A', 'Z', 'B']);
      final result = const BookFilter(
        genre: 'Fiction',
        status: 'Reading',
        favoritesOnly: true,
        search: ' DUNE ',
      ).apply(source);
      expect(result.map((b) => b.author), ['A', 'Z']);
      expect(const BookFilter(search: 'writer').apply(source).length, 1);
      expect(
        const BookFilter(status: 'Finished', favoritesOnly: true).apply(source),
        isEmpty,
      );
    },
  );
  test('Summary ranks count first, then prescribed status order, and omits empty statuses', () {
    final books = [
      book('A', 'X', 'Finished'),
      book('B', 'X', 'Reading'),
      book('C', 'X', 'To Read'),
    ];
    expect(statusBreakdown(books).map((e) => e.key), statuses);
    expect(
      statusBreakdown([books.first, books.first, books.last]).map((e) => e.key),
      ['Finished', 'To Read'],
    );
    expect(statusBreakdown([]), isEmpty);
  });
}

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const statuses = ['To Read', 'Reading', 'Finished'];

String bookId(String uid, String title, String author) {
  String hash(String value) =>
      sha256.convert(utf8.encode(value.trim().toLowerCase())).toString();
  return '${uid}_${hash(title)}_${hash(author)}';
}

class BookDraft {
  const BookDraft({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.notes = '',
  });
  final String title, author, genre, status, notes;
  final int? rating;
}

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.createdAt,
    this.rating,
    this.favorite = false,
    this.notes = '',
  });
  final String id, userId, title, author, genre, status, notes;
  final int? rating;
  final bool favorite;
  final Timestamp? createdAt;

  factory Book.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Book(
      id: doc.id,
      userId: d['userId'] as String,
      title: d['title'] as String,
      author: d['author'] as String,
      genre: d['genre'] as String,
      status: d['status'] as String,
      rating: d['rating'] as int?,
      favorite: d['favorite'] as bool,
      notes: d['notes'] as String? ?? '',
      createdAt: d['createdAt'] as Timestamp?,
    );
  }
  BookDraft get draft => BookDraft(
    title: title,
    author: author,
    genre: genre,
    status: status,
    rating: rating,
    notes: notes,
  );
}

class BookFilter {
  const BookFilter({
    this.genre = 'All',
    this.status = 'All',
    this.favoritesOnly = false,
    this.search = '',
  });
  final String genre, status, search;
  final bool favoritesOnly;
  List<Book> apply(List<Book> source) {
    final query = search.trim().toLowerCase();
    final result = source
        .where(
          (b) =>
              (genre == 'All' || b.genre == genre) &&
              (status == 'All' || b.status == status) &&
              (!favoritesOnly || b.favorite) &&
              (b.title.toLowerCase().contains(query) ||
                  b.author.toLowerCase().contains(query)),
        )
        .toList();
    result.sort((a, b) {
      final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      return title != 0
          ? title
          : a.author.toLowerCase().compareTo(b.author.toLowerCase());
    });
    return result;
  }
}

List<MapEntry<String, int>> statusBreakdown(List<Book> books) {
  final counts = <String, int>{};
  for (final book in books) {
    counts.update(book.status, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts.entries.toList()..sort((a, b) {
    final count = b.value.compareTo(a.value);
    return count != 0
        ? count
        : statuses.indexOf(a.key).compareTo(statuses.indexOf(b.key));
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/book.dart';

class BookRepository {
  BookRepository({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> get collection =>
      db.collection('books');
  Stream<List<Book>> watch(String uid) => collection
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Book.fromDocument).toList());

  Map<String, dynamic> _data(
    String uid,
    BookDraft draft,
    String id, {
    Book? original,
  }) => {
    'id': id,
    'userId': uid,
    'title': draft.title.trim(),
    'author': draft.author.trim(),
    'genre': draft.genre,
    'status': draft.status,
    'rating': draft.rating,
    'notes': draft.notes,
    'favorite': original?.favorite ?? false,
    'createdAt': original?.createdAt ?? FieldValue.serverTimestamp(),
  };

  Future<String> save(String uid, BookDraft draft, {Book? original}) async {
    final id = bookId(uid, draft.title, draft.author);
    final target = collection.doc(id);
    await db.runTransaction((tx) async {
      final existing = await tx.get(target);
      if (id != original?.id && existing.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'A book with the same title and author already exists.',
        );
      }
      Book? current;
      if (original != null) {
        final old = id == original.id
            ? existing
            : await tx.get(collection.doc(original.id));
        if (!old.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'not-found',
            message: 'This book no longer exists.',
          );
        }
        current = Book.fromDocument(old);
      }
      tx.set(target, _data(uid, draft, id, original: current));
      if (original != null && original.id != id) {
        tx.delete(collection.doc(original.id));
      }
    });
    return id;
  }

  Future<void> favorite(Book book) =>
      collection.doc(book.id).update({'favorite': !book.favorite});
  Future<void> delete(Book book) => collection.doc(book.id).delete();
}

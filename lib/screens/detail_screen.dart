import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../widgets/book_form.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.user,
    required this.initial,
    required this.books,
    required this.repository,
  });
  final User user;
  final Book initial;
  final Stream<List<Book>> books;
  final BookRepository repository;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String id;
  bool editing = false, deleting = false;
  @override
  void initState() {
    super.initState();
    id = widget.initial.id;
  }

  Future<void> delete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('Delete “${book.title}” from your bookshelf?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => deleting = true);
    try {
      await widget.repository.delete(book);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => deleting = false);
        notice(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    initialData: FirebaseAuth.instance.currentUser,
    builder: (context, auth) {
      if (auth.data?.uid != widget.user.uid) {
        return const Scaffold(
          body: Center(child: Text('Please log in to view this book.')),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: StreamBuilder<List<Book>>(
          stream: widget.books,
          initialData: [widget.initial],
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Could not load book: ${snapshot.error}'),
              );
            }
            final matches = (snapshot.data ?? []).where((b) => b.id == id);
            if (matches.isEmpty) {
              return const Center(child: Text('This book no longer exists.'));
            }
            final book = matches.first;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: editing
                      ? BookForm(
                          initial: book.draft,
                          onCancel: () => setState(() => editing = false),
                          onSave: (draft) async {
                            final nextId = await widget.repository.save(
                              widget.user.uid,
                              draft,
                              original: book,
                            );
                            if (mounted && context.mounted) {
                              setState(() {
                                id = nextId;
                                editing = false;
                              });
                              notice(context, 'Book saved');
                            }
                          },
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 64,
                              color: Color(0xff315b49),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              book.title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              book.author,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 24),
                            for (final entry in [
                              ('Genre', book.genre),
                              ('Status', book.status),
                              (
                                'Rating',
                                book.rating?.toString() ?? 'Not rated',
                              ),
                              (
                                'Notes',
                                book.notes.isEmpty ? 'No notes' : book.notes,
                              ),
                            ])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.$1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(entry.$2),
                                  ],
                                ),
                              ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: book.favorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                icon: Icon(
                                  book.favorite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 36,
                                  color: Colors.amber.shade800,
                                ),
                                onPressed: deleting
                                    ? null
                                    : () async {
                                        try {
                                          await widget.repository.favorite(
                                            book,
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            notice(context, e.toString());
                                          }
                                        }
                                      },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                FilledButton(
                                  onPressed: deleting
                                      ? null
                                      : () => setState(() => editing = true),
                                  child: const Text('Edit'),
                                ),
                                OutlinedButton(
                                  onPressed: deleting
                                      ? null
                                      : () => delete(book),
                                  child: Text(
                                    deleting ? 'Deleting…' : 'Delete',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

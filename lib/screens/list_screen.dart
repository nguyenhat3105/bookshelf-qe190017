import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app.dart';
import '../models/book.dart';
import '../repositories/book_repository.dart';
import '../widgets/book_form.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.user});
  final User user;
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final repository = BookRepository();
  final search = TextEditingController();
  late final Stream<List<Book>> books;
  String genre = 'All', status = 'All';
  bool favoritesOnly = false, loggingOut = false;
  @override
  void initState() {
    super.initState();
    books = repository.watch(widget.user.uid);
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    setState(() => loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) notice(context, e.toString());
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
  }

  Widget filter(
    String label,
    String selected,
    List<String> choices,
    ValueChanged<String?> onChanged,
  ) => SizedBox(
    width: 220,
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$selected'),
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        'All',
        ...choices,
      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 76,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List'),
          Text(widget.user.email ?? '', style: const TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loggingOut ? null : logout,
          child: const Text('Logout'),
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.user.email ?? '',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Your bookshelf',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Card(
                child: ExpansionTile(
                  title: const Text('Add a book'),
                  initiallyExpanded: false,
                  childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    BookForm(
                      onSave: (draft) async {
                        await repository.save(widget.user.uid, draft);
                        if (context.mounted) notice(context, 'Book added');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Filter, search and summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Title or author',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  filter(
                    'Genre filter',
                    genre,
                    genres,
                    (v) => setState(() => genre = v!),
                  ),
                  filter(
                    'Status filter',
                    status,
                    statuses,
                    (v) => setState(() => status = v!),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Favorites only'),
                value: favoritesOnly,
                onChanged: (v) => setState(() => favoritesOnly = v),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    genre = 'All';
                    status = 'All';
                    favoritesOnly = false;
                    search.clear();
                  }),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(height: 20),
              StreamBuilder<List<Book>>(
                stream: books,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Could not load books: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final visible = BookFilter(
                    genre: genre,
                    status: status,
                    favoritesOnly: favoritesOnly,
                    search: search.text,
                  ).apply(snapshot.data!);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 24,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    'Books: ${visible.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  Text(
                                    'Favorites: ${visible.where((b) => b.favorite).length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ],
                              ),
                              for (final row in statusBreakdown(visible))
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text('${row.key}: ${row.value}'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (visible.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No books found')),
                        ),
                      for (final book in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                8,
                                12,
                              ),
                              title: Text(
                                book.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${book.author}\n${book.genre} · ${book.status}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                tooltip: book.favorite
                                    ? 'Remove from favorites'
                                    : 'Add to favorites',
                                icon: Icon(
                                  book.favorite
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: book.favorite
                                      ? Colors.amber.shade800
                                      : null,
                                ),
                                onPressed: () async {
                                  try {
                                    await repository.favorite(book);
                                  } catch (e) {
                                    if (context.mounted) {
                                      notice(context, e.toString());
                                    }
                                  }
                                },
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetailScreen(
                                    user: widget.user,
                                    initial: book,
                                    books: books,
                                    repository: repository,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}

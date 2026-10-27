import 'package:flutter/material.dart';

import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    void open(bool register) => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AuthScreen(register: register)));
    return Scaffold(
      appBar: AppBar(
        title: const Text('BookShelf'),
        actions: [
          TextButton(onPressed: () => open(false), child: const Text('Login')),
          TextButton(
            onPressed: () => open(true),
            child: const Text('Register'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 64,
                  color: Color(0xff315b49),
                ),
                const SizedBox(height: 24),
                Text(
                  'BookShelf',
                  style: Theme.of(context).textTheme.displayMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'A little space for your next great read.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep a private collection of books you own or want to read. Organize your reading journey and remember the stories you love.',
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => open(true),
                  child: const Text('Register'),
                ),
                const SizedBox(height: 40),
                for (final item in [
                  (
                    Icons.library_books_outlined,
                    'Track your books',
                    'Your own library, always with you.',
                  ),
                  (
                    Icons.bookmark_border_rounded,
                    'Sort by status',
                    'From To Read to Reading to Finished.',
                  ),
                  (
                    Icons.star_outline_rounded,
                    'Rate your favorites',
                    'Save your favorites, ratings and personal notes.',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Icon(item.$1),
                        title: Text(item.$2),
                        subtitle: Text(item.$3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

# BookShelf

Flutter + Firebase private book tracker for PRM393, FALL 2026.

Student: Nguyễn Công Nhất — QE190017

## Run

1. Install Flutter stable (Dart 3.13 or newer) and an Android SDK.
2. Run `flutter pub get`.
3. Run `flutter run` on Android, or `flutter run -d chrome` for a web preview.
4. Build Android with `flutter build apk --release`.

Firebase project: `bookshelf-qe190017`. Email/Password Authentication is used.
`lib/firebase_options.dart` contains public client configuration only. To use
another Firebase project, replace those client options and publish
`firestore.rules` to that project. No admin or service-account credentials are used.

## Features

Public Home; Firebase Register/Login; private realtime List; validated Add/Edit;
favorite toggles; Detail; confirmed Delete; combined genre/status/favorite/search
filters; counts and ordered status breakdown; empty state; persistent sessions.

## Database identity and uniqueness

Only the `books` collection is used. Each document has `id`, `userId`, `title`,
`author`, `genre`, `status`, optional nullable `rating`, `favorite`, `notes`, and
`createdAt`. Rating defaults to null, favorite to false, notes to an empty string.

The document ID is:

```text
<uid>_<sha256(trim(lower(title)))>_<sha256(trim(lower(author)))>
```

Hashes use UTF-8 and lowercase hex. Hashing each component separately avoids
delimiter ambiguity and supports titles containing slashes. Security Rules
recompute this ID, so arbitrary-ID direct writes cannot introduce duplicate
case-insensitive title/author pairs. A case-only edit retains the ID. Renaming a
book to a different pair uses a transaction that reads the destination, rejects
an existing book, creates the replacement, and deletes the original atomically.
The transaction preserves favorite and creation time.

Direct client writes must use this canonical ID and include a matching `id`
field. Queries must include `where('userId', isEqualTo: currentUser.uid)`.
Unfiltered queries are intentionally denied. Rules validate the owner, field
types, enums, required text and length limits. Security rules remain enabled.

## Verification

```text
flutter analyze lib test
flutter test
npm ci
npm run test:rules
```

Rules tests run against a local demo Firestore Emulator with Java installed.
They exercise ownership, unauthenticated access, forged user IDs, invalid field
writes, canonical identity, missing-document transaction reads, and renames.

Do not put grader passwords in this public repository. The private submission
Word document contains the test account credentials.

## Submission

The ZIP must put `pubspec.yaml` at its root and include `pubspec.lock`, `lib/`,
`android/`, and `firestore.rules`. Exclude build output, caches, `.git`,
`node_modules`, signing keys, and private test credentials. Screenshots must be
captured from real running sessions and captioned in `QE190017.docx`.

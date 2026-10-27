import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { before, after, beforeEach, test } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc, Timestamp, runTransaction } from 'firebase/firestore';

let env;
const uid = 'alice';
const hash = s => createHash('sha256').update(s.trim().toLowerCase()).digest('hex');
const identity = (u, title, author) => `${u}_${hash(title)}_${hash(author)}`;
const data = (overrides = {}) => {
  const value = { userId: uid, title: 'Dune', author: 'Frank Herbert', genre: 'Fiction', status: 'To Read',
    favorite: false, rating: null, notes: '', createdAt: Timestamp.fromMillis(1000), ...overrides };
  return { ...value, id: identity(value.userId, value.title, value.author) };
};
const db = user => env.authenticatedContext(user).firestore();
const ref = (database, d) => doc(database, 'books', d.id);
before(async () => { env = await initializeTestEnvironment({projectId: 'demo-bookshelf', firestore: {rules: readFileSync('firestore.rules', 'utf8')}}); });
after(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

test('Owner can create/read/query/update/delete valid book', async () => {
  const database = db(uid), d = data();
  await assertSucceeds(setDoc(ref(database, d), d));
  await assertSucceeds(getDoc(ref(database, d)));
  await assertSucceeds(getDocs(query(collection(database, 'books'), where('userId', '==', uid))));
  await assertSucceeds(updateDoc(ref(database, d), {favorite: true, rating: 5}));
  await assertSucceeds(deleteDoc(ref(database, d)));
});
test('Owner can transactionally read missing canonical ID before create', async () => {
  const database = db(uid), d = data();
  await assertSucceeds(runTransaction(database, async tx => { await tx.get(ref(database, d)); tx.set(ref(database, d), d); }));
});
test('Anonymous and other accounts cannot access books or forge ownership', async () => {
  const d = data(); await setDoc(ref(db(uid), d), d);
  for (const database of [env.unauthenticatedContext().firestore(), db('bob')]) {
    await assertFails(getDoc(ref(database, d)));
    await assertFails(setDoc(ref(database, d), d));
    await assertFails(updateDoc(ref(database, d), {favorite: true}));
    await assertFails(deleteDoc(ref(database, d)));
    await assertFails(getDocs(collection(database, 'books')));
  }
  await assertFails(updateDoc(ref(db(uid), d), {userId: 'bob'}));
  await assertFails(getDocs(collection(db(uid), 'books')));
});
test('Database rejects each invalid field written directly', async () => {
  const invalid = [{title:''}, {title:'   '}, {title:'x'.repeat(101)}, {author:''}, {author:'  '}, {author:'x'.repeat(61)},
    {genre:'Fantasy'}, {status:'Done'}, {rating:1.5}, {rating:-1}, {rating:6}, {rating:'3'}, {notes:'x'.repeat(301)},
    {favorite:'yes'}, {createdAt:'today'}, {extra:true}];
  for (const values of invalid) {
    const d = data(values); await assertFails(setDoc(ref(db(uid), d), d));
  }
  const missing = data(); delete missing.title;
  await assertFails(setDoc(ref(db(uid), missing), missing));
});
test('Arbitrary IDs cannot bypass case-insensitive uniqueness', async () => {
  const database = db(uid), d = data(); await setDoc(ref(database, d), d);
  const duplicate = data({title:'dune', author:'FRANK HERBERT'});
  await assertFails(setDoc(doc(database, 'books', 'random-duplicate'), {...duplicate, id:'random-duplicate'}));
  await assertFails(setDoc(doc(database, 'books', `${uid}_fake`), {...duplicate, id:`${uid}_fake`}));
  const other = data({userId:'bob'}); await assertSucceeds(setDoc(ref(db('bob'), other), other));
});
test('Canonical title changes require atomic move; conflicting edit is detectable', async () => {
  const database = db(uid), old = data(), next = data({title:'Dune Messiah'});
  await setDoc(ref(database, old), old);
  await assertFails(updateDoc(ref(database, old), {title:'Dune Messiah'}));
  await assertSucceeds(runTransaction(database, async tx => {
    const target = await tx.get(ref(database, next));
    if (target.exists()) throw new Error('duplicate');
    tx.set(ref(database, next), next); tx.delete(ref(database, old));
  }));
  await assertFails(updateDoc(ref(database, next), {createdAt:Timestamp.now()}));
});
test('Optional rating and notes may be absent; unicode and slashes remain valid', async () => {
  const d = data({title:'Sách / Science', author:'Nguyễn Công Nhất'});
  delete d.rating; delete d.notes;
  await assertSucceeds(setDoc(ref(db(uid), d), d));
});
test('Concurrent duplicate transactions create only one book', async () => {
  const database = db(uid), d = data();
  const create = () => runTransaction(database, async tx => {
    const existing = await tx.get(ref(database, d));
    if (existing.exists()) throw new Error('duplicate');
    tx.set(ref(database, d), d);
  });
  const results = await Promise.allSettled([create(), create()]);
  if (results.filter(r => r.status === 'fulfilled').length !== 1) throw new Error('Expected one successful create');
  const books = await getDocs(query(collection(database,'books'),where('userId','==',uid)));
  if (books.size !== 1) throw new Error('Expected exactly one book');
});

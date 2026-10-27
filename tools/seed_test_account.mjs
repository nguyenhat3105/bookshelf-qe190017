// Creates the dedicated grader account using the public client SDK only.
// Credentials live in a gitignored local file, never in this source file.
import { readFileSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { initializeApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword, signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { getFirestore, doc, runTransaction, serverTimestamp, collection, query, where, getDocs, setDoc, terminate } from 'firebase/firestore';

const app = initializeApp({apiKey:'AIzaSyCcQoGzB8pjgvw7wyfGySazrXxqIR1cp4A', projectId:'bookshelf-qe190017', appId:'1:958806753776:web:1acb90b62d9b3209391d35'});
const credentials = JSON.parse(readFileSync('test-account.local.json', 'utf8'));
const auth = getAuth(app);
let user;
try { user = (await createUserWithEmailAndPassword(auth, credentials.email, credentials.password)).user; }
catch (error) {
  if (error.code !== 'auth/email-already-in-use') throw error;
  user = (await signInWithEmailAndPassword(auth, credentials.email, credentials.password)).user;
}
const db = getFirestore(app);
const hash = value => createHash('sha256').update(value.trim().toLowerCase()).digest('hex');
const identity = (title, author) => `${user.uid}_${hash(title)}_${hash(author)}`;
const samples = [
  {title:'Dune', author:'Frank Herbert', genre:'Fiction', status:'Reading', rating:5, favorite:true, notes:'A journey across Arrakis. Read the next chapter this weekend.'},
  {title:'Atomic Habits', author:'James Clear', genre:'Non-Fiction', status:'Finished', rating:4, favorite:true, notes:'Small improvements, repeated consistently.'},
  {title:'Clean Code', author:'Robert C. Martin', genre:'Academic', status:'To Read', rating:null, favorite:false, notes:'Focus on readable functions and meaningful names.'},
  {title:'The Little Prince', author:'Antoine de Saint-Exupéry', genre:'Fiction', status:'Finished', rating:5, favorite:false, notes:'A short story to revisit.'},
  {title:'Design Notes', author:'Alex Morgan', genre:'Other', status:'To Read', rating:null, favorite:false, notes:''},
];
for (const sample of samples) {
  const id = identity(sample.title, sample.author), target = doc(db, 'books', id);
  await runTransaction(db, async tx => {
    const existing = await tx.get(target);
    if (!existing.exists()) tx.set(target, {...sample, id, userId:user.uid, createdAt:serverTimestamp()});
  });
}
const books = await getDocs(query(collection(db, 'books'), where('userId','==',user.uid)));
console.log(`Grader account authenticated; ${books.size} sample books available.`);
const badId = `${user.uid}_invalid-direct-write`;
try {
  await setDoc(doc(db, 'books', badId), {...samples[0], title:'dune', id:badId, userId:user.uid, createdAt:serverTimestamp()});
  throw new Error('SECURITY FAILURE: invalid ID was accepted');
} catch (error) {
  if (error.code !== 'permission-denied') throw error;
  console.log('Published Rules rejected a direct duplicate write with an arbitrary ID.');
}
await signOut(auth);
await terminate(db);

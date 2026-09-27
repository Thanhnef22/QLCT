import { before, after, test } from 'node:test';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { getMetadata, ref, uploadBytes } from 'firebase/storage';

let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'demo-qlct-rules',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync(join('..', 'firestore.rules'), 'utf8'),
    },
    storage: {
      host: '127.0.0.1',
      port: 9199,
      rules: readFileSync(join('..', 'storage.rules'), 'utf8'),
    },
  });
});

after(async () => {
  await environment?.cleanup();
});

test('users can access only their own profile', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  const anonymous = environment.unauthenticatedContext().firestore();

  await assertSucceeds(setDoc(doc(alice, 'users/alice'), { fullName: 'Alice' }));
  await assertSucceeds(getDoc(doc(bob, 'users/bob')));
  await assertFails(getDoc(doc(bob, 'users/alice')));
  await assertFails(setDoc(doc(alice, 'users/bob'), { fullName: 'Intruder' }));
  await assertFails(getDoc(doc(anonymous, 'users/alice')));
  await assertFails(getDocs(collection(alice, 'users')));
});

test('categories, transactions, and budgets stay inside their owner path', async () => {
  const alice = environment.authenticatedContext('alice').firestore();
  const bob = environment.authenticatedContext('bob').firestore();
  for (const kind of ['categories', 'transactions', 'budgets']) {
    const path = `users/alice/${kind}/item`;
    await assertSucceeds(setDoc(doc(alice, path), { value: 1 }));
    await assertSucceeds(getDoc(doc(alice, path)));
    await assertFails(getDoc(doc(bob, path)));
    await assertFails(setDoc(doc(bob, path), { value: 2 }));
  }
});

test('only the owner can upload or read receipt images', async () => {
  const bucket = 'gs://demo-qlct-rules.appspot.com';
  const path = 'receipts/alice/transaction-1/receipt.png';
  const alice = environment.authenticatedContext('alice').storage(bucket);
  const bob = environment.authenticatedContext('bob').storage(bucket);
  const anonymous = environment.unauthenticatedContext().storage(bucket);

  await assertSucceeds(uploadBytes(ref(alice, path), new Uint8Array([1, 2, 3])));
  await assertSucceeds(getMetadata(ref(alice, path)));
  await assertFails(getMetadata(ref(bob, path)));
  await assertFails(uploadBytes(ref(bob, path), new Uint8Array([4])));
  await assertFails(getMetadata(ref(anonymous, path)));
  await assertFails(uploadBytes(ref(alice, 'receipts/bob/transaction-1/receipt.png'), new Uint8Array([5])));
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_qlct/auth/auth_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('register, provision profile, sign in, and reset password', (
    tester,
  ) async {
    final app = await Firebase.initializeApp(
      name: 'auth-integration-test',
      options: const FirebaseOptions(
        apiKey: 'demo-api-key',
        appId: '1:123456789:android:demo',
        messagingSenderId: '123456789',
        projectId: 'demo-qlct-rules',
      ),
    );
    final auth = FirebaseAuth.instanceFor(app: app);
    final firestore = FirebaseFirestore.instanceFor(app: app);
    await auth.useAuthEmulator('10.0.2.2', 9099);
    firestore.useFirestoreEmulator('10.0.2.2', 8080);

    final service = AuthService(auth: auth, firestore: firestore);
    final email = 'test-${DateTime.now().microsecondsSinceEpoch}@example.com';
    const password = 'safePassword123';
    await service.register(
      fullName: 'Nguyễn Minh Anh',
      email: email,
      password: password,
    );

    final uid = service.currentUser!.uid;
    final profile = await firestore.doc('users/$uid').get();
    expect(profile.data()?['fullName'], 'Nguyễn Minh Anh');
    expect(profile.data()?['email'], email);
    final categories = await firestore
        .collection('users/$uid/categories')
        .get();
    expect(categories.docs.length, 13);

    await service.signOut();
    expect(service.currentUser, isNull);
    await service.signIn(email: email, password: password);
    expect(service.currentUser?.uid, uid);
    await service.sendPasswordReset(email);
    await service.signOut();
  });
}

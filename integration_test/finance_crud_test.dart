import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_qlct/auth/auth_service.dart';
import 'package:flutter_qlct/finance/finance_repository.dart';
import 'package:flutter_qlct/finance/finance_rules.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('finance CRUD stays under the signed-in user', (tester) async {
    final app = await Firebase.initializeApp(
      name: 'finance-integration-test',
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
    final email =
        'finance-${DateTime.now().microsecondsSinceEpoch}@example.com';
    await AuthService(
      auth: auth,
      firestore: firestore,
    ).register(fullName: 'User A', email: email, password: 'safePassword123');
    final uid = auth.currentUser!.uid;
    final repository = FinanceRepository(auth: auth, firestore: firestore);
    expect((await repository.watchCategories().first).length, 13);

    final categoryId = await repository.saveCategory(
      name: 'Cafe',
      type: 'expense',
    );
    await repository.saveCategory(
      id: categoryId,
      name: 'Cà phê',
      type: 'expense',
    );
    final transactionId = await repository.saveTransaction(
      amount: 85000,
      categoryId: categoryId,
      date: DateTime(2026, 9, 26),
      note: 'Buổi sáng',
    );
    final budgetId = await repository.saveBudget(
      categoryId: categoryId,
      month: '2026-09',
      limitAmount: 100000,
    );
    expect(budgetId, '2026-09-$categoryId');
    final budget = (await repository.watchBudgets().first).singleWhere(
      (item) => item.id == budgetId,
    );
    expect(
      spentForBudget(await repository.watchTransactions().first, budget),
      85000,
    );
    expect(budgetStatus(85000, budget.limitAmount), BudgetStatus.warning);
    await expectLater(
      repository.saveBudget(
        categoryId: categoryId,
        month: '2026-09',
        limitAmount: 100000,
      ),
      throwsA(isA<FinanceFailure>()),
    );
    await expectLater(
      repository.deleteCategory(categoryId),
      throwsA(isA<FinanceFailure>()),
    );
    await expectLater(
      repository.saveCategory(id: categoryId, name: 'Cà phê', type: 'income'),
      throwsA(isA<FinanceFailure>()),
    );

    final transaction = await firestore
        .doc('users/$uid/transactions/$transactionId')
        .get();
    expect(transaction.data()?['categoryName'], 'Cà phê');
    await repository.saveTransaction(
      id: transactionId,
      amount: 95000,
      categoryId: categoryId,
      date: DateTime(2026, 10, 1),
      note: 'Đã sửa',
    );
    expect(
      (await firestore.doc('users/$uid/transactions/$transactionId').get())
          .data()?['amount'],
      95000,
    );
    expect(
      spentForBudget(await repository.watchTransactions().first, budget),
      0,
    );
    await repository.saveTransaction(
      id: transactionId,
      amount: 120000,
      categoryId: categoryId,
      date: DateTime(2026, 9, 26),
    );
    final updatedSpend = spentForBudget(
      await repository.watchTransactions().first,
      budget,
    );
    expect(updatedSpend, 120000);
    expect(
      budgetStatus(updatedSpend, budget.limitAmount),
      BudgetStatus.exceeded,
    );
    await auth.signOut();
    await AuthService(auth: auth, firestore: firestore).register(
      fullName: 'User B',
      email: 'other-$email',
      password: 'safePassword123',
    );
    expect(await repository.watchTransactions().first, isEmpty);
    expect(await repository.watchBudgets().first, isEmpty);
    await expectLater(
      firestore
          .doc('users/$uid/transactions/$transactionId')
          .get(const GetOptions(source: Source.server)),
      throwsA(isA<FirebaseException>()),
    );

    await auth.signOut();
    await AuthService(
      auth: auth,
      firestore: firestore,
    ).signIn(email: email, password: 'safePassword123');
    expect(auth.currentUser!.uid, uid);
    expect(
      (await repository.watchTransactions().first).single.id,
      transactionId,
    );
    expect((await repository.watchBudgets().first).single.id, budgetId);
    await repository.deleteTransaction(transactionId);
    await repository.deleteBudget(budgetId);
    await repository.saveCategory(
      id: categoryId,
      name: 'Cà phê',
      type: 'income',
    );
    await repository.deleteCategory(categoryId);
  });
}

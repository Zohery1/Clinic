import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_management/src/features/reports/domain/petty_expense_item.dart';

void main() {
  group('PettyExpenseItem Domain Unit Tests', () {
    test('creates PettyExpenseItem and serializes to Map correctly', () {
      final now = DateTime(2026, 11, 3, 14, 0);
      final item = PettyExpenseItem(
        id: 'exp_1',
        title: 'شراء أدوات نظافة ومعقمات',
        amount: 150.50,
        time: now,
      );

      expect(item.id, 'exp_1');
      expect(item.title, 'شراء أدوات نظافة ومعقمات');
      expect(item.amount, 150.50);
      expect(item.time, now);

      final map = item.toMap();
      expect(map['id'], 'exp_1');
      expect(map['title'], 'شراء أدوات نظافة ومعقمات');
      expect(map['amount'], 150.50);
      expect(map['time'], now.toIso8601String());

      final restored = PettyExpenseItem.fromMap(map);
      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.amount, item.amount);
      expect(restored.time, item.time);

      final json = item.toJson();
      expect(json, map);
      final fromJson = PettyExpenseItem.fromJson(json);
      expect(fromJson.id, item.id);
    });

    test('calculates total expenses correctly with multiple items', () {
      final items = [
        PettyExpenseItem(
          id: '1',
          title: 'شاي وقهوة',
          amount: 50.0,
          time: DateTime.now(),
        ),
        PettyExpenseItem(
          id: '2',
          title: 'ورق طباعة روشتات',
          amount: 120.0,
          time: DateTime.now(),
        ),
        PettyExpenseItem(
          id: '3',
          title: 'صيانة جهاز ضغط',
          amount: 230.50,
          time: DateTime.now(),
        ),
      ];

      final total = items.fold<double>(0.0, (acc, item) => acc + item.amount);
      expect(total, 400.50);
    });
  });

  group('Cash Drawer Reconciliation Math & Edge Cases', () {
    test('balanced cash drawer when actual matches expected perfectly', () {
      const openingFloat = 500.0;
      const todayRev = 3500.0;
      const totalExpenses = 400.0;

      const expectedCash = openingFloat + todayRev - totalExpenses;
      expect(expectedCash, 3600.0);

      const actualCash = 3600.0;
      const diff = actualCash - expectedCash;
      expect(diff.abs() < 0.01, isTrue);
    });

    test('detects deficit when actual cash is less than expected', () {
      const openingFloat = 500.0;
      const todayRev = 3000.0;
      const totalExpenses = 200.0;
      const expectedCash = openingFloat + todayRev - totalExpenses; // 3300.0

      const actualCash = 3100.0;
      const diff = actualCash - expectedCash; // -200.0
      expect(diff < 0, isTrue);
      expect(diff.abs(), 200.0);
    });

    test('detects surplus when actual cash is more than expected', () {
      const openingFloat = 500.0;
      const todayRev = 2000.0;
      const totalExpenses = 100.0;
      const expectedCash = openingFloat + todayRev - totalExpenses; // 2400.0

      const actualCash = 2550.0;
      const diff = actualCash - expectedCash; // +150.0
      expect(diff > 0, isTrue);
      expect(diff, 150.0);
    });

    test('handles negative revenue (refund adjustments exceeding collections) gracefully', () {
      const openingFloat = 500.0;
      const todayRev = -300.0; // Refunds exceeded income
      const totalExpenses = 100.0;

      const expectedCash = openingFloat + todayRev - totalExpenses; // 500 - 300 - 100 = 100.0
      expect(expectedCash, 100.0);

      const actualCash = 100.0;
      const diff = actualCash - expectedCash;
      expect(diff.abs() < 0.01, isTrue);
    });

    test('handles zero opening float and zero expenses', () {
      const openingFloat = 0.0;
      const todayRev = 1200.0;
      const totalExpenses = 0.0;

      const expectedCash = openingFloat + todayRev - totalExpenses;
      expect(expectedCash, 1200.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_management/src/core/ui/layout/app_top_bar.dart';
import 'package:clinic_management/src/core/widgets/double_bezel_card.dart';

void main() {
  group('DoubleBezelCard Widget Tests', () {
    testWidgets('renders child content with clinical styling and responds to taps',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleBezelCard(
              onTap: () => tapped = true,
              child: const Text('بطاقة المريض'),
            ),
          ),
        ),
      );

      expect(find.text('بطاقة المريض'), findsOneWidget);

      await tester.tap(find.text('بطاقة المريض'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders layered double-bezel structure and active glow state',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoubleBezelCard(
              isActiveGlow: true,
              outerRadius: 20.0,
              innerRadius: 17.5,
              child: Text('قيد الفحص'),
            ),
          ),
        ),
      );

      expect(find.text('قيد الفحص'), findsOneWidget);

      // Verify Ink widget inside Material provides the inner surface
      final materialFinder = find.descendant(
        of: find.byType(DoubleBezelCard),
        matching: find.byType(Material),
      );
      expect(materialFinder, findsOneWidget);

      final inkFinder = find.descendant(
        of: find.byType(DoubleBezelCard),
        matching: find.byType(Ink),
      );
      expect(inkFinder, findsOneWidget);
    });
  });

  group('AppTopBar Widget Tests', () {
    testWidgets('renders title, live operational status, and global search trigger',
        (tester) async {
      bool searchTapped = false;
      bool notifTapped = false;

      // Provide large desktop size for global search trigger to render
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: AppTopBar(
                title: 'لوحة التحكم السريرية',
                onSearchTap: () => searchTapped = true,
                onNotificationsTap: () => notifTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('لوحة التحكم السريرية'), findsOneWidget);
      expect(find.text('نظام العيادة متصل'), findsOneWidget);

      // Verify global search trigger exists and fires callback
      final searchTrigger = find.text('بحث عن مريض أو موعد...');
      expect(searchTrigger, findsOneWidget);

      await tester.tap(searchTrigger);
      await tester.pumpAndSettle();
      expect(searchTapped, isTrue);

      // Verify notification button fires callback
      final notifButton = find.byIcon(Icons.notifications_none_rounded);
      expect(notifButton, findsOneWidget);
      await tester.tap(notifButton);
      await tester.pumpAndSettle();
      expect(notifTapped, isTrue);
    });

    testWidgets('renders cleanly on narrow desktop viewport without overflow',
        (tester) async {
      // 920px total width with desktop mode active
      tester.view.physicalSize = const Size(920, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: AppTopBar(
                title: 'عيادة الدكتور عبد الرحمن الزهيري التخصصية',
                subtitle: 'إدارة الطابور والمواعيد اليومية',
                onSearchTap: () {},
                compact: false,
                actions: const [
                  SizedBox(width: 140, child: Text('فرع المعادي الرئيسي')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('عيادة الدكتور عبد الرحمن الزهيري التخصصية'), findsOneWidget);
      expect(find.text('بحث عن مريض أو موعد...'), findsOneWidget);
    });

    testWidgets('renders compact search icon button on mobile viewports',
        (tester) async {
      bool mobileSearchTapped = false;

      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: AppTopBar(
                title: 'عيادتي',
                compact: true,
                onSearchTap: () => mobileSearchTapped = true,
              ),
            ),
          ),
        ),
      );

      // Mobile top bar renders search icon button
      final searchIconBtn = find.byIcon(Icons.search_rounded);
      expect(searchIconBtn, findsOneWidget);

      await tester.tap(searchIconBtn);
      await tester.pumpAndSettle();
      expect(mobileSearchTapped, isTrue);
    });
  });
}

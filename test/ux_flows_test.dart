import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nee_construction_app/config/app_theme.dart';
import 'package:nee_construction_app/providers/auth_provider.dart';
import 'package:nee_construction_app/providers/cart_provider.dart';
import 'package:nee_construction_app/providers/product_provider.dart';
import 'package:nee_construction_app/screens/auth/login_screen.dart';
import 'package:nee_construction_app/screens/auth/email_login_screen.dart';
import 'package:nee_construction_app/screens/auth/register_screen.dart';
import 'package:nee_construction_app/screens/calculator_screen.dart';
import 'package:nee_construction_app/screens/products_screen.dart';
import 'package:nee_construction_app/widgets/app_empty_state.dart';
import 'package:nee_construction_app/widgets/app_search_field.dart';

class _Products extends ProductProvider {
  int retries = 0;
  @override
  String? get error => 'offline';
  @override
  Future<void> fetch({bool refresh = false}) async {
    retries++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const capture = bool.fromEnvironment('UX_CAPTURE');
  final captureKey = GlobalKey();

  setUpAll(() async {
    if (capture) {
      const path = String.fromEnvironment('UX_FONT_PATH');
      final loader = FontLoader('UXPreview');
      loader.addFont(
        Future.value(ByteData.sublistView(await File(path).readAsBytes())),
      );
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        Future.value(
          ByteData.sublistView(
            await File.fromUri(
              File(path).uri.resolve('materialicons-regular.otf'),
            ).readAsBytes(),
          ),
        ),
      );
      await icons.load();
    }
  });
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    double width = 390,
    double scale = 1,
    double keyboard = 0,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          theme: AppTheme.light(
            textTheme:
                capture ? ThemeData(fontFamily: 'UXPreview').textTheme : null,
          ),
          scrollBehavior: const AppScrollBehavior(),
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: RepaintBoundary(key: captureKey, child: child!),
              ),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  }

  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!capture) return;
    await tester.runAsync(() async {
      final boundary =
          captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('docs/ux-previews')
        ..createSync(recursive: true);
      await File(
        '${directory.path}/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('Input outlines and labels stay visible against white', () {
    final inputs = AppTheme.light().inputDecorationTheme;
    final border = inputs.enabledBorder! as OutlineInputBorder;
    double contrast(Color color) => 1.05 / (color.computeLuminance() + 0.05);
    expect(contrast(border.borderSide.color), greaterThan(3));
    expect(contrast(inputs.labelStyle!.color!), greaterThan(4.5));
    expect(contrast(inputs.hintStyle!.color!), greaterThan(4.5));
    expect(
      (inputs.focusedBorder! as OutlineInputBorder).borderSide.width,
      greaterThan(border.borderSide.width),
    );
  });

  testWidgets(
    'Search sends the latest query and clearing cancels pending work',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final queries = <String>[];
      await mount(
        tester,
        Scaffold(
          body: AppSearchField(
            controller: controller,
            hint: 'Search',
            onChanged: queries.add,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'ce');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField), 'cement');
      await tester.pump(const Duration(milliseconds: 350));
      expect(queries, ['cement']);
      await tester.enterText(find.byType(TextField), 'steel');
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(queries, ['cement', '']);
      expect(controller.text, isEmpty);
    },
  );

  testWidgets(
    'Empty state remains actionable with large text and little height',
    (tester) async {
      var retried = false;
      await mount(
        tester,
        Scaffold(
          body: AppEmptyState(
            icon: Icons.cloud_off,
            title: 'Could not load products',
            message: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => retried = true,
          ),
        ),
        width: 320,
        scale: 1.6,
        keyboard: 300,
      );
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Phone login renders with clear alternatives', (tester) async {
    await mount(tester, const LoginScreen());
    expect(find.text('Send verification code'), findsOneWidget);
    expect(find.text('Sign in with email'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    await screenshot(tester, 'login');
    await tester.tap(find.text('Send verification code'));
    await tester.pump();
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Login fits a small screen with keyboard and larger text', (
    tester,
  ) async {
    await mount(
      tester,
      const LoginScreen(),
      width: 320,
      scale: 1.4,
      keyboard: 290,
    );
    await tester.ensureVisible(find.text('Sign in with email'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Email login validates and toggles password visibility', (
    tester,
  ) async {
    await mount(tester, const EmailLoginScreen());
    await screenshot(tester, 'email-login');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    final password = tester.widgetList<TextField>(find.byType(TextField)).last;
    expect(password.obscureText, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Signup validates before changing steps and preserves details on back',
    (tester) async {
      await mount(tester, const RegisterScreen());
      await screenshot(tester, 'signup');
      await tester.tap(find.text('Continue to your role'));
      await tester.pump();
      expect(find.text('Step 1 of 2'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Anu Bora');
      await tester.enterText(fields.at(1), 'anu@example.com');
      await tester.enterText(fields.at(2), 'example123');
      await tester.enterText(fields.at(3), 'example123');
      await tester.tap(find.text('Continue to your role'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 2'), findsOneWidget);
      await screenshot(tester, 'signup-role');
      await tester.tap(find.byTooltip('Go back'));
      await tester.pumpAndSettle();
      expect(find.text('Anu Bora'), findsOneWidget);
      expect(find.text('anu@example.com'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Signup keeps its action visible above keyboard', (tester) async {
    await mount(
      tester,
      const RegisterScreen(),
      width: 320,
      scale: 1.3,
      keyboard: 290,
    );
    expect(find.text('Continue to your role').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Product load failure has a working retry action', (
    tester,
  ) async {
    final products = _Products();
    await mount(
      tester,
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: products),
          ChangeNotifierProvider(create: (_) => CartProvider()),
        ],
        child: const ProductsScreen(),
      ),
    );
    expect(find.text('Could not load products'), findsOneWidget);
    final before = products.retries;
    await tester.tap(find.text('Try again'));
    expect(products.retries, before + 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    products.dispose();
  });

  testWidgets('Calculator search narrows the tools and clears correctly', (
    tester,
  ) async {
    await mount(tester, const CalculatorScreen());
    await tester.enterText(find.byType(TextField), 'tiles');
    await tester.pumpAndSettle();
    expect(find.text('Tiles'), findsOneWidget);
    expect(find.text('Concrete Mix'), findsNothing);
    await tester.ensureVisible(find.byType(AppSearchField));
    await screenshot(tester, 'calculator-search');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Concrete Mix'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

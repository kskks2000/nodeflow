import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodeflow_frontend/app/nodeflow_app.dart';
import 'package:nodeflow_frontend/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('renders NodeFlow login screen', (tester) async {
    await tester.pumpWidget(const NodeFlowApp());

    expect(find.text('NodeFlow'), findsWidgets);
    expect(find.text('로그인'), findsWidgets);
    expect(find.byIcon(Icons.business_rounded), findsOneWidget);
    expect(find.byIcon(Icons.badge_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
  });

  testWidgets('navigates to sign up screen', (tester) async {
    await tester.pumpWidget(const NodeFlowApp());

    await tester.ensureVisible(find.text('회원가입'));
    await tester.tap(find.text('회원가입'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsWidgets);
    expect(find.text('회사코드'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('비밀번호 확인'), findsOneWidget);
    expect(find.text('사업자등록번호'), findsNothing);
  });

  testWidgets('navigates to forgot password screen', (tester) async {
    await tester.pumpWidget(const NodeFlowApp());

    await tester.ensureVisible(find.text('비밀번호 찾기'));
    await tester.tap(find.text('비밀번호 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('비밀번호 찾기'), findsWidgets);
    expect(find.text('회사코드'), findsOneWidget);
    expect(find.text('아이디'), findsOneWidget);
    expect(find.text('재설정 요청'), findsOneWidget);
    expect(find.text('비밀번호 확인'), findsNothing);
  });

  testWidgets('prefills login screen from sign up route arguments', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (_) {
          return MaterialPageRoute<void>(
            settings: const RouteSettings(
              arguments: {'companyCode': 'KCASTLE', 'loginId': 'signup_user'},
            ),
            builder: (_) => const LoginScreen(),
          );
        },
      ),
    );

    expect(find.text('KCASTLE'), findsOneWidget);
    expect(find.text('signup_user'), findsOneWidget);
  });
}

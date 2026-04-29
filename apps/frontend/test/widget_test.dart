import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodeflow_frontend/app/nodeflow_app.dart';
import 'package:nodeflow_frontend/features/auth/domain/auth_models.dart';
import 'package:nodeflow_frontend/features/auth/presentation/login_screen.dart';
import 'package:nodeflow_frontend/features/tms/presentation/new_dispatch_screen.dart';
import 'package:nodeflow_frontend/features/tms/presentation/tms_main_screen.dart';
import 'package:nodeflow_frontend/features/tms/presentation/transport_order_form_screen.dart';

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

  testWidgets('renders TMS main dashboard', (tester) async {
    const session = LoginResponse(
      accessToken: 'access',
      refreshToken: 'refresh',
      tokenType: 'bearer',
      expiresIn: 1800,
      user: AuthUser(
        id: 1,
        loginId: 'user001',
        name: '홍길동',
        userType: 'ADMIN',
        roles: ['ADMIN'],
      ),
      tenant: AuthTenant(
        id: 1,
        code: 'TEN001',
        name: '테스트 운송',
        timezone: 'Asia/Seoul',
        locale: 'ko-KR',
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: _TmsMainTestHost(session: session)),
    );

    expect(find.text('TMS Main'), findsOneWidget);
    expect(find.text('운영 대시보드'), findsOneWidget);
    expect(find.text('TMS 프로세스'), findsOneWidget);
    expect(find.text('오더 등록'), findsOneWidget);
    expect(find.text('신규 배차'), findsOneWidget);
    expect(find.text('배차 보드'), findsOneWidget);
    expect(find.text('운송 리스트'), findsOneWidget);
    expect(find.text('차량 상태'), findsOneWidget);
  });

  testWidgets('renders transport order registration workspace', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransportOrderFormScreen()),
    );

    expect(find.text('운송오더 등록 및 확정'), findsOneWidget);
    expect(find.text('기본 정보'), findsOneWidget);
    expect(find.text('상하차 정보'), findsOneWidget);
    expect(find.text('화물 및 차량 조건'), findsOneWidget);
    expect(find.text('등록 검토'), findsOneWidget);
    expect(find.text('등록 및 확정'), findsWidgets);
  });

  testWidgets('renders new dispatch workspace', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NewDispatchScreen()));

    expect(find.text('신규 배차 생성'), findsOneWidget);
    expect(find.text('운송오더 선택'), findsOneWidget);
    expect(find.text('운송 계획'), findsOneWidget);
    expect(find.text('기존 배차 확인'), findsOneWidget);
    expect(find.text('배차 자원 매칭'), findsOneWidget);
    expect(find.text('스케줄 및 지시사항'), findsOneWidget);
    expect(find.text('생성 검토'), findsOneWidget);
  });
}

class _TmsMainTestHost extends StatelessWidget {
  const _TmsMainTestHost({required this.session});

  final LoginResponse session;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) {
        return MaterialPageRoute<void>(
          settings: RouteSettings(arguments: session),
          builder: (_) => const TmsMainScreen(),
        );
      },
    );
  }
}

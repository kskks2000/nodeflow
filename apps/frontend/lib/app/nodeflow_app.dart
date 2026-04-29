import 'package:flutter/material.dart';

import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/tms/presentation/new_dispatch_screen.dart';
import '../features/tms/presentation/tms_main_screen.dart';
import '../features/tms/presentation/transport_order_form_screen.dart';
import 'nodeflow_theme.dart';

class NodeFlowApp extends StatelessWidget {
  const NodeFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NodeFlow',
      theme: NodeFlowTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/sign-up': (context) => const SignUpScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/main': (context) => const TmsMainScreen(),
        '/orders/new': (context) => const TransportOrderFormScreen(),
        '/dispatch/new': (context) => const NewDispatchScreen(),
      },
    );
  }
}

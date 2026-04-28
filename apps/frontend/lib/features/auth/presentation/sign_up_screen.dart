import 'package:flutter/material.dart';

import '../../../app/nodeflow_theme.dart';
import '../data/auth_api_client.dart';
import '../domain/auth_models.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authApiClient = AuthApiClient();
  final _tenantController = TextEditingController(text: 'KCASTLE');
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isSubmitting = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _authApiClient.close();
    _tenantController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final response = await _authApiClient.register(
        RegisterRequest(
          companyCode: _tenantController.text.trim(),
          loginId: _loginIdController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
        arguments: {
          'companyCode': response.tenant.code,
          'loginId': response.user.loginId,
          'registered': true,
        },
      );
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _message = error.message;
        _messageIsError = true;
      });
    }
  }

  void _goBackToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(color: NodeFlowColors.cloud),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Row(
                  children: [
                    const Expanded(flex: 11, child: _SignUpPanel()),
                    Expanded(
                      flex: 9,
                      child: _FormPane(
                        form: _buildForm(context, compact: false),
                      ),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const _MobileHeader(),
                    _FormPane(
                      compact: true,
                      form: _buildForm(context, compact: true),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool compact}) {
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!compact) const _BrandMark(),
          if (!compact) const SizedBox(height: 38),
          Text('회원가입', style: textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'NodeFlow TMS',
            style: textTheme.bodyLarge?.copyWith(
              color: NodeFlowColors.deepBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _tenantController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: '회사코드',
              hintText: 'KCASTLE',
              prefixIcon: Icon(Icons.business_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '회사코드를 입력해 주세요.';
              }
              if (value.trim().length < 3) {
                return '회사코드는 3자 이상이어야 합니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginIdController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            decoration: const InputDecoration(
              labelText: '아이디',
              hintText: 'login_id',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '아이디를 입력해 주세요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: '6자 이상',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 입력해 주세요.';
              }
              if (value.length < 6) {
                return '비밀번호는 6자 이상이어야 합니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordConfirmController,
            obscureText: _obscurePasswordConfirm,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: '비밀번호 확인',
              hintText: '다시 입력',
              prefixIcon: const Icon(Icons.lock_person_rounded),
              suffixIcon: IconButton(
                tooltip: _obscurePasswordConfirm ? '비밀번호 보기' : '비밀번호 숨기기',
                onPressed: () {
                  setState(
                    () => _obscurePasswordConfirm = !_obscurePasswordConfirm,
                  );
                },
                icon: Icon(
                  _obscurePasswordConfirm
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호를 다시 입력해 주세요.';
              }
              if (value != _passwordController.text) {
                return '비밀번호가 일치하지 않습니다.';
              }
              return null;
            },
          ),
          const SizedBox(height: 26),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1_rounded),
            label: Text(_isSubmitting ? '가입 처리 중' : '회원가입'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _goBackToLogin,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('로그인으로 돌아가기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: NodeFlowColors.deepBlue,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: NodeFlowColors.softSlate),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 22),
          if (_message != null)
            _SignUpMessage(message: _message!, isError: _messageIsError),
        ],
      ),
    );
  }
}

class _SignUpMessage extends StatelessWidget {
  const _SignUpMessage({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFB91C1C) : NodeFlowColors.deepBlue;
    final background = isError
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    final border = isError ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_rounded : Icons.verified_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormPane extends StatelessWidget {
  const _FormPane({required this.form, this.compact = false});

  final Widget form;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 560 : 470),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 22 : 48,
            vertical: compact ? 28 : 44,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NodeFlowColors.softSlate),
              boxShadow: [
                BoxShadow(
                  color: NodeFlowColors.ink.withValues(alpha: 0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 24 : 34),
              child: form,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignUpPanel extends StatelessWidget {
  const _SignUpPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: NodeFlowColors.deepBlue),
        ),
        CustomPaint(painter: _AccessRoutePainter()),
        Padding(
          padding: const EdgeInsets.fromLTRB(54, 48, 54, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(onDark: true),
              const Spacer(),
              Text(
                'Create\nNodeFlow\nAccess',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 42,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 28),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AccessPill(
                    icon: Icons.business_rounded,
                    label: 'Company',
                    value: 'Code',
                    accent: NodeFlowColors.mint,
                  ),
                  _AccessPill(
                    icon: Icons.badge_rounded,
                    label: 'Login',
                    value: 'ID',
                    accent: Colors.white,
                  ),
                  _AccessPill(
                    icon: Icons.lock_rounded,
                    label: 'Password',
                    value: 'Secure',
                    accent: NodeFlowColors.amber,
                  ),
                ],
              ),
              const Spacer(),
              const _StatusRail(),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: NodeFlowColors.deepBlue,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandMark(onDark: true),
          SizedBox(height: 22),
          _StatusRail(compact: true),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : NodeFlowColors.ink;
    final subtitle = onDark ? Colors.white70 : NodeFlowColors.slate;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: NodeFlowColors.ink.withValues(
                  alpha: onDark ? 0.18 : 0.08,
                ),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/brand/nodeflow_mark.png',
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NodeFlow',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: foreground, fontSize: 22),
            ),
            Text(
              'TMS Console',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subtitle,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusRail extends StatelessWidget {
  const _StatusRail({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = [
      const _StatusItem(label: 'Account', value: 'Ready'),
      const _StatusItem(label: 'FastAPI', value: 'Live'),
      const _StatusItem(label: 'PostgreSQL', value: 'Sync'),
    ];

    if (compact) {
      return Wrap(spacing: 10, runSpacing: 10, children: children);
    }

    return Row(children: children);
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _LiveDot(),
          const SizedBox(width: 8),
          Text(
            '$label $value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: NodeFlowColors.mint,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: NodeFlowColors.mint.withValues(alpha: 0.45),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _AccessRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(size.width * 0.14, size.height * 0.70),
      Offset(size.width * 0.32, size.height * 0.54),
      Offset(size.width * 0.52, size.height * 0.60),
      Offset(size.width * 0.74, size.height * 0.42),
      Offset(size.width * 0.87, size.height * 0.48),
    ];

    final route = Path()..moveTo(points.first.dx, points.first.dy);
    route.cubicTo(
      size.width * 0.22,
      size.height * 0.58,
      size.width * 0.26,
      size.height * 0.51,
      points[1].dx,
      points[1].dy,
    );
    route.cubicTo(
      size.width * 0.42,
      size.height * 0.56,
      size.width * 0.46,
      size.height * 0.66,
      points[2].dx,
      points[2].dy,
    );
    route.cubicTo(
      size.width * 0.62,
      size.height * 0.50,
      size.width * 0.67,
      size.height * 0.39,
      points[3].dx,
      points[3].dy,
    );
    route.cubicTo(
      size.width * 0.79,
      size.height * 0.41,
      size.width * 0.83,
      size.height * 0.47,
      points[4].dx,
      points[4].dy,
    );

    canvas.drawPath(
      route.shift(const Offset(0, 9)),
      Paint()
        ..color = NodeFlowColors.ink.withValues(alpha: 0.18)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.82)
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = NodeFlowColors.mint.withValues(alpha: 0.88)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isPrimary = i == 2 || i == 4;
      canvas.drawCircle(
        point,
        isPrimary ? 17 : 12,
        Paint()
          ..color = (isPrimary ? Colors.white : NodeFlowColors.mint).withValues(
            alpha: 0.2,
          ),
      );
      canvas.drawCircle(
        point,
        isPrimary ? 7 : 5,
        Paint()..color = isPrimary ? Colors.white : NodeFlowColors.mint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

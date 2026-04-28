import 'package:flutter/material.dart';

import '../../../app/nodeflow_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantController = TextEditingController();
  final _loginIdController = TextEditingController();

  bool _didApplyRoutePrefill = false;
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyRoutePrefill) {
      return;
    }
    _didApplyRoutePrefill = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is! Map) {
      return;
    }

    final companyCode = arguments['companyCode'];
    final loginId = arguments['loginId'];
    if (companyCode is String && companyCode.trim().isNotEmpty) {
      _tenantController.text = companyCode.trim();
    }
    if (loginId is String && loginId.trim().isNotEmpty) {
      _loginIdController.text = loginId.trim();
    }
  }

  @override
  void dispose() {
    _tenantController.dispose();
    _loginIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitted = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: NodeFlowColors.ink,
        content: Text(
          '${_loginIdController.text.trim()} 비밀번호 재설정 요청이 접수되었습니다.',
        ),
      ),
    );
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
                    const Expanded(flex: 11, child: _RecoveryPanel()),
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
          Text('비밀번호 찾기', style: textTheme.headlineLarge),
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.username],
            onFieldSubmitted: (_) => _submit(),
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
          const SizedBox(height: 18),
          const _RecoveryNotice(),
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
                : const Icon(Icons.lock_reset_rounded),
            label: Text(_isSubmitting ? '요청 처리 중' : '재설정 요청'),
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
          if (_submitted) ...[
            const SizedBox(height: 22),
            const _RecoveryMessage(),
          ],
        ],
      ),
    );
  }
}

class _RecoveryNotice extends StatelessWidget {
  const _RecoveryNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NodeFlowColors.cloud,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NodeFlowColors.softSlate),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.admin_panel_settings_rounded,
            color: NodeFlowColors.deepBlue,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '요청 후 관리자 확인을 거쳐 임시 비밀번호 또는 재설정 링크가 발급됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryMessage extends StatelessWidget {
  const _RecoveryMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: NodeFlowColors.deepBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '비밀번호 재설정 요청이 접수되었습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.deepBlue,
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

class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: NodeFlowColors.deepBlue),
        ),
        CustomPaint(painter: _RecoveryRoutePainter()),
        Padding(
          padding: const EdgeInsets.fromLTRB(54, 48, 54, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(onDark: true),
              const Spacer(),
              Text(
                'Recover\nNodeFlow\nAccess',
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
                  _RecoveryPill(
                    icon: Icons.business_rounded,
                    label: 'Company',
                    value: 'Code',
                    accent: NodeFlowColors.mint,
                  ),
                  _RecoveryPill(
                    icon: Icons.badge_rounded,
                    label: 'Login',
                    value: 'ID',
                    accent: Colors.white,
                  ),
                  _RecoveryPill(
                    icon: Icons.lock_reset_rounded,
                    label: 'Reset',
                    value: 'Request',
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
      const _StatusItem(label: 'Account', value: 'Verify'),
      const _StatusItem(label: 'Request', value: 'Ready'),
      const _StatusItem(label: 'Security', value: 'Queued'),
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

class _RecoveryPill extends StatelessWidget {
  const _RecoveryPill({
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
              fontSize: 26,
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

class _RecoveryRoutePainter extends CustomPainter {
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

    final center = Offset(size.width * 0.55, size.height * 0.48);
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, size.shortestSide * 0.18, ringPaint);
    canvas.drawCircle(center, size.shortestSide * 0.26, ringPaint);

    final route = Path()
      ..moveTo(size.width * 0.18, size.height * 0.68)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.54,
        size.width * 0.40,
        size.height * 0.62,
        center.dx,
        center.dy,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.36,
        size.width * 0.78,
        size.height * 0.42,
        size.width * 0.86,
        size.height * 0.34,
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

    final nodes = [
      Offset(size.width * 0.18, size.height * 0.68),
      center,
      Offset(size.width * 0.86, size.height * 0.34),
    ];
    for (final node in nodes) {
      canvas.drawCircle(
        node,
        16,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.drawCircle(node, 6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

import '../../../app/nodeflow_theme.dart';
import '../data/auth_api_client.dart';
import '../domain/auth_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authApiClient = AuthApiClient();
  final _tenantController = TextEditingController(text: 'TEN001');
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _rememberCompany = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _didApplyRoutePrefill = false;

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
    if (arguments['registered'] == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: NodeFlowColors.ink,
            content: Text('회원가입이 완료되었습니다. 로그인해 주세요.'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _authApiClient.close();
    _tenantController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _authApiClient.login(
        LoginRequest(
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

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/main', (route) => false, arguments: response);
    } on AuthFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    }
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
                    const Expanded(flex: 11, child: _OperationsPanel()),
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
                    const _MobileBrandHeader(),
                    _FormPane(
                      form: _buildForm(context, compact: true),
                      compact: true,
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
          Text('로그인', style: textTheme.headlineLarge),
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
              hintText: '예: NF-SEOUL',
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              hintText: 'password',
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
          const SizedBox(height: 14),
          _LoginOptionsRow(
            rememberCompany: _rememberCompany,
            onRememberChanged: (value) {
              setState(() => _rememberCompany = value ?? false);
            },
            onForgotPassword: () {
              Navigator.of(context).pushNamed(
                '/forgot-password',
                arguments: {
                  'companyCode': _tenantController.text.trim(),
                  'loginId': _loginIdController.text.trim(),
                },
              );
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
                : const Icon(Icons.login_rounded),
            label: Text(_isSubmitting ? '인증 중' : '로그인'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pushNamed('/sign-up'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('회원가입'),
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
          if (_errorMessage != null) ...[
            _LoginMessage(message: _errorMessage!, isError: true),
            const SizedBox(height: 14),
          ],
          const _ConnectionStrip(),
        ],
      ),
    );
  }
}

class _LoginMessage extends StatelessWidget {
  const _LoginMessage({required this.message, this.isError = false});

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

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: NodeFlowColors.deepBlue),
        ),
        CustomPaint(painter: _LogisticsMapPainter()),
        Padding(
          padding: const EdgeInsets.fromLTRB(54, 48, 54, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BrandMark(onDark: true),
              const Spacer(),
              Text(
                'Transport\nManagement\nSystem',
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
                  _MetricPill(
                    icon: Icons.route_rounded,
                    label: 'Dispatch',
                    value: '148',
                    accent: NodeFlowColors.mint,
                  ),
                  _MetricPill(
                    icon: Icons.local_shipping_rounded,
                    label: 'Fleet',
                    value: '92',
                    accent: Colors.white,
                  ),
                  _MetricPill(
                    icon: Icons.timer_rounded,
                    label: 'ETA',
                    value: '96%',
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

class _MobileBrandHeader extends StatelessWidget {
  const _MobileBrandHeader();

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

class _LoginOptionsRow extends StatelessWidget {
  const _LoginOptionsRow({
    required this.rememberCompany,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final bool rememberCompany;
  final ValueChanged<bool?> onRememberChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(value: rememberCompany, onChanged: onRememberChanged),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '회사코드 기억',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NodeFlowColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(onPressed: onForgotPassword, child: const Text('비밀번호 찾기')),
      ],
    );
  }
}

class _ConnectionStrip extends StatelessWidget {
  const _ConnectionStrip();

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
        children: [
          const _LiveDot(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'FastAPI Gateway',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NodeFlowColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'PostgreSQL',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: NodeFlowColors.deepBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRail extends StatelessWidget {
  const _StatusRail({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final children = [
      const _StatusItem(label: 'Orders', value: 'Live'),
      const _StatusItem(label: 'Dispatch', value: 'Ready'),
      const _StatusItem(label: 'POD', value: 'Synced'),
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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

class _LogisticsMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (var x = 0.0; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintGrid);
    }
    for (var y = 0.0; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    final points = [
      Offset(size.width * 0.12, size.height * 0.27),
      Offset(size.width * 0.33, size.height * 0.21),
      Offset(size.width * 0.54, size.height * 0.35),
      Offset(size.width * 0.77, size.height * 0.28),
      Offset(size.width * 0.84, size.height * 0.58),
      Offset(size.width * 0.61, size.height * 0.72),
      Offset(size.width * 0.36, size.height * 0.63),
      Offset(size.width * 0.18, size.height * 0.78),
    ];

    final routePaint = Paint()
      ..color = NodeFlowColors.mint.withValues(alpha: 0.58)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, routePaint);

    final ghostPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.13)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.52),
      size.shortestSide * 0.22,
      ghostPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.24, size.height * 0.47),
      size.shortestSide * 0.16,
      ghostPaint,
    );

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isHub = i == 2 || i == 5;
      final nodePaint = Paint()
        ..color = isHub ? Colors.white : NodeFlowColors.mint
        ..style = PaintingStyle.fill;
      final ringPaint = Paint()
        ..color = (isHub ? Colors.white : NodeFlowColors.mint).withValues(
          alpha: 0.22,
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, isHub ? 17 : 12, ringPaint);
      canvas.drawCircle(point, isHub ? 7 : 5, nodePaint);
    }

    final truckPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final truckCenter = Offset(size.width * 0.54, size.height * 0.35);
    final truckBody = RRect.fromRectAndRadius(
      Rect.fromCenter(center: truckCenter, width: 42, height: 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(truckBody, truckPaint);
    canvas.drawCircle(
      truckCenter.translate(-13, 13),
      3.5,
      Paint()..color = NodeFlowColors.deepBlue,
    );
    canvas.drawCircle(
      truckCenter.translate(13, 13),
      3.5,
      Paint()..color = NodeFlowColors.deepBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
